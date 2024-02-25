#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

. "$DIRNAME/../../util.sh"

REPO="wakapi"
clone_forked_repo

WAKAPI_PASSWORD_SALT="${WAKAPI_PASSWORD_SALT:-}"
NOASK="${NOASK:-}"

SALT_CACHE="salt-cache.generated"
PLIST_OUTDIR="$HOME/Library/LaunchAgents"

gen_salt() {
	WAKAPI_PASSWORD_SALT="$(cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)"
	cache_salt
}
cache_salt() {
	printf "%s\n" "$WAKAPI_PASSWORD_SALT" > "$SALT_CACHE"
}

test -z "$WAKAPI_PASSWORD_SALT" && {
	if test -f "$SALT_CACHE"; then
		WAKAPI_PASSWORD_SALT="$(cat "$SALT_CACHE")"
	elif test -n "$NOASK"; then
		gen_salt
	else
		while :; do
			printf "\nWARN: WAKAPI_PASSWORD_SALT not provided.\n[p]rovide existing or [g]enerate new? [p/g]"
			read -r ANS
			test "$ANS" = "p" || test "$ANS" == "P" && {
				printf "\npaste salt:\n"
				read -r WAKAPI_PASSWORD_SALT
				printf "got '%s', proceeding" "$WAKAPI_PASSWORD_SALT"
				cache_salt
				break
			}
			test "$ANS" = "g" || test "$ANS" == "G" && {
				gen_salt
				break
			}
		done
	fi
}

CONFIG_PATH="$REPO_ROOT/config.yml"
cp config.yml "$CONFIG_PATH"
replace_vars "$CONFIG_PATH" "INFRA_REPO_URL"

(
	cd "$REPO_ROOT"
	go build
)

daemon_macos() {
	PLIST_TEMPLATE="localhost.wakapi.plist"
	PLIST="$PLIST_OUTDIR/$PLIST_TEMPLATE"

	STDOUT="/tmp/wakapi.out.log"
	STDERR="/tmp/wakapi.err.log"
	
	cp -f "$PLIST_TEMPLATE" "$PLIST"
	replace_vars "$PLIST" "INFRA_REPO_URL" "REPO_ROOT" "WAKAPI_PASSWORD_SALT" "STDOUT" "STDERR"
	chmod 644 "$PLIST"

	cat > stop <<EOF
#!/bin/sh
launchctl list | grep wakapi && launchctl unload -w "$PLIST"
EOF
	chmod +x ./stop

	cat > start <<EOF
#!/bin/sh
./stop
launchctl load -w "$PLIST"
EOF
	chmod +x start

	./start
}

case "$OSTYPE" in
	darwin*)
		daemon_macos
		;;
	*)
		echo "$0: non-darwin os ($OSTYPE) not implemented yet"
		exit 1
	;;
esac

