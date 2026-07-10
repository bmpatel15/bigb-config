-- Python tooling split on top of the lang.python extra: ruff owns imports,
-- lint fixes, and formatting; pyright owns types, hover, and navigation.
-- The extra already disables ruff's hover, but LazyVim 16 leaves pyright's
-- organize-imports enabled — without this, both servers offer
-- source.organizeImports and organize-imports code actions show a two-entry
-- picker. Disabling pyright's copy keeps a single owner per responsibility.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          settings = {
            pyright = { disableOrganizeImports = true },
          },
        },
      },
    },
  },
}
