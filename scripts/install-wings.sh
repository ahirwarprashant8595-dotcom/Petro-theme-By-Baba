#!/usr/bin/env bash
set -Eeuo pipefail
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=ui.sh
source "$script_dir/ui.sh"
ui_banner
umask 077
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
[[ $EUID -eq 0 ]] || die 'Run as root.'
[[ -d /run/systemd/system ]] || die 'A Linux VPS booted with systemd is required.'
# shellcheck source=/dev/null
source /etc/os-release
case "$ID:$VERSION_ID" in ubuntu:22.04|ubuntu:24.04|debian:12) ;; *) die 'Supported: Ubuntu 22.04/24.04 or Debian 12.' ;; esac
[[ ! -e /usr/local/bin/wings && ! -L /usr/local/bin/wings && ! -e /etc/systemd/system/wings.service ]] || die 'Wings already exists. This installer will not overwrite it.'
case "$(uname -m)" in
  x86_64) arch=amd64; hash=7e763389bb5d386a7d32ccdd46cffcf1ab9ed697e5c2aca7fe44183b527cd4c0 ;;
  aarch64|arm64) arch=arm64; hash=516cc0b86fec092feb9893bacab2e1bf478b5477a5459ad9d722676c7549faa5 ;;
  *) die 'Wings supports amd64 or arm64 here.' ;;
esac
read -r -p 'Install official Wings 1.13.4 and Docker if needed? Type INSTALL: ' confirm
[[ "$confirm" == INSTALL ]] || die 'Cancelled.'
ui_stage "1 / 3  Docker and dependencies"
apt-get update
apt-get install -y ca-certificates curl
if ! command -v docker >/dev/null; then apt-get install -y docker.io; fi
systemctl enable --now docker
docker info >/dev/null
work="$(mktemp -d /var/tmp/baba-wings.XXXXXXXX)"
ui_stage "2 / 3  Official Wings binary"
ui_run "Download Wings 1.13.4" curl --fail --silent --show-error --location --retry 3 "https://github.com/pterodactyl/wings/releases/download/v1.13.4/wings_linux_$arch" -o "$work/wings"
printf '%s  %s\n' "$hash" "$work/wings" | sha256sum --check --status
install -m 0755 "$work/wings" /usr/local/bin/wings
mkdir -p /etc/pterodactyl
chmod 700 /etc/pterodactyl
ui_stage "3 / 3  Node configuration and service"
if [[ ! -f /etc/pterodactyl/config.yml ]]; then
  printf 'Create a node in Panel > Administration > Nodes and save its Configuration YAML to a local file.\n'
  read -r -p 'Path to that YAML (blank to configure later): ' config_path
  if [[ -n "$config_path" ]]; then
    [[ -f "$config_path" ]] || die 'Configuration file not found.'
    [[ "$(realpath -- "$config_path")" != /etc/pterodactyl/config.yml ]] || die 'Source and destination must differ.'
    install -m 0600 "$config_path" /etc/pterodactyl/config.yml
  fi
fi
cat > /etc/systemd/system/wings.service <<'SERVICE'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service
[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
RestartSec=5s
[Install]
WantedBy=multi-user.target
SERVICE
chmod 644 /etc/systemd/system/wings.service
systemctl daemon-reload
/usr/local/bin/wings version
if [[ -s /etc/pterodactyl/config.yml ]]; then
  systemctl enable --now wings
  sleep 3
  systemctl is-active --quiet wings || die 'Wings did not stay active. Inspect journalctl -u wings and the node configuration/certificates.'
  printf 'Wings installed and service active. Check node connectivity in your Panel.\n'
else
  printf 'Wings binary and service installed. Node configuration is pending.\nSave /etc/pterodactyl/config.yml, then run: systemctl enable --now wings\n'
fi
