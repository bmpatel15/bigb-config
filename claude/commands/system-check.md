---
description: Read-only Arch + Hyprland system health check
---
Run a **read-only** health check on this Arch Linux + Hyprland laptop and give me a concise summary (flag only what needs attention; otherwise say it's healthy). Do not change anything.

Check:
1. Pending updates: `checkupdates 2>/dev/null | wc -l` (and list a few if many).
2. Orphan packages: `pacman -Qtdq`.
3. Failed services: `systemctl --failed --no-legend` and `systemctl --user --failed --no-legend`.
4. Recent btrfs snapshots: `sudo -n snapper -c root list 2>/dev/null | tail -5` (skip gracefully if it needs a password).
5. Disk + journal: `df -h /` and `journalctl --disk-usage`.
6. Battery health: `capacity`, `cycle_count`, and `charge_full` vs `charge_full_design` under `/sys/class/power_supply/BAT0/`.
7. Config drift: `git -C ~/bigb-config status --short` (uncommitted config changes worth committing).

End with a one-line verdict and, if anything is off, the exact command to fix it.
