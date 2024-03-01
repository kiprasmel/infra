#!/bin/sh

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

. "$DIRNAME/../../vars.sh"

export DOMAIN=ssh.kipras.org
export PORT=2000

