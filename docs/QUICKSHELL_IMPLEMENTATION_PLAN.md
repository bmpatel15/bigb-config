# Quickshell Implementation Plan — bigb-config

> **STAGE STATUS** (update this block as stages complete — future Claude sessions: read this file instead of re-auditing the system)
>
> | Stage | Scope | Status |
> |---|---|---|
> | A | Foundation + bar (replaces Waybar only) | **Implemented & live** (2026-07-18; bar running, Waybar stopped, tray watcher acquired). Remaining sign-off: autostart at next login, ~1 week burn-in (esp. tray menus), then merge `quickshell`→`main`. |
> | B | OSDs + control center (SUPER+D) | **Implemented & live** (2026-07-18). Volume/mic/brightness OSDs at bottom-center overlay; XF86 keys route via `qs ipc call` with `\|\| wpctl/brightnessctl` fallback; CC on SUPER+D (chips, sliders, media, Wi-Fi/BT lists, session row). Remaining sign-off: user-driven Wi-Fi password connect + BT connect/disconnect from the panel, a few days of key/OSD burn-in. |
> | C | Notifications (replaces SwayNC, rebind SUPER+N) | **Implemented & live** (2026-07-18). qs owns org.freedesktop.Notifications; popups (8/4/never timeouts, urgency borders, actions, click-to-dismiss), history center on SUPER+N (DND, clear-all), bar bell w/ count; swaync removed from autostart but its D-Bus activation file = crash failsafe; SUPER+N falls back to swaync-client. Sign-off: real-app notifications (browser, telegram web) + a few days burn-in. |
> | D | Launcher (SUPER+SPACE) + wallpaper picker (SUPER+SHIFT+W) | **Implemented & live** (2026-07-18). Launcher: DesktopEntries + fuzzy scorer, icons, keyboard nav (arrows/Ctrl+J/K), terminal-app wrapping. Wallpaper picker over the existing thumb cache; applying goes through wallpaper-picker.sh `--set` (new subcommand; `--warm` builds thumbs) so awww/state/hyprlock-bg logic stays in the script and `--restore` is untouched. Both binds fall back to rofi. rofi stays installed indefinitely (cliphist SUPER+period, browser-mode SUPER+B). **Refactored** into a single morphing bottom-shelf: `overlay/BottomOverlayHost.qml` hosts `LauncherContent`/`WallpaperContent`, one surface grows upward from a collapsed shelf and morphs between the two modes; per-monitor via focused-monitor retarget; input mask so it never blocks the desktop; `overlay` token group + `reducedMotion` in Appearance. |
> | E | Optional extras (ranked in §29) | Not started |
>
> Shell source: `~/bigb-config/config/quickshell/` → symlinked to `~/.config/quickshell` (install.sh `LINK_CONFIG`). Work happens on git branch `quickshell`; merge to `main` per-stage after acceptance. Waybar/SwayNC/Rofi stay installed as fallbacks until Stage D is stable.

---

## 1. Executive summary

Replace the Waybar/SwayNC/Rofi shell stack with a single cohesive Quickshell (QML) desktop shell, in five incremental stages that each leave the desktop fully working and reversible in under a minute. Quickshell **0.3.0 (Arch `extra`)** natively provides every hard integration this shell needs — Hyprland state, system tray + DBus menus, PipeWire, MPRIS, notifications, UPower, **Bluetooth (BlueZ)** and **NetworkManager** — so the shell is event-driven with almost no external polling. Proven script backends (awww wallpaper, lock.sh, power-menu.sh, updates.sh, screenshot.sh) are reused, not rewritten. Theme = existing **Ethereal** palette expressed once as design tokens.

## 2. Current desktop inventory

| Capability | Current provider | Relevant files | Plan |
|---|---|---|---|
| Status bar | Waybar 0.15.0 | `config/waybar/{config.jsonc,style.css}` | **Replace in Stage A** |
| Notifications | SwayNC 0.12.6 | `config/swaync/{config.json,style.css}` | Keep until Stage C |
| App launcher | Rofi 2.0.0 (drun) | `config/rofi/{config,launcher}.rasi` | Keep until Stage D |
| Wallpaper picker | Rofi + script + awww | `config/rofi/wallpaper-picker.{sh,rasi}` | UI replaced Stage D; **awww backend + cache kept forever** |
| Power menu | wlogout (SUPER+M) + rofi script (bar click) | `config/wlogout/*`, `config/waybar/scripts/power-menu.sh` | Bar button reuses power-menu.sh in Stage A; wlogout untouched |
| Volume/brightness/media keys | wpctl / brightnessctl / playerctl (no OSD exists) | `config/hypr/hyprland.lua` | OSDs added Stage B (keys rebound to `qs ipc call`) |
| Clipboard history | cliphist + rofi (SUPER+period) | hyprland.lua | Keep; optional QS panel in Stage E |
| Browser mode picker | rofi script (SUPER+B) | `config/rofi/browser-mode.sh` | Keep as-is |
| Lock / idle | hyprlock + hypridle + lock.sh | `config/hypr/{hyprlock,hypridle}.conf`, `scripts/lock.sh` | Keep (custom lock explicitly discouraged, §29) |
| Login | ly 1.4.1 (autologin, uwsm session) | `/etc/ly/config.ini` | Never touched |
| Screenshots | grim/slurp/swappy script | `config/hypr/scripts/screenshot.sh` | Keep |

Everything under `config/` above lives in `~/bigb-config` and is symlinked into `~/.config` (whole-directory symlinks, `install.sh links`).

## 3. Existing configuration paths

- Hyprland: `~/bigb-config/config/hypr/hyprland.lua` — **native Hyprland Lua config** (single file, `hl.*` API; no generator). Reload: `hyprctl reload`; `hl.on("hyprland.start")` execs only run at login.
- Waybar: `~/bigb-config/config/waybar/` (bar h34, margins 6/12, three islands r17, modules r13, bg `rgba(6,11,30,0.85)`, border `1px rgba(255,255,255,0.06)`).
- SwayNC: `~/bigb-config/config/swaync/` (right-top, w420, timeouts 8/4/0-critical, radius 12).
- Rofi: `~/bigb-config/config/rofi/` (launcher/wallpaper-picker/browser-mode .rasi + .sh).
- Ghostty theme (canonical palette): `~/bigb-config/config/ghostty/themes/ethereal`.
- uwsm env: `~/bigb-config/config/uwsm/env` (`QT_QPA_PLATFORMTHEME=kde`, `KDE_SESSION_VERSION=6`).
- install.sh: `LINK_CONFIG` array at line 30 controls which config dirs get symlinked.

## 4. Relevant installed packages

Qt 6.11.1 full stack (base/declarative/wayland/svg) · qmlls (`/usr/lib/qt6/bin/qmlls`, PATH alias `qmlls6`) + `qmlformat6` · pipewire 1.6.8 + wireplumber 0.5.15 (`wpctl`) · playerctl 2.4.1 · networkmanager 1.56.1 · bluez 5.87 (+bluez-utils, blueman; service enabled) · brightnessctl 0.5.1 (`intel_backlight`) · upower 1.91.3 + power-profiles-daemon 0.30 (both active) · cliphist + wl-clipboard · grim/slurp · hyprpolkitagent · hyprlock 0.9.5 / hypridle 0.1.7 · uwsm 0.26.6 · imagemagick/ffmpeg · waybar 0.15.0 · swaync 0.12.6 · rofi 2.0.0 · awww (wallpaper daemon). **Missing: quickshell** (`sudo pacman -S --needed quickshell` → 0.3.0-2 from extra). No matugen/pywal/wallust (static theme). No screen recorder (Stage E concern only).

Hardware: Intel Core Ultra 9 288V laptop, Arc 140V iGPU, 32 GB. Single eDP-1 1920×1200 @ **1.25 scale** (1536×960 logical). Battery BAT0.

## 5. Existing scripts to reuse (never rewrite)

| Script | Purpose | Used by shell |
|---|---|---|
| `config/rofi/wallpaper-picker.sh` | awww daemon mgmt, thumb cache (`~/.cache/wallpaper-picker/thumbs/<name>.png`), state file `~/.cache/wallpaper-picker/current`, `--restore` at login | Stage D picker calls `awww img …` + writes `current` (compat with untouched `--restore`) |
| `config/waybar/scripts/power-menu.sh` | rofi dmenu Lock/Suspend/Logout/Reboot/Shutdown | Stage A bar power button |
| `config/waybar/scripts/updates.sh` | checkupdates + yay -Qua count (JSON) | Stage A Updates service (hourly) |
| `config/hypr/scripts/lock.sh` | stage blurred bg + hyprlock | via power-menu.sh |
| `config/hypr/scripts/nightlight.sh` | hyprsunset toggle | Stage B control-center toggle |
| `config/hypr/scripts/screenshot.sh` | grim/slurp/swappy | Stage E strip (maybe) |
| cliphist pipeline (wl-paste watchers) | clipboard history | Stage E panel (maybe) |

## 6. Current keybinding map (relevant subset) + conflict report

Free: `SUPER+W`, `SUPER+D`, `SUPER+ESCAPE`, `SUPER+G`, `SUPER+TAB`.

| Key | Today | Shell plan |
|---|---|---|
| SUPER+SPACE | rofi drun | Stage D → `qs ipc call launcher toggle` |
| SUPER+N | swaync toggle | Stage C → `qs ipc call notifs toggle` |
| SUPER+A | Claude webapp | **kept** (user decision) |
| SUPER+D | — | Stage B control center (user decision) |
| SUPER+SHIFT+W | rofi wallpaper picker | Stage D → `qs ipc call wallpicker toggle` |
| SUPER+M | wlogout | kept |
| XF86 volume/mic/brightness | wpctl / brightnessctl direct | Stage B → `qs ipc call audio/brightness …` (change+OSD atomic) |
| XF86 media | playerctl | kept (Mpris shown in bar regardless) |

Conflicts found: request-doc suggestion SUPER+A collided with Claude webapp → resolved to SUPER+D (user choice). No other conflicts; no binding is changed silently — each stage's rebind is an explicit reviewed hyprland.lua edit.

## 7. Current theme analysis

Canonical palette (`config/ghostty/themes/ethereal`, duplicated by hand in waybar/swaync/rofi/hyprlock/wlogout/btop/tmux/chromium — no generator):
bg `#060B1E` · surface `#0d1430` · surface-blue `#3C486D` · text `#dfeaf0` · peach/fg `#ffcead` · orange `#F99957` · lavender/accent `#7d82d9` · lavender-light `#c2c4f0` · mauve `#c89dc1` · muted `#6d7db6` · red `#ED5B5A` · red-alt `#ff6b81` · green `#92a593` · yellow `#E9BB4F` · cyan `#a3bfd1`. Font: JetBrainsMono Nerd Font (13px bar). Chrome: island radius 17, module 13, popup 12; bar h34, margins 6/12; Hyprland rounding 10, blur 3/1, easeOutExpo + spring "easy" animations. The shell centralizes these as tokens (§16) — first component of the stack where the palette isn't copy-pasted.

## 8. Recommended Quickshell version

**`extra/quickshell 0.3.0-2` (stable Arch package).** Not `quickshell-git`: 0.3.0 already ships every needed integration natively, including Bluetooth and NetworkManager (verified against version-pinned docs). Sole authoritative API reference: **https://quickshell.org/docs/v0.3.0/** — community dotfiles (caelestia, end-4, dms) track git and their property names may not match; never copy from them without checking the 0.3.0 docs.

## 9. Proposed shell architecture

```
config/quickshell/                    [stage]
├── shell.qml                         [A] ShellRoot; Variants over screens → Bar; IpcHandlers
├── .qmlls.ini                        [A] qmlls import paths
├── config/  Appearance.qml           [A] design tokens (`qs.*` imports need no qmldir files in 0.3.0)
│            Paths.qml                [A] ALL external commands/paths (env-derived, no /home literals)
├── services/
│   ├── Audio.qml                     [A] native Pipewire (default sink/source, volume/mute API)
│   ├── Battery.qml                   [A] native UPower displayDevice
│   ├── Network.qml                   [A] native Quickshell.Networking
│   ├── Bluetooth.qml                 [A] native Quickshell.Bluetooth (namespaced import)
│   ├── Brightness.qml                [A] brightnessctl Process, read-after-write + sysfs inotify + 15 s sysfs re-read (no process spawn; covers XF86 keys until Stage B)
│   ├── SysStats.qml                  [A] /proc/stat + /proc/meminfo, 3 s timer (only poller)
│   ├── Updates.qml                   [A] updates.sh Process, hourly
│   └── NotifServer.qml               [C] NotificationServer + persistence
│   (no PowerProfiles service: 0.3.0 exposes PowerProfiles natively in Quickshell.Services.UPower)
├── components/ Island, StyledText, StatusItem            [A]
├── bar/ Bar, LeftIsland, Workspaces, CenterIsland, RightIsland   [A]
├── osd/ Osd.qml                      [B] shared volume/mic/brightness overlay
├── controlcenter/ ControlCenter, WifiList, BluetoothList [B]
├── notifications/ Popups, Center     [C]
├── launcher/ Launcher.qml            [D] DesktopEntries + fuzzy scorer
└── wallpapers/ WallPicker.qml        [D] thumb grid, awww backend
```

Deliberate non-abstractions: Hyprland, SystemTray, and Mpris are used directly in widgets (their QML APIs are already clean); services exist only where there's real logic (default-node tracking, Process orchestration, aggregation). Bar layout (user decision): **left** = workspaces + submap + active window title, **center** = clock (media ticker fades in beside it without moving it), **right** = status cluster.

## 10. Component responsibility map

| Component | Owns | Consumes |
|---|---|---|
| shell.qml | window lifecycles, IPC surface | Variants/screens |
| Appearance | every color/size/font/duration token | — |
| Paths | every external command string + cache path | Quickshell.env |
| Island | pill chrome (bg/radius/border) | Appearance |
| StatusItem | icon+label cell, hover/click/scroll | Appearance |
| Bar | PanelWindow geometry, three-island layout | Island, per-screen data |
| Workspaces | workspace pills, click/scroll dispatch | Quickshell.Hyprland |
| CenterIsland | clock, date, media ticker | SystemClock, Mpris |
| RightIsland | status cells, tray, power button | all Stage A services, SystemTray |
| services/* | state + mutations for their domain | native modules / Paths commands |

## 11. Native API vs external command decisions

| Feature | Mechanism | Why |
|---|---|---|
| Workspaces/window/submap | native Quickshell.Hyprland (event socket) | zero polling; no hyprctl parsing |
| Tray (+menus) | native SystemTray + DBusMenu | only correct way to get DBus menus |
| Audio | native Pipewire | event-driven; enables Stage B set-volume without wpctl |
| Media | native Mpris | replaces playerctl polling for display |
| Battery | native UPower | event-driven |
| Network / Bluetooth | native (NM / BlueZ DBus) | new in 0.3.0; replaces nmcli/bluetoothctl parsing |
| Notifications (C) | native NotificationServer | it IS the daemon |
| App list (D) | native DesktopEntries | icon+action handling free |
| Brightness | `brightnessctl` Process + sysfs FileView | no native module; read-after-write for own changes, 15 s sysfs file re-read for external ones (sysfs inotify proved unreliable in testing) |
| CPU/RAM | /proc reads, 3 s timer | no event source exists (Waybar polls too) |
| Updates | existing `updates.sh`, hourly | reuse; checkupdates is inherently a command |
| Power profile | native PowerProfiles (Quickshell.Services.UPower) | writable `PowerProfiles.profile` — no powerprofilesctl needed |
| Wallpaper (D) | existing awww command + cache | reliable backend; QS is only the UI |
| Power menu / lock / nightlight / screenshots | existing scripts via Paths | working; no reason to rewrite |

All commands defined once in `Paths.qml`, argv-array form (no shell interpolation of dynamic values), availability-checked, failures logged not fatal.

## 12. Waybar migration strategy (Stage A)

Build bar to parity (minus `temperature` — informational noise + hwmon fragility; CPU% retained) with visual continuity (same geometry/palette). Test from a terminal (`qs -p ~/bigb-config/config/quickshell`) before touching autostart. Swap = one hyprland.lua line (§21 has the exact rollback). Waybar stays installed through Stage B minimum. `custom/updates` interval, on-click terminal apps (htop/btop/pavucontrol/gazelle/bluetui) preserved as click actions on the corresponding cells.

## 13. SwayNC migration strategy (Stage C)

QS `NotificationServer` takes the `org.freedesktop.Notifications` bus name at session start; remove `hl.exec_cmd("swaync")` (hyprland.lua line 59) in the same commit; rebind SUPER+N. **Conflict avoidance:** two daemons must never race — swaync ships a D-Bus activation file, so if qs crashes, the next notification auto-spawns swaync — an intentional failsafe, documented not fought. Verify owner: `gdbus call --session -d org.freedesktop.DBus -o /org/freedesktop/DBus -m org.freedesktop.DBus.GetNameOwner org.freedesktop.Notifications`. Match current behavior first (right-top popups, w420, timeouts 8/4/0-critical, DND, history, actions, urgency colors); keep swaync installed until Stage D is stable.

## 14. Rofi launcher migration strategy (Stage D)

`DesktopEntries.applications` + ~30-line fuzzy scorer (case-insensitive subsequence; bonuses for prefix/word-boundary/consecutive; sort score-then-name). Keyboard-first: arrows + vim keys, Enter launch, Esc close; icons via Quickshell icon lookup; centered overlay ≤560px wide. Rofi remains installed indefinitely (cliphist picker SUPER+period, browser-mode SUPER+B still use it).

## 15. Wallpaper-picker integration strategy (Stage D)

QS grid UI over the **existing** system: reads `~/Pictures/wallpaper` (`$WALLPAPER_DIR`), thumbs from `~/.cache/wallpaper-picker/thumbs/<basename>.png` (generate missing with the same magick command), applies via `awww img <file> --transition-type grow --transition-pos 0.9,0.9 --transition-fps 60 --transition-duration 1`, writes `~/.cache/wallpaper-picker/current`, regenerates `~/.cache/hyprlock-bg.png` — so login `--restore` and hyprlock keep working with zero script changes. Active wallpaper highlighted; no re-thumbnailing when cache is warm.

## 16. Theme and design-token strategy

Single static `Appearance.qml` singleton (`pragma Singleton`), grouped tokens: `colors` (Ethereal values, §7), `font` (family + 11/13/15/18), `spacing` (4/8/12/16/20), `radius` (17/13/12/8), `anim` (150/250/400 ms, OutExpo), `bar` (34/6/12). Components only reference `Appearance.*`. No generator/adapter now (nothing generates colors in this stack); if wallpaper-derived theming ever lands, Appearance switches to reading a JSON via FileView (or native ColorQuantizer) without touching components.

## 17. Multi-monitor strategy

`Variants { model: Quickshell.screens }` → one bar per screen; workspaces filtered per-monitor via Hyprland monitor mapping; popups/OSDs anchor to the focused screen. No hardcoded output names anywhere. Today: single eDP-1 @ 1.25 — correctness at fractional scale is the day-one check (crisp 1px borders, even logical sizes). Future monitors: hotplug add/remove is handled by Variants reacting to `Quickshell.screens`; panels cap their max width (launcher ≤560px, control center ≤420px) so an ultrawide never stretches content. Test strategy: primary = live laptop; secondary = temporarily set `monitor=eDP-1,1920x1200@60,0x0,1.0` and a headless output (`hyprctl output create headless`) to simulate 2-screen + scale-difference behavior, then remove.

## 18. Performance strategy

Event-driven everything except: SysStats 3 s tick (paused when bar hidden), Updates hourly, brightness read-after-write. Panels behind `LazyLoader` (nothing heavy at startup). No blur regions (transparency only — matches current waybar look). No animations while hidden; all animations ≤400 ms and interruptible. Thumbnail/icon caching reused from existing cache dirs. Acceptance: idle CPU ~0%, bar visible <1 s, no log flood.

## 19. Error-handling strategy

Services degrade to hidden/dimmed cells, never crash the shell: no battery → battery cell invisible; NM/BlueZ daemon missing → cell shows disabled state; Process exit≠0 → last-known state + one warning log (no retry storms; updates retries next hour). All Process commands argv-arrays from Paths (no interpolation). External commands availability-checked once at startup (log warning if absent).

## 20. Logging and debugging strategy

Run under `uwsm app -- qs` → own systemd scope → `journalctl --user` filtered by unit. Live: `qs log` attaches to running instance; `qs -p <path> --verbose` for repro runs in a terminal. QML errors appear in the same stream with file:line. Scratch harness: keep a `scratch.qml` habit — validate any uncertain native API with a 5-line ShellRoot before building the widget on it.

## 21. Rollback strategy

1. **Git**: all work on branch `quickshell`; hyprland.lua/install.sh edits land in the same commits as the code → `git checkout main` + relogin = complete restore. Backup of any pre-existing target: install.sh auto-backups to `~/.bigb-config-backup-<ts>/`.
2. **Immediate (<1 min, no relogin)**: `qs kill` then `uwsm app -- waybar`. Waybar remains installed until ≥Stage B; SwayNC until ≥Stage D; Rofi indefinitely.
3. **Config flag**: `USE_QUICKSHELL = false` in hyprland.lua (start-execs only run at login → effective next login; use step 2 for now).
4. **SwayNC restore (Stage C)**: re-add `hl.exec_cmd("swaync")`, rebind SUPER+N, `qs kill` or disable notif module; D-Bus activation auto-spawns swaync on demand meanwhile.
5. **Rofi restore (Stage D)**: rebind SUPER+SPACE / SUPER+SHIFT+W back to rofi commands (one-line each).
6. **No packages removed, no old configs deleted — ever** (until user explicitly retires them post-migration).

## 22. Phased implementation roadmap

### Stage A — Foundation + bar (CURRENT)
- **Objective:** prove the foundation; replace Waybar only.
- **Features:** tokens, Paths, 8 services, 3 components, per-screen 3-island bar (workspaces/title left, clock+media center, full status cluster + tray + power right).
- **Files:** everything marked [A] in §9; edits: `hyprland.lua:57` (waybar→qs toggle), `install.sh:30` (+quickshell).
- **Dependencies:** `pacman -S quickshell`.
- **Risks:** 0.3.0 API drift; fractional-scale crispness; tray menu quirks (§28).
- **Rollback:** §21.2.
- **Tests:** §26 Stage-A block. **DoD:** §27 bullets all green + rollback drill executed once.

### Stage B — OSDs + control center
- **Objective:** hardware-key feedback + one-stop quick settings.
- **Features:** volume/mic/brightness OSD (bottom-center overlay, 1.5 s); control center on SUPER+D (LazyLoader, focus-grab dismiss): audio+brightness sliders, wifi/bt/nightlight/power-profile toggles, expandable wifi+bt device lists, media card, session row (reuses power-menu actions); XF86 keys rebound to `qs ipc call` (makes change+OSD atomic and kills brightness state-drift).
- **Files:** osd/, controlcenter/, +Audio/Brightness mutation paths; hyprland.lua XF86 + SUPER+D binds.
- **Risks:** PipeWire volume-set semantics (test vs wpctl early); NM connect/password flow.
- **Rollback:** rebind XF86 back to wpctl/brightnessctl (git revert of the bind commit).
- **DoD:** OSD <100 ms after keypress; CC opens <150 ms; wifi connect w/ password works; DND n/a until C.

### Stage C — Notifications (§13)
- **DoD:** daemon holds bus name from login; popups match current behavior incl. actions/urgency/DND/history/clear-all; swaync failsafe verified; SUPER+N on QS panel.

### Stage D — Launcher + wallpaper picker (§14, §15)
- **DoD:** launcher opens <150 ms warm, fuzzy results correct, icons render; wallpaper picker reuses cache (0 regen on warm cache), `--restore` still works after picking; rofi paths still functional.

### Stage E — Optional extras (ranked, §29). One at a time, each with its own mini-DoD.

## 23. Dependencies per phase

A: `quickshell` package only. B: none new (powerprofilesctl/brightnessctl present). C: none. D: none (magick present for thumbs). E: `wf-recorder` or `gpu-screen-recorder` only if the recording strip is built.

## 24. Files created/modified (Stage A)

Created: `config/quickshell/**` (≈21 files, §9 [A] set), `config/nvim/lua/plugins/qml.lua`, this doc.
Modified: `config/hypr/hyprland.lua` (1 line → 3-line toggle block), `install.sh` (1 array entry).
Deleted: **nothing**.

## 25. Keybinding changes

Stage A: **none**. B: +SUPER+D; XF86 volume/mic/brightness → qs IPC. C: SUPER+N → qs IPC. D: SUPER+SPACE, SUPER+SHIFT+W → qs IPC. Each is an explicit hyprland.lua edit reviewed at stage start; §6 is the conflict report.

## 26. Testing checklist

Stage A: bar on eDP-1 correct at 1.25 scale · workspace switch/create/destroy/urgent/submap live · special:magic indicator · active-window title updates + elides · clock ticks; media ticker appears/disappears without moving clock · every right cell reacts to a live state change (mute, AC unplug, wifi toggle, bt toggle, brightness keys, play media, fake update count) · tray icons + left/right click + submenu · power button opens rofi menu · scroll actions (workspaces, volume, brightness) · `hyprctl reload` safe · hot-reload on save · `qs kill; uwsm app -- waybar` drill · idle CPU ~0% · no log flood · SUPER+SPACE/N/SHIFT+W workflows untouched.
Later stages: §22 per-stage DoD + regression of this list.

## 27. Acceptance criteria (Stage A)

Shell starts reliably with Hyprland (uwsm scope) · bar visible <1 s · workspace state correct at all times · no duplicate bar/tray daemons · idle CPU ~0% beyond 3 s stats tick · reload leaves no orphan windows · rollback <1 min · all pre-existing workflows (launcher, notifications, wallpaper, lock, clipboard) untouched.

## 28. Risks and mitigations

1. **0.3.0 vs git API drift** (community configs track git) → only v0.3.0 docs; scratch-QML validation per module before widget work.
2. **Fractional scale 1.25 crispness** → even logical sizes, IconImage, day-one visual check.
3. **Tray DBusMenu quirks** (Electron etc.) → test real tray immediately; Waybar fallback retained ≥1 week.
4. **Process-state drift** (brightness/profile) → read-after-write in A; B routes all mutation through qs IPC.
5. **hyprland.lua regression** (Lua error kills binds) → one minimal edit/stage, `hyprctl reload` + spot-check after each, all on branch.
6. **Notification daemon race** (C) → same-commit removal + D-Bus activation failsafe + owner check (§13).

## 29. Features explicitly deferred (Stage E ranking)

1. Calendar popup on clock (trivial, daily value) · 2. Workspace overview SUPER+TAB (verify ScreencopyView in 0.3.0 first) · 3. Clipboard panel (cliphist backend) · 4. System-monitor popup (SysStats history) · 5. Screenshot strip · 6. Weather, pomodoro, Obsidian shortcuts (nice-to-have; Quick Capture already has SUPER+SHIFT+O) · 7. **Custom lock screen — discouraged**: hyprlock works and lock bugs lock you out.
Anti-goals: full-screen dashboards, always-on system graphs in the bar, blur-heavy surfaces, gaming-HUD aesthetics.

## 30. Recommended first implementation milestone

> Minimal modular Quickshell foundation + production-quality top bar replacing Waybar, leaving SwayNC, Rofi, wallpaper system, Hyprlock, Hypridle, and ly untouched — Waybar restorable in <1 min.

= Stage A exactly. Proves: startup, tokens, per-screen windows, Hyprland state, tray, clock, status indicators, coexistence with old workflows, rollback.
