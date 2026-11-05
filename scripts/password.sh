#!/usr/bin/env bash
# Visible, literal password input as requested. No length or complexity policy.
read_admin_password() {
  local repeated
  while true; do
    IFS= read -r -p 'Admin password (visible, any non-empty password): ' admin_password || return 1
    if [[ -z "$admin_password" ]]; then
      printf 'Password cannot be blank. Try again.\n' >&2
      continue
    fi
    IFS= read -r -p 'Repeat password (visible): ' repeated || return 1
    if [[ "$admin_password" == "$repeated" ]]; then return 0; fi
    printf 'Passwords differ. Try again.\n' >&2
  done
}
