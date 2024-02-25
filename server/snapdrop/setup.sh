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

NGINX_BASEDIR="/etc/nginx"
NGINX_DIR="$NGINX_BASEDIR/sites-available"
NGINX_FILEPATH="$NGINX_DIR/$DOMAIN"
NGINX_TMP="nginx.conf.tmp"
cp "nginx.conf" "$NGINX_TMP"
replace_vars "$NGINX_TMP" "INFRA_REPO_URL" "PORT" "DOMAIN" "CLIENT_ROOT"
sudo mv "$NGINX_TMP" "$NGINX_FILEPATH"

sudo ln -s -f "$NGINX_FILEPATH" "$NGINX_BASEDIR/sites-enabled/"
sudo nginx -t

sudo certbot --nginx --redirect -d "$DOMAIN" -d "www.$DOMAIN"
sudo nginx -t

sudo systemctl reload nginx

# custom filepath so won't override existing file
# so can pull w/o conflicts
COMPOSE_FILEPATH="$REPO_ROOT/docker-compose.custom.yml"

cp "docker-compose.yml" "$COMPOSE_FILEPATH"
replace_vars "$COMPOSE_FILEPATH" "PORT"

(
	cd "$REPO_ROOT/server"
	npm i
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

