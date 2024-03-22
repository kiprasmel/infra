#!/usr/bin/env bash

set -euo pipefail
set -x

DIRNAME="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$DIRNAME"
. "../../util.sh"
. "./vars.sh"

NO_INTERACTIVE="${NO_INTERACTIVE:-0}"

(
	REPO_ROOT="$DIRNAME/kipras.org.git/blog"
	test -d "$REPO_ROOT" || git clone "git@github.com:kiprasmel/blog.git" "$REPO_ROOT"

	if test "$NO_INTERACTIVE" -ne 0; then
		echo "NO_INTERACTIVE: NOT UPDATING NGINX CONF"
	else
		install_nginx_site_with_replace "blog.kipras.org"
	fi

	cat > build-blog <<EOF
#!/bin/bash
set -xeuo pipefail

cd "$REPO_ROOT"
./clean
git pull

docker compose -f "$REPO_ROOT/docker-compose.prod.yml" down
docker compose -f "$REPO_ROOT/docker-compose.prod.yml" up -d --build

EOF
	chmod +x build-blog

	./build-blog
)

