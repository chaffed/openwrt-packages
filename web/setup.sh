#!/bin/sh
# Add chaffed's package source to this router (OpenWrt or GL.iNet firmware
# 4.x) and, if you like, install apps from it. Run it on the router, as root:
#
#   curl -fsSL https://chaffed.github.io/openwrt-packages/setup.sh | sh
#   curl -fsSL https://chaffed.github.io/openwrt-packages/setup.sh | sh -s -- luci-app-autobackup
#   curl -fsSL https://chaffed.github.io/openwrt-packages/setup.sh | sh -s -- all
#
# (Plain OpenWrt without curl: wget -qO- <same address> | sh)
#
# What it changes, and nothing else:
#   /etc/opkg/keys/e657e1c1cfd7d36d   the key the package list is signed with,
#                                     so opkg can check it came from here
#   /etc/opkg/customfeeds.conf        one line: src/gz chaffed <address>
# then it runs `opkg update` and installs the apps you named. Running it
# again changes nothing that is already in place.
#
# To undo: delete that line and that key file.
# SPDX-License-Identifier: MIT

set -e

FEED=${CHAFFED_FEED:-https://chaffed.github.io/openwrt-packages}
KEY_ID=e657e1c1cfd7d36d
KEY='RWTmV+HBz9fTbcglagPuNF948y+dkAtJXXWX1qXWQToq02XLmJmxW+wz'
APPS="luci-app-autobackup luci-app-ispy luci-app-modemhealth luci-app-redbook"

say() { printf '%s\n' "$*"; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" = 0 ] || die "run this as root (log in to the router as root)."

if ! command -v opkg >/dev/null 2>&1; then
	if command -v apk >/dev/null 2>&1; then
		die "this router uses the apk package manager (OpenWrt 25 or later), which this package source does not serve yet. Install the apps from their GitHub releases instead."
	fi
	die "no opkg found. Is this an OpenWrt or GL.iNet router?"
fi

# Which apps to install: names from the list, or "all".
want=""
for a in "$@"; do
	case "$a" in
		all) want="$APPS" ;;
		luci-app-autobackup|luci-app-ispy|luci-app-modemhealth|luci-app-redbook) want="$want $a" ;;
		autobackup|ispy|modemhealth|redbook) want="$want luci-app-$a" ;;
		*) die "unknown app '$a'. Choose from: $APPS (or all)." ;;
	esac
done

# 1. The signing key. Written here rather than with opkg-key, which needs
# usign, and GL.iNet firmware has no usign command.
mkdir -p /etc/opkg/keys
keyfile=/etc/opkg/keys/$KEY_ID
if [ "$(sed -n 2p "$keyfile" 2>/dev/null)" != "$KEY" ]; then
	printf 'untrusted comment: chaffed openwrt-packages\n%s\n' "$KEY" > "$keyfile"
	say "Added the package source's signing key ($keyfile)."
fi

# 2. The package source.
conf=/etc/opkg/customfeeds.conf
line="src/gz chaffed $FEED"
touch "$conf"
if grep -qx "$line" "$conf"; then
	:
elif grep -q '^src/gz chaffed ' "$conf"; then
	sed -i "s|^src/gz chaffed .*|$line|" "$conf"
	say "Updated the package source's address in $conf."
else
	echo "$line" >> "$conf"
	say "Added the package source to $conf."
fi

# 3. The package lists.
say "Updating the package lists (opkg update)..."
log=/tmp/chaffed-setup.log
opkg update > "$log" 2>&1 || true
lists=$(sed -n 's/^lists_dir[[:space:]]\{1,\}[^[:space:]]\{1,\}[[:space:]]\{1,\}//p' /etc/opkg.conf 2>/dev/null | head -n 1)
[ -n "$lists" ] || lists=/var/opkg-lists
if [ ! -s "$lists/chaffed" ]; then
	grep -i chaffed "$log" >&2 || cat "$log" >&2
	die "the package list could not be downloaded from $FEED. Does the router have internet access, and is its clock right?"
fi
if grep -qi 'signature check failed' "$log"; then
	die "the package list's signature did not check out. Nothing was installed. (Details: $log)"
fi
rm -f "$log"
say "The package source is ready."

# 4. The apps.
if [ -n "$want" ]; then
	say "Installing:$want"
	# shellcheck disable=SC2086
	opkg install $want
	say ""
	say "Done. The apps are in the GL.iNet admin panel (sign out and in again"
	say "if they do not show yet) and, where LuCI is installed, in LuCI."
else
	say ""
	say "Install an app with:  opkg install <name>"
	for a in $APPS; do
		v=$(opkg list "$a" 2>/dev/null | sed -n "s/^$a - \([^ ]*\).*/\1/p")
		inst=$(opkg list-installed "$a" 2>/dev/null | sed -n "s/^$a - //p")
		say "  $a ${v:+($v)}${inst:+  - installed: $inst}"
	done
fi
say "Later versions arrive with: opkg update && opkg upgrade <name>"
