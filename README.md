# chaffed's OpenWrt packages

A package source (opkg feed) for OpenWrt and GL.iNet routers with two apps:

| Package | What it does |
|---|---|
| [luci-app-ispy](https://github.com/chaffed/luci-app-ispy) | **ISPy**: scheduled internet speed tests, a dashboard, and a report comparing what your ISP delivers with what it advertises. |
| [luci-app-modemhealth](https://github.com/chaffed/luci-app-modemhealth) | **Modem Health**: watches your cable modem (SURFboard S33/S34): signal levels, errors, dropouts and outages, with a report for your ISP. |

Both appear in LuCI and in the GL.iNet admin panel. They are architecture
independent, so this one source works on any router.

## Add the source (once)

Log in to the router over SSH and run:

```sh
wget -O /tmp/chaffed.pub https://chaffed.github.io/openwrt-packages/chaffed.pub
opkg-key add /tmp/chaffed.pub
echo 'src/gz chaffed https://chaffed.github.io/openwrt-packages' >> /etc/opkg/customfeeds.conf
opkg update
```

The first two lines install the key that the package list is signed with,
so the router can check it came from here (fingerprint `e657e1c1cfd7d36d`).

## Install and update

```sh
opkg install luci-app-modemhealth   # and/or luci-app-ispy
```

Later versions arrive like any other package: `opkg update && opkg upgrade luci-app-modemhealth luci-app-ispy`,
or from **System → Software** in LuCI.

On GL.iNet routers, LuCI is an optional add-on: see each app's README for
enabling it. The apps' own pages appear in the GL admin panel either way.

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
(`scripts/build-feed.sh`), signs it with `usign` and publishes it with GitHub
Pages. It runs every six hours, on every push, and on demand, so a new
release reaches routers within six hours.

## License

MIT for the scripts here; each package carries its own license.
