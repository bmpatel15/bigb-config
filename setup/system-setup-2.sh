#!/usr/bin/env bash
# Second (final) root-level pass. Run: sudo bash ~/bigb-config/setup/system-setup-2.sh
#   - Intel GPU compute runtime (Level Zero) so PyTorch XPU sees the Arc 140V
#   - Anki (spaced repetition: AI-eng concepts + Satsang Diksha verses)
#   - GPU compute group access (render, video)
#   - weekly pacman cache trim + mirror refresh
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo: sudo bash $0"; exit 1; }
REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "$USER")}"

echo "== [1/4] Intel compute (Level Zero) + Anki =="
pacman -S --needed --noconfirm intel-compute-runtime level-zero-loader anki

echo "== [2/4] GPU compute group access for $REAL_USER =="
usermod -aG render,video "$REAL_USER"

echo "== [3/4] Weekly pacman cache trim (keeps last 3 versions) =="
systemctl enable --now paccache.timer

echo "== [4/4] Weekly mirror refresh (reflector) =="
install -Dm644 /dev/stdin /etc/xdg/reflector/reflector.conf <<'EOF'
--save /etc/pacman.d/mirrorlist
--country US
--protocol https
--latest 20
--sort rate
EOF
systemctl enable --now reflector.timer

echo
echo "=============================================================="
echo " DONE. Now REBOOT (or full logout/login) to activate:"
echo "   * groups: input (copy/paste), render+video (GPU compute)"
echo "   * /dev/uinput perms + the new Hyprland autostart"
echo " After reboot, torch.xpu.is_available() should report True."
echo "=============================================================="
