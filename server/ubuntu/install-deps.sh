#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIRNAME"
. "../../util.sh"

sudo apt install build-essential

(
	# nodejs version manager
	REPO="n"
	clone_forked_repo

	cd "$REPO_ROOT"

    # N_PREFIX defined in dotfiles' ~/.profile
	PREFIX="$N_PREFIX" make install

	# install latest stable version of nodejs
	#n stable

	# install specific node version to make sure nothing breaks
	n 16

	# install nodejs deps
	npm i -g yarn
)

