-- Auto-loader for mlir-fold plugin
-- This file is automatically sourced by Neovim on startup

if vim.fn.has('nvim-0.8') == 0 then
  return
end

require('mlir-fold.mlir-fold').setup()
