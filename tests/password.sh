#!/usr/bin/env bash
set -Eeuo pipefail
base="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../scripts/password.sh
source "$base/scripts/password.sh"
for sample in a 123 0 'lowercase' '  spaces and \literal$  '; do
  result="$(printf '%s\n%s\n' "$sample" "$sample" | /bin/bash -c 'source "$1/scripts/password.sh"; read_admin_password; printf "%s" "$admin_password"' -- "$base")"
  [[ "$result" == "$sample" ]]
done
result="$(printf '\na\nb\n0\n0\n' | /bin/bash -c 'source "$1/scripts/password.sh"; read_admin_password; printf "%s" "$admin_password"' -- "$base" 2>/dev/null)"
[[ "$result" == 0 ]]
if read_admin_password </dev/null; then exit 1; fi
echo 'PASS: short, numeric, literal zero, whitespace and special-character passwords; blank/mismatch retry and EOF.'
