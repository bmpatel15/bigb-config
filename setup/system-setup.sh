#!/usr/bin/env bash
# Root-level system setup for the bigb-config overhaul.
#   Run:  sudo bash ~/bigb-config/setup/system-setup.sh
#
# Idempotent. Does ONLY things that need root:
#   - install all repo packages for Phases 1-6
#   - remove the wlogout-debug orphan
#   - set up snapper + snap-pac (btrfs snapshot rollback on every pacman txn)
#   - grant uinput access for ydotool (universal SUPER+C/V copy-paste)
#   - install thermald (Intel thermal daemon)
# User-level wiring (systemctl --user, shell, venvs) is done separately, not here.

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo: sudo bash $0"; exit 1; }
REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "$USER")}"
echo ">> setup for user: $REAL_USER"

echo; echo "== [1/5] Packages (repo) =="
pacman -S --needed --noconfirm \
  snapper snap-pac \
  swaync ydotool cliphist wl-clipboard grim slurp swappy hyprsunset pacman-contrib \
  bat eza lazygit github-cli git-delta zellij \
  base-devel rustup go uv ruff pyright nodejs npm podman podman-compose podman-docker \
  zathura zathura-pdf-mupdf foliate reflector thermald

echo; echo "== [2/5] Remove debug orphan =="
pacman -Rns --noconfirm wlogout-debug 2>/dev/null || echo "   (wlogout-debug already gone)"

echo; echo "== [3/5] snapper + snap-pac (btrfs rollback) =="
if snapper list-configs 2>/dev/null | grep -qE '^root\b'; then
  echo "   root config already exists"
else
  snapper -c root create-config /
  echo "   created snapper 'root' config"
fi
systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
echo "   snap-pac will now snapshot every pacman/yay transaction (pre + post)"

echo; echo "== [4/5] ydotool uinput access (universal copy/paste) =="
cat >/etc/udev/rules.d/60-ydotool.rules <<'EOF'
KERNEL=="uinput", GROUP="input", MODE="0660", OPTIONS+="static_node=uinput"
EOF
udevadm control --reload-rules && udevadm trigger --sysname-match=uinput || true
usermod -aG input "$REAL_USER"
echo "   udev rule installed; $REAL_USER added to 'input' group"

echo; echo "== [5/5] thermald (Intel thermal management) =="
systemctl enable --now thermald || echo "   (thermald enable skipped)"

echo
echo "=============================================================="
echo " DONE. One thing needs a re-login to take effect:"
echo "   * group 'input' (for ydotool /dev/uinput access)"
echo " After this script, tell Claude to continue with the user-level"
echo " wiring (services, shell, ydotoold, venvs). A full logout/login"
echo " (or reboot) will make everything live."
echo "=============================================================="
