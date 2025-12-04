-- Neovim Init Configuration
-- Author: smbayer
-- Last Modified: 2025-10-21

-- Set leader key early (must be before lazy.nvim setup)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Basic Settings
vim.opt.number = true                -- Show line numbers
vim.opt.relativenumber = true        -- Show relative line numbers
vim.opt.mouse = 'a'                  -- Enable mouse support in all modes
vim.opt.mousemoveevent = true        -- Enable mouse move events (for hover effects)
vim.opt.ignorecase = true            -- Case insensitive search
vim.opt.smartcase = true             -- Case sensitive when uppercase present
vim.opt.hlsearch = true              -- Highlight search results
vim.opt.wrap = false                 -- Disable line wrap
vim.opt.breakindent = true           -- Preserve indentation in wrapped text
vim.opt.tabstop = 4                  -- Number of spaces for a tab
vim.opt.shiftwidth = 4               -- Number of spaces for indentation
vim.opt.expandtab = true             -- Use spaces instead of tabs
vim.opt.termguicolors = true         -- Enable 24-bit RGB colors
vim.opt.cursorline = true            -- Highlight current line
vim.opt.signcolumn = "yes"           -- Always show sign column
vim.opt.updatetime = 250             -- Faster completion
vim.opt.timeoutlen = 300             -- Time to wait for mapped sequence
vim.opt.splitbelow = true            -- Horizontal splits below
vim.opt.splitright = true            -- Vertical splits to the right
vim.opt.scrolloff = 8                -- Keep 8 lines visible when scrolling
vim.opt.sidescrolloff = 8            -- Keep 8 columns visible when scrolling

-- Clipboard integration with system clipboard (macOS)
vim.opt.clipboard = "unnamedplus"    -- Use system clipboard for all yank/delete/put operations

-- Folding settings (using treesitter when available)
vim.opt.foldmethod = 'expr'          -- Use expression for folding
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'  -- Use treesitter for folding
vim.opt.foldlevel = 99               -- Start with all folds open
vim.opt.foldlevelstart = 99          -- Start editing with all folds open
vim.opt.foldenable = true            -- Enable folding
vim.opt.foldcolumn = '1'             -- Show fold column

-- Enhanced Mouse Settings
vim.opt.mousemodel = 'popup_setpos'  -- Right-click pops up a menu and sets cursor position
vim.opt.mousescroll = 'ver:3,hor:6'  -- Smooth scrolling: 3 lines vertical, 6 columns horizontal

-- Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Bootstrap lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load plugins
require("lazy").setup({
  -- Load plugin configurations from lua/plugins/
  spec = {
    { import = "plugins" },
  },
  -- Lazy.nvim settings
  checker = {
    enabled = true,
    notify = false,
  },
  change_detection = {
    notify = false,
  },
})

-- Key Mappings
local keymap = vim.keymap.set

-- Better escape
keymap("i", "jk", "<ESC>", { desc = "Exit insert mode" })

-- Clear search highlight
keymap("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })

-- Better window navigation
keymap("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- Resize windows with arrows
keymap("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase window height" })
keymap("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
keymap("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
keymap("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

-- Buffer navigation
keymap("n", "<S-l>", ":bnext<CR>", { desc = "Next buffer" })
keymap("n", "<S-h>", ":bprevious<CR>", { desc = "Previous buffer" })
keymap("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })

-- Tab navigation
keymap("n", "<leader>tn", ":tabnew<CR>", { desc = "New tab" })
keymap("n", "<leader>tc", ":tabclose<CR>", { desc = "Close tab" })
keymap("n", "<leader>to", ":tabonly<CR>", { desc = "Close other tabs" })
keymap("n", "<C-Tab>", ":tabnext<CR>", { desc = "Next tab" })
keymap("n", "<C-S-Tab>", ":tabprevious<CR>", { desc = "Previous tab" })
keymap("n", "gt", ":tabnext<CR>", { desc = "Next tab (vim style)" })
keymap("n", "gT", ":tabprevious<CR>", { desc = "Previous tab (vim style)" })

-- Better indenting
keymap("v", "<", "<gv", { desc = "Indent left and keep selection" })
keymap("v", ">", ">gv", { desc = "Indent right and keep selection" })

-- Move text up and down
keymap("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move text down" })
keymap("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move text up" })

-- Keep cursor centered when scrolling
keymap("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
keymap("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })

-- Keep search terms centered
keymap("n", "n", "nzzzv", { desc = "Next search result" })
keymap("n", "N", "Nzzzv", { desc = "Previous search result" })

-- Folding keymaps
keymap("n", "za", "za", { desc = "Toggle fold under cursor" })
keymap("n", "zA", "zA", { desc = "Toggle all folds under cursor" })
keymap("n", "zc", "zc", { desc = "Close fold under cursor" })
keymap("n", "zC", "zC", { desc = "Close all folds under cursor" })
keymap("n", "zo", "zo", { desc = "Open fold under cursor" })
keymap("n", "zO", "zO", { desc = "Open all folds under cursor" })
keymap("n", "zR", "zR", { desc = "Open all folds in file" })
keymap("n", "zM", "zM", { desc = "Close all folds in file" })

-- Filetype selection
keymap("n", "<leader>ft", ":set filetype=", { desc = "Set filetype (language)" })

-- Mouse-specific keymaps
-- Middle mouse button paste
keymap({"n", "v"}, "<MiddleMouse>", "<LeftMouse><MiddleMouse>", { desc = "Middle mouse paste" })
keymap("i", "<MiddleMouse>", "<LeftMouse><MiddleMouse>", { desc = "Middle mouse paste in insert" })

-- Ctrl+ScrollWheel for horizontal scrolling
keymap({"n", "v", "i"}, "<C-ScrollWheelUp>", "<ScrollWheelLeft>", { desc = "Scroll left" })
keymap({"n", "v", "i"}, "<C-ScrollWheelDown>", "<ScrollWheelRight>", { desc = "Scroll right" })

-- Shift+ScrollWheel for faster vertical scrolling
keymap({"n", "v"}, "<S-ScrollWheelUp>", "5<C-y>", { desc = "Fast scroll up" })
keymap({"n", "v"}, "<S-ScrollWheelDown>", "5<C-e>", { desc = "Fast scroll down" })

-- Alt+ScrollWheel for zooming (changing font size simulation via zoom)
keymap("n", "<A-ScrollWheelUp>", ":set guifont=+<CR>", { desc = "Increase font size", silent = true })
keymap("n", "<A-ScrollWheelDown>", ":set guifont=-<CR>", { desc = "Decrease font size", silent = true })

-- Right-click context menu (visual mode)
keymap("v", "<RightMouse>", function()
  vim.cmd('normal! gv')
  local menu_items = {
    "Copy",
    "Cut",
    "Paste",
    "Delete",
  }
  vim.ui.select(menu_items, {
    prompt = "Select action:",
  }, function(choice)
    if choice == "Copy" then
      vim.cmd('normal! "+y')
    elseif choice == "Cut" then
      vim.cmd('normal! "+d')
    elseif choice == "Paste" then
      vim.cmd('normal! "+p')
    elseif choice == "Delete" then
      vim.cmd('normal! d')
    end
  end)
end, { desc = "Right-click context menu" })

-- Double-click to select word
keymap("n", "<2-LeftMouse>", "<LeftMouse>viw", { desc = "Double-click select word" })

-- Ctrl+Click to go to definition (when LSP is available)
keymap("n", "<C-LeftMouse>", "<LeftMouse><cmd>lua vim.lsp.buf.definition()<CR>", { desc = "Ctrl+Click go to definition" })

-- Scroll in insert mode without leaving insert mode
keymap("i", "<ScrollWheelUp>", "<C-X><C-Y>", { desc = "Scroll up in insert mode" })
keymap("i", "<ScrollWheelDown>", "<C-X><C-E>", { desc = "Scroll down in insert mode" })

-- Load ftplugin configurations
vim.cmd([[filetype plugin indent on]])

-- Display mouse mode info
vim.api.nvim_create_user_command('MouseInfo', function()
  local mouse_enabled = vim.o.mouse
  local mouse_model = vim.o.mousemodel
  local mouse_move = vim.o.mousemoveevent
  local mouse_scroll = vim.o.mousescroll

  print("Mouse Configuration:")
  print("  Enabled for: " .. (mouse_enabled ~= "" and mouse_enabled or "DISABLED"))
  print("  Model: " .. mouse_model)
  print("  Move Events: " .. tostring(mouse_move))
  print("  Scroll Settings: " .. mouse_scroll)
  print("\nMouse Features:")
  print("  • Click to position cursor")
  print("  • Drag to select text")
  print("  • Double-click to select word")
  print("  • Scroll wheel to navigate")
  print("  • Shift+Scroll for fast scrolling")
  print("  • Ctrl+Scroll for horizontal scrolling")
  print("  • Right-click for context menu")
  print("  • Ctrl+Click for go-to-definition (with LSP)")
  print("  • Middle-click to paste")
end, { desc = "Display mouse configuration info" })
