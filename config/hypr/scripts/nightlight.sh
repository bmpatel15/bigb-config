#!/usr/bin/env bash
# Toggle hyprsunset warm mode (good for evening reading / Satsang study).
TEMP="${1:-4000}"
if pgrep -x hyprsunset >/dev/null; then
	pkill -x hyprsunset
	notify-send -t 2000 -u low "󰛨 Night light" "off"
else
	hyprsunset -t "$TEMP" >/dev/null 2>&1 &
	disown
	notify-send -t 2000 -u low "󰛨 Night light" "on (${TEMP}K)"
fi
