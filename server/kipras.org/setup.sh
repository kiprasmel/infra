#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

. "$DIRNAME/../../util.sh"
. "$DIRNAME/vars.sh"

(
	REPO="draw.kipras.org"
	clone_forked_repo
	install_nginx_site_with_replace "draw.kipras.org" "USER"
)

(
	REPO="kiprasmel.github.io"
	REPO_ROOT="$DIRNAME/kipras.org.git"
	clone_forked_repo
	install_nginx_site_with_replace "kipras.org" "USER"
)

(
	REPO="rusty-grid"
	clone_forked_repo

	install_nginx_site_with_replace "rusty-grid.kipras.org"
)

install_nginx_site_with_replace "ts.kipras.org"
install_nginx_site_with_replace "tt.kipras.org"

