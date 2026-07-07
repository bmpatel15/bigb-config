#!/usr/bin/env bash
# Power menu for waybar's ⏻ button (rofi dmenu)

chosen=$(printf '󰌾  Lock\n󰒲  Suspend\n󰍃  Logout\n󰜉  Reboot\n󰐥  Shutdown' \
  | rofi -dmenu -i -p "Power" -theme-str 'listview { lines: 5; }')

case "$chosen" in
  *Lock)     "$HOME/.config/hypr/scripts/lock.sh" ;;
  *Suspend)
    # lock first, then wait until hyprlock has actually grabbed the screen
    # before suspending — otherwise the system can suspend before the lock
    # paints, flashing the desktop for a moment on resume.
    "$HOME/.config/hypr/scripts/lock.sh" &
    for _ in $(seq 1 50); do pgrep -x hyprlock >/dev/null && break; sleep 0.1; done
    systemctl suspend
    ;;
  *Logout)   hyprctl dispatch exit ;;
  *Reboot)   systemctl reboot ;;
  *Shutdown) systemctl poweroff ;;
esac
