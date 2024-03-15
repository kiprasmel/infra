#!/usr/bin/env bash

# should be standalone, because will be used
# while building the docker image

set -euo pipefail
set -x

# TODO extract
# TODO ssh?
DOTFILES_REPO="https://github.com/kiprasmel/voidrice"

(
	cd "$HOME"
	REPO_ROOT="$HOME/voidrice"
	git clone --depth=1 "$DOTFILES_REPO" "$REPO_ROOT"

	(
		# see infra/server/dotfiles/setup.sh
		cd "$REPO_ROOT"
		mv "$REPO_ROOT/.git" "$HOME/.git"
		rm -rf "$REPO_ROOT"
		cd "$HOME"
		git reset --hard HEAD # we don't care about overwriting something because new user
		mv "$HOME/.git" "$HOME/.dotfiles"
		# manage via `config` instead of via `git`
	)

	# gpg key warning
	mkdir -p "$HOME/.config"
	touch "$HOME/.config/.shell-warn-off"

	which zsh || sudo apt install -y zsh
	chsh -s "$(which zsh)" "$USER"
)

