#!/bin/sh

set -euo pipefail

#sudo apt install -y docker
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-cache policy docker-ce
sudo apt install -y docker-ce
sudo systemctl status docker

# prevent disk exhaustion from infinite logfiles
# https://docs.docker.com/config/containers/logging/configure/#configure-the-default-logging-driver
# https://docs.docker.com/config/containers/logging/local/
sudo cat > /etc/docker/daemon.conf <<EOF
{
  "log-driver": "local"
}
EOF
sudo systemctl restart docker
docker info --format '{{.LoggingDriver}}' | grep local

# rootless mode
# https://docs.docker.com/engine/security/rootless/

sudo apt install -y dbus-user-session
echo "need to logout & re-login."
exit

