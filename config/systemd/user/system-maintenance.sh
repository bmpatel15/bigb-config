#!/usr/bin/env bash
# Weekly system-maintenance report (NON-destructive): available updates + orphans.
# Cache trimming (paccache.timer) and mirror refresh (reflector.timer) are handled
# by their own timers. This script only *reports* — it never removes anything.
set -uo pipefail

log="${XDG_STATE_HOME:-$HOME/.local/state}/system-maintenance.log"
mkdir -p "$(dirname "$log")"

updates=$(checkupdates 2>/dev/null | wc -l)
orphans=$(pacman -Qtdq 2>/dev/null | wc -l)

printf '%s  updates=%s orphans=%s\n' "$(date '+%Y-%m-%d %H:%M')" "$updates" "$orphans" >> "$log"

# Only notify when there's something worth acting on.
if (( updates > 0 || orphans > 0 )); then
  body="${updates} update(s) available."
  (( orphans > 0 )) && body+=$'\n'"${orphans} orphan(s) — review: pacman -Qtdq   remove: sudo pacman -Rns \$(pacman -Qtdq)"
  notify-send -a "System maintenance" -i system-software-update "Weekly maintenance" "$body" 2>/dev/null || true
fi
