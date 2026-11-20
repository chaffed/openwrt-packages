#!/bin/sh
# Build an opkg package index for the .ipk files in a folder:
#   Packages      every package's control fields plus Filename, Size and
#                 SHA256sum, as opkg expects (like OpenWrt's ipkg-make-index)
#   Packages.gz   the same, compressed ("src/gz" feeds fetch this one)
# Signing (Packages.sig) is a separate step, done with usign.
#
# Usage: scripts/build-feed.sh <folder>
set -eu
DIR=$1
cd "$DIR"
: > Packages
for ipk in *.ipk; do
	[ -e "$ipk" ] || continue
	# Our packages are gzipped tarballs; packages built by the OpenWrt SDK
	# are ar archives. Read the control file from either.
	if tar -tzf "$ipk" >/dev/null 2>&1; then
		control=$(tar -xzOf "$ipk" ./control.tar.gz | tar -xzOf - ./control)
	else
		control=$(ar p "$ipk" control.tar.gz | tar -xzOf - ./control)
	fi
	printf '%s\n' "$control" | sed '/^$/d'
	echo "Filename: $ipk"
	echo "Size: $(wc -c < "$ipk" | tr -d ' ')"
	echo "SHA256sum: $(sha256sum "$ipk" | cut -d' ' -f1)"
	echo
done >> Packages
gzip -9nc Packages > Packages.gz
grep -c '^Package:' Packages | sed 's/$/ package(s) indexed/'
