#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

. "$DIRNAME/../../util.sh"

# apt install w/o asking
APT_CONF="/etc/apt/apt.conf"
touch "$APT_CONF"
grep "Assume-Yes" "$APT_CONF" || {
	printf "%s" 'APT::Get::Assume-Yes "true"' >> "$APT_CONF"
}

sudo apt update && sudo apt upgrade

sudo printf "\nSystemMaxUse=100M\n" >> "/etc/systemd/journald.conf"
sudo systemctl restart systemd-journald

# get rid of snap - not needed bloat & disk inflator
sudo systemctl disable snapd --now
sudo apt purge snapd gnome-software-plugin-snap
rm -rf "$HOME/snap"
sudo rm -rf /snap /var/snap /var/lib/snapd /var/cache/snapd /usr/lib/snapd
sudo apt-mark hold snap snapd
cat <<EOF | sudo tee /etc/apt/preferences.d/snapd
Package: snapd
Pin: origin *
Pin-Priority: -1
EOF

# install dotfiles
"$DIRNAME/../dotfiles/setup.sh"

sudo apt install nginx certbot python3-certbot-nginx

./install-docker-rootless-p1.sh
echo "re-login please, then run ./setup-p2.sh yourself."
exit

