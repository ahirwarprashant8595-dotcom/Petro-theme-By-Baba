#!/usr/bin/env bash
set -Eeuo pipefail
base="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$base/scripts/ui.sh"
ui_banner
cd "$base"
ui_run "Verify installer package" sha256sum --check --quiet PACKAGE.sha256
theme_work="$(mktemp -d /var/tmp/baba-theme-package.XXXXXXXX)"
trap 'rm -rf -- "$theme_work"' EXIT
ui_run "Extract current theme files" tar -xzf "$base/Theme-By-Baba-1.4.0.tar.gz" -C "$theme_work"
ui_stage "Apply theme and verify panel"
bash "$theme_work/Theme-By-Baba-1.4.0/install.sh" "${1:-/var/www/pterodactyl}" "${2:-}"
if [[ "${2:-}" != --check ]]; then bash "$base/scripts/preview-nginx.sh" "${1:-/var/www/pterodactyl}"; fi
