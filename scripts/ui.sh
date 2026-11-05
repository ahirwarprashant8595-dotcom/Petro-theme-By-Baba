#!/usr/bin/env bash
# Shared terminal presentation. No installation decisions or simulated progress.
UI_ACCENT='' UI_MUTED='' UI_TEXT='' UI_OK='' UI_RESET=''
UI_TTY=0
if [[ -t 1 && "${TERM:-dumb}" != dumb && -z "${NO_COLOR:-}" ]]; then
  UI_TTY=1
  UI_ACCENT=$'\033[38;5;141m'
  UI_MUTED=$'\033[38;5;244m'
  UI_TEXT=$'\033[1;37m'
  UI_OK=$'\033[38;5;114m'
  UI_RESET=$'\033[0m'
fi
ui_line() { printf '%s%s%s\n' "$UI_MUTED" '  ------------------------------------------------------------' "$UI_RESET"; }
ui_stage() { printf '\n  %s>%s %s\n' "$UI_ACCENT" "$UI_RESET" "$*"; }
ui_success() { printf '  %sOK%s  %s\n' "$UI_OK" "$UI_RESET" "$*"; }
ui_banner() {
  local line
  local lines=(
    '  B A B A   H O S T'
    '  Your panel. Your identity.'
    ''
    '  PTERODACTYL TOOLKIT  /  PANEL + WINGS + THEME'
  )
  printf '\n'
  ui_line
  for line in "${lines[@]}"; do
    printf '%s%s%s\n' "$UI_ACCENT" "$line" "$UI_RESET"
    if [[ $UI_TTY -eq 1 && "${BABA_MOTION:-1}" != 0 ]]; then sleep 0.045; fi
  done
  ui_line
}
ui_menu() {
  ui_banner
  printf '\n  %sCHOOSE YOUR SETUP%s\n\n' "$UI_TEXT" "$UI_RESET"
  printf '  %s[1]%s  Install Panel          %sOfficial Pterodactyl%s\n' "$UI_ACCENT" "$UI_RESET" "$UI_MUTED" "$UI_RESET"
  printf '  %s[2]%s  Install Wings          %sOfficial daemon + Docker%s\n' "$UI_ACCENT" "$UI_RESET" "$UI_MUTED" "$UI_RESET"
  printf '  %s[3]%s  Install Theme          %sExisting panel%s\n' "$UI_ACCENT" "$UI_RESET" "$UI_MUTED" "$UI_RESET"
  printf '  %s[4]%s  Remove Theme           %sRestore saved backup%s\n' "$UI_ACCENT" "$UI_RESET" "$UI_MUTED" "$UI_RESET"
  printf '  %s[5]%s  Exit\n' "$UI_ACCENT" "$UI_RESET"
  printf '  %s[6]%s  Panel + Theme          %sFresh VPS%s\n\n' "$UI_ACCENT" "$UI_RESET" "$UI_MUTED" "$UI_RESET"
  ui_line
  printf '  %sCommunity  discord.gg/babahost\n  Support    discord.gg/E2qctRDZm%s\n\n' "$UI_MUTED" "$UI_RESET"
}
ui_run() {
  local label="$1"; shift
  local log_file pid status frame=0
  local frames=('|' '/' '-' '\')
  if [[ $UI_TTY -eq 0 || "${BABA_MOTION:-1}" == 0 ]]; then
    ui_stage "$label"
    if "$@"; then ui_success "$label"; else status=$?; printf '  FAILED  %s\n' "$label" >&2; return "$status"; fi
    return 0
  fi
  log_file="$(mktemp)"
  chmod 600 "$log_file"
  "$@" >"$log_file" 2>&1 &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    printf '\r\033[2K  %s%s%s  %s' "$UI_ACCENT" "${frames[$((frame%4))]}" "$UI_RESET" "$label"
    frame=$((frame+1))
    sleep 0.1
  done
  if wait "$pid"; then status=0; else status=$?; fi
  printf '\r\033[2K'
  if [[ $status -eq 0 ]]; then
    ui_success "$label"
    cat "$log_file"
    rm -f -- "$log_file"
  else
    printf '  FAILED  %s\n' "$label" >&2
    cat "$log_file" >&2
    printf '  Details saved: %s\n' "$log_file" >&2
  fi
  return "$status"
}
