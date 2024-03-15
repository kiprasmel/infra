#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIRNAME"
. "$DIRNAME/../../util.sh"
. "$DIRNAME/vars.sh"

REPO="git"
clone_forked_repo

cat > init <<EOF
#!/bin/sh
set -euo pipefail

docker build -t "$IMAGE_NAME" .

# TODO: check if container doesn't already exist
# TODO: mount homedir to backup bash_history etc
docker run -d -it --name "$CONTAINER_NAME" --hostname "$CONTAINER_NAME" \
	-v "$REPO_ROOT":/git "$IMAGE_NAME" \
	"$SHELL"

# authorize ssh
docker exec "$CONTAINER_NAME" sh -c "mkdir -p ~/.ssh && touch ~/.ssh/authorized_keys"
export PUBKEY="\$(cat "$SSH_PUBKEY_PATH")"
test -n "\$PUBKEY" || {
	echo "\nerror: ssh public key empty ($SSH_PUBKEY_PATH)\n"
	exit 1
}
docker exec "$CONTAINER_NAME" sh -c "cat ~/.ssh/authorized_keys | grep '\$PUBKEY' || echo '\$PUBKEY' >> ~/.ssh/authorized_keys"
docker exec "$CONTAINER_NAME" sh -c 'cat ~/.ssh/authorized_keys' | grep "\$PUBKEY" || {
	echo "\nerror: failed adding ssh public key to container\n"
	exit 1
}

EOF
chmod +x init

cat > destroy <<EOF
#!/bin/sh
set -xeuo pipefail
docker rm -f "$CONTAINER_NAME"
EOF
chmod +x destroy

cat > stop <<EOF
#!/bin/sh
set -xeuo pipefail
docker ps | grep -v "$CONTAINER_NAME" >/dev/null || docker stop "$CONTAINER_NAME"
EOF
chmod +x stop

cat > start <<EOF
#!/bin/sh
set -xeuo pipefail
./stop
# TODO: check if not init'ed, and do if not
docker start "$CONTAINER_NAME"
EOF
chmod +x start

cat > "exec" <<EOF
#!/bin/sh
set -xeuo pipefail
# TODO: verify that is running 1st
docker exec -it "$CONTAINER_NAME" "$SHELL"
EOF
chmod +x "exec"

# TODO: re-enable after dotfiles cleanup
#cat > push <<EOF
##!/bin/sh
#set -xeuo pipefail
#docker push "$IMAGE_NAME"
#EOF
#chmod +x push

./init

