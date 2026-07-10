---
description: Interactive Arch maintenance — updates, orphans, cache, journal (asks before acting)
---
Perform routine maintenance on this Arch Linux + Hyprland laptop. This command MAY change the system, but you MUST show me what you found and get explicit confirmation before ANY destructive or privileged (`sudo`) action. Work through these, reporting concisely at each step:

1. **Updates** — `checkupdates` for repo updates (and note `yay -Sua` for AUR if relevant). If any, show the count + notable ones, then ask before running the upgrade.
2. **Orphans** — `pacman -Qtdq` for orphaned dependencies. If any, list them, then ask before `sudo pacman -Rns $(pacman -Qtdq)`.
3. **Package cache** — report size via `du -sh /var/cache/pacman/pkg/`. paccache.timer already trims weekly; only offer `sudo paccache -r` (keep 3) if it's unusually large.
4. **Failed services** — `systemctl --failed` and `systemctl --user --failed`. Surface anything failed and propose a fix; do not auto-restart without asking.
5. **Journal size** — `journalctl --disk-usage`; if over ~1G, offer `sudo journalctl --vacuum-size=500M`.
6. **Config drift** — `git -C ~/bigb-config status --short`; if there are uncommitted config changes, offer to commit them.

Never run a `sudo`/removal step without my explicit go-ahead. End with a summary of what changed and what I declined. This is the acting counterpart to the read-only `/system-check`.
