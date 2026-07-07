#!/usr/bin/env bash
# lock.sh — make sure hyprlock has a background, then lock. Fast path.
#
# The blur + dim is applied by hyprlock itself (background{} in hyprlock.conf).
# This script only ensures ~/.cache/hyprlock-bg.png is a copy of the current
# wallpaper. The wallpaper picker already stages it whenever the wallpaper
# changes, so in the normal case this is a no-op and the lock is instant.
# (Re-encoding the 4K wallpaper here on every lock is what used to add ~1s.)
set -euo pipefail

STATE="$HOME/.cache/wallpaper-picker/current"   # written by rofi/wallpaper-picker.sh
OUT="$HOME/.cache/hyprlock-bg.png"

wall=""
[[ -s "$STATE" ]] && wall="$(< "$STATE")"

if [[ -n "$wall" && -f "$wall" && ! "$OUT" -nt "$wall" ]]; then
    # cache is missing or older than the wallpaper → (re)stage it now
    mkdir -p "$(dirname "$OUT")"
    magick "$wall" -auto-orient -resize 1920x -strip "$OUT"
elif [[ ! -e "$OUT" ]] && command -v grim >/dev/null 2>&1; then
    grim "$OUT" || true      # nothing recorded → freeze the current screen
fi

exec hyprlock "$@"
