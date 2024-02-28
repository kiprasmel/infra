#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

. "$DIRNAME/../../util.sh"
#. "$DIRNAME/vars.sh"

DOMAIN="tvarkarastis.com"
NGINX_TMP="$DOMAIN.tmp"
cp "$DOMAIN" "$NGINX_TMP"
replace_vars "$NGINX_TMP" "INFRA_REPO_URL"

NO_CERTBOT=1 # TODO FIXME
install_nginx_site "$NGINX_TMP" "$DOMAIN"

REPO="turbo-schedule"
BRANCH="whole-week-schedule" # TODO FIXME
clone_forked_repo

cd "$REPO_ROOT"
./run-docker.sh

>&2 printf "\ndeployed turbo-schedule at $DOMAIN. though, for full deployment, re-deploy yourself thru turbo-schedule/deploy.sh\n\n"

