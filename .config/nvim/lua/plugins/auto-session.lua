-- Auto-session plugin for automatic session management
return {
  "rmagatti/auto-session",
  config = function()
    require("auto-session").setup({
      -- Session save/restore on directory change
      log_level = "error",
      auto_session_enabled = true,
      auto_save_enabled = true,
      auto_restore_enabled = true,
      auto_session_suppress_dirs = {
        "~/",
        "~/Downloads",
        "~/Documents",
        "~/Desktop",
        "/",
      },
      auto_session_use_git_branch = false,

      -- Pre and post hooks
      pre_save_cmds = {
        "NvimTreeClose", -- Close nvim-tree before saving session
      },
      post_restore_cmds = {},

      -- Session lens (telescope integration)
      session_lens = {
        load_on_setup = true,
        theme_conf = { border = true },
        previewer = false,
      },
    })

    -- Key mappings for session management
    local keymap = vim.keymap.set
    keymap("n", "<leader>ss", ":SessionSave<CR>", { desc = "Save session" })
    keymap("n", "<leader>sr", ":SessionRestore<CR>", { desc = "Restore session" })
    keymap("n", "<leader>sd", ":SessionDelete<CR>", { desc = "Delete session" })
    keymap("n", "<leader>sf", ":Telescope session-lens search_session<CR>", { desc = "Find sessions" })
  end,
}
