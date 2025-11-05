-- Telescope fuzzy finder configuration
return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    -- Fuzzy finder algorithm which requires local dependencies to be built
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      cond = function()
        return vim.fn.executable("make") == 1
      end,
    },
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    telescope.setup({
      defaults = {
        prompt_prefix = " 🔍 ",
        selection_caret = " ➤ ",
        path_display = { "truncate" },
        file_ignore_patterns = {
          "node_modules",
          ".git/",
          "dist/",
          "build/",
          "target/",
          "%.lock",
        },
        mappings = {
          i = {
            ["<C-n>"] = actions.move_selection_next,
            ["<C-p>"] = actions.move_selection_previous,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-c>"] = actions.close,
            ["<Down>"] = actions.move_selection_next,
            ["<Up>"] = actions.move_selection_previous,
            ["<CR>"] = actions.select_default,
            ["<C-x>"] = actions.select_horizontal,
            ["<C-v>"] = actions.select_vertical,
            ["<C-t>"] = actions.select_tab,
            ["<C-u>"] = actions.preview_scrolling_up,
            ["<C-d>"] = actions.preview_scrolling_down,
            ["<PageUp>"] = actions.results_scrolling_up,
            ["<PageDown>"] = actions.results_scrolling_down,
            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
            ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            ["<C-l>"] = actions.complete_tag,
            ["<C-_>"] = actions.which_key, -- <C-/> to show key mappings
          },
          n = {
            ["<esc>"] = actions.close,
            ["<CR>"] = actions.select_default,
            ["<C-x>"] = actions.select_horizontal,
            ["<C-v>"] = actions.select_vertical,
            ["<C-t>"] = actions.select_tab,
            ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
            ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
            ["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
            ["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            ["j"] = actions.move_selection_next,
            ["k"] = actions.move_selection_previous,
            ["H"] = actions.move_to_top,
            ["M"] = actions.move_to_middle,
            ["L"] = actions.move_to_bottom,
            ["<Down>"] = actions.move_selection_next,
            ["<Up>"] = actions.move_selection_previous,
            ["gg"] = actions.move_to_top,
            ["G"] = actions.move_to_bottom,
            ["<C-u>"] = actions.preview_scrolling_up,
            ["<C-d>"] = actions.preview_scrolling_down,
            ["<PageUp>"] = actions.results_scrolling_up,
            ["<PageDown>"] = actions.results_scrolling_down,
            ["?"] = actions.which_key,
          },
        },
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width = 0.55,
            results_width = 0.8,
          },
          vertical = {
            mirror = false,
          },
          width = 0.87,
          height = 0.80,
          preview_cutoff = 120,
        },
        sorting_strategy = "ascending",
        winblend = 0,
        border = {},
        borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
        color_devicons = true,
        set_env = { ["COLORTERM"] = "truecolor" },
      },
      pickers = {
        find_files = {
          theme = "dropdown",
          previewer = false,
          hidden = false,
          find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
        },
        live_grep = {
          theme = "ivy",
        },
        buffers = {
          theme = "dropdown",
          previewer = false,
          initial_mode = "normal",
          mappings = {
            i = {
              ["<C-d>"] = actions.delete_buffer,
            },
            n = {
              ["dd"] = actions.delete_buffer,
            },
          },
        },
      },
      extensions = {},
    })

    -- Load fzf extension if available
    pcall(telescope.load_extension, "fzf")

    -- Key mappings for Telescope
    local keymap = vim.keymap.set
    local builtin = require("telescope.builtin")

    -- File pickers
    keymap("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
    keymap("n", "<leader>fg", builtin.git_files, { desc = "Find git files" })
    keymap("n", "<leader>fr", builtin.oldfiles, { desc = "Find recent files" })
    keymap("n", "<leader>fa", function()
      builtin.find_files({ hidden = true, no_ignore = true })
    end, { desc = "Find all files (including hidden)" })

    -- Search pickers
    keymap("n", "<leader>fw", builtin.live_grep, { desc = "Find word (grep)" })
    keymap("n", "<leader>fc", builtin.grep_string, { desc = "Find word under cursor" })

    -- Buffer pickers
    keymap("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })

    -- Vim pickers
    keymap("n", "<leader>fh", builtin.help_tags, { desc = "Find help tags" })
    keymap("n", "<leader>fk", builtin.keymaps, { desc = "Find keymaps" })
    keymap("n", "<leader>fm", builtin.marks, { desc = "Find marks" })
    keymap("n", "<leader>fo", builtin.vim_options, { desc = "Find vim options" })
    keymap("n", "<leader>ft", builtin.colorscheme, { desc = "Find colorscheme" })

    -- Git pickers
    keymap("n", "<leader>gc", builtin.git_commits, { desc = "Git commits" })
    keymap("n", "<leader>gb", builtin.git_branches, { desc = "Git branches" })
    keymap("n", "<leader>gs", builtin.git_status, { desc = "Git status" })

    -- LSP pickers (will work when LSP is set up)
    keymap("n", "<leader>fd", builtin.diagnostics, { desc = "Find diagnostics" })
    keymap("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "Find document symbols" })
    keymap("n", "<leader>fS", builtin.lsp_workspace_symbols, { desc = "Find workspace symbols" })

    -- Resume last picker
    keymap("n", "<leader>f<leader>", builtin.resume, { desc = "Resume last search" })

    -- Quick search in current buffer
    keymap("n", "<leader>/", builtin.current_buffer_fuzzy_find, { desc = "Search in current buffer" })

    -- Most commonly used: quick file finder with Ctrl+P (like VSCode)
    keymap("n", "<C-p>", builtin.find_files, { desc = "Find files (quick)" })
  end,
}
