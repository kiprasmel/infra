#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIRNAME"
. "$DIRNAME/../../util.sh"
. "$DIRNAME/vars.sh"

ls /swapfile || {
	# https://wiki.archlinux.org/title/Swap#Swap_file
	
	SWAP_SIZE_GB="${SWAP_SIZE_GB:-2}"
	sudo dd if=/dev/zero of=/swapfile bs=1M count="${SWAP_SIZE_GB}k" status=progress
	sudo chmod 0600 /swapfile
	# '-U clear' broken on ubuntu
	sudo mkswap /swapfile
	sudo swapon /swapfile
	sudo printf "%s\n" "/swapfile 	none 	swap 	defaults 	0 	0" >> /etc/fstab
}

