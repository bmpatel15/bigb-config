-- QML tooling for the Quickshell shell (~/bigb-config/config/quickshell).
-- qmlls ships with Arch's qt6-declarative as `qmlls6` (not installable via
-- mason, hence mason = false). Import resolution for `import Quickshell.*`
-- comes from the checked-in .qmlls.ini in the quickshell config root.
-- Formatting: Qt6 qmlformat via conform — full path required: the bare
-- `qmlformat` on PATH is the Qt5 build and there is no qmlformat6 alias.
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed or {}, { "qmljs" })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        qmlls = {
          mason = false,
          cmd = { "qmlls6" },
        },
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        qml = { "qmlformat" },
      },
      formatters = {
        qmlformat = { command = "/usr/lib/qt6/bin/qmlformat" },
      },
    },
  },
}
