#!/usr/bin/env bash
set -Eeuo pipefail
base="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../scripts/platform.sh
source "$base/scripts/platform.sh"
[[ "$(platform_php_version ubuntu 22.04)" == 8.3 ]]
[[ "$(platform_php_version ubuntu 24.04)" == 8.3 ]]
[[ "$(platform_php_version debian 12)" == 8.2 ]]
[[ "$(platform_php_version debian 13)" == 8.3 ]]
if platform_php_version debian 99; then exit 1; fi
if platform_php_version unknown 13; then exit 1; fi
[[ "$(debian_php_source debian 13)" == *'signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg'*'trixie main' ]]
if debian_php_source debian 12; then exit 1; fi
# Native-package platforms must not run repository installation commands.
apt-get() { echo 'Unexpected repository mutation' >&2; return 19; }
install_php_repository debian 12
install_php_repository ubuntu 24.04
echo 'PASS: supported platforms, Debian 13 PHP selection, signed repository and unsupported OS rejection.'
