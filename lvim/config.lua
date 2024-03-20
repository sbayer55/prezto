-- Read the docs: https://www.lunarvim.org/docs/configuration
-- Video Tutorials: https://www.youtube.com/watch?v=sFA9kX-Ud_c&list=PLhoH5vyxr6QqGu0i7tt_XoVK9v-KvZ3m6
-- Forum: https://www.reddit.com/r/lunarvim/
-- Discord: https://discord.com/invite/Xb9B4Ny

vim.opt.relativenumber = true

-- use treesitter folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

-- File explorer
lvim.keys.normal_mode["<C-b>"] = false
lvim.keys.normal_mode["<C-b>"] = ":NvimTreeToggle<CR>"

-- Indent / Unindent
-- Conflicts with code folding
-- lvim.keys.normal_mode["<TAB>"] = ">>"
-- lvim.keys.normal_mode["<S-TAB>"] = "<<"

-- Telescope find keybinds
lvim.keys.normal_mode["<LEADER>ff"] = "<CMD>lua require('telescope').find_files()<CR>"
lvim.keys.normal_mode["<LEADER>fg"] = "<CMD>lua require('telescope').live_grep()<CR>"
lvim.keys.normal_mode["<LEADER>fb"] = "<CMD>lua require('telescope').buffers()<CR>"
lvim.keys.normal_mode["<LEADER>fh"] = "<CMD>lua require('telescope').help_tags()<CR>"

-- ToggleTerm
lvim.keys.normal_mode["<C-`>"] = ":ToggleTerm<CR>"

