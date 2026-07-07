-- In-buffer markdown rendering (headings, code blocks, checkboxes, tables,
-- callouts, [[wikilinks]]). This plugin OWNS all rendering and manages
-- `conceallevel` per window, so obsidian.nvim's own UI layer is disabled
-- (see lua/plugins/obsidian.lua -> ui = { enable = false }) to avoid conflicts.
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    -- mini.icons is already provided globally by LazyVim; render-markdown picks
    -- it up automatically, so only the treesitter parser dep is declared here.
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    ---@module "render-markdown"
    ---@type render.md.UserConfig
    opts = {
      -- Let render-markdown expose its completions to blink.cmp.
      completions = { lsp = { enabled = true } },
      checkbox = {
        -- Obsidian "in progress" / cancelled style checkboxes render nicely too.
        custom = {
          todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo", scope_highlight = nil },
        },
      },
    },
  },

  -- render-markdown requires both markdown parsers. LazyVim already ships them,
  -- but ensure them explicitly (LazyVim merges this list with its defaults).
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "markdown", "markdown_inline" } },
  },
}
