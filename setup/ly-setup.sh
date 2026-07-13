#!/usr/bin/env bash
# Ly display manager: boot autologin + Ethereal greeter theme (root-level pass).
#   Run: sudo bash ~/bigb-config/setup/ly-setup.sh
#
# Reapplies the /etc-side ly configuration that lives OUTSIDE the git-tracked
# dotfiles (root-owned; install.sh's symlinks never touch it, so a machine
# reprovision resets it to package defaults). Idempotent; safe to re-run.
# Full rationale: docs/ly-autologin-setup.md.
#
#   - enables ly@tty1.service (Conflicts=getty@tty1 displaces the getty at boot)
#   - one-shot boot autologin -> Hyprland (auto_login_user/session in config.ini)
#   - Ethereal greeter palette (config.ini colors + startup.sh 16-slot VT table)
#   - Terminus console font for a crisp greeter on the 1920x1200 panel
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo: sudo bash $0"; exit 1; }

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo bmpatel15)}"
SESSION="hyprland"          # matches hyprland-uwsm.desktop first — see doc §6
CONFIG=/etc/ly/config.ini
STARTUP=/etc/ly/startup.sh
VCONSOLE=/etc/vconsole.conf
FONT="ter-124n"            # Terminus 12x24

# set_key KEY VALUE FILE — replace `KEY = ...` in place, or append if absent.
set_key() {
    local key="$1" val="$2" file="$3"
    if grep -qE "^${key} = " "$file"; then
        sed -i "s|^${key} = .*|${key} = ${val}|" "$file"
    else
        printf '%s = %s\n' "$key" "$val" >> "$file"
    fi
}

echo "== [1/5] Backup current /etc ly files =="
BK="/home/$REAL_USER/.local/state/ly-setup-backup/$(date +%Y%m%d-%H%M%S)"
install -d -o "$REAL_USER" -g "$REAL_USER" "$BK"
for f in "$CONFIG" "$STARTUP" "$VCONSOLE"; do
    [[ -f "$f" ]] && cp -a "$f" "$BK/"
done
echo "   saved to $BK"

echo "== [2/5] Terminus console font =="
pacman -S --needed --noconfirm terminus-font

echo "== [3/5] config.ini: autologin + Ethereal colors =="
set_key auto_login_user     "$REAL_USER"       "$CONFIG"
set_key auto_login_session  "$SESSION"         "$CONFIG"
set_key auto_login_service  ly-autologin       "$CONFIG"
set_key allow_empty_password true              "$CONFIG"   # mandatory for autologin (doc §6)
set_key start_cmd           "$STARTUP"         "$CONFIG"
set_key full_color          false              "$CONFIG"   # palette-index mode (doc §10)
set_key bg                  0x00000000         "$CONFIG"
set_key fg                  0x40000008         "$CONFIG"   # BRIGHT+WHITE -> slot 15 peach
set_key border_fg           0x00000005         "$CONFIG"   # BLUE -> slot 4 lavender
set_key error_fg            0x01000002         "$CONFIG"   # BOLD+RED -> slot 9 soft red
set_key initial_info_text   ethereal           "$CONFIG"
set_key clock               "%H:%M"            "$CONFIG"

echo "== [4/5] startup.sh: Ethereal 16-slot VT palette =="
cat > "$STARTUP" <<'LYSTARTUP'
#!/bin/sh
# Ethereal 16-slot VT palette (managed by bigb-config setup/ly-setup.sh).
# Slots 1-15 match the Ghostty Ethereal ANSI table; slot 0 is the true
# background navy. See docs/ly-autologin-setup.md §10.
if [ "$TERM" = "linux" ]; then
    printf '\033]P0060B1E'   # 0  background navy
    printf '\033]P1ED5B5A'   # 1  red
    printf '\033]P292A593'   # 2  green
    printf '\033]P3E9BB4F'   # 3  yellow
    printf '\033]P47D82D9'   # 4  blue (lavender accent)
    printf '\033]P5C89DC1'   # 5  magenta
    printf '\033]P6A3BFD1'   # 6  cyan
    printf '\033]P7F99957'   # 7  white (peach)
    printf '\033]P86D7DB6'   # 8  bright black
    printf '\033]P9FAAAA9'   # 9  bright red (error)
    printf '\033]PAC4CFC4'   # 10 bright green
    printf '\033]PBF7DC9C'   # 11 bright yellow
    printf '\033]PCC2C4F0'   # 12 bright blue
    printf '\033]PDEAD7E7'   # 13 bright magenta
    printf '\033]PEDFEAF0'   # 14 bright cyan
    printf '\033]PFFFCEAD'   # 15 bright white (foreground)
    clear
fi
LYSTARTUP
chmod 755 "$STARTUP"

echo "== [5/5] Console font + enable ly@tty1 =="
# vconsole.conf uses FONT=VALUE (no spaces), not the config.ini `key = value` form.
if grep -qE '^FONT=' "$VCONSOLE" 2>/dev/null; then
    sed -i "s|^FONT=.*|FONT=${FONT}|" "$VCONSOLE"
else
    printf 'FONT=%s\n' "$FONT" >> "$VCONSOLE"
fi
systemctl enable ly@tty1.service

echo
echo "=============================================================="
echo " DONE. ly@tty1 enabled; boot autologin -> Hyprland for $REAL_USER."
echo " Reboot to activate. Backup of prior /etc files: $BK"
echo
echo " Test without rebooting (fires one autologin on tty3):"
echo "   sudo systemctl start ly@tty3.service   # Ctrl+Alt+F3 to view"
echo "   sudo systemctl stop  ly@tty3.service   # Ctrl+Alt+F1 back first"
echo "=============================================================="
