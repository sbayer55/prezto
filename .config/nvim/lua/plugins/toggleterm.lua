-- Terminal management configuration
return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.4
        end
      end,
      open_mapping = [[<c-\>]],
      hide_numbers = true,
      shade_terminals = true,
      shading_factor = 2,
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      persist_size = true,
      persist_mode = true,
      direction = "float", -- 'vertical' | 'horizontal' | 'tab' | 'float'
      close_on_exit = true,
      shell = vim.o.shell,
      auto_scroll = true,
      float_opts = {
        border = "curved", -- 'single' | 'double' | 'shadow' | 'curved'
        winblend = 0,
        highlights = {
          border = "Normal",
          background = "Normal",
        },
      },
      winbar = {
        enabled = false,
      },
    })

    -- Terminal key mappings
    function _G.set_terminal_keymaps()
      local opts = { buffer = 0 }
      vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
      vim.keymap.set("t", "jk", [[<C-\><C-n>]], opts)
      vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
      vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
      vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
      vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
      vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], opts)
    end

    vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")

    -- Custom terminal commands
    local Terminal = require("toggleterm.terminal").Terminal

    -- Horizontal terminal
    vim.keymap.set("n", "<leader>th", function()
      local term = Terminal:new({ direction = "horizontal" })
      term:toggle()
    end, { desc = "Open horizontal terminal", silent = true })

    -- Vertical terminal
    vim.keymap.set("n", "<leader>tv", function()
      local term = Terminal:new({ direction = "vertical" })
      term:toggle()
    end, { desc = "Open vertical terminal", silent = true })

    -- Float terminal
    vim.keymap.set("n", "<leader>tf", function()
      local term = Terminal:new({ direction = "float" })
      term:toggle()
    end, { desc = "Open floating terminal", silent = true })

    -- Lazygit terminal
    local lazygit = Terminal:new({
      cmd = "lazygit",
      dir = "git_dir",
      direction = "float",
      float_opts = {
        border = "double",
      },
      on_open = function(term)
        vim.cmd("startinsert!")
        vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
      end,
    })

    vim.keymap.set("n", "<leader>tg", function()
      lazygit:toggle()
    end, { desc = "Open lazygit", silent = true })

    -- Python REPL
    local python = Terminal:new({
      cmd = "python3",
      direction = "float",
      close_on_exit = false,
    })

    vim.keymap.set("n", "<leader>tp", function()
      python:toggle()
    end, { desc = "Open Python REPL", silent = true })
  end,
}
