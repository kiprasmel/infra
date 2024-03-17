#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIRNAME"
. "../../util.sh"
. "./vars.sh"

REPO="snapdrop"
clone_forked_repo

CLIENT_ROOT="$REPO_ROOT/client"

cp "nginx.conf" "$DOMAIN"
install_nginx_site_with_replace "$DOMAIN" "PORT" "DOMAIN" "CLIENT_ROOT"
rm "$DOMAIN"

# custom filepath so won't override existing file
# so can pull w/o conflicts
COMPOSE_FILEPATH="$REPO_ROOT/docker-compose.custom.yml"

cp "docker-compose.yml" "$COMPOSE_FILEPATH"
replace_vars "$COMPOSE_FILEPATH" "PORT"

(
	cd "$REPO_ROOT/server"
	npm ci
)

cat > start <<EOF
#!/bin/sh
docker compose -f "$COMPOSE_FILEPATH" up -d
EOF
chmod +x start

cat > stop <<EOF
#!/bin/sh
docker compose -f "$COMPOSE_FILEPATH" down
EOF
chmod +x stop

docker ps | grep snapdrop && ./stop
./start

