#!/usr/bin/env bash

LIST_REPOS_DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
. "$LIST_REPOS_DIRNAME/vars.sh"

REPO_ROOT="$(git rev-parse --show-toplevel)"

Q="[\"']"
NQ="[^\"']"

git -c grep.lineNumber=false grep -hoP "REPO=$Q${NQ}+$Q" "$REPO_ROOT" \
	| sort | uniq \
	| sed -r "s,REPO=$Q(${NQ}+)$Q,https://github.com/$GITHUB_USERNAME/\1,g"

