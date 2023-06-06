local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  if packer_bootstrap then
    require('packer').sync()
  end

  use 'nvim-tree/nvim-web-devicons'

  use {
    "nvim-tree/nvim-tree.lua",
    
    config = function()
      require("nvim-web-devicons").setup()

      require("nvim-tree").setup {
        hijack_cursor = true,
        view = {
          width = 40
        }
      }

    end
  }

  use {
    'wincent/command-t',
    run = 'cd lua/wincent/commandt/lib && make',
    setup = function ()
        vim.g.CommandTPreferredImplementation = 'lua'
    end,
    config = function()
      require('wincent.commandt').setup({
        -- Customizations go here.
      })
    end,
  }
  vim.keymap.set('n', '<Leader>b', '<Plug>(CommandTBuffer)')
  vim.keymap.set('n', '<Leader>t', '<Plug>(CommandT)')
  vim.keymap.set('n', '<Leader>n', '<Cmd>NvimTreeToggle<CR>')

  vim.cmd([[
    augroup packer_user_config
      autocmd!
      autocmd BufWritePost plugins.lua source <afile> | PackerSync
    augroup end
  ]])

  use 'ishan9299/nvim-solarized-lua'
  vim.g.solarized_italics = 1
  vim.cmd('colorscheme solarized')

  use {
    'nvim-treesitter/nvim-treesitter',
    run = function()
            local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
            ts_update()
    end,
  }

  require'nvim-treesitter.configs'.setup {
  -- A list of parser names, or "all" (the five listed parsers should always be installed)
  ensure_installed = { "cpp", "c", "lua", "vim", "vimdoc", "query", "python", "perl", "ruby" },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- Automatically install missing parsers when entering buffer
  -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
  auto_install = true,

  highlight = {
    enable = true,

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  }
  }

  use {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup()
    end
  }

  use {
    'romgrk/barbar.nvim',
  }

  use { 'mhartington/formatter.nvim' ,
    config = function()
            -- Utilities for creating configurations
local util = require "formatter.util"

-- Provides the Format, FormatWrite, FormatLock, and FormatWriteLock commands
require("formatter").setup {
  -- Enable or disable logging
  logging = true,
  -- Set the log level
  log_level = vim.log.levels.WARN,
  -- All formatter configurations are opt-in
  filetype = {
    cpp = {
            require("formatter.filetypes.cpp").clangformat,
    },
    c = {
            require("formatter.filetypes.cpp").clangformat,
    },

  }
}
    end
  }


end)
