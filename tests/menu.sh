#!/usr/bin/env bash
set -Eeuo pipefail
base="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
temp="$(mktemp -d)"
trap 'rm -rf -- "$temp"' EXIT
# Replace only child dispatch; never run installers while testing menu choices.
printf '#!/bin/sh\nprintf "DISPATCH: %%s\\n" "$*"\n' > "$temp/bash"
chmod +x "$temp/bash"
expected=(panel wings theme remove-theme '' fresh)
for choice in 1 2 3 4 5 6; do
  output="$(printf '%s\n' "$choice" | PATH="$temp:$PATH" /bin/bash "$base/install.sh")"
  if [[ "$choice" == 5 ]]; then
    [[ "$output" != *DISPATCH:* ]]
  else
    [[ "$output" == *"DISPATCH: $base/install.sh ${expected[$((choice-1))]}"* ]]
  fi
done
output="$(printf 'invalid\n5\n' | /bin/bash "$base/install.sh")"
[[ "$output" == *'Please choose a number from 1 to 6.'* ]]
echo 'PASS: all six menu choices and invalid-input handling.'
