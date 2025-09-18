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

      vim.keymap.set('n', '<Leader>n', '<Cmd>NvimTreeToggle<CR>')

    end
  }

  use {
    'ishan9299/nvim-solarized-lua',
    config = function()
      vim.g.solarized_italics = 1
      vim.cmd('colorscheme solarized')
    end,
  }

  use {
    'nvim-treesitter/nvim-treesitter',
    run = function()

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

            local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
            ts_update()
    end,
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
            --
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

  use {
    'neovim/nvim-lspconfig',

    config = function()
            vim.lsp.enable('clangd')
    end
  }

  use {
    'hedyhli/outline.nvim',
    config = function()
      require('outline').setup({})
      vim.keymap.set('n', '<Leader>o', '<Cmd>Outline<CR>')
    end
  }

  use {
    'nvim-telescope/telescope.nvim',
    requires = { {'nvim-lua/plenary.nvim'} },
    config = function()
      	require('telescope').setup({})
	local builtin = require('telescope.builtin')
	vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Telescope find files' })
	vim.keymap.set('n', '<leader>fr', builtin.live_grep, { desc = 'Telescope live grep' })
	vim.keymap.set('n', '<leader>fg', builtin.git_status, { desc = 'Telescope git' })
	vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Telescope buffers' })
	vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Telescope help tags' })
    end
  }

  use {
    'folke/trouble.nvim',
    config = function()
      	require('trouble').setup({})
      vim.keymap.set('n', '<Leader>to', '<Cmd>Trouble diagnostics toggle focus=false filter.buf=0<CR>')
      vim.keymap.set('n', '<Leader>ts', '<Cmd>Trouble symbols toggle focus=false<CR>')
      vim.keymap.set('n', '<Leader>tl', '<Cmd>Trouble lsp toggle focus=false<CR>')
    end
  }

  if packer_bootstrap then
    require('packer').sync()
  end

end)

