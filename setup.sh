#!/usr/bin/env bash
set -Eeuo pipefail
base="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$base/scripts/ui.sh"
ui_banner
cd "$base"
ui_run "Verify installer package" sha256sum --check --quiet PACKAGE.sha256
if [[ ! -d "$base/Theme-By-Baba-1.4.0" ]]; then
  ui_run "Extract theme files" tar -xzf "$base/Theme-By-Baba-1.4.0.tar.gz" -C "$base"
fi
ui_stage "Apply theme and verify panel"
exec bash "$base/Theme-By-Baba-1.4.0/install.sh" "${1:-/var/www/pterodactyl}" "${2:-}"
