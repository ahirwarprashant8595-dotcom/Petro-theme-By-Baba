#!/usr/bin/env bash
set -Eeuo pipefail
base="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$base"
sha256sum --check --quiet PACKAGE.sha256
if [[ ! -d "$base/Theme-By-Baba-1.4.0" ]]; then
  tar -xzf "$base/Theme-By-Baba-1.4.0.tar.gz" -C "$base"
fi
exec bash "$base/Theme-By-Baba-1.4.0/install.sh" "${1:-/var/www/pterodactyl}" "${2:-}"
