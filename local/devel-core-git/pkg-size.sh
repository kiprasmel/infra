#!/bin/sh

for pkg in "$@"; do
	sz="$(apt-cache show "$pkg" | grep -i installed-size | awk '{print $2/1024 " MB"}')"
	printf "%s: %s\n" "$pkg" "$sz"
done

