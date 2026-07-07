-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Prefer absolute line numbers for markdown/prose work.
vim.opt.relativenumber = false

-- Sync yank/paste/delete with the Wayland system clipboard (needs wl-clipboard),
-- so y/p round-trip with other apps and the SUPER+C/V universal copy/paste binds.
vim.opt.clipboard = "unnamedplus"
