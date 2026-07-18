# Adaptive (wallpaper-derived) theming — archived design

Status: **designed, verified against Quickshell v0.3.0 docs, NOT implemented** (user chose to keep the static Ethereal palette, 2026-07-18). If the shell should ever recolor itself from the wallpaper (Material-You style, as in the soramane rice video), this is the ready-to-build plan. Every component already consumes `Appearance.colors.*`, so no consumer changes are needed.

## Verified API: ColorQuantizer (core Quickshell module, v0.3.0)
- `source` (set to `encodeURI("file://" + absPath)`), `depth: real` (result count = 2^depth; use 3 → 8 colors), `rescaleSize: real` (use 128 — caps cost on huge images), `colors: list<color>` (readonly output), `imageRect: rect`.
- No error signal documented; async unspecified — react only to `onColorsChanged`, never read synchronously.

## Architecture
- New `config/Theme.qml` singleton (same qs.config module as Appearance/Paths — no import cycle):
  - FileView watch on `Paths.wallpaperStateFile` (300 ms debounce Timer against write+rename double events) → ColorQuantizer rerun → `recompute()`.
  - `mode: "ethereal" | "adaptive"`, persisted via `FileView { path: Quickshell.statePath("theme.json"); blockLoading: true; JsonAdapter { property string mode } }` — survives restarts (PersistentProperties only survives reloads); `onAdapterUpdated: writeAdapter()`, `onLoadFailed: writeAdapter()`.
  - `palette`: QtObject of ~16 writable `property color` members, each with `Behavior on X { ColorAnimation { duration: 600; easing.type: Easing.OutCubic } }` — animate at the source; `apply()` assigns either the Ethereal literals or the derived set, everything downstream tweens. (Both wallpaper changes and mode toggles animate; no per-consumer Behaviors.)
- `Appearance.qml`: current literals move into `readonly property QtObject ethereal`; `colors.X` become readonly *bindings* to `Theme.palette.X` (readonly ≠ unbindable). `border`/`hover` (white-alpha) and semantic `red/redAlt/green/yellow` stay static in both modes.

## Derivation (recompute) — key rules
- Chroma proxy `S * (1 - |2L - 1|)`. accentSrc = most chromatic quantized color; bgSrc = darkest.
- Degenerate guard: chroma(accentSrc) < 0.15 or hue < 0 → grayscale wallpaper → Ethereal accent/peach hues over wallpaper-tinted bg.
- OLED bg: `Qt.hsla(bgHue, clamp(S,0.35,0.70), 0.05)`; surface at L 0.12; bgBar same at 0.85 alpha.
- accent: hue from accentSrc, S clamp 0.45–0.75, L clamp 0.60–0.72, then contrast-raise vs bg to ≥3.0.
- text: near-white with faint accent cast (S 0.15, L 0.91), contrast ≥7.0; muted ≥4.5.
- peach-role: most chromatic quantized color in the 15°–75° hue band else hue 24°; mauve-role: 2nd chromatic color ≥40° hue distance from accent else accent+60°; cyan: accent−34°.
- Contrast raiser: `while contrast < ratio && L < 0.97: L += 0.02; S *= 0.97` (WCAG relative-luminance formula).
- Quantizer produced <4 colors → keep last-applied palette, mark invalid (stale-good beats broken).

## Effort estimate
~1 new file (Theme.qml ≈ 150 lines), ~30-line Appearance restructure, control-center ToggleChip for the mode. No other files.
