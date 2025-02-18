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

-- vim.g.mapleader = "\\"

-- require("lazy").setup(plugins, opts)

require("lazy").setup({
  'tpope/vim-sleuth',
  "folke/which-key.nvim",
  { "folke/neoconf.nvim", cmd = "Neoconf" },
  "folke/neodev.nvim",
  --{
  --  "georgewfraser/java-language-server",
  --  config = function()
  --    require("java-language-server").setup()
  --  end
  --},
  "williamboman/mason.nvim",
  "williamboman/mason-lspconfig.nvim",
  'neovim/nvim-lspconfig',
  'ms-jpq/coq_nvim',
  "hedyhli/outline.nvim",
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' }
  },
  "nvim-lua/plenary.nvim",
  "BurntSushi/ripgrep",
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = 'make',
  },
  {
    "nvim-telescope/telescope.nvim",
    tag = '0.1.5',
    -- config = function()
    --   require("lvim.core.telescope").setup()
    -- end,
    dependencies = { "telescope-fzf-native.nvim" },
    lazy = true,
    cmd = "Telescope",
    -- enabled = lvim.builtin.telescope.active,
  },
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
      require('codewindow').setup({
        max_lines = nil,
        minimap_width = 16,
        auto_enable = false,
        screen_bounds = 'background',
      })
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
  {
    'ms-jpq/chadtree',
    branch = "chad",
    build = "python3 -m chadtree deps",
  },
  'rmehri01/onenord.nvim',
  {
    'olivercederborg/poimandres.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      require('poimandres').setup {}
    end,
    init = function()
      vim.cmd("colorscheme poimandres")
    end
  },
  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup {}
    end
  },
  {
    'smoka7/hop.nvim',
    version = "*",
    opts = {},
  }
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
require("mason-lspconfig").setup()
require('lspconfig').bashls.setup({})
-- require('lspconfig').java_language_server.setup({})
require('lspconfig').jdtls.setup({})
require('lspconfig').lua_ls.setup({})
-- require("lspconfig").ruby_ls.setup({})
require("lspconfig").sorbet.setup({})

-- require("outline").setup()
require("startup").setup({theme = "evil"})

require('lualine').setup {
  options = {
    theme = 'poimandres',
    component_separators = '',
    section_separators = { left = '', right = '' },
    always_divide_middle = true,
  },
  sections = {
    lualine_a = { { 'mode', separator = { left = '' }, right_padding = 2 } },
    lualine_b = {
      {
        'filename',
        file_status = true,
        path = 4,  -- 0: Just the filename
                   -- 1: Relative path
                   -- 2: Absolute path
                   -- 3: Absolute path, with tilde as the home directory
                   -- 4: Filename and parent dir, with tilde as the home directory
        shorting_target = 40
      },
      'diff'
    },
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
    lualine_z = {},
  },
  tabline = {},
  extensions = { 'chadtree', 'mason' },
}

vim.cmd("set virtualedit=all")
vim.cmd("set nowrap")

vim.keymap.set({'n'}, "<leader>ww", "<Cmd>set nowrap!<CR>")

vim.keymap.set({'n', 'c', 'i', 'v'}, '<C-b>', ':CHADopen<CR>')
vim.keymap.set({'n'}, '<C-o>', ':Telescope find_files<CR>')

vim.keymap.set({'n', 'v'}, '<Tab>', '>>')
vim.keymap.set({'i'}, '<Tab>', '<Esc>>>i')
vim.keymap.set({'n', 'v'}, '<S-Tab>', '<<')
vim.keymap.set({'i'}, '<S-Tab>', '<Esc><<i')

vim.keymap.set({'n'}, '<C-o>', ':Telescope find_files<CR>')  -- builtin.find_files	Lists files in your current working directory
-- vim.keymap.set({'n'}, '<C-O>', ':Telescope git_files<CR>')   -- Fuzzy search through the output of git ls-files command,
-- vim.keymap.set({'n'}, '<C-f>', ':Telescope grep_string<CR>') -- Searches for the string under your cursor or selection
vim.keymap.set({'n'}, '<leader>ff', ':Telescope live_grep<CR>')   -- Search for a string in your current working directory

vim.keymap.set({'n'}, '<M-Up>', '<Cmd>move .-2<CR>')
vim.keymap.set({'n'}, '<M-Down>', '<Cmd>move .+1<CR>')

vim.keymap.set({'n', 'i'}, '<C-j>', '<Cmd>HopWord<CR>')

-- Insert <C-J> = insert new line
-- Insert <C-M> = insert new line
-- Insert <C-W> = Delete the word before cursor
-- Insert <C-U> = Delete all before cursor
-- Insert <C-R>* = print clipboard contents
-- Insert <C-T> = Indent line
-- Insert <C-D> = Unindent line
--
-- Normal y y = Yank line
-- Normal p = put after current line
-- Normal P = put before the current line

vim.o.foldenable = false
vim.o.foldmethod = 'syntax'
vim.o.foldlevel = 1
vim.o.foldlevelstart = 1
-- Normal zo = Open fold
-- Normal zO = Open folds recursivly
-- Normal zc = Close fold
-- Normal zC = Close fold recursivly
-- Normal za = Toggle fold
-- Normal zA = Toggle fold recursivly
-- Normal zx = Reapply folding
-- Normal zm = Fold more
-- Normal zM = Close all folds
-- Normal zr = Fold less
-- Normal zR = Unfold all
-- Normal z =



