-- Color scheme configuration
return {
  {
    "tanvirtin/monokai.nvim",
    priority = 1000,
    config = function()
      require("monokai").setup({
        palette = require("monokai").pro,  -- Options: classic, pro, soda, ristretto
        -- Custom colors (optional)
        custom_hlgroups = {
          -- Match fold column background to editor background
          FoldColumn = { bg = "NONE" },
          -- Also customize fold text appearance if needed
          Folded = { bg = "#2d2a2e", fg = "#727072" },  -- Slightly darker than background
        },
      })
      vim.cmd.colorscheme("monokai")

      -- Get the cursor color (usually from Normal highlight group)
      local cursor_color = vim.api.nvim_get_hl(0, { name = "Cursor" })
      local cursor_bg = cursor_color.bg or "#FFFFFF"

      -- Get the line number color
      local linenr_color = vim.api.nvim_get_hl(0, { name = "LineNr" })
      local linenr_fg = linenr_color.fg or "#727072"

      -- Additional customizations
      vim.api.nvim_set_hl(0, "FoldColumn", { bg = "NONE", fg = string.format("#%06x", linenr_fg) })
      vim.api.nvim_set_hl(0, "MatchParen", {
        bg = string.format("#%06x", cursor_bg),
        fg = "#000000",
        bold = true
      })
    end,
  },
}
