#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIRNAME"
. "../../util.sh"
. "./vars.sh"

REPO="turbo-schedule"
clone_forked_repo

(
	cd "$REPO_ROOT"
	./run-docker.sh
)

install_nginx_site_with_replace "tvarkarastis.com" "PORT" "CONFIG_URL"

>&2 printf "\ndeployed turbo-schedule. though, for full deployment, re-deploy yourself thru turbo-schedule/deploy.sh\n\n"
