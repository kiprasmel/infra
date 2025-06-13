#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIRNAME"
. "../../util.sh"

LOCAL_BIN="$HOME/.local/bin"

SPICETIFY_DIR="$HOME/.config/spicetify"
SPICETIFY_EXT_DIR="$SPICETIFY_DIR/Extensions"
SPICETIFY_THEME_DIR="$SPICETIFY_DIR/Themes"
SPICETIFY_APP_DIR="$SPICETIFY_DIR/CustomApps"

(
	REPO="spicetify-cli"
	clone_forked_repo_shallow

	cd "$REPO_ROOT"
	EXE="spicetify"
	go build -o "$EXE"
	ln -s -f "$REPO_ROOT/$EXE" "$LOCAL_BIN/"
)

which spicetify-creator || (
	REPO="spicetify-creator"
	clone_forked_repo_shallow

	(
		cd "$REPO_ROOT"
		yarn

		cd "packages/spicetify-creator/"
		yarn
		yarn build

		chmod +x dist/index.js
		ln -s $PWD/dist/index.js "$(yarn global bin)/spicetify-creator"
	)
)

(
	REPO="spicetify-themes"
	clone_forked_repo_shallow --filter=blob:limit=1M

	cd "$REPO_ROOT"
	find . -type d -maxdepth 1 \
		| grep -vE '(^\.$|.git|^./_)' \
		| xargs -I{} ln -s -f "$REPO_ROOT/{}" "$SPICETIFY_THEME_DIR/"
)

(
	REPO="spicetify-catppuccin"
	clone_forked_repo_shallow

	ln -s -f "$REPO_ROOT/catppuccin" "$SPICETIFY_THEME_DIR/"
)

(
	base="galaxy"
	REPO="spicetify-$base"
	clone_forked_repo_shallow

	ln -s -f "$REPO_ROOT" "$SPICETIFY_THEME_DIR/$base"
)
(
	base="ziro"
	REPO="spicetify-$base"
	clone_forked_repo_shallow

	ln -s -f "$REPO_ROOT" "$SPICETIFY_THEME_DIR/$base"
)
(
	base="retroblur"
	REPO="spicetify-$base"
	clone_forked_repo_shallow

	ln -s -f "$REPO_ROOT" "$SPICETIFY_THEME_DIR/$base"
)

(
	REPO="spicetify-oneko"
	clone_forked_repo_shallow

	EXT="oneko.js"
	ln -s -f "$REPO_ROOT/$EXT" "$SPICETIFY_EXT_DIR/"
	spicetify config extensions "$EXT"
)

(
	REPO="spicetify-theblockbuster1"
	clone_forked_repo_shallow

	EXT="CoverAmbience.js"
	ln -s -f "$REPO_ROOT/CoverAmbience/$EXT" "$SPICETIFY_EXT_DIR/"
	spicetify config extensions "$EXT"
)

(
	REPO="spicetify-playlist-icons"
	BRANCH="dist"
	OVERRIDE_INSTEAD_OF_REBASE=1
	clone_forked_repo_shallow

	EXT="playlist-icons.js"
	ln -s -f "$REPO_ROOT/$EXT" "$SPICETIFY_EXT_DIR/"
	spicetify config extensions "$EXT"
)

(
	REPO="spicetify-power-bar"
	BRANCH="dist"
	clone_forked_repo_shallow

	EXT="power-bar.js"
 	ln -s -f "$REPO_ROOT/$EXT" "$SPICETIFY_EXT_DIR/"
	spicetify config extensions "$EXT"
)

(
	REPO="spicetify-pithaya"

	# fix - constantly getting untracked changes
	pushd "$REPO.git"
	git reset --hard
	popd

	clone_forked_repo_shallow

	(
		cd "$REPO_ROOT"
		git clean -xdf
		npm ci
		#npm run build-local --workspaces --if-present
	)

	(
		cd "$REPO_ROOT/extensions/made-for-you-shortcut/"
		npm run build-local

		EXT="made-for-you-shortcut.js"
		ln -s -f "$PWD/dist/$EXT" "$SPICETIFY_EXT_DIR/"
		spicetify config extensions "$EXT"
	)

	(
		cd "$REPO_ROOT/custom-apps/eternal-jukebox/"
		npm run build-local

		APP="eternal-jukebox"
		ln -s -f "$PWD/dist" "$SPICETIFY_APP_DIR/$APP"
		spicetify config custom_apps "$APP"
	)
)

(
	base="ncs-visualizer"
	REPO="spicetify-$base"
	BRANCH="dist"
	OVERRIDE_INSTEAD_OF_REBASE=1
	clone_forked_repo_shallow

	ln -s -f "$REPO_ROOT" "$SPICETIFY_APP_DIR/$base"
	spicetify config custom_apps "$base"
)

(
	base="stats"
	REPO="spicetify-apps"
	BRANCH="dist"
	OVERRIDE_INSTEAD_OF_REBASE=1
	clone_forked_repo_shallow

	ln -s -f "$REPO_ROOT" "$SPICETIFY_APP_DIR/$base"
	spicetify config custom_apps stats
)

#spicetify config current_theme catppuccin
#spicetify config current_theme retroblur
#spicetify config current_theme galaxy # + background from retroblur = 🔥

spicetify apply enable-devtools

