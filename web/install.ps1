# Add chaffed's package source to a router from Windows, and install apps
# from it. In PowerShell:
#
#   irm https://chaffed.github.io/openwrt-packages/install.ps1 | iex
#
# It asks for the router's address and which apps you want, then logs in to
# the router over SSH (as root; you type the router's admin password) and
# runs setup.sh there. Needs the OpenSSH client, which Windows 10 and 11
# include.
# SPDX-License-Identifier: MIT

& {
    $ErrorActionPreference = 'Stop'
    $Feed = if ($env:CHAFFED_FEED) { $env:CHAFFED_FEED } else { 'https://chaffed.github.io/openwrt-packages' }

    if (-not (Get-Command ssh -ErrorAction SilentlyContinue)) {
        Write-Host "This needs the OpenSSH client. Install it in Settings > System > Optional features > OpenSSH Client, then run this again." -ForegroundColor Red
        return
    }

    Write-Host "chaffed's OpenWrt packages: add the package source to your router."
    Write-Host ""
    $router = Read-Host "Router address [192.168.8.1]"
    if ([string]::IsNullOrWhiteSpace($router)) { $router = '192.168.8.1' }
    $router = $router.Trim()
    if ($router -notmatch '^[A-Za-z0-9.:_-]+$') {
        Write-Host "'$router' does not look like a router address." -ForegroundColor Red
        return
    }

    Write-Host ""
    Write-Host "Which apps should be installed?"
    Write-Host "  1) Auto Backup    luci-app-autobackup    settings backups to a USB drive"
    Write-Host "  2) ISPy           luci-app-ispy          scheduled speed tests and a report"
    Write-Host "  3) Modem Health   luci-app-modemhealth   cable modem signal and outages"
    Write-Host "  4) Red Book       luci-app-redbook       the router's logs, kept on a USB drive"
    $choice = Read-Host "Numbers separated by spaces, 'all', or Enter for none (just add the source)"

    $names = @{ '1' = 'luci-app-autobackup'; '2' = 'luci-app-ispy'; '3' = 'luci-app-modemhealth'; '4' = 'luci-app-redbook' }
    $apps = @()
    foreach ($n in ($choice -split '[\s,]+' | Where-Object { $_ -ne '' })) {
        if ($n -ieq 'all') { $apps = @('all'); break }
        if (-not $names.ContainsKey($n)) {
            Write-Host "'$n' is not one of 1, 2, 3, 4 or all." -ForegroundColor Red
            return
        }
        $apps += $names[$n]
    }

    Write-Host ""
    Write-Host "Logging in to root@$router (enter the router's admin password if asked)..."
    # The router fetches setup.sh itself: GL.iNet firmware has curl, plain
    # OpenWrt has wget. The command is one line, so Windows line endings
    # cannot get into it.
    $cmd = "f=/tmp/chaffed-setup.sh; rm -f `$f; { curl -fsSL '$Feed/setup.sh' -o `$f 2>/dev/null || wget -qO `$f '$Feed/setup.sh'; } && CHAFFED_FEED='$Feed' sh `$f $($apps -join ' '); rc=`$?; rm -f `$f; exit `$rc"
    & ssh -o ConnectTimeout=10 "root@$router" $cmd
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Something went wrong (see above)." -ForegroundColor Red
    }
}
