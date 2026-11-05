# BABA HOST — Panel + Theme Installer

Install Pterodactyl **1.15.2** with the existing BABA HOST theme, or apply only the theme to an existing compatible panel. Theme snapshot: 5 November 2026. This community installer is independent of the Pterodactyl project.

## Fresh VPS: Panel + theme

Supported: **Ubuntu 22.04 / 24.04 or Debian 12**, root access, systemd and a domain pointing to your VPS. Start on a dedicated fresh VPS. Ports 80/443 must be reachable for HTTPS. Install Git first if it is missing (`apt-get update && apt-get install -y git`).

Run this command as root:

```bash
git clone https://github.com/ahirwarprashant8595-dotcom/Petro-theme-By-Baba.git && cd Petro-theme-By-Baba && bash install.sh fresh
```

Enter the domain, admin email/username, password and timezone. Choose HTTPS and type `INSTALL` to continue. The installer installs PHP, MariaDB, Redis, NGINX, the pinned official Panel release, an administrator, scheduler, queue worker and the theme. It verifies package hashes, frontend assets, Laravel, theme routes/schema, service state and the rendered login page. Admin passwords are entered privately; they are not stored in the repository or passed as command-line arguments.

Fresh mode refuses an existing panel, existing BABA Panel service configuration, other NGINX sites or an existing `baba_panel` database/user. A failed installation leaves partial files for inspection rather than deleting data. It does not automatically roll back OS packages, database creation or certificates; do not rerun over a partial installation without reviewing it.

**Wings is separate.** To host game servers, install Wings and create/configure your node, allocations and Eggs after the panel setup. This script does not provision those. Configure SMTP in Administration > Settings; until then mail is logged locally. DNS, firewall and any reverse proxy must be configured correctly. Telemetry is disabled by default.

## Existing panel: theme only

For an already working **Pterodactyl 1.15.2** panel:

```bash
bash install.sh theme /var/www/pterodactyl
```

Read-only preflight:

```bash
bash install.sh theme /var/www/pterodactyl --check
```

Use `--keep-branding` instead of `--check` to retain target panel theme settings. Otherwise BABA HOST branding is applied. Source and compiled frontend are included, so Node/Yarn is not required to apply the theme. No accounts, server files, node settings, `.env`, credentials or database dumps are distributed.

Theme installation backs up overwritten files/settings to `/var/backups/theme-by-baba-*`, applies the additive Egg artwork migration, refreshes caches and runs verification. It preserves existing panel accounts and servers. Review other custom modifications before applying a theme overlay.

## Verify / restore

```bash
bash install.sh verify /var/www/pterodactyl
```

For theme rollback, use the exact backup path printed by installation:

```bash
bash /var/backups/theme-by-baba-XXXXXXXX/restore.sh /var/backups/theme-by-baba-XXXXXXXX
```

The additive Egg artwork database columns remain after theme rollback. Back up your panel `.env` and database securely as well. Theme rollback is not a fresh-panel uninstall.

Administration > Edit Theme manages branding. Optional runtime Egg definitions are inside the theme archive's `eggs/` folder. Import them through Administration > Nests. Minecraft live player/inventory/map features require the included MC bridge on a compatible Paper/Spigot server; installing a theme alone cannot supply live game data.

## Package / tests

`Theme-By-Baba-1.4.0.tar.gz` contains theme source, built assets, configuration, theme installer/restore script and upstream license notices. `PACKAGE.sha256` covers the archive and installer helpers. `UPSTREAM.json` records the pinned official Panel release and checksum.

```bash
bash tests/check-package.sh
```

See [VERIFICATION.txt](VERIFICATION.txt) for checks actually completed. Syntax/preflight and live snapshot checks do not prove a fresh VPS install. See [NOTICE.md](NOTICE.md) for upstream/artwork ownership. Do not commit `.env`, keys, databases, logs or server backups.

Official references: [Panel installation](https://docs.pterodactyl.io/v1/panel/getting-started), [web server](https://docs.pterodactyl.io/v1/panel/webserver-configuration).
