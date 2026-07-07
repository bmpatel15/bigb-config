-- List / checkbox continuation. With bullets.vim's default mappings, <CR> in
-- insert mode and `o` in normal mode start the next bullet, number, or checkbox.
-- blink.cmp accepts completions with <C-y> (LazyVim default), so <CR> stays free
-- for list continuation while still accepting the completion menu when it is open.
return {
  {
    "dkarter/bullets.vim",
    ft = { "markdown", "text", "gitcommit" },
    init = function()
      vim.g.bullets_enabled_file_types = { "markdown", "text", "gitcommit", "scratch" }
    end,
  },
}
