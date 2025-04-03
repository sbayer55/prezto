-- init.lua for Neovim
-- Features:
-- - Lazy package manager
-- - LSP support for Java, Python, and C++
-- - File browser panel
-- - Custom keybindings for tab navigation

-- General settings
vim.g.mapleader = " "                  -- Set leader key to space
vim.g.maplocalleader = " "             -- Set local leader to space as well
vim.opt.number = true                  -- Show line numbers
vim.opt.relativenumber = true          -- Show relative line numbers
vim.opt.mouse = "a"                    -- Enable mouse support
vim.opt.clipboard = "unnamedplus"      -- Use system clipboard
vim.opt.breakindent = true             -- Enable break indent
vim.opt.undofile = true                -- Save undo history
vim.opt.ignorecase = true              -- Case-insensitive search
vim.opt.smartcase = true               -- Unless uppercase is present
vim.opt.signcolumn = "yes"             -- Always show sign column
vim.opt.updatetime = 250               -- Faster updates
vim.opt.timeoutlen = 300               -- Quicker timeout for key combinations
vim.opt.termguicolors = true           -- True color support
vim.opt.shiftwidth = 2                 -- Default indentation width
vim.opt.tabstop = 2                    -- Default tab width
vim.opt.expandtab = true               -- Use spaces instead of tabs
vim.opt.cursorline = true              -- Highlight current line
vim.opt.scrolloff = 8                  -- Keep 8 lines above/below cursor
vim.opt.sidescrolloff = 8              -- Keep 8 columns left/right of cursor

-- Install lazy.nvim if not already installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Tab navigation keybindings
vim.api.nvim_set_keymap('n', '[', ':tabprevious<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', ']', ':tabnext<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<leader>tn', ':tabnew<CR>', { noremap = true, silent = true, desc = "New tab" })

-- Plugin specifications
require("lazy").setup({
  -- Colorscheme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("tokyonight-moon")
    end,
  },

  -- Which-key for hotkey help
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
      require("which-key").setup({
        plugins = {
          spelling = {
            enabled = true,
          },
        },
        window = {
          border = "single",
          position = "bottom",
        },
      })
      
      -- Register group names for better organization
      local wk = require("which-key")
      wk.register({
        f = { name = "Find/Files" },
        b = { name = "Buffers" },
        c = { name = "Code" },
        g = { name = "Git" },
        l = { name = "LSP" },
        t = { name = "Tabs/Toggle" },
        s = { name = "Search/Symbol" },
      }, { prefix = "<leader>" })
    end,
  },

  -- nvim-cmp for command line completion
  {
    "hrsh7th/cmp-cmdline",
    dependencies = {
      "hrsh7th/nvim-cmp",
    },
    config = function()
      local cmp = require("cmp")
      
      -- Use nvim-cmp for cmdline '/'
      cmp.setup.cmdline('/', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = 'buffer' }
        }
      })
      
      -- Use nvim-cmp for cmdline ':'
      cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = 'path' }
        }, {
          { name = 'cmdline' }
        })
      })
    end,
  },

  -- Symbols-outline for listing functions and variables
  {
    "simrat39/symbols-outline.nvim",
    cmd = "SymbolsOutline",
    keys = {
      { "<leader>so", "<cmd>SymbolsOutline<CR>", desc = "Toggle symbols outline" },
    },
    config = function()
      require("symbols-outline").setup({
        width = 25,
        show_numbers = true,
        show_relative_numbers = true,
        show_symbol_details = true,
        keymaps = {
          close = {"<Esc>", "q"},
          goto_location = "<Cr>",
          focus_location = "o",
          hover_symbol = "<C-space>",
          rename_symbol = "r",
          code_actions = "a",
        },
        symbols = {
          File = {icon = "", hl = "TSURI"},
          Module = {icon = "", hl = "TSNamespace"},
          Namespace = {icon = "", hl = "TSNamespace"},
          Package = {icon = "", hl = "TSNamespace"},
          Class = {icon = "𝓒", hl = "TSType"},
          Method = {icon = "ƒ", hl = "TSMethod"},
          Property = {icon = "", hl = "TSMethod"},
          Field = {icon = "", hl = "TSField"},
          Constructor = {icon = "", hl = "TSConstructor"},
          Enum = {icon = "ℰ", hl = "TSType"},
          Interface = {icon = "ﰮ", hl = "TSType"},
          Function = {icon = "", hl = "TSFunction"},
          Variable = {icon = "", hl = "TSConstant"},
          Constant = {icon = "", hl = "TSConstant"},
          String = {icon = "𝓐", hl = "TSString"},
          Number = {icon = "#", hl = "TSNumber"},
          Boolean = {icon = "⊨", hl = "TSBoolean"},
          Array = {icon = "", hl = "TSConstant"},
          Object = {icon = "⦿", hl = "TSType"},
          Key = {icon = "🔐", hl = "TSType"},
          Null = {icon = "NULL", hl = "TSType"},
          EnumMember = {icon = "", hl = "TSField"},
          Struct = {icon = "𝓢", hl = "TSType"},
          Event = {icon = "🗲", hl = "TSType"},
          Operator = {icon = "+", hl = "TSOperator"},
          TypeParameter = {icon = "𝙏", hl = "TSParameter"}
        }
      })
    end,
  },

  -- Code minimap for navigation
  {
    "wfxr/minimap.vim",
    build = "cargo install --locked code-minimap",
    cmd = {"Minimap", "MinimapClose", "MinimapToggle", "MinimapRefresh", "MinimapUpdateHighlight"},
    keys = {
      { "<leader>tm", "<cmd>MinimapToggle<CR>", desc = "Toggle minimap" },
    },
    config = function()
      vim.g.minimap_width = 10
      vim.g.minimap_auto_start = 0
      vim.g.minimap_auto_start_win_enter = 0
    end,
  },

  -- File explorer
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "Toggle file explorer" },
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = true,
        enable_git_status = true,
        window = {
          width = 30,
        },
      })
    end,
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Find in files" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Find buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Find help" },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          mappings = {
            i = {
              ["<C-j>"] = "move_selection_next",
              ["<C-k>"] = "move_selection_previous",
            },
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      })
      require("telescope").load_extension("fzf")
    end,
  },

  -- LSP Configuration & Plugins
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- LSP Installation
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      
      -- Autocompletion
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-nvim-lsp-signature-help",
      
      -- Snippets
      "L3MON4D3/LuaSnip",
      "rafamadriz/friendly-snippets",
      
      -- Additional LSP utilities
      { "folke/neodev.nvim", opts = {} },
      "nvimdev/lspsaga.nvim",
    },
    config = function()
      -- Setup Mason for LSP, DAP, linters, and formatters
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          },
        },
      })
      
      -- Configure LSPs through Mason
      require("mason-lspconfig").setup({
        ensure_installed = {
          "jdtls",       -- Java
          "pyright",     -- Python
          "clangd",      -- C/C++
          "lua_ls",      -- Lua
        },
      })

      -- LSP keybindings
      local on_attach = function(client, bufnr)
        local lsp_keymap = function(mode, lhs, rhs, desc)
          if desc then
            desc = 'LSP: ' .. desc
          end
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, noremap = true, silent = true })
        end

        -- LSP actions
        lsp_keymap('n', 'gD', vim.lsp.buf.declaration, 'Go to declaration')
        lsp_keymap('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
        lsp_keymap('n', 'K', vim.lsp.buf.hover, 'Hover documentation')
        lsp_keymap('n', 'gi', vim.lsp.buf.implementation, 'Go to implementation')
        lsp_keymap('n', '<C-k>', vim.lsp.buf.signature_help, 'Signature help')
        lsp_keymap('n', '<leader>D', vim.lsp.buf.type_definition, 'Type definition')
        lsp_keymap('n', '<leader>rn', vim.lsp.buf.rename, 'Rename')
        lsp_keymap('n', '<leader>ca', vim.lsp.buf.code_action, 'Code action')
        lsp_keymap('n', 'gr', vim.lsp.buf.references, 'Go to references')
        
        -- Diagnostics
        lsp_keymap('n', '<leader>d', '<cmd>Lspsaga show_cursor_diagnostics<CR>', 'Show diagnostics')
        lsp_keymap('n', '[d', '<cmd>Lspsaga diagnostic_jump_prev<CR>', 'Previous diagnostic')
        lsp_keymap('n', ']d', '<cmd>Lspsaga diagnostic_jump_next<CR>', 'Next diagnostic')
        lsp_keymap('n', '<leader>q', vim.diagnostic.setloclist, 'Set location list')
      end

      -- Configure LSP capabilities with nvim-cmp
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      
      -- Configure LSPSaga
      require("lspsaga").setup({
        ui = {
          border = 'rounded',
        },
        symbol_in_winbar = {
          enable = true,
        },
        lightbulb = {
          enable = true,
          sign = true,
          virtual_text = false,
        },
      })

      -- Language servers
      local lspconfig = require('lspconfig')
      
      -- Lua LSP
      require("neodev").setup({})
      lspconfig.lua_ls.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = { globals = { 'vim' } },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
          },
        },
      })
      
      -- Python LSP
      lspconfig.pyright.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              diagnosticMode = "workspace",
              useLibraryCodeForTypes = true,
            },
          },
        },
      })
      
      -- C/C++ LSP
      lspconfig.clangd.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        cmd = {
          "clangd",
          "--background-index",
          "--suggest-missing-includes",
          "--clang-tidy",
          "--header-insertion=iwyu",
        },
      })

      -- Java LSP needs special setup with jdtls
      -- We'll configure it to attach when Java files are opened
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "java",
        callback = function()
          -- Message to remind to install jdtls separately
          vim.notify("Java LSP is handled by the jdtls plugin. Make sure it's installed with Mason.", vim.log.levels.INFO)
        end,
      })

      -- Set up nvim-cmp completion
      local cmp = require('cmp')
      local luasnip = require('luasnip')

      -- Add vscode snippet support
      require('luasnip.loaders.from_vscode').lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ 
            behavior = cmp.ConfirmBehavior.Replace,
            select = true 
          }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'nvim_lsp_signature_help' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path' },
        }),
        formatting = {
          format = function(entry, vim_item)
            vim_item.menu = ({
              nvim_lsp = "[LSP]",
              luasnip = "[Snippet]",
              buffer = "[Buffer]",
              path = "[Path]",
            })[entry.source.name]
            return vim_item
          end,
        },
      })
    end,
  },
  
  -- Better syntax highlighting with TreeSitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "c", "cpp", "java", "python", "lua", "vim", "vimdoc",
          "query", "markdown", "json", "yaml", "html", "css",
        },
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            scope_incremental = "<C-s>",
            node_decremental = "<C-backspace>",
          },
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["al"] = "@loop.outer",
              ["il"] = "@loop.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
              ["ai"] = "@conditional.outer",
              ["ii"] = "@conditional.inner",
            },
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              ["]f"] = "@function.outer",
              ["]c"] = "@class.outer",
            },
            goto_next_end = {
              ["]F"] = "@function.outer",
              ["]C"] = "@class.outer",
            },
            goto_previous_start = {
              ["[f"] = "@function.outer",
              ["[c"] = "@class.outer",
            },
            goto_previous_end = {
              ["[F"] = "@function.outer",
              ["[C"] = "@class.outer",
            },
          },
        },
      })
    end,
  },
  
  -- Git integration
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
      current_line_blame = true,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol',
        delay = 500,
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        
        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end
        
        -- Navigation
        map('n', ']h', function()
          if vim.wo.diff then return ']c' end
          vim.schedule(function() gs.next_hunk() end)
          return '<Ignore>'
        end, {expr=true, desc = "Next git hunk"})
        
        map('n', '[h', function()
          if vim.wo.diff then return '[c' end
          vim.schedule(function() gs.prev_hunk() end)
          return '<Ignore>'
        end, {expr=true, desc = "Previous git hunk"})
        
        -- Actions
        map('n', '<leader>gs', gs.stage_hunk, { desc = "Stage hunk" })
        map('n', '<leader>gr', gs.reset_hunk, { desc = "Reset hunk" })
        map('v', '<leader>gs', function() gs.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end, { desc = "Stage hunk" })
        map('v', '<leader>gr', function() gs.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end, { desc = "Reset hunk" })
        map('n', '<leader>gS', gs.stage_buffer, { desc = "Stage buffer" })
        map('n', '<leader>gu', gs.undo_stage_hunk, { desc = "Undo stage hunk" })
        map('n', '<leader>gR', gs.reset_buffer, { desc = "Reset buffer" })
        map('n', '<leader>gp', gs.preview_hunk, { desc = "Preview hunk" })
        map('n', '<leader>gb', function() gs.blame_line{full=true} end, { desc = "Blame line" })
        map('n', '<leader>gtb', gs.toggle_current_line_blame, { desc = "Toggle line blame" })
        map('n', '<leader>gd', gs.diffthis, { desc = "Diff this" })
        map('n', '<leader>gD', function() gs.diffthis('~') end, { desc = "Diff this ~" })
        map('n', '<leader>gtd', gs.toggle_deleted, { desc = "Toggle deleted" })
      end
    },
  },
  
  -- Highlight current word and references
  {
    "RRethy/vim-illuminate",
    event = "BufReadPost",
    opts = {
      delay = 100,
      large_file_cutoff = 2000,
      large_file_overrides = {
        providers = { "lsp" },
      },
    },
    config = function(_, opts)
      require("illuminate").configure(opts)
      
      -- Change the highlight style
      vim.api.nvim_set_hl(0, "IlluminatedWordText", { bg = "#3b4261" })
      vim.api.nvim_set_hl(0, "IlluminatedWordRead", { bg = "#3b4261" })
      vim.api.nvim_set_hl(0, "IlluminatedWordWrite", { bg = "#3b4261" })
      
      -- Add keymaps
      vim.keymap.set("n", "]]", function() require("illuminate").goto_next_reference() end, { desc = "Next reference" })
      vim.keymap.set("n", "[[", function() require("illuminate").goto_prev_reference() end, { desc = "Previous reference" })
    end,
    keys = {
      { "]]", desc = "Next reference" },
      { "[[", desc = "Previous reference" },
    },
  },
  
  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "tokyonight",
        globalstatus = true,
      },
      sections = {
        lualine_c = {
          { "filename", path = 1 }, -- Show relative path
        },
      },
    },
  },
  
  -- Indentation guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = {
        char = "│",
        tab_char = "│",
      },
      scope = { enabled = true },
      exclude = {
        filetypes = {
          "help",
          "alpha",
          "dashboard",
          "neo-tree",
          "Trouble",
          "trouble",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
          "lazyterm",
        },
      },
    },
  },
  
  -- Autopairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },
  
  -- Comment toggling
  {
    "numToStr/Comment.nvim",
    opts = {},
  },
})

-- Additional Java Specific Configuration
-- Create jdtls.lua setup file in your config directory
local jdtls_setup_file = vim.fn.stdpath("config") .. "/ftplugin/java.lua"

-- Check if the file exists, if not create it
if vim.fn.filereadable(jdtls_setup_file) == 0 then
  -- Create the ftplugin directory if it doesn't exist
  local ftplugin_dir = vim.fn.stdpath("config") .. "/ftplugin"
  if vim.fn.isdirectory(ftplugin_dir) == 0 then
    vim.fn.mkdir(ftplugin_dir, "p")
  end
  
  -- Write the JDTLS configuration to the file
  local jdtls_config = [[
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
]]

  -- Write the configuration to the file
  local file = io.open(jdtls_setup_file, "w")
  if file then
    file:write(jdtls_config)
    file:close()
    vim.notify("Created JDTLS configuration at " .. jdtls_setup_file, vim.log.levels.INFO)
  else
    vim.notify("Failed to create JDTLS configuration", vim.log.levels.ERROR)
  end
end

-- Add autocmds and other settings here
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    -- Trim trailing whitespace on save
    vim.cmd [[%s/\s\+$//e]]
  end,
})

-- Add a user command to manually trim trailing whitespace
vim.api.nvim_create_user_command("TrimWhitespace", function()
  local save_cursor = vim.fn.getpos(".")
  vim.cmd [[%s/\s\+$//e]]
  vim.fn.setpos(".", save_cursor)
  vim.notify("Trailing whitespace removed", vim.log.levels.INFO)
end, { desc = "Trim trailing whitespace" })

-- Show diagnostic signs in the sign column
local signs = { Error = "✘ ", Warn = "▲ ", Hint = "⚑ ", Info = "» " }
for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
end

-- Show diagnostics in a prettier way
vim.diagnostic.config({
  virtual_text = {
    prefix = '●', -- Could be '■', '▎', 'x'
  },
  severity_sort = true,
  float = {
    source = "always",
    border = "rounded",
  },
})

-- Print a message when the init.lua is loaded
vim.notify("Neovim configuration loaded", vim.log.levels.INFO)
