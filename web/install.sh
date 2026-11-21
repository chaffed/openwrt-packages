#!/bin/sh
# Add chaffed's package source to a router from your Mac or Linux computer,
# and install apps from it. In a terminal:
#
#   curl -fsSL https://chaffed.github.io/openwrt-packages/install.sh | sh
#
# It asks for the router's address and which apps you want, then logs in to
# the router over SSH (as root; you type the router's admin password) and
# runs setup.sh there. Without questions:
#
#   curl -fsSL https://chaffed.github.io/openwrt-packages/install.sh | sh -s -- 192.168.8.1 luci-app-autobackup
#
# SPDX-License-Identifier: MIT

set -e

FEED=${CHAFFED_FEED:-https://chaffed.github.io/openwrt-packages}

say() { printf '%s\n' "$*"; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

command -v ssh >/dev/null 2>&1 || die "this needs ssh (OpenSSH), which macOS and most Linux systems have."

# This script arrives on standard input, so questions are read from the terminal.
ask() {
	printf '%s' "$1" > /dev/tty
	IFS= read -r REPLY < /dev/tty || REPLY=""
}

router=${1:-}
[ $# -gt 0 ] && shift
apps="$*"

if [ -z "$router" ]; then
	say "chaffed's OpenWrt packages: add the package source to your router."
	say ""
	ask "Router address [192.168.8.1]: "
	router=${REPLY:-192.168.8.1}
	say ""
	say "Which apps should be installed?"
	say "  1) Auto Backup    luci-app-autobackup    settings backups to a USB drive"
	say "  2) ISPy           luci-app-ispy          scheduled speed tests and a report"
	say "  3) Modem Health   luci-app-modemhealth   cable modem signal and outages"
	ask "Numbers separated by spaces, 'all', or Enter for none (just add the source): "
	for n in $(printf '%s' "$REPLY" | tr ',' ' '); do
		case "$n" in
			1) apps="$apps luci-app-autobackup" ;;
			2) apps="$apps luci-app-ispy" ;;
			3) apps="$apps luci-app-modemhealth" ;;
			all|a|ALL) apps="all" ;;
			*) die "'$n' is not one of 1, 2, 3 or all." ;;
		esac
	done
fi

case "$router" in
	*[!A-Za-z0-9.:_-]*|'') die "'$router' does not look like a router address." ;;
esac
for a in $apps; do
	case "$a" in
		all|luci-app-autobackup|luci-app-ispy|luci-app-modemhealth|autobackup|ispy|modemhealth) ;;
		*) die "unknown app '$a'." ;;
	esac
done

say ""
say "Logging in to root@$router (enter the router's admin password if asked)..."
# The router fetches setup.sh itself: GL.iNet firmware has curl, plain
# OpenWrt has wget.
# shellcheck disable=SC2029
ssh -o ConnectTimeout=10 "root@$router" "f=/tmp/chaffed-setup.sh; rm -f \$f; { curl -fsSL '$FEED/setup.sh' -o \$f 2>/dev/null || wget -qO \$f '$FEED/setup.sh'; } && CHAFFED_FEED='$FEED' sh \$f $apps; rc=\$?; rm -f \$f; exit \$rc"
