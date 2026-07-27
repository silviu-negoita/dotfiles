#!/usr/bin/env bash

set -euo pipefail

for command in curl xdotool; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$command" >&2
    exit 1
  fi
done

message="$(curl --fail --silent --show-error https://whatthecommit.com/index.txt)"
xdotool type --clearmodifiers "$message"
