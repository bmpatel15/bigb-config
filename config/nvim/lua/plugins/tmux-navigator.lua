-- Seamless Ctrl-h/j/k/l movement between Neovim splits and tmux panes.
-- Pairs with the christoomey/vim-tmux-navigator TPM plugin in
-- ~/.config/tmux/tmux.conf — the tmux side detects a running nvim and
-- passes the keystroke through instead of switching panes.
return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
    "TmuxNavigatePrevious",
    "TmuxNavigatorProcessList",
  },
  keys = {
    { "<c-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Go to left split/pane" },
    { "<c-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Go to lower split/pane" },
    { "<c-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Go to upper split/pane" },
    { "<c-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Go to right split/pane" },
    { "<c-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Go to previous split/pane" },
  },
}
