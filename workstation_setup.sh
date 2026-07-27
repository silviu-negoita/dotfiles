#!/usr/bin/env bash

set -euo pipefail

if ! command -v gsettings >/dev/null 2>&1; then
  printf '%s\n' "gsettings is not available; skipping GNOME workstation setup."
  exit 0
fi

schema="org.gnome.desktop.wm.keybindings"

for key in switch-to-workspace-left switch-to-workspace-right; do
  if [[ "$(gsettings writable "$schema" "$key" 2>/dev/null)" == "true" ]]; then
    gsettings set "$schema" "$key" "['']"
  else
    printf 'Cannot update %s %s; skipping.\n' "$schema" "$key" >&2
  fi
done
