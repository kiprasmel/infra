#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

. "$DIRNAME/../../util.sh"
. "$DIRNAME/vars.sh"

cp "nginx.conf" "$DOMAIN"
install_nginx_site_with_replace "$DOMAIN" "INFRA_REPO_URL" "DOMAIN" "PORT" "USER"
rm "$DOMAIN"

