-- See `:help vim.lsp.start_client` for an overview of the supported `config` options.
local jdtls_path = vim.fn.stdpath('data') .. "/mason/packages/jdtls"
local config_path = jdtls_path .. "/config_linux" -- or config_mac, config_win
local plugins_path = jdtls_path .. "/plugins/"
local lombok_path = jdtls_path .. "/lombok.jar"
local path_separator = vim.fn.has('win32') == 1 and ';' or ':'
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
local workspace_dir = vim.fn.expand('~/.cache/jdtls-workspace/') .. project_name

-- Get the mason jdtls installation directory
local function get_jdtls_cmd()
  local cmd = {
    'java',
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xms1g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens', 'java.base/java.util=ALL-UNNAMED',
    '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
    '-javaagent:' .. lombok_path,

    -- The jar file is located in the `plugins` directory
    '-jar', vim.fn.glob(plugins_path .. 'org.eclipse.equinox.launcher_*.jar'),

    -- The configuration for jdtls is in the config directory
    '-configuration', config_path,

    -- The workspace directory
    '-data', workspace_dir
  }
  return cmd
end

local config = {
  cmd = get_jdtls_cmd(),
  root_dir = require('jdtls.setup').find_root({'.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle'}),
  settings = {
    java = {
      signatureHelp = { enabled = true },
      contentProvider = { preferred = 'fernflower' },
      completion = {
        favoriteStaticMembers = {
          "org.hamcrest.MatcherAssert.assertThat",
          "org.hamcrest.Matchers.*",
          "org.hamcrest.CoreMatchers.*",
          "org.junit.jupiter.api.Assertions.*",
          "java.util.Objects.requireNonNull",
          "java.util.Objects.requireNonNullElse",
          "org.mockito.Mockito.*"
        },
        filteredTypes = {
          "com.sun.*",
          "io.micrometer.shaded.*",
          "java.awt.*",
          "jdk.*",
          "sun.*",
        },
      },
      sources = {
        organizeImports = {
          starThreshold = 9999,
          staticStarThreshold = 9999,
        },
      },
      codeGeneration = {
        toString = {
          template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}"
        },
        useBlocks = true,
      },
    }
  },
  init_options = {
    bundles = {}
  }
}

-- This starts a new client & server
require('jdtls').start_client(config)

-- Add additional keybindings
-- Example keybindings for Java-specific actions
vim.keymap.set('n', '<leader>ji', "<cmd>lua require('jdtls').organize_imports()<CR>", { buffer = 0, desc = "Organize imports" })
vim.keymap.set('n', '<leader>jt', "<cmd>lua require('jdtls').test_class()<CR>", { buffer = 0, desc = "Test class" })
vim.keymap.set('n', '<leader>jn', "<cmd>lua require('jdtls').test_nearest_method()<CR>", { buffer = 0, desc = "Test nearest method" })
vim.keymap.set('n', '<leader>jc', "<cmd>lua require('jdtls').extract_constant()<CR>", { buffer = 0, desc = "Extract constant" })
vim.keymap.set('v', '<leader>jm', "<cmd>lua require('jdtls').extract_method(true)<CR>", { buffer = 0, desc = "Extract method" })
