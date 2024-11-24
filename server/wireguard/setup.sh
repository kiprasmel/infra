#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIRNAME"
. "../../util.sh"
. "./vars.sh"

REPO="wireguard-install"
clone_forked_repo
(
	cd "$REPO_ROOT"
	sudo bash ./wireguard-install.sh
)
