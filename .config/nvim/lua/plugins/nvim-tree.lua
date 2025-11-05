-- File browser tree configuration
return {
  "nvim-tree/nvim-tree.lua",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    -- Disable netrw (recommended by nvim-tree)
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    require("nvim-tree").setup({
      sort_by = "case_sensitive",
      view = {
        width = 35,
        side = "left",
      },
      renderer = {
        group_empty = true,
        icons = {
          show = {
            file = true,
            folder = true,
            folder_arrow = true,
            git = true,
          },
        },
      },
      filters = {
        dotfiles = false,
        custom = { "^.git$" },
      },
      git = {
        enable = true,
        ignore = false,
      },
      actions = {
        open_file = {
          quit_on_open = false,
          window_picker = {
            enable = true,
          },
        },
      },
    })

    -- Key mappings for nvim-tree
    vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file explorer", silent = true })
    vim.keymap.set("n", "<leader>ef", ":NvimTreeFindFile<CR>", { desc = "Find current file in explorer", silent = true })
    vim.keymap.set("n", "<leader>ec", ":NvimTreeCollapse<CR>", { desc = "Collapse file explorer", silent = true })
    vim.keymap.set("n", "<leader>er", ":NvimTreeRefresh<CR>", { desc = "Refresh file explorer", silent = true })
  end,
}
