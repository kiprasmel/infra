#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIRNAME"
. "../../util.sh"

TMPDIR="/tmp/backup2remote"
mkdir -p "$TMPDIR"

TIMESTAMP=$(date -Iseconds)

take_var_or_cache_or_exit "BACKUP_DIR"
take_var_or_cache_or_exit "REMOTE_DIR"
take_var_or_cache_or_exit "REMOTE_ARG"
take_var_or_cache_or_exit "GPG_ARG"

take_var_or_cache_or_default "ID" "$(basename "$BACKUP_DIR")"

BACKUP_FILE="${TMPDIR}/$ID.${TIMESTAMP}.tar.gz"
ENCRYPTED_FILE="${BACKUP_FILE}.gpg"

# create tarball
tar -czf "$BACKUP_FILE" -C "$BACKUP_DIR" .

# create ENCRYPTED_FILE
gpg --batch --yes --encrypt $GPG_ARG "$BACKUP_FILE"

# cleanup non-encrypted
shred -zxfun30 "$BACKUP_FILE"

ssh -o BatchMode=yes -o AddKeysToAgent=no "$REMOTE_ARG" \
	"REMOTE_DIR=$REMOTE_DIR" \
	'bash -s' <<EOF
mkdir -p "$REMOTE_DIR"
EOF

ENCRYPTED_FILENAME="$(basename "$ENCRYPTED_FILE")"
scp "$ENCRYPTED_FILE" "$REMOTE_ARG:$REMOTE_DIR/$ENCRYPTED_FILENAME"

# cleanup encrypted too
shred -zxfun30 "$ENCRYPTED_FILE"

