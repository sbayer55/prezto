-- Status line configuration
return {
  "nvim-lualine/lualine.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("lualine").setup({
      options = {
        icons_enabled = true,
        theme = "catppuccin", -- Matches your color scheme
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
        disabled_filetypes = {
          statusline = {},
          winbar = {},
        },
        ignore_focus = {},
        always_divide_middle = true,
        globalstatus = true, -- Single statusline for all windows
        refresh = {
          statusline = 1000,
          tabline = 1000,
          winbar = 1000,
        },
      },
      sections = {
        -- Left side
        lualine_a = { "mode" },
        lualine_b = {
          "branch",
          "diff",
          {
            "diagnostics",
            sources = { "nvim_diagnostic" },
            symbols = { error = " ", warn = " ", info = " ", hint = " " },
          },
        },
        lualine_c = {
          {
            "filename",
            file_status = true, -- Displays file status (readonly, modified)
            path = 1, -- 0: Just filename, 1: Relative path, 2: Absolute path
            shorting_target = 40,
            symbols = {
              modified = "[+]",
              readonly = "[-]",
              unnamed = "[No Name]",
            },
          },
        },
        -- Right side
        lualine_x = {
          {
            "encoding",
            fmt = function(str)
              return str:upper()
            end,
          },
          {
            "fileformat",
            symbols = {
              unix = "LF",
              dos = "CRLF",
              mac = "CR",
            },
          },
          "filetype",
        },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { "filename" },
        lualine_x = { "location" },
        lualine_y = {},
        lualine_z = {},
      },
      tabline = {},
      winbar = {},
      inactive_winbar = {},
      extensions = {
        "nvim-tree",
        "toggleterm",
        "lazy",
      },
    })
  end,
}
