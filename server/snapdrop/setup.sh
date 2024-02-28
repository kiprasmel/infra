#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

. "$DIRNAME/../../util.sh"
. "$DIRNAME/vars.sh"

REPO="snapdrop"
clone_forked_repo

CLIENT_ROOT="$REPO_ROOT/client"

NGING_TMP="nginx.conf.tmp"
cp "nginx.conf" "$NGINX_TMP"
replace_vars "$NGINX_TMP" "INFRA_REPO_URL" "PORT" "DOMAIN" "CLIENT_ROOT"
install_nginx_site "$NGINX_TMP" "$DOMAIN"

# custom filepath so won't override existing file
# so can pull w/o conflicts
COMPOSE_FILEPATH="$REPO_ROOT/docker-compose.custom.yml"

cp "docker-compose.yml" "$COMPOSE_FILEPATH"
replace_vars "$COMPOSE_FILEPATH" "INFRA_REPO_URL" "PORT"

cat > start <<EOF
#!/bin/sh
docker-compose -f "$COMPOSE_FILEPATH" up -d
EOF
chmod +x start

cat > stop <<EOF
#!/bin/sh
docker-compose -f "$COMPOSE_FILEPATH" down
EOF
chmod +x stop

sudo docker ps | grep snapdrop && ./stop
./start

