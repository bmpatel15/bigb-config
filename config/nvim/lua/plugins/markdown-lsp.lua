-- Cross-note markdown LSP: marksman. Enabled through LazyVim's nvim-lspconfig
-- `servers` table so mason-lspconfig installs the binary and wires it up.
-- Provides [[wikilink]] completion, goto-definition (gd), references, and
-- document symbols ACROSS notes (not just the current file).
--
-- A workspace marker at ~/Documents/BigB-PKM/.marksman.toml makes marksman
-- treat the whole vault (which has no .git) as one workspace.
--
-- Note: marksman is a .NET binary and cold-starts in ~20s the very first time;
-- after that it is fast. If `gd` does nothing right after opening a note, give
-- the server a moment to attach (:LspInfo to check).
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        marksman = {},
      },
    },
  },
}
