-- Treesitter configuration for better syntax highlighting and folding
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects", -- Better text objects
  },
  config = function()
    require("nvim-treesitter.configs").setup({
      -- Install parsers for these languages
      ensure_installed = {
        "ruby",
        "lua",
        "vim",
        "vimdoc",
        "python",
        "javascript",
        "typescript",
        "json",
        "yaml",
        "markdown",
        "markdown_inline",
        "bash",
        "html",
        "css",
      },

      -- Install parsers synchronously (only applied to `ensure_installed`)
      sync_install = false,

      -- Automatically install missing parsers when entering buffer
      auto_install = true,

      -- Highlight configuration
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },

      -- Indentation based on treesitter
      indent = {
        enable = true,
      },

      -- Incremental selection
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },

      -- Text objects
      textobjects = {
        select = {
          enable = true,
          lookahead = true, -- Automatically jump forward to textobj
          keymaps = {
            -- You can use the capture groups defined in textobjects.scm
            ["af"] = "@function.outer",
            ["if"] = "@function.inner",
            ["ac"] = "@class.outer",
            ["ic"] = "@class.inner",
            ["aa"] = "@parameter.outer",
            ["ia"] = "@parameter.inner",
          },
        },
        move = {
          enable = true,
          set_jumps = true, -- whether to set jumps in the jumplist
          goto_next_start = {
            ["]m"] = "@function.outer",
            ["]]"] = "@class.outer",
          },
          goto_next_end = {
            ["]M"] = "@function.outer",
            ["]["] = "@class.outer",
          },
          goto_previous_start = {
            ["[m"] = "@function.outer",
            ["[["] = "@class.outer",
          },
          goto_previous_end = {
            ["[M"] = "@function.outer",
            ["[]"] = "@class.outer",
          },
        },
      },
    })

    -- Set folding to use treesitter
    vim.opt.foldmethod = "expr"
    vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  end,
}
