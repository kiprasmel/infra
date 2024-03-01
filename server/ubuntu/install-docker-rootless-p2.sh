#!/usr/bin/env bash

sudo systemctl disable --now docker.service docker.socket
sudo apt install -y uidmap docker-ce-rootless-extras

# TODO: add to ~/.profile (patch)
#export XDG_RUNTIME_DIR=/home/ubuntu/.docker/run
XDG_RUNTIME_DIR="/run/user/$(id -u $USER)"
export PATH=/usr/bin:$PATH

/usr/bin/dockerd-rootless-setuptool.sh install

# 1st time: fail:
#[INFO] systemd not detected, dockerd-rootless.sh needs to be started manually:
#
#PATH=/usr/bin:/sbin:/usr/sbin:$PATH dockerd-rootless.sh
#
#[INFO] Creating CLI context "rootless"
#Successfully created context "rootless"
#[INFO] Using CLI context "rootless"
#Current context is now "rootless"
#
#[INFO] Make sure the following environment variable(s) are set (or add them to ~/.bashrc):
## WARNING: systemd not found. You have to remove XDG_RUNTIME_DIR manually on every logout.
#export XDG_RUNTIME_DIR=/home/ubuntu/.docker/run
#export PATH=/usr/bin:$PATH
#
#[INFO] Some applications may require the following environment variable too:
#export DOCKER_HOST=unix:///home/ubuntu/.docker/run/docker.sock

# 2nd time: succ:
#Created symlink /home/ubuntu/.config/systemd/user/default.target.wants/docker.service → /home/ubuntu/.config/systemd/user/docker.service.
#[INFO] Installed docker.service successfully.
#[INFO] To control docker.service, run: `systemctl --user (start|stop|restart) docker.service`
#[INFO] To run docker.service on system startup, run: `sudo loginctl enable-linger ubuntu`
#
#[INFO] Creating CLI context "rootless"
#Successfully created context "rootless"
#[INFO] Using CLI context "rootless"
#Current context is now "rootless"
#
#[INFO] Make sure the following environment variable(s) are set (or add them to ~/.bashrc):
#export PATH=/usr/bin:$PATH
#
#[INFO] Some applications may require the following environment variable too:
#export DOCKER_HOST=unix:///run/user/1000/docker.sock

sudo loginctl enable-linger "$USER"

docker ps || die "failed to install docker...\n"

