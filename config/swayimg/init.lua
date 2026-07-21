-- swayimg — image viewer for Wayland. Ethereal-themed.
--
-- Linked to ~/.config/swayimg/init.lua (LINK_CONFIG in install.sh). This file only
-- overrides defaults; the full annotated reference is /usr/share/swayimg/example.lua.
--
-- Launch paths: Dolphin double-click (via applications/swayimg.desktop) and SUPER+I
-- for gallery mode over ~/Pictures. Hyprland floats it centered — see the
-- "float-image-viewer" rule in config/hypr/hyprland.lua.
--
-- Colors are 0xAARRGGBB. Palette source of truth: config/ghostty/themes/ethereal
-- and config/quickshell/config/Appearance.qml.

-- Ethereal palette
local bg = 0xff060b1e -- deep navy, window background
local surface = 0xff0d1430 -- raised surface (unselected thumbnails)
local surfaceBlue = 0xff3c486d -- selected thumbnail background
local accent = 0xff7d82d9 -- periwinkle, selection border
local peach = 0xffffcead -- primary foreground text
local shadow = 0x80060b1e -- bg at 50% — keeps text legible over bright images

-- General -------------------------------------------------------------------
swayimg.enable_antialiasing(true)
swayimg.enable_exif_orientation(true)
-- No CSD titlebar: Hyprland draws the border/rounding for this floating window.
swayimg.enable_decoration(false)

-- Camera white balance for raw files (libraw) rather than the daylight default.
swayimg.set_format_params("raw", { camera_wb = true })

-- Image list ----------------------------------------------------------------
-- The important one. Default is false, which means opening a single file from
-- Dolphin gives you exactly that file and nothing to arrow through. With it on,
-- the rest of the directory is pulled into the list, so a double-click becomes a
-- browsable folder rather than a dead end.
swayimg.imagelist.enable_adjacent(true)
swayimg.imagelist.set_order("numeric") -- img2 before img10
swayimg.imagelist.enable_fsmon(true) -- pick up new screenshots without a restart

-- Text overlay --------------------------------------------------------------
swayimg.text.set_font("JetBrainsMono Nerd Font")
swayimg.text.set_size(16)
swayimg.text.set_foreground(peach)
swayimg.text.set_background(0x00000000)
swayimg.text.set_shadow(shadow)

-- Viewer mode ---------------------------------------------------------------
swayimg.viewer.set_window_background(bg)
swayimg.viewer.set_mark_color(accent)
-- Transparency checkerboard in palette tones instead of the default greys.
swayimg.viewer.set_image_chessboard(20, bg, surface)

-- Gallery mode --------------------------------------------------------------
swayimg.gallery.set_window_color(bg)
swayimg.gallery.set_unselected_color(surface)
swayimg.gallery.set_selected_color(surfaceBlue)
swayimg.gallery.set_border_color(accent)
swayimg.gallery.set_thumb_size(200)
swayimg.gallery.enable_hover(true) -- launched from a file manager; mouse is in play
swayimg.gallery.enable_embedded_thumb(true) -- use EXIF thumbnails when present
-- Persistent thumbnail cache (default off). Makes reopening ~/Pictures instant
-- instead of re-decoding every file each time.
swayimg.gallery.enable_pstore(true)

-- Tiling compositor fix -----------------------------------------------------
-- Hyprland resizes the window after mapping; without this the image keeps its
-- initial scale and ends up cropped or letterboxed.
--
-- The mode guard is required: set_fix_scale throws "mode not active" if the
-- resize lands while gallery or slideshow is up, which is exactly what happens
-- when starting with `swayimg -g`.
swayimg.on_window_resize(function()
	if swayimg.get_mode() == "viewer" then
		swayimg.viewer.set_fix_scale("optimal")
	end
end)
