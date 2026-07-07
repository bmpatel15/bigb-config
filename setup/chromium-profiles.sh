#!/usr/bin/env bash
# One-time Chromium profile setup for the browser-mode system (rofi/browser-mode.sh).
#   Run with Chromium FULLY CLOSED:  bash ~/bigb-config/setup/chromium-profiles.sh
# Does:
#   1. Creates "Satsang" and "Entertainment" profiles (dir name = mode name).
#   2. Sets a GM3 baseline theme color (Ethereal bg #060B1E) on all three —
#      the real theme is the unpacked extension (see final echo / README).
#   3. Renames the Default profile's DISPLAY name -> "Education" (dir stays
#      "Default"; all logins/data preserved). Backs up the JSON it edits.
# Idempotent: re-running skips existing profiles and re-applies names/colors.
set -euo pipefail

CHROME_DIR="$HOME/.config/chromium"
LOCAL_STATE="$CHROME_DIR/Local State"
STAMP="$(date +%Y%m%d-%H%M%S)"

# Editing Chromium's JSON while it runs corrupts/loses state — hard refuse.
if pgrep -x chromium >/dev/null; then
    echo "ERROR: Chromium is running. Close it fully, then re-run." >&2
    exit 1
fi
[[ -f "$LOCAL_STATE" ]] || { echo "ERROR: $LOCAL_STATE not found." >&2; exit 1; }

wait_chromium_gone() {
    for _ in $(seq 1 150); do pgrep -x chromium >/dev/null || return 0; sleep 0.2; done
    echo "ERROR: Chromium did not exit; aborting before touching JSON." >&2
    exit 1
}

set_profile_name() { # $1 profile-dir  $2 display-name
    cp -a "$LOCAL_STATE" "$LOCAL_STATE.bak-$STAMP" 2>/dev/null || true
    cp -a "$CHROME_DIR/$1/Preferences" "$CHROME_DIR/$1/Preferences.bak-$STAMP" 2>/dev/null || true
    python3 - "$LOCAL_STATE" "$CHROME_DIR/$1/Preferences" "$1" "$2" <<'PY'
import json, sys
ls_path, pref_path, pdir, name = sys.argv[1:5]

with open(ls_path) as f: ls = json.load(f)
entry = ls["profile"]["info_cache"].setdefault(pdir, {})
entry["name"] = name
entry["is_using_default_name"] = False
with open(ls_path, "w") as f: json.dump(ls, f)

with open(pref_path) as f: pref = json.load(f)
pref.setdefault("profile", {})["name"] = name
with open(pref_path, "w") as f: json.dump(pref, f)
print(f"  {pdir} -> display name '{name}'")
PY
}

echo "== [1/3] Create missing profiles (Satsang, Entertainment) =="
for p in Satsang Entertainment; do
    if [[ -f "$CHROME_DIR/$p/Preferences" ]]; then
        echo "  exists: $p"
        continue
    fi
    chromium --no-first-run --profile-directory="$p" --no-startup-window >/dev/null 2>&1 &
    for _ in $(seq 1 100); do
        [[ -f "$CHROME_DIR/$p/Preferences" ]] && break
        sleep 0.2
    done
    [[ -f "$CHROME_DIR/$p/Preferences" ]] \
        || { echo "ERROR: profile '$p' was not created within 20s." >&2; exit 1; }
    echo "  created: $p"
done

echo "== [2/3] Baseline GM3 theme color (Ethereal bg) on all profiles =="
for p in Default Satsang Entertainment; do
    chromium --profile-directory="$p" --no-startup-window --set-theme-color="6,11,30" >/dev/null 2>&1
    sleep 1
done
sleep 2
pkill -TERM -x chromium 2>/dev/null || true # graceful: flushes Preferences
wait_chromium_gone

echo "== [3/3] Display names (Local State + per-profile Preferences) =="
set_profile_name Default       Education
set_profile_name Satsang       Satsang
set_profile_name Entertainment Entertainment

echo
echo "Done. Manual step remaining, once per profile:"
echo "  chrome://extensions -> Developer mode -> Load unpacked ->"
echo "  $HOME/bigb-config/chromium/ethereal-theme"
