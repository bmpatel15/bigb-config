#!/usr/bin/env bash
# ethereal-kde.sh — Ethereal theming for KDE apps (Dolphin) outside Plasma.
#
# Builds ~/.local/share/icons/Ethereal-Papirus (Papirus-Dark folders recolored
# to the Ethereal accent), installs the EtherealDark color scheme, and seeds
# the Places sidebar on a fresh machine. Idempotent; re-run after major
# papirus-icon-theme updates. Usage: ethereal-kde.sh [--force]
#
# Pairs with config/kdeglobals (Icons Theme=Ethereal-Papirus, ColorScheme=EtherealDark).
set -euo pipefail

DOTS="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME="$HOME/.local/share/icons/Ethereal-Papirus"
SRC_BASE="/usr/share/icons/Papirus-Dark" # 32px+ size dirs symlink into ../Papirus
# violet base -> Ethereal accent; shadow/detail shades keep Papirus's darkness ratio
RECOLOR='s/#7e57c2/#7d82d9/gI; s/#5d399b/#5a5fc0/gI; s/#2c1e44/#262a55/gI'
FORCE="${1:-}"

info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }

[[ -d "$SRC_BASE" ]] || { echo "ERROR: $SRC_BASE not found — install papirus-icon-theme" >&2; exit 1; }

# --- icon theme ------------------------------------------------------------
rm -rf "$THEME"
total=0
for s in 16 22 24 32 48 64; do
    src="$SRC_BASE/${s}x${s}/places" dst="$THEME/${s}x${s}/places"
    mkdir -p "$dst"
    for f in "$src"/folder-violet*.svg "$src"/user-violet*.svg; do
        [[ -e "$f" ]] || continue # 16x16 only has folder-violet.svg
        name="$(basename "$f")"
        sed -E "$RECOLOR" "$f" > "$dst/${name/-violet/}" # sed derefs the symlinked variants
        ((++total))
    done
    # plain dirs resolve via the mimetype name, not "folder"
    [[ -e "$dst/folder.svg" ]] && cp "$dst/folder.svg" "$dst/inode-directory.svg"
done
((total > 300)) || { echo "ERROR: expected ~400 violet icons, got $total — Papirus layout changed?" >&2; exit 1; }

cat > "$THEME/index.theme" <<'EOF'
[Icon Theme]
Name=Ethereal-Papirus
Comment=Papirus-Dark with Ethereal-accent folders
Inherits=Papirus-Dark,Papirus,breeze-dark,hicolor
Directories=16x16/places,22x22/places,24x24/places,32x32/places,48x48/places,64x64/places

[16x16/places]
Size=16
Context=Places
Type=Fixed

[22x22/places]
Size=22
Context=Places
Type=Fixed

[24x24/places]
Size=24
Context=Places
Type=Fixed

[32x32/places]
Size=32
Context=Places
Type=Fixed

[48x48/places]
Size=48
Context=Places
Type=Scalable
MinSize=33
MaxSize=48

[64x64/places]
Size=64
Context=Places
Type=Scalable
MinSize=49
MaxSize=512
EOF
info "Ethereal-Papirus: $total icons"

# --- color scheme ----------------------------------------------------------
install -Dm644 "$DOTS/setup/EtherealDark.colors" "$HOME/.local/share/color-schemes/EtherealDark.colors"
info "EtherealDark.colors installed"

# --- places sidebar (seed only — KDE mutates this file at runtime) ----------
mkdir -p "$HOME/Desktop" "$HOME/Downloads" "$HOME/Projects" # sidebar targets
PLACES="$HOME/.local/share/user-places.xbel"
if [[ ! -e "$PLACES" || "$FORCE" == "--force" ]]; then
    mkdir -p "$(dirname "$PLACES")"
    sed "s|file:///home/bmpatel15|file://$HOME|g" "$DOTS/setup/user-places.xbel.seed" > "$PLACES"
    info "user-places.xbel seeded"
else
    info "user-places.xbel exists, left alone (--force to overwrite)"
fi

rm -f "$HOME/.cache/icon-cache.kcache" # KIconLoader cache; forces re-scan
info "done — restart Dolphin to see changes"
