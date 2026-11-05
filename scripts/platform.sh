#!/usr/bin/env bash
# Shared compatibility matrix for Panel and Wings.
platform_php_version() {
  case "$1:$2" in
    ubuntu:22.04|ubuntu:24.04|debian:13) printf '8.3\n' ;;
    debian:12) printf '8.2\n' ;;
    *) return 1 ;;
  esac
}
debian_php_source() {
  [[ "$1:$2" == debian:13 ]] || return 1
  printf '%s\n' 'deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ trixie main'
}
install_php_repository() {
  if [[ "$1:$2" == ubuntu:22.04 ]]; then
    apt-get install -y software-properties-common
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
    apt-get update
  elif [[ "$1:$2" == debian:13 ]]; then
    local keyring source_file expected
    source_file=/etc/apt/sources.list.d/baba-php.list
    expected="$(debian_php_source "$1" "$2")"
    if [[ -e "$source_file" || -L "$source_file" ]]; then
      [[ ! -L "$source_file" && "$(cat "$source_file")" == "$expected" ]] || {
        printf 'Conflicting PHP repository configuration: %s\n' "$source_file" >&2
        return 1
      }
    fi
    # Debian 13 ships PHP 8.4; use PHP 8.3 following the Pterodactyl Debian guide.
    keyring="$(mktemp --suffix=.deb /var/tmp/baba-sury-keyring.XXXXXXXX)"
    curl --fail --silent --show-error --location --retry 3 https://packages.sury.org/debsuryorg-archive-keyring.deb -o "$keyring"
    dpkg -i "$keyring"
    rm -f -- "$keyring"
    printf '%s\n' "$expected" > "$source_file"
    chmod 644 "$source_file"
    apt-get update
  fi
}
