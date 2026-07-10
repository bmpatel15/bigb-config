-- Modest SQL support: treesitter highlight/indent/folds, nothing more.
-- Deliberately NOT LazyVim's `lang.sql` extra — that pulls in vim-dadbod (a
-- full database UI/completion layer) plus sqlfluff lint+format, none of which
-- is needed for learning/editing SQL files. Revisit dadbod if live-database
-- work ever becomes a real workflow.

-- Same two guards the sql extra sets: Vim's builtin sqlcomplete omnifunc
-- errors ("dbext plugin must be loaded") when triggered without dbext, so keep
-- syntax-only completion and disable the builtin sql completion plugin.
vim.g.omni_sql_default_compl_type = "syntax"
vim.g.loaded_sql_completion = true

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "sql" } },
  },
}
