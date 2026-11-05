#!/usr/bin/env bash
set -Eeuo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."
sha256sum --check PACKAGE.sha256
bash -n install.sh setup.sh scripts/install-wings.sh scripts/remove-theme.sh scripts/ui.sh scripts/platform.sh scripts/password.sh scripts/public-check.sh tests/check-package.sh tests/menu.sh tests/ui.sh tests/platform.sh tests/password.sh tests/public-check.sh
bash tests/menu.sh
bash tests/ui.sh
bash tests/platform.sh
bash tests/password.sh
bash tests/public-check.sh
php -l scripts/configure-panel.php
php -l scripts/admin-user.php
php -l tests/admin-user.php
temp="$(mktemp -d)"
trap 'rm -rf -- "$temp"' EXIT
tar -xzf Theme-By-Baba-1.4.0.tar.gz -C "$temp"
cd "$temp/Theme-By-Baba-1.4.0"
sha256sum --check --quiet SHA256SUMS
bash -n install.sh restore.sh
php -l settings.php
php -l verify.php
php verify.php --package
while IFS= read -r -d '' file; do php -l "$file" >/dev/null; done < <(find payload -type f -name '*.php' -print0)
echo 'PASS: package integrity, PHP, Bash and compiled frontend asset checks.'
