-- Obsidian vault integration: note/daily creation, templates, backlinks, tags,
-- follow-link, and an in-process completion source for [[wikilinks]] / #tags.
-- Settings mirror ~/Documents/BigB-PKM/.obsidian so notes created from Neovim
-- match what the Obsidian app expects.
--
-- render-markdown.nvim owns all in-buffer rendering, so obsidian's own UI layer
-- is disabled (ui = { enable = false }) to keep the two from fighting over
-- concealment and highlights.
return {
  {
    "obsidian-nvim/obsidian.nvim",
    ft = "markdown",
    dependencies = { "nvim-lua/plenary.nvim" },
    ---@module 'obsidian'
    ---@type obsidian.config.ClientOpts
    opts = {
      workspaces = {
        { name = "BigB-PKM", path = "~/Documents/BigB-PKM" },
      },

      -- Use the modern `:Obsidian <subcommand>` syntax (see keys below); disable
      -- the deprecated legacy `:Obsidian<Cmd>` aliases.
      legacy_commands = false,

      -- New notes -> "02 - Fleeting Notes" with human-readable, title-based filenames.
      notes_subdir = "02 - Fleeting Notes",
      new_notes_location = "notes_subdir",
      note_id_func = function(title)
        if title ~= nil and title ~= "" then
          return title
        end
        return "Untitled " .. tostring(os.time())
      end,

      daily_notes = {
        folder = "01 - Daily Notes",
        date_format = "%Y-%m-%d",
        template = "Daily Note Template.md",
      },

      templates = {
        folder = "09 - Templates",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
      },

      attachments = {
        folder = "08 - Attachments",
      },

      -- Vault uses [[wikilinks]] (app setting useMarkdownLinks: false).
      link = {
        style = "wiki",
      },

      -- Fleeting-style frontmatter: type / created / status / tags
      -- (matches "02 - Fleeting Notes/Example Fleeting Thought.md").
      frontmatter = {
        enabled = true,
        func = function(note)
          local out = {
            type = "fleeting",
            created = os.date("%Y-%m-%d"),
            status = "inbox",
            tags = note.tags,
          }
          -- Preserve any frontmatter the note already has (e.g. keep original
          -- `created`/`type` on existing notes instead of resetting them).
          if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
            for k, v in pairs(note.metadata) do
              out[k] = v
            end
          end
          return out
        end,
      },

      -- Picker + completion provided by the existing LazyVim stack.
      -- (obsidian.nvim now auto-detects blink.cmp; no engine flag needed.)
      picker = {
        name = "snacks.picker",
      },
      completion = {
        min_chars = 2,
      },

      -- render-markdown.nvim does the rendering.
      ui = { enable = false },
    },
    keys = {
      { "<leader>of", "<cmd>Obsidian quick_switch<cr>", desc = "Find note (quick switch)" },
      { "<leader>og", "<cmd>Obsidian search<cr>", desc = "Grep notes" },
      { "<leader>on", "<cmd>Obsidian new<cr>", desc = "New note" },
      { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Backlinks" },
      { "<leader>ot", "<cmd>Obsidian tags<cr>", desc = "Tags" },
      { "<leader>od", "<cmd>Obsidian today<cr>", desc = "Today's daily" },
      { "<leader>oy", "<cmd>Obsidian yesterday<cr>", desc = "Yesterday's daily" },
      { "<leader>oo", "<cmd>Obsidian open<cr>", desc = "Open in Obsidian app" },
      { "<leader>ol", "<cmd>Obsidian follow_link<cr>", desc = "Follow link" },
      { "<leader>or", "<cmd>Obsidian rename<cr>", desc = "Rename note" },
      { "<leader>oi", "<cmd>Obsidian template<cr>", desc = "Insert template" },
    },
  },

  -- which-key group label for the <leader>o obsidian maps.
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>o", group = "obsidian" },
      },
    },
  },
}
