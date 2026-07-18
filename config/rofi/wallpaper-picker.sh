#!/usr/bin/env bash
# Wallpaper picker for rofi + awww (Omarchy Ethereal grid theme).
#   wallpaper-picker.sh            open the rofi grid picker
#   wallpaper-picker.sh --restore  (login) start daemon + re-apply saved wallpaper

set -euo pipefail

WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/wallpaper}"
THEME="$HOME/.config/rofi/wallpaper-picker.rasi"
CACHE_DIR="$HOME/.cache/wallpaper-picker"
THUMB_DIR="$CACHE_DIR/thumbs"
STATE_FILE="$CACHE_DIR/current"
THUMB_SIZE=256   # icons render ~90px; 256 stays crisp while keeping decode cheap

mkdir -p "$THUMB_DIR"

# ---- awww daemon ----------------------------------------------------------
ensure_daemon() {
    if ! awww query >/dev/null 2>&1; then
        awww-daemon >/dev/null 2>&1 &
        for _ in $(seq 1 50); do
            awww query >/dev/null 2>&1 && break
            sleep 0.1
        done
    fi
}

# ---- thumbnails -----------------------------------------------------------
# Thumb name = the wallpaper's full filename (with extension) + ".png", e.g.
# "apple-dark.jpg.png". Derived with pure-bash parameter expansion (NO sha256sum
# or basename subprocess) so building all ~180 rofi entries costs ~0ms instead
# of ~2s of process spawns — this is what makes the picker pop up instantly.
make_thumb() {  # $1 src  $2 dst
    if command -v magick >/dev/null 2>&1; then
        magick "$1" -auto-orient -thumbnail "${THUMB_SIZE}x${THUMB_SIZE}^" \
            -gravity center -extent "${THUMB_SIZE}x${THUMB_SIZE}" "$2" >/dev/null 2>&1
    else
        ffmpeg -y -loglevel error -i "$1" \
            -vf "scale=${THUMB_SIZE}:${THUMB_SIZE}:force_original_aspect_ratio=increase,crop=${THUMB_SIZE}:${THUMB_SIZE}" \
            "$2" </dev/null >/dev/null 2>&1
    fi
}
export -f make_thumb
export THUMB_SIZE THUMB_DIR

warm_thumbs() {  # build missing/stale thumbs in parallel; fast no-op when cache is warm
    local img b missing=()
    for img in "${images[@]}"; do
        b="${img##*/}"
        [[ -f "$THUMB_DIR/$b.png" && ! "$img" -nt "$THUMB_DIR/$b.png" ]] || missing+=("$img")
    done
    ((${#missing[@]})) || return 0
    notify-send -t 3000 "Wallpaper picker" "Caching ${#missing[@]} thumbnails…" 2>/dev/null || true
    printf '%s\0' "${missing[@]}" | xargs -0 -P"$(nproc)" -I{} bash -c \
        'src="$1"; make_thumb "$src" "$THUMB_DIR/${src##*/}.png"' _ {}
}

# ---- set + persist --------------------------------------------------------
set_wallpaper() {
    ensure_daemon
    awww img "$1" --transition-type grow --transition-pos 0.9,0.9 \
        --transition-fps 60 --transition-duration 1 >/dev/null 2>&1
    printf '%s\n' "$1" > "$STATE_FILE"
    # keep hyprlock's lock background in sync, in the background so the picker
    # stays snappy — this is what lets lock.sh (Alt+L) skip re-encoding and lock instantly
    magick "$1" -auto-orient -resize 1920x -strip "$HOME/.cache/hyprlock-bg.png" >/dev/null 2>&1 &
}

# collect wallpapers (top level only; skips the .git dir and README/LICENSE)
mapfile -t images < <(find "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | sort)

# ---- set / warm modes (used by the Quickshell picker) ---------------------
# --set <path>  apply one wallpaper (daemon, transition, state, hyprlock bg)
# --warm        build missing thumbnails only
if [[ "${1:-}" == "--set" ]]; then
    [[ -n "${2:-}" && -f "${2:-}" ]] || { echo "usage: $0 --set <image>" >&2; exit 1; }
    set_wallpaper "$2"
    exit 0
fi
if [[ "${1:-}" == "--warm" ]]; then
    warm_thumbs
    exit 0
fi

# ---- restore mode (login) -------------------------------------------------
if [[ "${1:-}" == "--restore" ]]; then
    ensure_daemon
    if [[ -s "$STATE_FILE" && -f "$(cat "$STATE_FILE")" ]]; then
        set_wallpaper "$(cat "$STATE_FILE")"
    elif ((${#images[@]})); then
        set_wallpaper "${images[0]}"   # first-ever boot: sensible default
    fi
    warm_thumbs >/dev/null 2>&1 &      # pre-cache so the picker opens instantly
    exit 0
fi

# ---- picker mode ----------------------------------------------------------
((${#images[@]})) || { notify-send "Wallpaper picker" "No images in $WALLPAPER_DIR"; exit 1; }

warm_thumbs

idx=$(
    for img in "${images[@]}"; do
        b="${img##*/}"
        printf '%s\0icon\x1f%s\n' "${b%.*}" "$THUMB_DIR/$b.png"
    done | rofi -dmenu -i -p "Wallpaper" -theme "$THEME" -format i -no-custom
) || idx=""

[[ -n "$idx" ]] && set_wallpaper "${images[$idx]}"
