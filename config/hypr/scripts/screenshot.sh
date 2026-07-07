#!/usr/bin/env bash
# Screenshot helper: region | window | full  -> swappy (annotate, then save/copy).
# swappy's toolbar lets you copy to clipboard or save (default: XDG_PICTURES_DIR).
set -euo pipefail
mode="${1:-region}"

case "$mode" in
	region) grim -g "$(slurp)" - | swappy -f - ;;
	window)
		geom="$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')"
		grim -g "$geom" - | swappy -f -
		;;
	full) grim - | swappy -f - ;;
	*) echo "usage: $0 region|window|full" >&2; exit 1 ;;
esac
