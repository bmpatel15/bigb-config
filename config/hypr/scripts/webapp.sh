#!/usr/bin/env bash
# Launch a URL as a Chromium --app window in a mode profile.
#   webapp.sh <url>          -> active browser mode (falls back to Education)
#   webapp.sh <url> <mode>   -> pinned mode (Education | Satsang | Entertainment)
# Mode -> profile dir mapping matches rofi/browser-mode.sh (Education = "Default").
set -euo pipefail

url="${1:?usage: webapp.sh <url> [mode]}"
STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/browser-mode"

mode="${2:-$(cat "$STATE_FILE" 2>/dev/null || true)}"
mode="${mode:-Education}"

case "$mode" in
    Education) profile="Default" ;;
    *)         profile="$mode" ;;
esac

exec chromium --profile-directory="$profile" --new-window --app="$url"
