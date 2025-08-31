#!/usr/bin/env bash

DIRECTORY="$(dirname "$(readlink -f "$0")")"

. $DIRECTORY/vars.sh

read -p "Enter server address (default $SSH_ADDRESS): " input
SSH_ADDRESS="${input:-$SSH_ADDRESS}"
SSH_ROOT="root@$SSH_ADDRESS"
SSH_USER="$USER@$SSH_ADDRESS"

read -p "Do we make a new SSH key? (y/n, default: y): " input
SSH_NEW="${input:-y}"

if [[ $SSH_NEW == 'y' ]]; then
	read -p "New SSH key dir (default: ~/.ssh/id_infra): " input
	SSH_KEY="${input:-$HOME/.ssh/id_infra}"
	ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -N ""
else
	read -p "Enter SSH key dir (default: ~/.ssh/id_infra): " input
	SSH_KEY="${input:-$HOME/.ssh/id_infra}"
fi

#p-1, making and setting up ssh keys for further logins
publicKey=$(cat "$SSH_KEY.pub")
ssh $SSH_ROOT "\
	mkdir -p /root/.ssh && \
	chmod 700 /root/.ssh && \
	echo '$publicKey' >> /root/.ssh/authorized_keys && \
	chmod 600 /root/.ssh/authorized_keys
"

# Get .../server/ubuntu/vars.sh and .../server/vars.sh into a single vars.sh on the remote
scp -i "$SSH_KEY" "$DIRECTORY"/vars.sh $SSH_ROOT:~
ssh -i "$SSH_KEY" $SSH_ROOT "cat >> ~/vars.sh" < "$(dirname "$(dirname "$DIRECTORY") ")"/vars.sh

# Copy and run setup-p0 on remote, which will also git clone p1, p2 and run them
scp -i "$SSH_KEY" "$DIRECTORY"/setup-p0.sh $SSH_ROOT:~
ssh -i "$SSH_KEY" -t $SSH_ROOT "bash ~/setup-p0.sh"
