#!/usr/bin/env bash
check_public_panel() {
  local url="$1" code status=0
  if code="$(curl --silent --show-error --location --max-redirs 5 --connect-timeout 10 --max-time 30 --output /dev/null --write-out '%{http_code}' "$url/auth/login")"; then
    status=0
  else
    status=$?
  fi
  if [[ $status -eq 0 && "$code" == 200 ]]; then
    printf 'Public login check passed: %s/auth/login (HTTP 200).\n' "$url"
    return 0
  fi
  printf 'Panel is installed, but public login verification is pending (curl %s, HTTP %s).\n' "$status" "$code" >&2
  if [[ $status -eq 47 ]]; then
    printf 'Redirect loop: if using Cloudflare with origin HTTPS, set SSL/TLS encryption to Full (strict). Also check redirect rules.\n' >&2
  else
    printf 'Check domain DNS, proxy/TLS settings and firewall. Do not reinstall the panel to fix public routing.\n' >&2
  fi
  return 1
}
