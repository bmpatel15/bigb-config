# Image viewer setup — swayimg

Status: **implemented, verified 2026-07-20** (Arch + Hyprland, `jarvis`).

Covers how images open on this machine: which viewer, how it is themed, how the MIME
associations are wired, and the two non-obvious gotchas that will bite on a rebuild.

## 1. The problem

There was no image viewer installed at all. Double-clicking an image in Dolphin, or
running `xdg-open photo.png`, opened it in a **Chromium tab** — not by choice, but because
Chromium was the only installed application broadly claiming `image/*`, so it won by
falling through to `/usr/share/applications/mimeinfo.cache`. `~/.config/mimeapps.list`
had zero `image/*` entries.

Related gaps found at the same time:

- `libheif` was absent — HEIC/HEIF (iPhone photos) could not be decoded at all.
- `kimageformats` / `qt6-imageformats` were absent — Dolphin's own thumbnail grid could
  not preview AVIF, HEIF, JXL, PSD, or XCF.

## 2. Why swayimg

Wayland-native (no XWayland), official Arch `extra` repo, ~1.2 MB, and configured in
**Lua** — the same language as `hyprland.lua`. It hard-depends on `libheif`, `libjxl`,
`libavif`, and `libraw`, so installing it closed the HEIC gap as a side effect.

Reported formats (`swayimg --version`): png, jpg, webp, jxl, avif, raw, heif, gif, sixel,
tiff, svg, jp2, exr, xbm, ttf, qoi, pnm, farbfeld, dicom, bmp, tga.

## 3. Packages

```bash
sudo pacman -S --needed swayimg kimageformats qt6-imageformats
```

`kimageformats` and `qt6-imageformats` are for **Dolphin**, not swayimg — they install the
`kimg_*.so` Qt plugins into `/usr/lib/qt6/plugins/imageformats/` so the file manager's
thumbnail grid renders modern formats. Worth keeping regardless of which viewer is default.

## 4. Gotcha: the packaged .desktop sets `NoDisplay=true`

`/usr/share/applications/swayimg.desktop` ships with `NoDisplay=true`, which hides swayimg
from Dolphin's "Open With" menu and from application launchers. It still functions as a
`mimeapps.list` default, but it cannot be *chosen*.

Fix: `applications/swayimg.desktop` in this repo is a local override, symlinked to
`~/.local/share/applications/swayimg.desktop`. A local file with the **same basename**
fully replaces the system one. Changes vs. packaged:

- `NoDisplay=true` removed
- `Name=Image Viewer` (clearer than "Swayimg" in a menu)
- `MimeType=` extended — the packaged list has `image/heif` but **not `image/heic`**, which
  is the type iPhone photos actually use. Also added `image/jp2`, `image/qoi`, and the
  libraw types (`image/x-adobe-dng`, `x-canon-cr2`, `x-nikon-nef`, `x-sony-arw`,
  `x-panasonic-rw2`, `x-olympus-orf`, `x-fuji-raf`).

`~/.local/share/applications/` was previously untracked by this repo — see §7.

## 5. Gotcha: Dolphin resolves through ksycoca, not the freedesktop db

Dolphin/KIO do **not** use `mimeapps.list` + `mimeinfo.cache` directly — they resolve
"open with" through KDE's own service cache, **ksycoca**. A newly added `.desktop` file is
invisible to them until `kbuildsycoca6` runs, and a Dolphin that was already open when the
file appeared keeps its stale cache until restarted. Symptom: `xdg-mime query default`
and `gio mime` both report swayimg correctly, but double-clicking in Dolphin does nothing.

`install.sh` now runs `kbuildsycoca6 --noincremental` after linking desktop entries.
If it ever recurs, run that and restart Dolphin.

Note `kde-open` is not installed here, so `xdg-open` falls through to `gio` — meaning a
successful `xdg-open` test does **not** prove Dolphin will work. They are different paths.

## 6. Gotcha: `enable_adjacent` is off by default

`swayimg.imagelist.enable_adjacent` defaults to **false**, meaning opening a single file
from Dolphin gives you that one file and nothing to navigate to — a dead end. `init.lua`
sets it to `true`, so a double-click loads the whole containing directory into the list.
Verified: opening one wallpaper yields a list of 184.

Recursion (`enable_recursive`) is deliberately left **off** in `init.lua`, so that opening
a file in e.g. `~/Downloads` doesn't scan every subdirectory beneath it. Only the SUPER+I
*fallback* turns it on, via `-e` — see §8.

## 7. Gotcha: `set_fix_scale` throws in gallery mode

The upstream example config suggests this for tiling compositors:

```lua
swayimg.on_window_resize(function()
  swayimg.viewer.set_fix_scale("optimal")
end)
```

Used verbatim it errors on every resize when the window is in gallery or slideshow mode —
`Unable to execute swayimg.viewer.set_fix_scale: mode not active` — which is exactly what
happens when starting with `swayimg -g`. `init.lua` guards it with
`if swayimg.get_mode() == "viewer" then`.

## 8. SUPER+I — the Quickshell image picker

SUPER+I opens a filmstrip in the Quickshell bottom overlay, the same morphing shelf as the
app launcher (SUPER+Space) and wallpaper picker (SUPER+SHIFT+W) — a new `"images"` mode in
`BottomOverlayHost.qml` rather than a separate window, so it inherits the unfold animation,
focus grab and focused-monitor retarget for free.

It spans **Pictures, Downloads, Desktop and Documents**, newest first, listed by
`bin/image-list` (maxdepth 3, dotdirs pruned; ~5 ms for 194 files). Typing filters on
filename **or folder** — "downloads" narrows to that folder, so there's no separate
folder-choosing step. Enter or click opens the pick in swayimg; `enable_adjacent` then
gives you that image's folder to arrow through.

Two deliberate departures from `WallpaperContent.qml`, which it is otherwise modelled on:

- **No thumbnail cache.** `ListView` only builds visible delegates, so loading originals
  with `sourceSize` capped at 256 is cheap and leaves nothing to invalidate. Qt decodes
  AVIF/HEIF/JXL here only because `qt6-imageformats` + `kimageformats` are installed — the
  same packages that fixed Dolphin's thumbnails (§3). Tiles that still fail to decode show
  a placeholder glyph rather than a blank frame.
- **Search matches the folder path**, not just the basename.

The keybind keeps a fallback so it still works if `qs` is down:

```lua
qs ipc call imagepicker toggle || swayimg -g -e 'swayimg.imagelist.enable_recursive(true)' $HOME/Pictures
```

The `-e` recursion is needed only in that fallback, because `~/Pictures` has no loose
images — everything is under `~/Pictures/wallpaper/`, so a non-recursive gallery opens empty.

## 9. Where everything lives

| Path | Tracking | Purpose |
|---|---|---|
| `config/swayimg/init.lua` | LINKED (`LINK_CONFIG`) | Ethereal theme + behaviour |
| `applications/swayimg.desktop` | LINKED (`LINK_APPS`) | overrides the packaged entry |
| `config/mimeapps.list` | COPIED (`COPY_CONFIG`) | `image/*` → `swayimg.desktop` |
| `config/hypr/hyprland.lua` | LINKED | float rule + SUPER+I keybind |
| `bin/image-list` | LINKED (`LINK_BIN`) | multi-folder listing for the picker |
| `config/quickshell/overlay/ImageContent.qml` | LINKED | the picker UI |

`LINK_APPS` is new. `~/.local/share/applications/` had no tracking at all before this —
the lone file there, `claude-code-url-handler.desktop`, is still untracked and its
`mimeapps.list` reference would dangle on a fresh machine. Not fixed here; noted.

Colors in `init.lua` come from the Ethereal palette (`config/ghostty/themes/ethereal`,
`config/quickshell/config/Appearance.qml`): bg `#060B1E`, surface `#0d1430`, surfaceBlue
`#3C486D`, accent `#7d82d9`, peach `#ffcead`. swayimg takes `0xAARRGGBB`.

The Hyprland rule matches `class = "swayimg"` — the default Wayland app_id — so one rule
covers both the Dolphin and keybind launch paths. Note swayimg's flag is `--appid`, not
`--class`, which is why there is no `com.ethereal.*` class here like the Ghostty TUIs use.

## 10. Verification

```bash
swayimg --version                                     # 5.4
grep -c '^NoDisplay' ~/.local/share/applications/swayimg.desktop   # 0
for t in image/png image/heic image/svg+xml; do xdg-mime query default "$t"; done
timeout 3 swayimg --verbose ~/Pictures/wallpaper 2>&1 | grep -i error   # silent
image-list | wc -l                                    # non-zero, newest first
qs ipc show | grep -A1 imagepicker                    # target registered
```

Then: double-click an image in Dolphin **from a few different folders**, Downloads
included (opens floating and centered, not in Chromium); `hyprctl clients` shows
`class: swayimg`, `floating: true`, sized 70% × 75% of the logical screen. SUPER+I opens
the filmstrip with selection on the first (newest) tile; typing a folder name filters to
it; Enter opens the pick.

## 11. Rollback

```bash
sudo pacman -Rns swayimg
```

Remove the `image/*` lines from `~/.config/mimeapps.list`, delete the
`float-image-viewer` rule and the SUPER+I bind from `config/hypr/hyprland.lua`, and drop
`swayimg` from `LINK_CONFIG` / `image-list` from `LINK_BIN` / `swayimg.desktop` from
`LINK_APPS` in `install.sh`. For the picker: delete
`config/quickshell/overlay/ImageContent.qml`, the `"images"` branches in
`BottomOverlayHost.qml`, the `imagepicker` `IpcHandler` in `shell.qml`, and the
`images*` tokens in `Appearance.qml`.

Keep `libheif`, `kimageformats`, and `qt6-imageformats` — they benefit Dolphin and any
other viewer independently of swayimg.
