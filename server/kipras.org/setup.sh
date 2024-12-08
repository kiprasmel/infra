#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIRNAME"
. "../../util.sh"
. "./vars.sh"

(
	REPO="draw.kipras.org"
	clone_forked_repo
	install_nginx_site_with_replace "draw.kipras.org" "USER"
)

(
	REPO="kiprasmel.github.io"
	REPO_ROOT_OVERRIDE="$DIRNAME/kipras.org.git"
	clone_forked_repo
	install_nginx_site_with_replace "kipras.org" "USER"
)

(
	REPO="rusty-grid"
	BRANCH="gh-pages"
	OVERRIDE_INSTEAD_OF_REBASE=1
	clone_forked_repo

	install_nginx_site_with_replace "rusty-grid.kipras.org"
)

(
	REPO="surfe-note-app"
	REPO_ROOT_OVERRIDE="$DIRNAME/note.kipras.org.git"
	clone_forked_repo

	cat > build-note <<EOF
#!/bin/bash
set -xeuo pipefail
cd "$REPO_ROOT"
git pull
yarn
yarn build
EOF
	chmod +x build-note

	./build-note

	install_nginx_site_with_replace "note.kipras.org"
)

install_nginx_site_with_replace "ts.kipras.org"
install_nginx_site_with_replace "tt.kipras.org"

