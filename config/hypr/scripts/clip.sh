#!/usr/bin/env bash
# Universal copy/paste dispatcher for Hyprland (bound to SUPER+C / SUPER+V).
#
#   Terminals need Ctrl+Shift+C / Ctrl+Shift+V (Ctrl+C = SIGINT);
#   GUI apps use Ctrl+C / Ctrl+V.
# We detect the focused window's class and emit the right chord via ydotool.
#
# Requires: ydotool + a running ydotoold (see hypr autostart), jq, hyprctl.
# ydotool `key` takes Linux input-event keycodes  (press = :1, release = :0):
#   LEFTCTRL=29  LEFTSHIFT=42  C=46  V=47

set -uo pipefail
export YDOTOOL_SOCKET="${YDOTOOL_SOCKET:-$XDG_RUNTIME_DIR/.ydotool_socket}"

action="${1:-}"
class="$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // ""' 2>/dev/null || true)"

is_terminal() {
	case "${class,,}" in
		*ghostty*|*foot*|*kitty*|*alacritty*|*wezterm*|*st*) return 0 ;;
		*) return 1 ;;
	esac
}

term_copy()  { ydotool key 29:1 42:1 46:1 46:0 42:0 29:0; }  # Ctrl+Shift+C
term_paste() { ydotool key 29:1 42:1 47:1 47:0 42:0 29:0; }  # Ctrl+Shift+V
gui_copy()   { ydotool key 29:1 46:1 46:0 29:0; }            # Ctrl+C
gui_paste()  { ydotool key 29:1 47:1 47:0 29:0; }            # Ctrl+V

case "$action" in
	copy)  is_terminal && term_copy  || gui_copy  ;;
	paste) is_terminal && term_paste || gui_paste ;;
	*) echo "usage: $0 copy|paste" >&2; exit 1 ;;
esac
