# bigb-config

Personal system configuration for **Arch Linux + Hyprland** (`jarvis` — Dell 14 Plus 2-in-1, Intel Lunar Lake).

Migrated from an older Fedora Sway Atomic setup. Palette is **Omarchy Ethereal**, font is **JetBrainsMono Nerd Font** across Ghostty / Waybar / Rofi / Neovim / tmux / yazi.

One script (`install.sh`) turns a **plain Arch base install** into this full desktop — packages, dotfiles, shell, fonts, and tmux plugins — and is safe to re-run any time.

---

## What you get

- **Hyprland** Wayland desktop — Waybar (bar), Rofi (launcher), swaync (notifications), hypridle + hyprlock (idle/lock), wlogout (power menu), `uwsm` session manager.
- **Ghostty** terminal + **zsh** (oh-my-zsh + powerlevel10k + fzf-tab/autosuggestions/syntax-highlighting).
- **Neovim** (LazyVim, Ethereal colorscheme), **tmux** (Ethereal, TPM plugins), **yazi** file manager.
- **PipeWire** audio, **NetworkManager**, `xdg-desktop-portal-hyprland`, grim/slurp screenshots, Bibata cursor, **Chromium** (with per-mode profiles + Ethereal theme).
- **Claude Code** CLI, and `system-maintenance` + `qc-process` user timers.

---

## Quick start

On a machine that **already has Arch base installed** (see [prerequisites](#0-prerequisites) if not):

```sh
sudo pacman -S --needed git                                   # git, to clone the repo
git clone https://github.com/bmpatel15/bigb-config.git ~/bigb-config
cd ~/bigb-config
./install.sh                                                  # full setup (asks for sudo)
```

Then do the [manual steps](#4-finish-the-manual-steps) and [start Hyprland](#5-start-your-session). That's it.

---

## Full setup on a fresh Arch machine

### 0. Prerequisites

This repo **configures** an Arch system; it does **not** partition disks or install the base OS. Before you start, you need:

- A completed **Arch base install** (e.g. via [`archinstall`](https://wiki.archlinux.org/title/Archinstall)) with `base`, `linux`, `linux-firmware`.
- A **non-root user** with **`sudo`** rights (the script uses `sudo` and will prompt for your password).
- **Working internet** (Ethernet, or connect Wi-Fi with `nmtui` / `iwctl`).

Everything else — including the AUR helper (`yay`), `base-devel`, and all 120+ packages — is installed for you.

> **Tip:** clone over **HTTPS** (as shown) on a brand-new machine, since you won't have SSH keys yet. You can switch the remote to SSH later — see [step 4](#4-finish-the-manual-steps).

### 1. Get the repo

```sh
sudo pacman -S --needed git
git clone https://github.com/bmpatel15/bigb-config.git ~/bigb-config
cd ~/bigb-config
```

> Cloning to `~/bigb-config` is the convention (your live configs become symlinks into it). Any path works, but keep it somewhere permanent — **don't delete the repo after installing**, or every symlinked config breaks.

### 2. Run the installer

```sh
./install.sh
```

It's **idempotent** — safe to run again; already-done steps are detected and skipped.

### 3. What `./install.sh` does

It runs these phases in order (the `all` target):

| # | Phase | What happens |
|---|-------|--------------|
| 1 | **Packages** | Bootstraps `yay` (AUR helper), then installs everything in `packages/pacman.txt` — repo **and** AUR — with `yay -S --needed`. |
| 2 | **Links** | Symlinks the **LINKED** configs into `~` and `~/.config`. Any file already there is moved to `~/.bigb-config-backup-<timestamp>/` first, never overwritten. |
| 3 | **tmux** | Clones [TPM](https://github.com/tmux-plugins/tpm) into `~/.config/tmux/plugins/` and installs the tmux plugins headlessly. |
| 4 | **Copies** | Copies the **COPIED** configs into `~/.config` (skips any that already exist, so it won't clobber live edits). |
| 5 | **Shell** | Installs oh-my-zsh + powerlevel10k + zsh plugins, and sets your login shell to `zsh`. |
| 6 | **Font** | Installs **JetBrainsMono Nerd Font**. |
| 7 | **Claude Code** | Installs the `claude` CLI. |
| 8 | **Timers** | Enables the `system-maintenance` and `qc-process` user systemd timers. |

When it finishes, it prints the remaining manual steps (below).

### 4. Finish the manual steps

These are intentionally **not** automated:

1. **SSH keys** — restore your `~/.ssh`, or generate a new key and add the public half to GitHub:
   ```sh
   ssh-keygen -t ed25519 -C "you@example.com"
   cat ~/.ssh/id_ed25519.pub          # add this at github.com/settings/keys
   ```
   Then switch this repo's remote to SSH so pushes use your key:
   ```sh
   git -C ~/bigb-config remote set-url origin git@github.com:bmpatel15/bigb-config.git
   ```
2. **Sign in** — Chromium (per profile), and Claude Code (`claude`).
   Chromium profiles: run `bash ~/bigb-config/setup/chromium-profiles.sh` (browser closed), then per profile load the unpacked theme: `chrome://extensions` → Developer mode → Load unpacked → `~/bigb-config/chromium/ethereal-theme`.
3. **Obsidian vault** — restore it to `~/Documents/BigB-PKM` from your own sync/backup.
4. **btrfs snapshots** — set up snapper (see [below](#btrfs-snapshots-do-once-needs-root)).

### 5. Start your session

This repo installs **`uwsm`** (Universal Wayland Session Manager) but deliberately configures **no display manager / greeter**. After a reboot, log in at the TTY and launch Hyprland:

```sh
uwsm start hyprland
```

> Want it automatic? Add a greeter (e.g. `greetd` + `tuigreet`, or `ly`), or a `~/.zprofile` hook — neither is managed by this repo. Log out/in once so the zsh login shell fully takes effect.

---

## Repo layout

| Path | What |
|------|------|
| `install.sh` | Idempotent bootstrap (packages, symlinks, tmux plugins, oh-my-zsh, font, Claude Code, timers) |
| `config/` | `~/.config/*` app configs |
| `home/` | Home dotfiles (`.zshrc`, `.p10k.zsh`, `.gitconfig`) |
| `packages/pacman.txt` | Explicit packages (`pacman -Qqe`) — repo + AUR, fed to `yay` |
| `packages/aur.txt` | Foreign/AUR packages (`pacman -Qqm`) — reference/audit list |
| `setup/` | Extra one-time setup scripts (root system setup, Chromium profiles) |
| `config/systemd/user/` | User systemd units (`system-maintenance`, `qc-process` timers) |

---

## How config tracking works

Two strategies, chosen per app by whether the app rewrites its own config file:

- **LINKED** (`hypr`, `ghostty`, `waybar`, `rofi`, `nvim`, `tmux`, `yazi`, `swaync`, `zathura`, `wlogout`, `systemd`, plus `.zshrc`, `.p10k.zsh`, `.gitconfig`) — `~/.config/<x>` is a **symlink into this repo**, so hand-edits auto-track. **Edit in place, then `git commit`.**
- **COPIED** (`gtk-3.0`, `gtk-4.0`, `nwg-look`, `xsettingsd`, `btop`, `mimeapps.list`, `dolphinrc`, `kdeglobals`, `pavucontrol.ini`) — these apps rewrite the file via temp-file+rename, which would detach a symlink, so they're tracked as **copies**. After changing one in its app, run `./install.sh sync` to pull the live version back into the repo before committing.

> **tmux plugins** live under `~/.config/tmux/plugins/` and are **gitignored** — TPM re-fetches them via `./install.sh tmux` (or `prefix + I` = `Ctrl-a I` inside tmux). They're never committed.

---

## `install.sh` subcommands

```sh
./install.sh                # full setup on a fresh machine (all phases above)
./install.sh links          # (re)create the LINKED symlinks only
./install.sh tmux           # clone TPM + install tmux plugins
./install.sh restore        # copy COPIED configs from repo -> ~ (fresh machine)
./install.sh sync           # pull live COPIED configs from ~ -> repo (before a commit)
./install.sh sync-packages  # regenerate packages/{pacman,aur}.txt from installed packages
```

---

## Everyday use

| I did this… | …run this, then commit |
|-------------|------------------------|
| Edited a LINKED config (hypr, nvim, tmux, `.zshrc`, …) | nothing — it's a symlink, already tracked. Just `git commit` |
| Changed a COPIED app's settings (GTK, KDE, btop) | `./install.sh sync` |
| Installed or removed packages | `./install.sh sync-packages` |
| Want fresh tmux plugins | `./install.sh tmux` (or `Ctrl-a I` in tmux) |

```sh
git -C ~/bigb-config add -A && git -C ~/bigb-config commit -m "…" && git -C ~/bigb-config push
```

---

## btrfs snapshots (do once, needs root)

The system is btrfs (`@`, `@home`, `@pkg`, `@log`) on LUKS. Set up rollback:

```sh
sudo pacman -S --needed snapper snap-pac
sudo snapper -c root create-config /
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
```

`snap-pac` then snapshots every `pacman`/`yay` transaction. Boot is systemd-boot (no snapshot boot menu), so recover with `snapper rollback <N>` from a booted/live system, then reboot.

---

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| An old config was "in the way" during install | It wasn't lost — it's in `~/.bigb-config-backup-<timestamp>/`. Re-run `./install.sh links`. |
| tmux status bar is plain / plugins missing | `./install.sh tmux`, or inside tmux press `Ctrl-a` then `Shift-i`. |
| Terminal shows boxes instead of icons | Confirm the font: `fc-list \| grep -i JetBrains`; if missing, re-run `./install.sh`, then `fc-cache -f`. |
| `yay` bootstrap fails | Ensure `base-devel` + `git` are installed and the network is up, then re-run. |
| Shell still bash after install | Log out and back in (the `chsh` change applies at next login), or run `chsh -s /usr/bin/zsh`. |
| Hyprland won't start | Run `uwsm start hyprland` from a **TTY** (not over SSH); check `journalctl --user -b` for errors. |

---

## Manual steps recap

- Restore `~/.ssh` keys (or generate + add pubkey to GitHub, then switch the remote to SSH).
- Sign in: Chromium (per profile), Claude Code (`claude`).
- Restore the Obsidian vault to `~/Documents/BigB-PKM` (own sync/backup).
- Set up snapper for btrfs rollback.
- Log out/in so the zsh login shell + Hyprland session take effect.
