#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

. "$DIRNAME/../../util.sh"

LOCAL_BIN="$HOME/.local/bin"

SPICETIFY_DIR="$HOME/.config/spicetify"
SPICETIFY_EXT_DIR="$SPICETIFY_DIR/Extensions"
SPICETIFY_THEME_DIR="$SPICETIFY_DIR/Themes"

(
	REPO="spicetify-cli"
	clone_forked_repo

	cd "$REPO_ROOT"
	EXE="spicetify"
	go build -o "$EXE"
	ln -s -f "$REPO_ROOT/$EXE" "$LOCAL_BIN/"
)

(
	REPO="spicetify-themes"
	clone_forked_repo --filter=blob:limit=1M

	cd "$REPO_ROOT"
	find . -type d -maxdepth 1 \
		| grep -vE '(^\.$|.git|^./_)' \
		| xargs -I{} ln -s -f "$REPO_ROOT/{}" "$SPICETIFY_THEME_DIR/"
)
(
	REPO="spicetify-catppuccin"
	clone_forked_repo

	ln -s -f "$REPO_ROOT/catppuccin" "$SPICETIFY_THEME_DIR/"
)
spicetify config current_theme catppuccin

(
	REPO="spicetify-oneko"
	clone_forked_repo

	EXT="oneko.js"
	ln -s -f "$REPO_ROOT/$EXT" "$SPICETIFY_EXT_DIR/"
	spicetify config extensions "$EXT"
)

(
	REPO="spicetify-theblockbuster1"
	clone_forked_repo

	EXT="CoverAmbience.js"
	ln -s -f "$REPO_ROOT/CoverAmbience/$EXT" "$SPICETIFY_EXT_DIR/"
	spicetify config extensions "$EXT"
)

(
	REPO="spicetify-playlist-icons"
	BRANCH="dist"
	clone_forked_repo

	EXT="playlist-icons.js"
	ln -s -f "$REPO_ROOT/$EXT" "$SPICETIFY_EXT_DIR/"
	spicetify config extensions "$EXT"
)

(
	REPO="spicetify-power-bar"
	BRANCH="dist"
	clone_forked_repo

	EXT="power-bar.js"
 	ln -s -f "$REPO_ROOT/$EXT" "$SPICETIFY_EXT_DIR/"
	spicetify config extensions "$EXT"
)

spicetify apply enable-devtools

