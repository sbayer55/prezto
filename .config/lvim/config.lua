vim.opt.relativenumber = true

-- use treesitter folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

-- File explorer
lvim.keys.normal_mode["<C-b>"] = false
lvim.keys.normal_mode["<C-b>"] = ":NvimTreeToggle<CR>"
lvim.keys.normal_mode["<C-1>"] = ":NvimTreeToggle<CR>"
-- vim.api.nvim_set_keymap("n", "<D-1>", ":NvimTreeToggle<CR>", { noremap = true, silent = true })

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

-- Diable code folding
vim.wo.foldenable = false

-- Override indent level
lvim.keys.normal_mode["<C-t>"] = function()
    local current_indent = vim.opt_local.shiftwidth:get()
    if current_indent == 4 then
        vim.opt_local.tabstop = 2
        vim.opt_local.shiftwidth = 2
        vim.opt_local.softtabstop = 2
    else
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
        vim.opt_local.softtabstop = 4
    end
end

