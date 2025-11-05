-- Color scheme configuration
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha", -- latte, frappe, macchiato, mocha
        transparent_background = false,
        term_colors = true,
        integrations = {
          nvimtree = true,
          treesitter = true,
          native_lsp = {
            enabled = true,
          },
        },
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },
}
