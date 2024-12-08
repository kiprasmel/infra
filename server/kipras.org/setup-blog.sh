#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIRNAME"
. "../../util.sh"
. "./vars.sh"

NO_INTERACTIVE="${NO_INTERACTIVE:-0}"

(
	REPO="blog"
	PRIVATE=1
	clone_forked_repo
	install_nginx_site_with_replace "blog.kipras.org"

	cat > build-blog <<EOF
#!/bin/bash
set -xeuo pipefail

cd "$REPO_ROOT"
./clean
git pull

docker compose -f "$REPO_ROOT/docker-compose.build.yml" up

EOF
	chmod +x build-blog

	./build-blog
)
