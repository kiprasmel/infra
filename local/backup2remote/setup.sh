#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIRNAME"
. "$DIRNAME/../../util.sh"
. "$DIRNAME/vars.sh"

main() {
	# define backup jobs
	GPG_ARG="$G_GPG_ARG"
	REMOTE_ARG="$G_REMOTE_ARG"
	REMOTE_DIR="$G_REMOTE_DIR"

	ID="notes"
	BACKUP_DIR="$HOME/Documents/notes"
	create_backup_script

	# enable daemon
	case "$OSTYPE" in
		darwin*)
			daemon_macos
			;;
		*)
			echo "$0: non-darwin os ($OSTYPE) not implemented yet"
			exit 1
		;;
	esac
}

BACKUP_RUNNER="$DIRNAME/backup-runner.sh"

# creates a generated script,
# that will be called by BACKUP_RUNNER,
# which itself will be called by a daemon/cronjob
# on a schedule.
ID=
BACKUP_DIR=
REMOTE_DIR=
REMOTE_ARG=
GPG_ARG=
create_backup_script() {
	GEN_SCRIPT="run.$ID"

	cat > "$GEN_SCRIPT" <<EOF
#!/bin/sh

ID="$ID" BACKUP_DIR="$BACKUP_DIR" REMOTE_DIR="$REMOTE_DIR" REMOTE_ARG="$REMOTE_ARG" GPG_ARG="$GPG_ARG" "$DIRNAME/backup2remote.sh"

EOF
	chmod +x "$GEN_SCRIPT"
}

daemon_macos() {
	PLIST_TEMPLATE="localhost.backup2remote.plist"
	PLIST="$MACOS_DAEMON_CONFIG_OUTDIR/$PLIST_TEMPLATE"

	STDOUT="/tmp/backup2remote.out.log"
	STDERR="/tmp/backup2remote.err.log"

	cp -f "$PLIST_TEMPLATE" "$PLIST"
	replace_vars "$PLIST" "BACKUP_RUNNER" "BACKUP_DIR" "REMOTE_ARG" "GPG_ARG" "STDOUT" "STDERR"
	chmod 644 "$PLIST"

	cat > stop <<EOF
#!/bin/sh
launchctl list | grep backup2remote && launchctl unload -w "$PLIST"
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

main

