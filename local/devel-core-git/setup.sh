#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIRNAME"
. "$DIRNAME/../../util.sh"
. "$DIRNAME/vars.sh"

SHELL_ARGS="/bin/zsh -l"

REPO="git"
clone_forked_repo

cat > build <<EOF
#!/bin/sh
set -xeuo pipefail
if docker ps | grep git; then
	docker stop "$CONTAINER_NAME"
	docker rm "$CONTAINER_NAME"
fi

docker build -t "$IMAGE_NAME" "\$@" .
EOF
chmod +x build

cat > rebuild <<EOF
#!/bin/sh
set -xeuo pipefail
./build --no-cache "\$@"
EOF
chmod +x rebuild

cat > init <<EOF
#!/bin/sh
set -euo pipefail

./build

./destroy
# TODO: mount homedir to backup bash_history etc
docker run -d -it --name "$CONTAINER_NAME" --hostname "$CONTAINER_NAME" \
	-p $SSH_PORT:22 \
	-v "$REPO_ROOT:/git" \
	-v "$HOME/projects/turbo-schedule:/tt" \
	-e "DISPLAY=host.docker.internal:0" \
	-v "/tmp/.X11-unix:/tmp/.X11-unix" \
	-v "$HOME/.Xauthority:/root/.Xauthority" \
	"$IMAGE_NAME"


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
if docker container ls -a | grep git; then
	docker rm -f "$CONTAINER_NAME"
fi
EOF
chmod +x destroy

cat > stop <<EOF
#!/bin/sh
set -xeuo pipefail
if docker ps | grep "$CONTAINER_NAME"; then
	docker stop "$CONTAINER_NAME"
fi
EOF
chmod +x stop

cat > start <<EOF
#!/bin/sh
set -xeuo pipefail
./stop
docker start "$CONTAINER_NAME"
EOF
chmod +x start

cat > "exec" <<EOF
#!/bin/sh
set -xeuo pipefail
docker exec -it "$CONTAINER_NAME" $SHELL_ARGS
EOF
chmod +x "exec"

cat > ssh <<EOF
#!/bin/sh
set -xeuo pipefail
ssh root@localhost -p $SSH_PORT
EOF
chmod +x ssh

cat > push <<EOF
#!/bin/sh
set -xeuo pipefail
docker push "$IMAGE_NAME"
EOF
chmod +x push

./init

