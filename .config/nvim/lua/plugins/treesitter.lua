-- Treesitter: pinned to the last main-branch commit that supports Neovim 0.11.
-- The master branch is archived and has a completely different API.
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  commit = "90cd6580e720caedacb91fdd587b747a6e77d61f",
  build = ":TSUpdate",
  lazy = false,
  priority = 1000,
  config = function()
    local languages = {
      "bash",
      "css",
      "html",
      "javascript",
      "json",
      "lua",
      "markdown",
      "markdown_inline",
      "python",
      "ruby",
      "tsx",
      "typescript",
      "vim",
      "vimdoc",
      "yaml",
    }

    require("nvim-treesitter").setup({
      install_dir = vim.fn.stdpath("data") .. "/site",
    })

    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })

    vim.opt.foldmethod = "expr"
    vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"

    vim.defer_fn(function()
      require("nvim-treesitter").install(languages)
    end, 100)
  end,
}
