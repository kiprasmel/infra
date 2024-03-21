#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIRNAME"
. "$DIRNAME/../../util.sh"
. "$DIRNAME/vars.sh"

REPO="umami"
clone_forked_repo

COMPOSE_FILEPATH="$REPO_ROOT/docker-compose.custom.yml"
cp "docker-compose.yml" "$COMPOSE_FILEPATH"
replace_vars "$COMPOSE_FILEPATH" "PORT" # TODO others

cp "nginx.conf" "$DOMAIN"
install_nginx_site_with_replace "$DOMAIN" "DOMAIN" "PORT"
rm "$DOMAIN"

cat > init <<EOF
#!/bin/bash
set -xeuo pipefail

(
	cd "$REPO_ROOT"
	git pull
)
EOF
chmod +x init

cat > init-with-local-build <<EOF
#!/bin/bash
set -xeuo pipefail

(
	cd "$REPO_ROOT"
	git pull
	docker compose -f "$COMPOSE_FILEPATH" build
)
EOF
chmod +x init-with-local-build

cat > start <<EOF
#!/bin/bash
set -xeuo pipefail

docker ps | grep umami && ./stop
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

./init
./start

