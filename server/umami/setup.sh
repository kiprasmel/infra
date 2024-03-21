#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIRNAME"
. "$DIRNAME/../../util.sh"

REPO="umami"
clone_forked_repo

(
	cd "$REPO_ROOT"
)

