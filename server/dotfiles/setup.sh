#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIRNAME"
. "../../util.sh"

REPO="voidrice"
clone_forked_repo

(
	cd "$REPO_ROOT"
	mv "$REPO_ROOT/.git" "$HOME/.git"
	rm -rf "$REPO_ROOT"
	cd "$HOME"
	git reset --hard HEAD # we don't care about overwriting something because new user
	mv "$HOME/.git" "$HOME/.dotfiles"
)

# ~/.config/aliasrc
config() {
	git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" -c commit.gpgSign=false $*
}

config am "$DIRNAME/server.patch"

# gpg key warning
touch "$HOME/.config/.shell-warn-off"

# TODO: install progs (like LARBS?)

which zsh || sudo apt install -y zsh
chsh -s "$(which zsh)" "$USER"

