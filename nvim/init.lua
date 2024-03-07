local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "

-- require("lazy").setup(plugins, opts)

require("lazy").setup({
  'tpope/vim-sleuth',
  "folke/which-key.nvim",
  { "folke/neoconf.nvim", cmd = "Neoconf" },
  "folke/neodev.nvim",
  "williamboman/mason.nvim",
  'neovim/nvim-lspconfig',
  'ms-jpq/coq_nvim',
  "hedyhli/outline.nvim",
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' }
  },
  "nvim-telescope/telescope.nvim",
  "nvim-lua/plenary.nvim",
  {
    "startup-nvim/startup.nvim",
    requires = {"nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim"},
    config = function()
      -- require("startup").setup({theme = "evil"})
      require("startup").setup()
    end
  },
  "jbyuki/venn.nvim",
  'ada0l/obsidian',
  {
    'gsuuon/note.nvim',
    opts = {
      -- Spaces are note roots. These directories should contain a `./notes` directory (will be made if not).
      -- Defaults to { '~' }.
      spaces = {
        '~',
        -- '~/projects/foo'
      },

      -- Set keymap = false to disable keymapping
      -- keymap = { 
      --   prefix = '<leader>n'
      -- }
    },
    cmd = 'Note',
    ft = 'note'
  },
  {
    "karb94/neoscroll.nvim",
    config = function ()
      require('neoscroll').setup {}
    end
  },
  'nvim-treesitter/nvim-treesitter',
  {
    'gorbit99/codewindow.nvim',
    config = function()
      -- local codewindow = require('codewindow')
      require('codewindow').setup({})
      -- require('codewindow').setup({auto_enable = true})
      require('codewindow').apply_default_keybinds()
    end,
  },
  'sbdchd/neoformat',
  'cappyzawa/trim.nvim',
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} },
  {
    'mawkler/modicator.nvim',
    dependencies = 'olivercederborg/poimandres.nvim', -- Add your colorscheme plugin here
    init = function()
      vim.o.termguicolors = true
      vim.o.cursorline = true
      vim.o.number = true
      vim.wo.relativenumber = true
    end,
  },
  'RRethy/vim-illuminate',
  'ms-jpq/chadtree',
  'rmehri01/onenord.nvim',
  {
    'olivercederborg/poimandres.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('poimandres').setup {
        -- leave this setup function empty for default config
        -- or refer to the configuration section
        -- for configuration options
      }
    end,

    -- optionally set the colorscheme within lazy config
    init = function()
      vim.cmd("colorscheme poimandres")
    end
  },
  -- {
  --   'nvimdev/dashboard-nvim',
  --   event = 'VimEnter',
  --   config = function()
  --     require('dashboard').setup {
  --       -- config
  --     }
  --   end,
  --   dependencies = { {'nvim-tree/nvim-web-devicons'}}
  -- },
})

require("mason").setup()
require('lspconfig').bashls.setup({})
require('lspconfig').lua_ls.setup({})

require("outline").setup()
--require("startup").setup({theme = "evil"})

-- stylua: ignore
local colors = {
  blue   = '#80a0ff',
  cyan   = '#79dac8',
  black  = '#080808',
  white  = '#c6c6c6',
  red    = '#ff5189',
  violet = '#d183e8',
  grey   = '#303030',
}

local bubbles_theme = {
  normal = {
    a = { fg = colors.black, bg = colors.violet },
    b = { fg = colors.white, bg = colors.grey },
    c = { fg = colors.white },
  },

  insert = { a = { fg = colors.black, bg = colors.blue } },
  visual = { a = { fg = colors.black, bg = colors.cyan } },
  replace = { a = { fg = colors.black, bg = colors.red } },

  inactive = {
    a = { fg = colors.white, bg = colors.black },
    b = { fg = colors.white, bg = colors.black },
    c = { fg = colors.white },
  },
}

require('lualine').setup {
  options = {
    theme = bubbles_theme,
    component_separators = '',
    section_separators = { left = '', right = '' },
    always_divide_middle = true,
  },
  sections = {
    lualine_a = { { 'mode', separator = { left = '' }, right_padding = 2 } },
    lualine_b = { { 'filename', file_status = true, path = 3, shorting_target = 40 }, 'branch', 'diff' },
    lualine_c = {
      '%=', --[[ add your center compoentnts here in place of this comment ]]
    },
    lualine_x = {},
    lualine_y = { 'filetype', 'progress' },
    lualine_z = {
      { 'location', separator = { right = '' }, left_padding = 2 },
    },
  },
  inactive_sections = {
    lualine_a = { 'filename' },
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = { 'location' },
  },
  tabline = {},
  extensions = {},
}

vim.cmd("set virtualedit=all")

-- require('onenord').setup({})

