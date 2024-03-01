#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

. "$DIRNAME/../../util.sh"
. "$DIRNAME/vars.sh"

REPO="umami"
clone_forked_repo

echo "# TODO: not setup yet."
exit 1

