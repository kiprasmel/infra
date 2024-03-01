#!/bin/sh

VARS_DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

. "$VARS_DIRNAME/../../vars.sh"
. "$VARS_DIRNAME/../ubuntu/vars.sh"

