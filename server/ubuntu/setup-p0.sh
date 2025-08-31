#!/usr/bin/env bash

# Creates the user, runs p1 and p2
DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
. $DIRNAME/vars.sh

stty sane
useradd -m $NEW_USER
passwd $NEW_USER
usermod -aG sudo $NEW_USER
cp -r /root/.ssh /home/$NEW_USER
rm -r /root/.ssh

sudo apt install -y git

#su $NEW_USER

sudo -u $NEW_USER bash <<EOF
	cd ~
	git clone https://github.com/$GITHUB_USERNAME/infra ~/infra
	sudo ~/infra/server/ubuntu/setup-p1.sh
EOF

sudo -u $NEW_USER bash <<EOF
	cd ~
	source ~/.profile
	~/infra/server/ubuntu/setup-p2.sh
EOF
