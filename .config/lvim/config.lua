vim.opt.relativenumber = true

-- use treesitter folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

-- Add vim-visual-multi to plugins
lvim.plugins = {
    {
        "mg979/vim-visual-multi",
        branch = "master",
    }
}

-- File explorer
lvim.keys.normal_mode["<C-b>"] = false
lvim.keys.normal_mode["<C-b>"] = ":NvimTreeToggle<CR>"
lvim.keys.normal_mode["<C-1>"] = ":NvimTreeToggle<CR>"

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

-- Add indentation controls
lvim.keys.normal_mode["<Tab>"] = ">>"    -- Increase indentation
lvim.keys.normal_mode["<S-Tab>"] = "<<"  -- Decrease indentation
lvim.keys.visual_mode["<Tab>"] = ">gv"   -- Increase indentation and reselect visual selection
lvim.keys.visual_mode["<S-Tab>"] = "<gv" -- Decrease indentation and reselect visual selection

-- Window splitting
lvim.keys.normal_mode["<C-S-d>"] = ":vsplit<CR>"  -- Split window vertically

-- Line duplication
lvim.keys.normal_mode["<C-d>"] = "yyp"  -- Duplicate current line
lvim.keys.visual_mode["<C-d>"] = "y`>p" -- Duplicate selected lines

vim.g.VM_maps = {
    ["Find Under"] = "<C-n>",
    ["Find Subword Under"] = "<C-n>",
    -- ["Add Cursor Down"] = "<C-Down>",
    -- ["Add Cursor Up"] = "<C-Up>",
    ["Select All"] = "<C-S-a>",
    -- ["Skip Region"] = "<C-x>",
}
