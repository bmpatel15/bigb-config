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
- **Dolphin** file manager, fully Ethereal-themed: `EtherealDark` KDE color scheme, **Ethereal-Papirus** icons (Papirus folders recolored to the accent), Breeze widgets, and a minimal Places sidebar (Desktop / Downloads / Projects / Config / Trash).
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
| 5 | **KDE theming** | Runs `setup/ethereal-kde.sh`: builds the **Ethereal-Papirus** icon theme into `~/.local/share/icons`, installs the `EtherealDark` color scheme, and seeds Dolphin's Places sidebar (only if absent). Takes effect after login thanks to `config/uwsm/env` (`QT_QPA_PLATFORMTHEME=kde` + `KDE_SESSION_VERSION=6`). |
| 6 | **Shell** | Installs oh-my-zsh + powerlevel10k + zsh plugins, and sets your login shell to `zsh`. |
| 7 | **Font** | Installs **JetBrainsMono Nerd Font**. |
| 8 | **Claude Code** | Installs the `claude` CLI. |
| 9 | **Hermes** | Installs the [Hermes agent](https://github.com/NousResearch/hermes-agent) (official installer) — the AI CLI that `qc-process` uses for the nightly QC pass. |
| 10 | **Argus** | Clones the private `argus` repo to `~/Projects/argus` and links `~/.local/bin/argus` (skips gracefully until SSH keys are set up). |
| 11 | **Timers** | Enables the `system-maintenance` and `qc-process` user systemd timers. |

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
2. **Sign in** — Chromium (per profile), and Claude Code (`claude` — its `pyright-lsp` plugin auto-installs from the tracked `settings.json` on first run).
   Chromium profiles: run `bash ~/bigb-config/setup/chromium-profiles.sh` (browser closed), then per profile load the unpacked theme: `chrome://extensions` → Developer mode → Load unpacked → `~/bigb-config/chromium/ethereal-theme`.
3. **Obsidian vault** — notes arrive via **Obsidian Sync**: install Obsidian, sign in, and connect the `BigB-PKM` vault at `~/Documents/BigB-PKM` **before** the nightly `qc-process` timer fires (quick-capture and argus write into it). The git clone is only needed to restore/inspect the versioned backup, or to link the backup remote on the one machine that runs `vpush`:
   ```sh
   git clone git@github.com:bmpatel15/BigB-PKM.git ~/Documents/BigB-PKM   # backup restore / vpush machine only
   ```
4. **API keys** — run `hermes` once to configure its keys (`qc-process` depends on it), and create `~/.config/argus/api_key`. Neither is tracked in git.
5. **btrfs snapshots** — set up snapper (see [below](#btrfs-snapshots-do-once-needs-root)).

### 5. Start your session

Login is handled by the **Ly display manager** (`ly@tty1.service`), with one-shot boot autologin into Hyprland and the Ethereal VT palette. Ly's config lives in `/etc/ly/` (system-level, root-owned) — it is **not** symlinked by `install.sh`; set it up once per machine following [`docs/ly-autologin-setup.md`](docs/ly-autologin-setup.md), then check it with:

```sh
ly-status        # read-only diagnostic (services, autologin arming, config sanity)
```

> Until Ly is set up, log in at the TTY and run `uwsm start hyprland` manually. Log out/in once so the zsh login shell fully takes effect.

---

## Repo layout

| Path | What |
|------|------|
| `install.sh` | Idempotent bootstrap (packages, symlinks, tmux plugins, oh-my-zsh, font, Claude Code, timers) |
| `config/` | `~/.config/*` app configs |
| `home/` | Home dotfiles (`.zshrc`, `.p10k.zsh`, `.gitconfig`) |
| `claude/` | Claude Code config: slash commands (`~/.claude/commands`), `settings.json`, project permissions (`~/.config/.claude`) — all LINKED. Credentials/history/sessions stay out of the repo |
| `packages/pacman.txt` | Explicit packages (`pacman -Qqe`) — repo + AUR, fed to `yay` |
| `packages/aur.txt` | Foreign/AUR packages (`pacman -Qqm`) — reference/audit list |
| `bin/` | User scripts, LINKED into `~/.local/bin` (quick-capture, `qc-process`, `ly-status`) |
| `docs/` | Machine docs (Ly display-manager / autologin setup) |
| `setup/` | Extra one-time setup scripts (root system setup, Chromium profiles, `ethereal-kde.sh` + its `EtherealDark.colors` / `user-places.xbel.seed` assets) |
| `config/systemd/user/` | User systemd units (`system-maintenance`, `qc-process` timers) |

---

## How config tracking works

Two strategies, chosen per app by whether the app rewrites its own config file:

- **LINKED** (`hypr`, `ghostty`, `waybar`, `rofi`, `nvim`, `tmux`, `yazi`, `swaync`, `zathura`, `wlogout`, `systemd`, Claude Code commands/settings, plus `.zshrc`, `.p10k.zsh`, `.gitconfig`) — `~/.config/<x>` is a **symlink into this repo**, so hand-edits auto-track. **Edit in place, then `git commit`.**
  > If Claude Code's `/config` UI ever replaces `~/.claude/settings.json` with a plain file (detaching the symlink), re-run `./install.sh links` and `git diff` to reconcile.
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
./install.sh ethereal       # rebuild Ethereal-Papirus icons + EtherealDark color scheme
./install.sh hermes         # install the Hermes agent (needed by qc-process)
./install.sh argus          # clone the argus repo + link ~/.local/bin/argus
./install.sh pkm            # link the PKM note-processing commands + daily-routine greeter (+ deps/vault check)
```

**Duplicate the PKM tooling on another machine** — pull this repo, then:

```sh
cd ~/bigb-config && git pull
./install.sh pkm            # links today-note/ot/rollover/og/sn/tasks/week-note/obs + the greeter
# vault arrives via Obsidian Sync (install Obsidian + connect BigB-PKM at ~/Documents/BigB-PKM);
# clone from GitHub only to restore the backup or to make this the vpush backup machine:
# git clone git@github.com:bmpatel15/BigB-PKM.git ~/Documents/BigB-PKM
exec zsh                    # loads the PKM aliases (oo/od/or/ow/os) + the daily greeter
```

The Claude Code commands in `claude/commands/` come along automatically (the `~/.claude/commands` symlink). The daily note itself is written by hand — there are no morning/evening ritual commands. The daily rhythm is documented in the vault: `06 - Command Center/Daily Workflow.md`.

---

## Everyday use

| I did this… | …run this, then commit |
|-------------|------------------------|
| Edited a LINKED config (hypr, nvim, tmux, `.zshrc`, …) | nothing — it's a symlink, already tracked. Just `git commit` |
| Changed a COPIED app's settings (GTK, KDE, btop) | `./install.sh sync` |
| Installed or removed packages | `./install.sh sync-packages` |
| `papirus-icon-theme` got a major update | `./install.sh ethereal` (rebuilds the recolored copies) |
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
- Connect the Obsidian vault via Obsidian Sync (`~/Documents/BigB-PKM`). Git clone only for backup restore / the `vpush` machine.
- Run `hermes` once to configure API keys; create `~/.config/argus/api_key`.
- Set up snapper for btrfs rollback.
- Log out/in so the zsh login shell + Hyprland session take effect.
