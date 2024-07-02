#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIRNAME"
. "../../util.sh"

REPO="wakapi"
clone_forked_repo

WAKAPI_PASSWORD_SALT="${WAKAPI_PASSWORD_SALT:-}"
NOASK="${NOASK:-}"

gen_salt() {
	WAKAPI_PASSWORD_SALT="$(cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)"
	cache "WAKAPI_PASSWORD_SALT"
}

test -n "$WAKAPI_PASSWORD_SALT" || {
	echo "NO SALT"
	if has_cached "WAKAPI_PASSWORD_SALT"; then
		echo "HAS CACHED"
		read_cached "WAKAPI_PASSWORD_SALT"
	elif test -n "$NOASK"; then
		echo "NOT HAS CACHED"
		gen_salt
	else
		while :; do
			printf "\nWARN: WAKAPI_PASSWORD_SALT not provided.\n[p]rovide existing or [g]enerate new? [p/g]"
			read -r ANS
			test "$ANS" = "p" || test "$ANS" == "P" && {
				printf "\npaste salt:\n"
				read -r WAKAPI_PASSWORD_SALT
				printf "got '%s', proceeding" "$WAKAPI_PASSWORD_SALT"
				cache "WAKAPI_PASSWORD_SALT"
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
replace_vars "$CONFIG_PATH"

(
	cd "$REPO_ROOT"
	go build
)

daemon_macos() {
	PLIST_TEMPLATE="localhost.wakapi.plist"
	PLIST="$MACOS_DAEMON_CONFIG_OUTDIR/$PLIST_TEMPLATE"

	STDOUT="/tmp/wakapi.out.log"
	STDERR="/tmp/wakapi.err.log"

	cp -f "$PLIST_TEMPLATE" "$PLIST"
	replace_vars "$PLIST" "REPO_ROOT" "WAKAPI_PASSWORD_SALT" "STDOUT" "STDERR"
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

