# bigb-config

Personal system configuration for **Arch Linux + Hyprland** (`jarvis` — Dell 14 Plus 2-in-1, Intel Lunar Lake).

Migrated from an older Fedora Sway Atomic setup. Palette is **Omarchy Ethereal**, font is **JetBrainsMono Nerd Font** across Ghostty / Waybar / Rofi / Neovim.

## Layout

| Path | What |
|------|------|
| `install.sh` | Idempotent bootstrap (packages, symlinks, oh-my-zsh, font, Claude Code) |
| `config/` | `~/.config/*` configs |
| `home/` | Home dotfiles (`.zshrc`, `.p10k.zsh`, `.gitconfig`) |
| `packages/pacman.txt` | Explicit packages (`pacman -Qqe`) — repo + AUR |
| `packages/aur.txt` | Foreign/AUR packages (`pacman -Qqm`) |

## Two tracking strategies

- **LINKED** (`hypr`, `ghostty`, `waybar`, `rofi`, `nvim`, `.zshrc`, `.p10k.zsh`, `.gitconfig`) —
  `~/.config/<x>` is a **symlink into this repo**, so hand-edits auto-track. Edit in place, `git commit`.
- **COPIED** (`gtk-3.0`, `gtk-4.0`, `nwg-look`, `xsettingsd`, `btop`, `yazi`, `mimeapps.list`,
  `dolphinrc`, `kdeglobals`, `pavucontrol.ini`) — apps rewrite these via temp-file+rename,
  which detaches symlinks, so they're tracked as **copies**. After changing them in the app,
  run `./install.sh sync` to pull the live versions back into the repo before committing.

## Usage

```sh
./install.sh          # full setup on a fresh machine
./install.sh links    # (re)create the LINKED symlinks only
./install.sh restore  # copy COPIED configs from repo -> ~ (fresh machine)
./install.sh sync     # pull live COPIED configs from ~ -> repo (before a commit)
```

## btrfs snapshots (not in install.sh — do once, needs root)

The system is btrfs (`@`, `@home`, `@pkg`, `@log`) on LUKS. Set up rollback:

```sh
sudo pacman -S --needed snapper snap-pac
sudo snapper -c root create-config /
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
```

`snap-pac` then snapshots every `pacman`/`yay` transaction. Rollback: boot is systemd-boot
(no snapshot boot menu), so recover with `snapper rollback <N>` from a booted/live system, then reboot.

## Manual steps after a fresh install

- Restore `~/.ssh` keys (or generate + add pubkey to GitHub).
- Sign in: Zen browser, Claude Code (`claude`).
- Restore the Obsidian vault to `~/Documents/BigB-PKM` (own sync/backup).
