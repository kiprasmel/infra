#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIRNAME"
. "../../util.sh"
. "./vars.sh"

REPO="pr-versions"
GITHUB_USERNAME="pr-versions"
PRIVATE=1
clone_forked_repo

COMPOSE_FILEPATH="$REPO_ROOT/docker-compose.yml"
cp "$DIRNAME/docker-compose.yml" "$COMPOSE_FILEPATH"
replace_vars "$COMPOSE_FILEPATH" "PORT" "DOMAIN" "IMAGE_HOST"

install_nginx_site_with_replace "pr-versions.kipras.org" "DOMAIN" "PORT"

ENV_EXAMPLE="$REPO_ROOT/.env.example"

cat > init <<EOF
#!/bin/bash
set -xeuo pipefail

(
	cd "$REPO_ROOT"
	GIT_SSH_COMMAND="$GIT_SSH_COMMAND" git pull
	docker compose -f "$COMPOSE_FILEPATH" build
)
EOF
chmod +x init

cat > start <<EOF
#!/bin/bash
set -xeuo pipefail

docker ps | grep pr-versions && ./stop || true
(
	cd "$REPO_ROOT"
	docker compose -f "$COMPOSE_FILEPATH" up -d
)
EOF
chmod +x start

cat > stop <<EOF
#!/bin/bash
set -xeuo pipefail

(
	cd "$REPO_ROOT"
	docker compose -f "$COMPOSE_FILEPATH" down
)
EOF
chmod +x stop

cat > deploy <<EOF
#!/bin/bash
set -xeuo pipefail

cd "$DIRNAME"
. "../../util.sh"

check_env_file "$ENV_EXAMPLE" || exit 1
ln -sf "$DIRNAME/.env" "$REPO_ROOT/.env"
./init
./start
EOF
chmod +x deploy

cat > logs <<EOF
#!/bin/bash
set -xeuo pipefail

LEVEL="\${1:-info}"

(
	docker logs pr-versions -f | npx pino-pretty -L "\$LEVEL" -S || sleep 5 && ./logs
)
EOF
chmod +x logs

cat > "exec" <<EOF
#!/bin/bash

docker exec -it pr-versions bash \$*
EOF
chmod +x exec

cat > cli <<EOF
#!/bin/bash
set -xeuo pipefail

docker exec -it pr-versions bash -c "node lib/cli/index.js \$*"
EOF
chmod +x cli

# sync env file (creates .env from example if missing)
sync_env_file "$ENV_EXAMPLE"

# fill in public vars from vars.sh
set_env_var "PORT" "$PORT"
set_env_var "DOMAIN" "$DOMAIN"
set_env_var "IMAGE_HOST" "$IMAGE_HOST"

>&2 printf "\n"
>&2 printf "========================================\n"

set +e
check_env_file "$ENV_EXAMPLE"
env_ready=$?
set -e

if [ $env_ready -eq 0 ]; then
	>&2 printf "\npr-versions ready. running ./deploy\n"
	./deploy
else
	>&2 printf "\nafter filling .env, run: ./deploy\n"
fi
>&2 printf "========================================\n"
