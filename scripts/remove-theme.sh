#!/usr/bin/env bash
set -Eeuo pipefail
[[ $EUID -eq 0 ]] || { echo 'Run as root.' >&2; exit 1; }
panel="$(realpath -e -- "${1:-/var/www/pterodactyl}")"
[[ -f "$panel/artisan" ]] || { echo 'Panel not found.' >&2; exit 1; }
shopt -s nullglob
backups=()
for backup in /var/backups/theme-by-baba-*; do
  [[ -d "$backup" && -f "$backup/panel-path.txt" && -f "$backup/restore.sh" && -f "$backup/original-files.tar.gz" ]] || continue
  saved="$(realpath -m -- "$(cat "$backup/panel-path.txt")")"
  [[ "$saved" == "$panel" ]] && backups+=("$backup")
done
[[ ${#backups[@]} -gt 0 ]] || { echo 'No matching theme backup exists. Cannot safely restore the original theme.' >&2; exit 1; }
printf 'Restore a theme backup for %s:\n' "$panel"
for i in "${!backups[@]}"; do printf '  %s) %s (%s)\n' "$((i+1))" "${backups[$i]}" "$(date -r "${backups[$i]}/original-files.tar.gz" '+%F %T')"; done
read -r -p 'Backup number (blank to cancel): ' selection
[[ -n "$selection" ]] || exit 0
[[ "$selection" =~ ^[1-9][0-9]{0,4}$ ]] && ((selection<=${#backups[@]})) || { echo 'Invalid backup number.' >&2; exit 1; }
chosen="${backups[$((selection-1))]}"
printf 'This restores files/settings from %s. Later edits at those paths can be replaced.\n' "$chosen"
read -r -p 'Type RESTORE to remove the theme and restore this backup: ' confirm
[[ "$confirm" == RESTORE ]] || exit 0
exec bash "$chosen/restore.sh" "$chosen"
