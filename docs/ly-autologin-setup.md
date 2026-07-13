# Ly Display Manager — One-Time Boot Autologin + Ethereal Theme

Machine: `jarvis` (Arch Linux, Hyprland, LUKS FDE) · User: `bmpatel15`
Migrated: 2026-07-07 · Backup: `~/.local/state/ly-migration-backup/20260707-180139/`

> **Reproducible now:** these `/etc`-side settings are root-owned and live outside
> the git-tracked dotfiles, so a machine reprovision resets them to package
> defaults (`install.sh`'s symlinks don't touch `/etc`). Reapply with
> `./install.sh ly` (→ `setup/ly-setup.sh`, idempotent). This document remains the
> rationale/reference; the script is the source of truth for the exact values.

## Architecture

```text
LUKS unlock  (interactive passphrase — the real authentication gate)
    ↓
system boot  (graphical.target)
    ↓
ly@tty1.service starts ly-dm on tty1 (Conflicts= displaces getty@tty1)
    ↓
ly-dm reads auto_login_user + auto_login_session → one-shot autologin
    ↓
Hyprland (start-hyprland → ~/.config/hypr/hyprland.lua)
    ↓
session exits (logout / compositor exit)
    ↓
ly-dm's in-process autologin flag is already consumed (is_autologin = false)
    ↓
Ly greeter — interactive login path
    ↓
PAM password authentication (/etc/pam.d/ly → auth include login)
    ↓
Hyprland (same start-hyprland launcher, identical environment)
```

## 1. What was installed

- `ly 1.4.1-1` was **already installed** (repo `extra`) — nothing to install; it was
  configured and enabled.
- `terminus-font` was installed for a crisper greeter on the 1920x1200 panel.

## 2. Ly version

`Ly version 1.4.1` (`ly-dm --version`). Package `ly 1.4.1-1` from `extra`.

## 3. Files changed

| File | Change |
|---|---|
| `/etc/ly/config.ini` | autologin keys, Ethereal colors, hardening (see §10) |
| `/etc/ly/startup.sh` | Ethereal 16-slot VT palette (runs before Ly takes the TTY) |
| `/etc/vconsole.conf` | `FONT=ter-124n` (Terminus 12x24) |
| `~/bigb-config/home/.zprofile` | tty1 `exec start-hyprland` autostart block removed (Ly owns login now); live `~/.zprofile` is a symlink to it |
| `~/.local/bin/ly-status` | new read-only diagnostic script |
| this file | new |

Not touched: PAM (`/etc/pam.d/ly` and `/etc/pam.d/ly-autologin` are the stock
packaged files), LUKS, sudoers, hypridle/hyprlock, wlogout,
`/usr/share/wayland-sessions/hyprland.desktop`.

## 4. Services enabled

- `ly@tty1.service` (templated Arch unit; runs `ly-dm` on tty1).
  Note: Arch's `ly@.service` ships no `Alias=display-manager.service`, so
  `systemctl status display-manager` says "not found" — that is normal here.

## 5. Services disabled

- None. There was no previous display manager (boot used `getty@tty1` + manual
  console login + `.zprofile` autostart). `getty@tty1.service` stays *enabled*;
  at boot `ly@tty1.service`'s `Conflicts=getty@%i.service` displaces it — the
  standard Arch pattern. tty2–tty6 keep normal gettys (recovery path).

## 6. How one-time boot autologin works

Ly 1.4.1 has **native one-shot autologin**. In `/etc/ly/config.ini`:

```ini
auto_login_user = bmpatel15
auto_login_session = hyprland      # /usr/share/wayland-sessions/hyprland.desktop
auto_login_service = ly-autologin  # packaged PAM stack, used ONLY for this one login
allow_empty_password = true        # REQUIRED for autologin — see below
```

**`allow_empty_password = true` is mandatory** (fixed 2026-07-07). Ly 1.4.1
(and upstream master as of 2026-07-07) checks the empty-password guard
*before* the autologin exemption in `authenticate()` (`src/main.zig`): at
boot the password field is empty, so with `allow_empty_password = false` the
autologin attempt silently aborts with "please enter password" — the log
shows `attempting autologin` → `starting authentication` and then nothing.
Setting it to `true` is safe: an empty password submitted at the interactive
greeter still goes to PAM, and `pam_unix` (`nullok`) rejects empty input for
any account that has a password set. The option only disables Ly's cosmetic
pre-check, not authentication.

Related quirk of the same bug: after the failed autologin attempt,
`is_autologin` stays armed, so the *next* interactive login from that greeter
still uses the `ly-autologin` PAM service (`pam_permit`) — whatever password
is typed is accepted. One-shot semantics resume after that session exits.

**Which session actually launches**: `auto_login_session = hyprland` matches
`hyprland-uwsm.desktop`, not plain `hyprland.desktop`. Ly's matcher compares
the name case-insensitively against each entry's filename, `Name`, and
`DesktopNames`, in directory-iteration order — and `hyprland-uwsm.desktop`
(shipped by the `hyprland` package) has `DesktopNames=Hyprland` and is
iterated first. Net effect: autologin runs
`uwsm start -e -D Hyprland hyprland.desktop`, i.e. the same
`/usr/bin/start-hyprland` launcher but uwsm/systemd-managed. Every alias of
the plain entry (`hyprland`, `Hyprland`) collides the same way, so this
cannot be disambiguated in Ly config alone. It works (verified 2026-07-07);
if the bare non-uwsm session is ever wanted for autologin, either remove the
uwsm entry via pacman `NoExtract` or accept uwsm management.

At `ly-dm` startup, an in-process flag (`is_autologin` in upstream
`src/main.zig`) is set once, the first login happens through the
`ly-autologin` PAM service (`auth required pam_permit.so` — account and
session stacks still `include login`), and the flag is cleared. No password is
stored anywhere; the LUKS passphrase is the boot-time authentication gate.

## 7. Why logout does NOT autologin again

Three independent reasons, all verified:

1. `ly-dm` is one long-running process across login/logout cycles; the
   autologin flag is consumed by the first authentication and explicitly reset
   (`state.is_autologin = false`) when the session exits. The packaged config
   documents it: *"Autologin only happens once at startup - it won't
   re-trigger after logout."*
2. All subsequent logins go through the normal PAM service
   (`service_name = ly` → `/etc/pam.d/ly` → `auth include login`) — password
   required. (`allow_empty_password = true` does not weaken this: `pam_unix`
   rejects empty passwords for accounts that have one; see §6.)
3. `ly@.service` has **no `Restart=`** directive, so a session/greeter exit
   cannot respawn a fresh `ly-dm` (which would re-arm autologin).

Known caveat (by design): `sudo systemctl restart ly@tty1` starts a new
`ly-dm` process and therefore re-fires autologin once. Root-only action,
consistent with the LUKS security model. Same applies to a full reboot —
which is exactly the desired cold-boot behavior.

## 8. Where Ly configuration lives

- `/etc/ly/config.ini` — main config (pristine reference: `config.ini.example`)
- `/etc/ly/startup.sh` — pre-greeter hook (holds the Ethereal VT palette)
- `/etc/ly/save.ini` — auto-written; remembers last user/session for the greeter
- `/etc/pam.d/ly`, `/etc/pam.d/ly-autologin` — stock packaged PAM stacks
- `/usr/lib/systemd/system/ly@.service` — the unit template
- `/var/log/ly.log` — ly's own log; Wayland session output goes to
  `~/.local/state/ly-session.log`

## 9. How the Ethereal colors were discovered

The active theme is static (no Omarchy theme switcher on this machine). The
palette source of truth is the Ghostty theme file
`~/bigb-config/config/ghostty/themes/ethereal`, cross-checked against waybar,
swaync, hyprlock, wlogout, rofi and btop configs in `~/bigb-config` (all
hard-code the same hex values).

## 10. Exact color mapping in Ly

The Linux VT is a 16-color surface, so exactness is achieved by **redefining
the VT palette** in `/etc/ly/startup.sh` (OSC `\033]P<idx><RRGGBB>`) and
running Ly in deterministic palette-index mode (`full_color = false`; ly
addresses 8 base colors + BRIGHT/BOLD styling = all 16 slots).

| Ly element | config key = value | Slot addressed | Ethereal semantic | Hex |
|---|---|---|---|---|
| Screen + box background | `bg = 0x00000000` (terminal default) | 0 (redefined) | background navy | `#060B1E` |
| Main text / fields | `fg = 0x40000008` (BRIGHT+WHITE) | 15 | peach foreground | `#ffcead` |
| Box border | `border_fg = 0x00000005` (BLUE) | 4 | lavender accent | `#7d82d9` |
| Error text | `error_fg = 0x01000002` (BOLD+RED → bright) | 9 | soft red | `#faaaa9` |
| Info line | `initial_info_text = ethereal` | — | wordmark | — |
| Clock (top-right) | `clock = %H:%M` | — | — | — |

Full 16-slot palette written by `startup.sh` (slots 1–15 match the Ghostty
Ethereal ANSI table; slot 0 deviates from Ghostty's `#3C486D` on purpose to
carry the true background navy):

```text
0 #060B1E   4 #7D82D9   8  #6D7DB6  12 #C2C4F0
1 #ED5B5A   5 #C89DC1   9  #FAAAA9  13 #EAD7E7
2 #92A593   6 #A3BFD1   10 #C4CFC4  14 #DFEAF0
3 #E9BB4F   7 #F99957   11 #F7DC9C  15 #FFCEAD
```

Honest TTY limits: this yields exact Ethereal colors at 16-color granularity.
True 24-bit rendering on the greeter would require the kmscon path
(`ly-kmsconvt@tty1.service`) — deliberately not used (extra dependency, worse
fonts, marginal gain).

## 11. How to edit the theme

- Colors of UI elements: edit the `0xSSRRGGBB`-style keys in
  `/etc/ly/config.ini` (format documented in the file header; in
  `full_color = false` mode use the 8-color codes + styling bytes).
- Actual RGB values: edit the hex table in `/etc/ly/startup.sh`.
- Layout/extras: `box_title`, `blank_box`, `hide_borders`, `bigclock`,
  `margin_box_*` in `config.ini`.
- Apply: changes take effect the next time ly-dm starts (reboot, or
  `sudo systemctl restart ly@tty1` — remember that re-fires autologin once).

## 12. How to validate Ly configuration

Ly 1.4.1 has **no** `--validate-config` flag (`ly-dm --help`: only
`-h -v -c/--config --use-kmscon-vt`). Safe validation procedure:

```bash
sudo systemctl start ly@tty3.service   # transient test greeter on tty3
# Ctrl+Alt+F3: check rendering; test a WRONG password; do NOT log in
sudo systemctl stop ly@tty3.service    # Ctrl+Alt+F1 back to Hyprland first
ly-status                              # config-key sanity check vs example
```

Caution: if autologin keys are armed, starting any ly@ instance fires an
autologin session there — disarm first (§13) when testing on a spare tty.

## 13. Temporarily disable boot autologin

```bash
sudo sed -i 's/^auto_login_user = bmpatel15/auto_login_user = null/' /etc/ly/config.ini
```

(Ly requires BOTH keys set; nulling one disables autologin. Takes effect next
boot — every login then requires the password.)

## 14. Re-enable boot autologin

```bash
sudo sed -i 's/^auto_login_user = null/auto_login_user = bmpatel15/' /etc/ly/config.ini
```

(`auto_login_session = hyprland` is left in place by §13, so this is the only
line to flip back.)

## 15. Disable Ly entirely

```bash
sudo systemctl disable ly@tty1.service   # next boot: getty@tty1 again
```

Then either log in manually on the console, or also restore the `.zprofile`
autostart block (§16) for the old auto-start behavior.

## 16. Restore the previous setup completely

```bash
sudo ~/.local/state/ly-migration-backup/20260707-180139/restore.sh
```

Restores config.ini, startup.sh, vconsole.conf (+ initramfs rebuild if
needed), the `.zprofile` autostart block, disables `ly@tty1.service`, and
daemon-reloads. Reboot afterwards. (`.zprofile` is also recoverable from
`~/bigb-config` git history.)

## 17. Backup location

`~/.local/state/ly-migration-backup/20260707-180139/`
(`config.ini`, `startup.sh`, `vconsole.conf`, `zprofile`, `manifest.txt`
with original owners/modes, `state.txt` pre-migration service snapshot,
`restore.sh`).

## 18. Troubleshooting

- **Black screen / no greeter on tty1 at boot** → switch to tty2
  (Ctrl+Alt+F2), log in, check `systemctl status ly@tty1` and
  `/var/log/ly.log`. Worst case run `restore.sh` (§16) and reboot.
- **Autologin didn't fire** → first check `allow_empty_password = true` is
  set (§6 — with `false`, Ly 1.4.1 silently aborts autologin; the log shows
  `attempting autologin` → `starting authentication` → nothing). Then
  `ly-status`; check both `auto_login_*` keys are set and
  `journalctl -b -u ly@tty1`. A typo in `auto_login_session` (must match
  `hyprland.desktop` filename/Name) also silently disables it.
- **Logged out but greeter looks wrong / colors off** → palette applies via
  `/etc/ly/startup.sh` only when `TERM=linux`; check the file is executable
  and `start_cmd = /etc/ly/startup.sh` is set.
- **Session starts but desktop is broken** → compare with a tty2 manual run of
  `start-hyprland`; session stdout/err is in `~/.local/state/ly-session.log`.
- **Ly crashed / dead tty1** → `sudo systemctl restart ly@tty1` from tty2
  (note: re-fires autologin once), or reboot.
- **Wrong console font size** → edit `FONT=` in `/etc/vconsole.conf`
  (installed Terminus sizes: `ter-1XX{n,b}`), then `sudo mkinitcpio -P`.
- **Lock/suspend** → unchanged by this migration: hypridle dims at 2.5m,
  locks at 5m, suspends at 30m; `before_sleep_cmd = loginctl lock-session`
  locks on lid close/suspend; ALT+L manual lock; hyprlock `grace = 0`.
