-- Buffer/Tab management configuration
return {
  "akinsho/bufferline.nvim",
  version = "*",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("bufferline").setup({
      options = {
        mode = "buffers", -- set to "tabs" to only show tabpages instead
        numbers = "none", -- "none" | "ordinal" | "buffer_id" | "both"
        close_command = "bdelete! %d",
        right_mouse_command = "bdelete! %d",
        left_mouse_command = "buffer %d",
        middle_mouse_command = nil,
        indicator = {
          icon = "▎",
          style = "icon", -- 'icon' | 'underline' | 'none'
        },
        buffer_close_icon = "󰅖",
        modified_icon = "●",
        close_icon = "",
        left_trunc_marker = "",
        right_trunc_marker = "",
        max_name_length = 18,
        max_prefix_length = 15,
        truncate_names = true,
        tab_size = 18,
        diagnostics = "nvim_lsp",
        diagnostics_indicator = function(count, level)
          local icon = level:match("error") and " " or " "
          return " " .. icon .. count
        end,
        offsets = {
          {
            filetype = "NvimTree",
            text = "File Explorer",
            text_align = "center",
            separator = true,
          },
        },
        color_icons = true,
        show_buffer_icons = true,
        show_buffer_close_icons = true,
        show_close_icon = true,
        show_tab_indicators = true,
        persist_buffer_sort = true,
        separator_style = "thin", -- "slant" | "thick" | "thin" | { 'any', 'any' }
        enforce_regular_tabs = false,
        always_show_bufferline = true,
        hover = {
          enabled = true,
          delay = 200,
          reveal = { "close" },
        },
        sort_by = "insert_after_current",
      },
    })

    -- Key mappings for bufferline
    vim.keymap.set("n", "<leader>bp", ":BufferLinePick<CR>", { desc = "Pick buffer", silent = true })
    vim.keymap.set("n", "<leader>bc", ":BufferLinePickClose<CR>", { desc = "Pick buffer to close", silent = true })
    vim.keymap.set("n", "<leader>bh", ":BufferLineCloseLeft<CR>", { desc = "Close buffers to the left", silent = true })
    vim.keymap.set("n", "<leader>bl", ":BufferLineCloseRight<CR>", { desc = "Close buffers to the right", silent = true })
    vim.keymap.set("n", "<leader>bo", ":BufferLineCloseOthers<CR>", { desc = "Close other buffers", silent = true })
    vim.keymap.set("n", "<Tab>", ":BufferLineCycleNext<CR>", { desc = "Next buffer", silent = true })
    vim.keymap.set("n", "<S-Tab>", ":BufferLineCyclePrev<CR>", { desc = "Previous buffer", silent = true })
    vim.keymap.set("n", "<leader>b1", ":BufferLineGoToBuffer 1<CR>", { desc = "Go to buffer 1", silent = true })
    vim.keymap.set("n", "<leader>b2", ":BufferLineGoToBuffer 2<CR>", { desc = "Go to buffer 2", silent = true })
    vim.keymap.set("n", "<leader>b3", ":BufferLineGoToBuffer 3<CR>", { desc = "Go to buffer 3", silent = true })
    vim.keymap.set("n", "<leader>b4", ":BufferLineGoToBuffer 4<CR>", { desc = "Go to buffer 4", silent = true })
    vim.keymap.set("n", "<leader>b5", ":BufferLineGoToBuffer 5<CR>", { desc = "Go to buffer 5", silent = true })
  end,
}
