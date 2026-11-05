#!/usr/bin/env bash
set -Eeuo pipefail
base="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
output="$(NO_COLOR=1 /bin/bash -c 'source "$1/scripts/ui.sh"; ui_menu; ui_run "Real command" printf "command-output\n"' -- "$base")"
[[ "$output" == *'command-output'* && "$output" == *'OK  Real command'* ]]
[[ "$output" != *$'\033'* ]]
if output="$(BABA_MOTION=0 /bin/bash -c 'source "$1/scripts/ui.sh"; ui_run "Expected failure" /bin/sh -c "exit 7"' -- "$base" 2>&1)"; then
  echo 'Failure status was swallowed.' >&2; exit 1
else
  status=$?
fi
[[ $status -eq 7 && "$output" == *'FAILED  Expected failure'* ]]
[[ "$output" != *'OK  Expected failure'* ]]
echo 'PASS: plain output, command output and exact failure status are preserved.'
