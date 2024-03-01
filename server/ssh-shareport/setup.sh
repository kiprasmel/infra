#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIRNAME"
. "../../util.sh"
. "./vars.sh"

HTML="index.generated.html"
cp "index.html" "$HTML"
replace_vars "$HTML"

cp "nginx.conf" "$DOMAIN"
(
	CERTBOT_ARGS="--no-redirect"
	install_nginx_site_with_replace "$DOMAIN" "DOMAIN" "PORT" "USER"
)
rm "$DOMAIN"

