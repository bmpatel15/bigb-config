#!/usr/bin/env bash
# Browser mode picker (rofi) — Education / Satsang / Entertainment.
# Picks a mode, records it as the "active mode", opens that profile's Chromium.
# Mode -> Chromium profile dir: Education keeps the original "Default" dir
# (all logins preserved); the other modes use their own name as the dir.
set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
STATE_FILE="$STATE_DIR/browser-mode"
THEME="$HOME/.config/rofi/browser-mode.rasi"

MODES=(Education Satsang Entertainment)

profile_dir() {
    case "$1" in
        Education) echo "Default" ;;
        *)         echo "$1" ;;
    esac
}

current="$(cat "$STATE_FILE" 2>/dev/null || echo Education)"

choice=$(printf '%s\n' "${MODES[@]}" \
    | rofi -dmenu -i -p "Mode" -theme "$THEME" -no-custom -select "$current") || exit 0

mkdir -p "$STATE_DIR"
printf '%s\n' "$choice" > "$STATE_FILE"
exec chromium --profile-directory="$(profile_dir "$choice")" --new-window
