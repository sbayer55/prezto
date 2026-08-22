-- Auto-session plugin for automatic session management
return {
  "rmagatti/auto-session",
  config = function()
    require("auto-session").setup({
      log_level = "error",
      enabled = true,
      auto_save = true,
      auto_restore = true,
      suppressed_dirs = {
        "~/",
        "~/Downloads",
        "~/Documents",
        "~/Desktop",
        "/",
      },
      git_use_branch_name = false,
      pre_save_cmds = {
        "NvimTreeClose",
      },
      post_restore_cmds = {},
      session_lens = {
        load_on_setup = true,
        picker_opts = { border = true },
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
