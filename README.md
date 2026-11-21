# chaffed's OpenWrt packages

A signed package source (opkg feed) for OpenWrt and GL.iNet routers with
three apps. Its web site, with the one-line setup, is
**https://chaffed.github.io/openwrt-packages/**.

| Package | What it does |
|---|---|
| [luci-app-autobackup](https://github.com/chaffed/GLINet_Config_Backup) | **Auto Backup**: saves the router's settings to a USB drive on a schedule (optionally encrypted) and restores them after checking they fit the router. |
| [luci-app-ispy](https://github.com/chaffed/luci-app-ispy) | **ISPy**: scheduled internet speed tests, a dashboard, and a report comparing what your ISP delivers with what it advertises. |
| [luci-app-modemhealth](https://github.com/chaffed/luci-app-modemhealth) | **Modem Health**: watches your cable modem (SURFboard S33/S34) or T-Mobile 5G gateway: signal levels, errors, dropouts and outages, with a report for your provider. |

All three appear in LuCI and in the GL.iNet admin panel. They are
architecture independent, so this one source works on any router.

## Add the source

From a **Mac or Linux** computer (it asks for the router's address and which
apps to install, then logs in to the router over SSH):

```sh
curl -fsSL https://chaffed.github.io/openwrt-packages/install.sh | sh
```

From **Windows** (PowerShell, with Windows' built-in SSH client):

```powershell
irm https://chaffed.github.io/openwrt-packages/install.ps1 | iex
```

Or **on the router** over SSH (`all` installs every app; leave it out to
only add the source, or name apps instead):

```sh
curl -fsSL https://chaffed.github.io/openwrt-packages/setup.sh | sh -s -- all
```

GL.iNet firmware has `curl` but no `wget`; plain OpenWrt has `wget` but
usually no `curl`, so there use
`wget -qO- https://chaffed.github.io/openwrt-packages/setup.sh | sh`.

`setup.sh` changes two things and nothing else:

- `/etc/opkg/keys/e657e1c1cfd7d36d`: the key the package list is signed
  with, so opkg can check it came from here. It writes the key file itself
  rather than using `opkg-key`, which needs `usign`, a command GL.iNet
  firmware does not have.
- one line in `/etc/opkg/customfeeds.conf`:
  `src/gz chaffed https://chaffed.github.io/openwrt-packages`

Then it runs `opkg update` and installs the apps you named. Running it again
changes nothing.

### By hand

```sh
printf 'untrusted comment: chaffed openwrt-packages\nRWTmV+HBz9fTbcglagPuNF948y+dkAtJXXWX1qXWQToq02XLmJmxW+wz\n' > /etc/opkg/keys/e657e1c1cfd7d36d
echo 'src/gz chaffed https://chaffed.github.io/openwrt-packages' >> /etc/opkg/customfeeds.conf
opkg update
opkg install luci-app-autobackup luci-app-ispy luci-app-modemhealth
```

## Install and update

```sh
opkg install luci-app-autobackup   # and/or luci-app-ispy, luci-app-modemhealth
```

Later versions arrive like any other package:
`opkg update && opkg upgrade luci-app-autobackup`, or from
**System → Software** in LuCI.

On GL.iNet routers, LuCI is an optional add-on; the apps' pages appear in
the GL admin panel either way (Auto Backup under System, ISPy and Modem
Health under Applications).

## Requirements

- OpenWrt 21.02 to 24.10, or GL.iNet firmware 4.x (these use `opkg`).
- OpenWrt 25.x has moved to the `apk` package manager, which this source
  does not serve yet. Install from each app's GitHub release instead.

## Remove the source

Delete the `src/gz chaffed` line from `/etc/opkg/customfeeds.conf`, and the
key with `rm /etc/opkg/keys/e657e1c1cfd7d36d`.

## How it works

`.github/workflows/publish.yml` downloads the latest release of each
repository listed in `packages.txt`, builds the `Packages` index
(`scripts/build-feed.sh`), signs it with `usign` and publishes it, with the
web site in `web/` (landing page, `setup.sh`, `install.sh`, `install.ps1`),
on GitHub Pages. Before publishing it checks the scripts (shellcheck, the
PowerShell parser), then runs `setup.sh all` on a clean OpenWrt 23.05
against the new build and checks that every package installs. It runs every
six hours, on every push, and on demand, so a new release reaches routers
within six hours.

## License

MIT for the scripts and the web site here; each package carries its own
license.
