#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

. "$DIRNAME/../../util.sh"

./install-docker-rootless-p2.sh

# DO enhanced monitoring
docker run -v /proc:/host/proc:ro -v /sys:/host/sys:ro --name do-agent -d digitalocean/do-agent:stable

