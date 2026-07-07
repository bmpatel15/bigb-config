#!/usr/bin/env bash
# bigb-config — Arch Linux + Hyprland setup bootstrap.
#
# Idempotent; safe to re-run. Subcommands:
#   ./install.sh          full setup: packages -> AUR -> links -> tmux -> shell -> font -> claude
#   ./install.sh links    only (re)create the hand-edited config symlinks
#   ./install.sh tmux     clone TPM + install tmux plugins (needs the tmux symlink)
#   ./install.sh restore  copy app-managed configs from repo -> ~ (fresh machine)
#   ./install.sh sync     pull live app-managed configs from ~ -> repo (before commit)
#   ./install.sh sync-packages  regenerate packages/{pacman,aur}.txt from installed packages
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
LINK_CONFIG=(hypr ghostty waybar rofi nvim swaync zathura wlogout systemd tmux yazi gazelle chromium-flags.conf)
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

enable_timers() {
    log "User systemd timers"
    systemctl --user daemon-reload
    systemctl --user enable --now system-maintenance.timer && info "enabled: system-maintenance.timer"
}

main() {
    case "${1:-all}" in
        links)   link_configs ;;
        tmux)    setup_tmux ;;
        restore) restore_copies ;;
        sync)    sync_copies ;;
        sync-packages) sync_packages ;;
        all)     install_packages; link_configs; setup_tmux; restore_copies; setup_omz; set_shell; install_font; install_claude; enable_timers
                 log "Done"
                 cat <<'EOF'

    Manual steps (intentionally not automated):
      * Restore ~/.ssh keys, or generate new ones and add the pubkey to GitHub.
      * Sign in: Chromium (per profile), Claude Code (run `claude`).
      * Chromium: run  bash ~/bigb-config/setup/chromium-profiles.sh  (browser closed),
        then per profile: chrome://extensions -> Developer mode -> Load unpacked ->
        ~/bigb-config/chromium/ethereal-theme
      * Restore the Obsidian vault to ~/Documents/BigB-PKM (own sync/backup).
      * Set up snapper (see README) for btrfs snapshot rollback.
      * Log out/in so the zsh login shell + Hyprland session take effect.
EOF
                 ;;
        *) echo "usage: $0 [all|links|tmux|restore|sync|sync-packages]" >&2; exit 1 ;;
    esac
}
main "$@"
