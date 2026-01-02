#!/usr/bin/env bash

set -euo pipefail
set -x

die() {
	>&2 printf "$1"
	exit "${2:-1}"
}
BUG() {
	die "BUG: $1"
}

test "$0" = "${BASH_SOURCE[0]}" && {
	BUG "util.sh should be sourced, not ran.\n"
}

UTILS_DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

. "$UTILS_DIRNAME/vars.sh"

# replace_vars FILE VAR1 VAR2 VAR...
replace_vars() {
	FILE="$1"
	shift

	# replace all given by caller, and all from /vars.sh, and some extras
	for var in "$@" \
		"PERSON_NAME" "GITHUB_USERNAME" "INFRA_REPO_URL" \
		"USER"
	do
		echo "${!var}" | grep "#" >/dev/null \
			&& BUG "variable $var contains sed special char '#' (${!var}).\n"

		sed -i "s#\$${var}#${!var}#g" "$FILE"
	done
}

require_root() {
	test "$(id -u)" -eq 0 || die "script must be run as root.\n"
}

REPO_ROOT_OVERRIDE=
OVERRIDE_INSTEAD_OF_REBASE=0
PRIVATE=0
clone_forked_repo() {
	test -n "$REPO" || {
		BUG "clone_forked_repo: \$REPO not defined\n"
	}

	# we suffix $REPO with '.git'
	# to be automatically git-ignored in the infra repo.
	REPO_ROOT="${REPO_ROOT_OVERRIDE:-${DIRNAME}/${REPO}.git}"
	unset REPO_ROOT_OVERRIDE

	if test -d "$REPO_ROOT"; then
		>&2 printf "warn: not cloning repo - directory already exists ($REPO_ROOT).\n"
	else
		if test "$PRIVATE" -eq 0; then
			git clone $* "https://github.com/$GITHUB_USERNAME/$REPO" "$REPO_ROOT"
		else
			git clone $* "git@github.com:$GITHUB_USERNAME/$REPO" "$REPO_ROOT"
		fi
	fi

	(
		cd "$REPO_ROOT"
		local BRANCH="${BRANCH:-""}"

		test -z "$BRANCH" || {
			local remote="origin"
			git fetch origin "+refs/heads/$BRANCH:refs/remotes/$remote/$BRANCH"

			local curr_branch="$(git branch --show-current)"
			test "$curr_branch" = "$BRANCH" \
				|| git checkout -B "$BRANCH" "$remote/$BRANCH"
		}

		if test "$OVERRIDE_INSTEAD_OF_REBASE" -ne 0; then
			# TODO: check if any local commits present
			# TODO: check if any local uncommitted changes present
			git reset --hard "$remote/$BRANCH"
		else
			git pull --rebase
		fi
	)
}

clone_forked_repo_shallow() {
	clone_forked_repo --depth=1 $*
}

NO_CERTBOT=
CERTBOT_ARGS=
install_nginx_site() {
	test $# -eq 2 || BUG "install_nginx_site: need exactly 2 args (config and domain), got $#.\n"

	local conf="$1"
	shift
	local domain="$1"
	shift

	local NGINX_BASEDIR="/etc/nginx"
	local NGINX_DIR="$NGINX_BASEDIR/sites-available"
	local NGINX_FILEPATH="$NGINX_DIR/$domain"

	sudo mv "$conf" "$NGINX_FILEPATH"

	sudo ln -s -f "$NGINX_FILEPATH" "$NGINX_BASEDIR/sites-enabled/"

	test -n "$NO_CERTBOT" || \
		sudo certbot --keep --nginx --redirect -d "$domain" $CERTBOT_ARGS

	sudo nginx -t

	sudo systemctl reload nginx
}

# install_nginx_site_with_replace DOMAIN VAR1 VAR2 VAR...
#
# if nginx.conf != DOMAIN, simply cp nginx.conf DOMAIN
#
install_nginx_site_with_replace() {
	local domain="$1"
	shift

	test -f "$domain" \
		|| BUG "install_nginx_site_with_replace: nginx config not found for domain '$domain'.\n"

	local nginx_tmp="$domain.tmp"

	cp "$domain" "$nginx_tmp"
	replace_vars "$nginx_tmp" "$@"
	install_nginx_site "$nginx_tmp" "$domain"
}

cache() {
	test $# -eq 1 || die "cache(): expected 1 arg (VARNAME), got $#.\n"
	VARNAME="$1"; shift

	printf "%s\n" "${!VARNAME}" > "${VARNAME}.cache"
}
has_cached() {
	test $# -eq 1 || die "cache(): expected 1 arg (VARNAME), got $#.\n"
	VARNAME="$1"; shift

	test -f "${VARNAME}.cache"
}
read_cached() {
	test $# -eq 1 || die "cache(): expected 1 arg (VARNAME), got $#.\n"
	VARNAME="$1"; shift

	declare -g "${VARNAME}"="$(cat "${VARNAME}.cache")"
}

take_var_or_cache_or_exit() {
	test -n "${!1}" || {
		if has_cached "$1"; then
			read_cached "$1"
		else
			>&2 echo "$1 is not set nor cached."
			exit 1
		fi
	}
}
take_var_or_cache_or_default() {
	set +u
	test -n "${!1}" || {
		if has_cached "$1"; then
			read_cached "$1"
		else
			test $# -eq 2 || \
				BUG "take_var_or_cache_or_default: expected 2 args (var name and default value), got $#."
			declare -g "$1"="$2"
		fi
	}
	set -u
}

# for placing macos daemon .plist configs
MACOS_DAEMON_CONFIG_OUTDIR="$HOME/Library/LaunchAgents"

# env file utilities for managing secrets outside of infra repo
#
# usage in setup.sh:
#   sync_env_file "$REPO_ROOT/.env.example"
#   # creates/updates .env, reports missing vars
#
# usage in deploy script:
#   check_env_file "$REPO_ROOT/.env.example" || exit 1
#   cp .env "$REPO_ROOT/.env"
#

# get required var names from .env.example (lines matching VAR=)
_env_get_required_vars() {
	local example="$1"
	grep -E '^[A-Z_]+=.*$' "$example" | cut -d= -f1
}

# get missing or empty vars from .env compared to .env.example
# returns space-separated list of missing var names
_env_get_missing_vars() {
	local example="$1"
	local env_file="${2:-.env}"
	local missing=""

	for var in $(_env_get_required_vars "$example"); do
		local val
		val=$(grep -E "^${var}=" "$env_file" 2>/dev/null | cut -d= -f2- | tr -d '"' | tr -d "'" || true)
		if [ -z "$val" ]; then
			missing="$missing $var"
		fi
	done

	echo "$missing"
}

# sync .env file with .env.example
# - creates .env from example if missing
# - reports missing/empty vars
# returns 0 if env is ready, 1 if user needs to fill vars
sync_env_file() {
	local example="$1"
	local env_file="${2:-.env}"

	if [ ! -f "$env_file" ]; then
		cp "$example" "$env_file"
		>&2 printf "created %s from template. fill in the values.\n" "$env_file"
		return 1
	fi

	local missing
	missing=$(_env_get_missing_vars "$example" "$env_file")

	if [ -n "$missing" ]; then
		>&2 printf "missing or empty vars in %s:%s\n" "$env_file" "$missing"
		return 1
	fi

	return 0
}

# check if .env file is ready (all vars filled)
# returns 0 if ready, 1 if not
check_env_file() {
	local example="$1"
	local env_file="${2:-.env}"

	if [ ! -f "$env_file" ]; then
		>&2 printf "error: %s not found. run setup.sh first.\n" "$env_file"
		return 1
	fi

	local missing
	missing=$(_env_get_missing_vars "$example" "$env_file")

	if [ -n "$missing" ]; then
		>&2 printf "error: missing or empty vars in %s:%s\n" "$env_file" "$missing"
		return 1
	fi

	return 0
}

# set a var in .env file
# usage: set_env_var VAR_NAME "value"
set_env_var() {
	local var="$1"
	local val="$2"
	local env_file="${3:-.env}"

	if grep -qE "^${var}=" "$env_file" 2>/dev/null; then
		# var exists - replace it
		sed -i "s#^${var}=.*#${var}=${val}#" "$env_file"
	else
		# var doesn't exist - append it
		echo "${var}=${val}" >> "$env_file"
	fi
}
