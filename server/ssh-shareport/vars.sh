#!/bin/sh

VARS_DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

. "$VARS_DIRNAME/../../vars.sh"

export DOMAIN=share.kipras.org
export PORT=9999

