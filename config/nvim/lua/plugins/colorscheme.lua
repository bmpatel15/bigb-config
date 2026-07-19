-- Omarchy Ethereal theme (https://github.com/basecamp/omarchy/tree/master/themes/ethereal)
return {
  {
    "bjarneo/ethereal.nvim",
    priority = 1000,
    opts = {
      -- Let ghostty's background-opacity (0.85) show through. Without this the
      -- colorscheme paints Normal with an explicit bg, and since ghostty runs
      -- background-opacity-cells = false, those cells stay fully opaque —
      -- nvim would be the one window that ignores the terminal transparency.
      transparent = true,
      styles = {
        -- Sidebars are part of the main editing surface, so they match.
        sidebars = "transparent",
        -- Floats stay opaque on purpose: telescope/lazy/which-key pop over
        -- the wallpaper, and a solid backdrop keeps them readable. Set to
        -- "transparent" if you'd rather have them match too.
        floats = "dark",
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "ethereal",
    },
  },
}
