#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIRNAME"
. "../../util.sh"

TIMESTAMP=$(date -Iseconds)

take_var_or_cache_or_exit "BACKUP_DIR"
take_var_or_cache_or_exit "REMOTE_DIR"
take_var_or_cache_or_exit "REMOTE_ARG"
take_var_or_cache_or_exit "GPG_ARG"

BACKUP_FILE="${BACKUP_DIR}.${TIMESTAMP}.tar.gz"
ENCRYPTED_FILE="${BACKUP_FILE}.gpg"

# create tarball
tar -czf "$BACKUP_FILE" -C "$BACKUP_DIR" .

# create ENCRYPTED_FILE
gpg --batch --yes --encrypt $GPG_ARG "$BACKUP_FILE"

ssh -o BatchMode=yes -o AddKeysToAgent=no "$REMOTE_ARG" \
	"REMOTE_DIR=$REMOTE_DIR" \
	'bash -s' <<EOF
mkdir -p "$REMOTE_DIR"
EOF

ENCRYPTED_FILENAME="$(basename "$ENCRYPTED_FILE")"
scp "$ENCRYPTED_FILE" "$REMOTE_ARG:$REMOTE_DIR/$ENCRYPTED_FILENAME"

# Clean up local files
rm "$BACKUP_FILE" "$ENCRYPTED_FILE"

