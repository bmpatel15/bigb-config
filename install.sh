#!/usr/bin/env bash
# bigb-config — Arch Linux + Hyprland setup bootstrap.
#
# Idempotent; safe to re-run. Subcommands:
#   ./install.sh          full setup: packages -> links -> tmux -> copies -> kde theming -> shell -> font -> claude -> hermes -> argus -> timers
#   ./install.sh links    only (re)create the hand-edited config symlinks
#   ./install.sh tmux     clone TPM + install tmux plugins (needs the tmux symlink)
#   ./install.sh restore  copy app-managed configs from repo -> ~ (fresh machine)
#   ./install.sh sync     pull live app-managed configs from ~ -> repo (before commit)
#   ./install.sh sync-packages  regenerate packages/{pacman,aur}.txt from installed packages
#   ./install.sh ethereal rebuild the Ethereal-Papirus icons + KDE color scheme (setup/ethereal-kde.sh)
#   ./install.sh ly       ly display manager: boot autologin + Ethereal greeter (sudo; setup/ly-setup.sh)
#   ./install.sh blueman  disable blueman's tray icon (waybar's bluetooth module replaces it)
#   ./install.sh hermes   install the Hermes agent (needed by qc-process)
#   ./install.sh argus    clone the argus repo + link ~/.local/bin/argus
#   ./install.sh pkm      link the PKM note-processing commands + daily-routine greeter; check deps + vault
#
# Two tracking strategies (see arrays below):
#   LINKED  — configs WE hand-edit; ~/.config/<x> is a symlink into this repo,
#             so edits auto-track in git.
#   COPIED  — configs APPS rewrite via temp-file+rename (KDE/GTK/mime); a symlink
#             would get detached, so these are tracked as copies and synced.

set -euo pipefail

DOTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.bigb-config-backup-$(date +%Y%m%d-%H%M%S)"

LINK_HOME=(.zshrc .zprofile .p10k.zsh .gitconfig)
LINK_CONFIG=(hypr ghostty waybar rofi nvim swaync zathura wlogout systemd tmux yazi gazelle chromium-flags.conf fastfetch uwsm quickshell)
LINK_BIN=(obsidian-capture obsidian-capture-popup qc-process ly-status)
# PKM note-processing commands + daily-routine greeter (vault: ~/Documents/BigB-PKM).
LINK_BIN_PKM=(today-note ot rollover on og sn tasks week-note obs pkm-daily)
COPY_CONFIG=(gtk-3.0 gtk-4.0 nwg-look xsettingsd btop mimeapps.list dolphinrc kdeglobals pavucontrol.ini)

log()  { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
info() { printf '    %s\n' "$*"; }

link() { # src dst — backs up an existing target, then symlinks
    local src="$1" dst="$2"
    if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]]; then
        info "ok: $dst"; return 0
    fi
    if [[ -e "$dst" || -L "$dst" ]]; then
        mkdir -p "$BACKUP"; info "backup: $dst -> $BACKUP/"; mv "$dst" "$BACKUP/"
    fi
    ln -sn "$src" "$dst"; info "linked: $dst -> $src"
}

link_configs() {
    log "Symlinking hand-edited configs (LINKED)"
    for f in "${LINK_HOME[@]}";   do [[ -e "$DOTS/home/$f"   ]] && link "$DOTS/home/$f"   "$HOME/$f"; done
    mkdir -p "$HOME/.config"
    for d in "${LINK_CONFIG[@]}"; do [[ -e "$DOTS/config/$d" ]] && link "$DOTS/config/$d" "$HOME/.config/$d"; done
    mkdir -p "$HOME/.local/bin"
    for b in "${LINK_BIN[@]}" "${LINK_BIN_PKM[@]}"; do [[ -e "$DOTS/bin/$b" ]] && link "$DOTS/bin/$b" "$HOME/.local/bin/$b"; done
    # Claude Code: slash commands + skills + settings (secrets/state stay in ~/.claude, untracked)
    mkdir -p "$HOME/.claude"
    link "$DOTS/claude/commands"       "$HOME/.claude/commands"
    link "$DOTS/claude/skills"         "$HOME/.claude/skills"
    link "$DOTS/claude/settings.json"  "$HOME/.claude/settings.json"
    link "$DOTS/claude/config-project" "$HOME/.config/.claude"
}

setup_tmux() { # clone TPM into the (symlinked) tmux config dir, then install plugins
    command -v tmux >/dev/null || { info "skip: tmux not installed"; return 0; }
    log "tmux plugin manager (TPM) + plugins"
    local tpm="$HOME/.config/tmux/plugins/tpm"   # -> repo config/tmux/plugins (gitignored)
    if [[ -d "$tpm/.git" ]]; then
        info "ok: tpm"
    elif git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm"; then
        info "cloned: tpm"
    else
        info "tpm clone failed (network?) — run: prefix + I  inside tmux later"; return 0
    fi
    # Headless install. TMUX= lets this run even if invoked from inside tmux.
    if [[ -x "$tpm/bin/install_plugins" ]]; then
        TMUX= tmux new-session -d -s _tpm 2>/dev/null || true
        if TMUX= "$tpm/bin/install_plugins" >/dev/null 2>&1; then info "plugins installed";
        else info "some plugins pending — run: prefix + I  inside tmux"; fi
        TMUX= tmux kill-session -t _tpm 2>/dev/null || true
    fi
}

restore_copies() {
    log "Restoring app-managed configs (COPIED)"
    mkdir -p "$HOME/.config"
    for d in "${COPY_CONFIG[@]}"; do
        [[ -e "$DOTS/config/$d" ]] || continue
        if [[ -e "$HOME/.config/$d" ]]; then info "exists, skip: ~/.config/$d"
        else cp -a "$DOTS/config/$d" "$HOME/.config/"; info "restored: ~/.config/$d"; fi
    done
}

sync_copies() {
    log "Pulling live app-managed configs into the repo (COPIED)"
    for d in "${COPY_CONFIG[@]}"; do
        if [[ -e "$HOME/.config/$d" && ! -L "$HOME/.config/$d" ]]; then
            cp -a "$HOME/.config/$d" "$DOTS/config/"; info "pulled: $d"
        fi
    done
}

setup_ethereal_kde() {
    log "Ethereal KDE theming (Dolphin icons + color scheme)"
    bash "$DOTS/setup/ethereal-kde.sh"
}

setup_ly() { # ly display manager: boot autologin + Ethereal greeter (root-level /etc pass)
    log "Ly display manager (boot autologin + Ethereal greeter)"
    sudo bash "$DOTS/setup/ly-setup.sh"
}

setup_blueman() {
    log "Blueman: no tray icon (waybar's bluetooth module replaces it)"
    # ShowConnected must be disabled too: it depends on StatusIcon, and blueman
    # force-loads dependencies even when they are on the '!' disable list.
    gsettings set org.blueman.general plugin-list \
        "['!ShowConnected', '!StatusIcon', '!StatusNotifierItem']" 2>/dev/null \
        && info "disabled applet plugins: ShowConnected, StatusIcon, StatusNotifierItem" \
        || info "gsettings failed (no session bus?) — re-run: ./install.sh blueman"
}

sync_packages() {
    log "Refreshing package manifests"
    pacman -Qqe  > "$DOTS/packages/pacman.txt"; info "wrote packages/pacman.txt ($(wc -l < "$DOTS/packages/pacman.txt") explicit repo + AUR)"
    pacman -Qqem > "$DOTS/packages/aur.txt";    info "wrote packages/aur.txt ($(wc -l < "$DOTS/packages/aur.txt") foreign/AUR)"
    info "review with: git -C \"$DOTS\" diff packages/  then commit"
}

bootstrap_yay() {
    command -v yay &>/dev/null && return 0
    command -v paru &>/dev/null && return 0
    log "Bootstrapping yay (AUR helper)"
    sudo pacman -S --needed --noconfirm git base-devel
    local tmp; tmp="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    ( cd "$tmp/yay-bin" && makepkg -si --noconfirm )
    rm -rf "$tmp"
}

install_packages() {
    log "Packages (repo + AUR via helper)"
    bootstrap_yay
    local helper; helper="$(command -v yay || command -v paru)"
    # packages/pacman.txt is `pacman -Qqe` (explicit repo + AUR); yay resolves both.
    xargs -a "$DOTS/packages/pacman.txt" "$helper" -S --needed --noconfirm
}

setup_omz() {
    log "oh-my-zsh + powerlevel10k + plugins"
    local OMZ="$HOME/.oh-my-zsh" C="$HOME/.oh-my-zsh/custom"
    clone() { [[ -d "$2" ]] && { info "ok: $2"; return; } || GIT_CONFIG_GLOBAL=/dev/null git clone --depth=1 "$1" "$2"; }
    clone https://github.com/ohmyzsh/ohmyzsh.git                   "$OMZ"
    clone https://github.com/romkatv/powerlevel10k.git             "$C/themes/powerlevel10k"
    clone https://github.com/zsh-users/zsh-autosuggestions.git     "$C/plugins/zsh-autosuggestions"
    clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$C/plugins/zsh-syntax-highlighting"
    clone https://github.com/Aloxaf/fzf-tab.git                    "$C/plugins/fzf-tab"
}

set_shell() {
    log "Login shell -> zsh"
    [[ "$(getent passwd "$USER" | cut -d: -f7)" == */zsh ]] && { info "already zsh"; return; }
    chsh -s /usr/bin/zsh || info "run: sudo usermod --shell /usr/bin/zsh $USER"
}

install_font() {
    log "JetBrainsMono Nerd Font"
    if fc-list | grep -i 'JetBrainsMono Nerd Font' >/dev/null; then info "already installed"; return; fi
    sudo pacman -S --needed --noconfirm ttf-jetbrains-mono-nerd || {
        local dir="$HOME/.local/share/fonts/JetBrainsMonoNerdFont" tmp; tmp="$(mktemp -d)"
        curl -fsSLo "$tmp/f.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
        mkdir -p "$dir"; unzip -o "$tmp/f.zip" -d "$dir" '*.ttf'; rm -rf "$tmp"; fc-cache -f
    }
}

install_claude() {
    log "Claude Code"
    command -v claude &>/dev/null && { info "already installed"; return; }
    curl -fsSL https://claude.ai/install.sh | bash
}

install_hermes() { # required by qc-process (nightly QC pass)
    log "Hermes agent"
    [[ -x "$HOME/.local/bin/hermes" ]] && { info "already installed"; return; }
    curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
    info "configure API keys on first run:  hermes"
}

setup_argus() { # research agent; its state lives in the vault (~/Documents/BigB-PKM/.argus)
    log "Argus research agent"
    if [[ ! -d "$HOME/Projects/argus" ]]; then
        GIT_CONFIG_GLOBAL=/dev/null git clone git@github.com:bmpatel15/argus.git "$HOME/Projects/argus" \
            || { info "clone failed — needs SSH keys with access to the private repo; retry later with: ./install.sh argus"; return 0; }
    else
        info "ok: ~/Projects/argus"
    fi
    mkdir -p "$HOME/.local/bin"
    link "$HOME/Projects/argus/bin/argus" "$HOME/.local/bin/argus"
    [[ -f "$HOME/.config/argus/api_key" ]] || info "reminder: create ~/.config/argus/api_key (not tracked in git)"
}

setup_pkm() { # PKM note-processing commands + daily-routine greeter (vault: ~/Documents/BigB-PKM)
    log "PKM vault tooling (note-processing commands + daily routines)"
    mkdir -p "$HOME/.local/bin"
    for b in "${LINK_BIN_PKM[@]}"; do [[ -e "$DOTS/bin/$b" ]] && link "$DOTS/bin/$b" "$HOME/.local/bin/$b"; done
    # /morning + /end-of-day ride along with the whole-dir commands symlink (link_configs).
    [[ -L "$HOME/.claude/commands" ]] || { mkdir -p "$HOME/.claude"; link "$DOTS/claude/commands" "$HOME/.claude/commands"; }

    local miss=()
    for c in rg nvim perl tmux git; do command -v "$c" >/dev/null || miss+=("$c"); done
    ((${#miss[@]})) && info "missing runtime deps: ${miss[*]} — sudo pacman -S --needed ripgrep neovim perl tmux git"
    command -v claude >/dev/null || info "claude not installed — the full ./install.sh installs it"

    if [[ -d "$HOME/Documents/BigB-PKM" ]]; then
        info "ok: vault at ~/Documents/BigB-PKM"
    else
        info "vault not found — it arrives via Obsidian Sync (install Obsidian, connect BigB-PKM at ~/Documents/BigB-PKM)."
        info "  git clone git@github.com:bmpatel15/BigB-PKM.git only for backup restore / the vpush machine"
    fi

    cat <<'EOF'

    PKM daily workflow ready. Open a new terminal (or `exec zsh`), then:
      morning        start the day  (note + rollover + Main 3, via Claude Code /morning)
      ot "task"      add a task to today   ·   SUPER+SHIFT+O   quick-capture a thought
      tasks          list every open task  ·   od / ow / os    open today / week / scripture
      evening        close the day  (rating + Win/Struggle/Lesson + tomorrow, via /end-of-day)
    Reference:  ~/Documents/BigB-PKM/06 - Command Center/Daily Workflow.md
EOF
}

enable_timers() {
    log "User systemd timers"
    systemctl --user daemon-reload
    systemctl --user enable --now system-maintenance.timer && info "enabled: system-maintenance.timer"
    systemctl --user enable --now qc-process.timer          && info "enabled: qc-process.timer"
}

main() {
    case "${1:-all}" in
        links)   link_configs ;;
        tmux)    setup_tmux ;;
        restore) restore_copies ;;
        sync)    sync_copies ;;
        sync-packages) sync_packages ;;
        ethereal) setup_ethereal_kde ;;
        ly)      setup_ly ;;
        blueman) setup_blueman ;;
        hermes)  install_hermes ;;
        argus)   setup_argus ;;
        pkm)     setup_pkm ;;
        all)     install_packages; link_configs; setup_tmux; restore_copies; setup_ethereal_kde; setup_blueman; setup_omz; set_shell; install_font; install_claude; install_hermes; setup_argus; setup_pkm; enable_timers
                 log "Done"
                 cat <<'EOF'

    Manual steps (intentionally not automated):
      * Restore ~/.ssh keys, or generate new ones and add the pubkey to GitHub.
      * Sign in: Chromium (per profile), Claude Code (run `claude`).
      * Chromium: run  bash ~/bigb-config/setup/chromium-profiles.sh  (browser closed),
        then per profile: chrome://extensions -> Developer mode -> Load unpacked ->
        ~/bigb-config/chromium/ethereal-theme
      * Connect the Obsidian vault via Obsidian Sync (~/Documents/BigB-PKM) BEFORE
        the nightly qc-process timer fires. Git clone only for backup restore or
        the machine that runs vpush:
          git clone git@github.com:bmpatel15/BigB-PKM.git ~/Documents/BigB-PKM
      * Run `hermes` once to configure its API keys (qc-process depends on it).
      * Create ~/.config/argus/api_key (argus API key; never committed).
      * Set up ly (boot autologin + Ethereal greeter):  ./install.sh ly
        (root-level /etc pass — not in the automated flow; see docs/ly-autologin-setup.md)
      * Set up snapper (see README) for btrfs snapshot rollback.
      * Log out/in so the zsh login shell, Hyprland session, and the Qt/KDE
        theming env (config/uwsm/env — needed for Dolphin) take effect.
EOF
                 ;;
        *) echo "usage: $0 [all|links|tmux|restore|sync|sync-packages|ethereal|ly|blueman|hermes|argus|pkm]" >&2; exit 1 ;;
    esac
}
main "$@"
