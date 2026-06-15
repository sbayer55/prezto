-- Treesitter configuration for better syntax highlighting and folding
return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  lazy = false,
  priority = 1000,
  config = function()
    -- Install parsers for these languages
    local ensure_installed = {
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
    }

    -- Install missing parsers on startup
    local function ensure_parsers_installed()
      for _, lang in ipairs(ensure_installed) do
        local ok = pcall(vim.treesitter.language.inspect, lang)
        if not ok then
          pcall(vim.cmd, "TSInstall " .. lang)
        end
      end
    end

    vim.defer_fn(ensure_parsers_installed, 100)

    -- Enable treesitter-based highlighting
    vim.api.nvim_create_autocmd("FileType", {
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })

    -- Set folding to use treesitter
    vim.opt.foldmethod = "expr"
    vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  end,
}
