#!/usr/bin/env bash
set -Eeuo pipefail
base="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../scripts/public-check.sh
source "$base/scripts/public-check.sh"
curl() { printf '%s' "$mock_http"; return "$mock_exit"; }
mock_http=200 mock_exit=0
output="$(check_public_panel https://panel.example.test)"
[[ "$output" == *'Public login check passed'* ]]
mock_http=301 mock_exit=47
if output="$(check_public_panel https://panel.example.test 2>&1)"; then exit 1; fi
[[ "$output" == *'Full (strict)'* && "$output" != *'Public login check passed'* ]]
mock_http=403 mock_exit=0
if output="$(check_public_panel https://panel.example.test 2>&1)"; then exit 1; fi
[[ "$output" == *'HTTP 403'* ]]
mock_http=000 mock_exit=60
if output="$(check_public_panel https://panel.example.test 2>&1)"; then exit 1; fi
[[ "$output" == *'curl 60'* ]]
echo 'PASS: public login success, redirect loop, HTTP error and TLS error diagnostics.'
