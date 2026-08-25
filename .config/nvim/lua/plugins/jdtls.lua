-- nvim-jdtls: required by ftplugin/java.lua, which calls require('jdtls').
-- jdtls itself is installed by Mason (see lua/plugins/lsp.lua) and needs a JDK
-- on PATH.
return {
  "mfussenegger/nvim-jdtls",
  ft = "java",
  dependencies = {
    "mason-org/mason.nvim",
  },
}
