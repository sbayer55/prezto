-- See `:help vim.lsp.start` for an overview of the supported `config` options.
local jdtls_ok, jdtls = pcall(require, 'jdtls')
if not jdtls_ok then
  vim.notify('nvim-jdtls is not installed; Java LSP disabled', vim.log.levels.WARN)
  return
end

local jdtls_path = vim.fn.stdpath('data') .. "/mason/packages/jdtls"

-- jdtls ships one launcher config per platform; picking the wrong one makes
-- the server fail to start. It was hard-coded to config_linux.
local function config_dir()
  local candidates
  if vim.fn.has('win32') == 1 then
    candidates = { 'config_win_arm', 'config_win' }
  elseif vim.fn.has('mac') == 1 then
    candidates = { 'config_mac_arm', 'config_mac' }
  else
    candidates = { 'config_linux_arm', 'config_linux' }
  end

  for _, name in ipairs(candidates) do
    local path = jdtls_path .. '/' .. name
    if vim.fn.isdirectory(path) == 1 then
      return path
    end
  end
  return jdtls_path .. '/' .. candidates[#candidates]
end

local config_path = config_dir()
local plugins_path = jdtls_path .. "/plugins/"
local lombok_path = jdtls_path .. "/lombok.jar"
local project_name = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
local workspace_dir = vim.fn.expand('~/.cache/jdtls-workspace/') .. project_name

if vim.fn.isdirectory(jdtls_path) == 0 then
  vim.notify('jdtls is not installed; run :MasonInstall jdtls', vim.log.levels.WARN)
  return
end

if vim.fn.executable('java') == 0 then
  vim.notify('java is not on PATH; Java LSP disabled', vim.log.levels.WARN)
  return
end

-- Build the jdtls launch command from the Mason installation.
local function get_jdtls_cmd()
  local lombok_agent = vim.fn.filereadable(lombok_path) == 1
      and ('-javaagent:' .. lombok_path)
      or '-Djdtls.lombok.disabled=true'

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
    -- lombok is optional; passing a missing agent jar aborts the JVM.
    lombok_agent,

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
  root_dir = require('jdtls.setup').find_root({'.git', 'mvnw', 'gradlew', 'pom.xml', 'build.gradle'})
      or vim.fn.getcwd(),
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
jdtls.start_or_attach(config)

-- Add additional keybindings
-- Example keybindings for Java-specific actions
vim.keymap.set('n', '<leader>ji', "<cmd>lua require('jdtls').organize_imports()<CR>", { buffer = 0, desc = "Organize imports" })
vim.keymap.set('n', '<leader>jt', "<cmd>lua require('jdtls').test_class()<CR>", { buffer = 0, desc = "Test class" })
vim.keymap.set('n', '<leader>jn', "<cmd>lua require('jdtls').test_nearest_method()<CR>", { buffer = 0, desc = "Test nearest method" })
vim.keymap.set('n', '<leader>jc', "<cmd>lua require('jdtls').extract_constant()<CR>", { buffer = 0, desc = "Extract constant" })
vim.keymap.set('v', '<leader>jm', "<cmd>lua require('jdtls').extract_method(true)<CR>", { buffer = 0, desc = "Extract method" })
