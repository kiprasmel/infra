#!/bin/sh

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

. "$DIRNAME/../../vars.sh"
. "$DIRNAME/../ubuntu/vars.sh"

