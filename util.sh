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
		echo "${!var}" | grep "@" >/dev/null \
			&& BUG "variable $var contains sed special char '@' (${!var}).\n"

		sed -i "s@\$${var}@${!var}@g" "$FILE"
	done
}

require_root() {
	test "$(id -u)" -eq 0 || die "script must be run as root.\n"
}

REPO_ROOT_OVERRIDE=
OVERRIDE_INSTEAD_OF_REBASE=0
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
		git clone $* "https://github.com/$GITHUB_USERNAME/$REPO" "$REPO_ROOT"
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
		sudo certbot --keep --nginx --redirect -d "$domain" -d "www.$domain" $CERTBOT_ARGS

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

