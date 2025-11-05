-- LSP Configuration
return {
  -- Mason: LSP installer
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })
    end,
  },

  -- nvim-lspconfig: LSP configuration helper
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp", -- LSP completion source
    },
  },

  -- Mason LSP Config Bridge
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Diagnostic signs
      local signs = {
        { name = "DiagnosticSignError", text = "" },
        { name = "DiagnosticSignWarn", text = "" },
        { name = "DiagnosticSignHint", text = "" },
        { name = "DiagnosticSignInfo", text = "" },
      }

      for _, sign in ipairs(signs) do
        vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
      end

      -- Diagnostic configuration
      vim.diagnostic.config({
        virtual_text = true,
        signs = { active = signs },
        update_in_insert = true,
        underline = true,
        severity_sort = true,
        float = {
          focusable = false,
          style = "minimal",
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        },
      })

      -- Hover configuration
      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
        border = "rounded",
      })

      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
        border = "rounded",
      })

      -- LSP keybindings function
      local on_attach = function(client, bufnr)
        local keymap = vim.keymap.set
        local opts = { buffer = bufnr, silent = true }

        -- Navigation
        keymap("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
        keymap("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))
        keymap("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Go to implementation" }))
        keymap("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "Show references" }))
        keymap("n", "gt", vim.lsp.buf.type_definition, vim.tbl_extend("force", opts, { desc = "Go to type definition" }))

        -- Information
        keymap("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover documentation" }))
        keymap("n", "<C-k>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help" }))
        keymap("i", "<C-k>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help (insert)" }))

        -- Actions
        keymap("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
        keymap("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
        keymap("v", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action (visual)" }))

        -- Formatting
        keymap("n", "<leader>cf", function()
          vim.lsp.buf.format({ async = true })
        end, vim.tbl_extend("force", opts, { desc = "Format document" }))

        -- Diagnostics
        keymap("n", "[d", vim.diagnostic.goto_prev, vim.tbl_extend("force", opts, { desc = "Previous diagnostic" }))
        keymap("n", "]d", vim.diagnostic.goto_next, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))
        keymap("n", "<leader>d", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Show diagnostic" }))
        keymap("n", "<leader>dl", vim.diagnostic.setloclist, vim.tbl_extend("force", opts, { desc = "Diagnostic list" }))

        -- Workspace
        keymap("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, vim.tbl_extend("force", opts, { desc = "Add workspace folder" }))
        keymap("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, vim.tbl_extend("force", opts, { desc = "Remove workspace folder" }))
        keymap("n", "<leader>wl", function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, vim.tbl_extend("force", opts, { desc = "List workspace folders" }))

        -- Highlight symbol under cursor
        if client.server_capabilities.documentHighlightProvider then
          vim.api.nvim_create_augroup("lsp_document_highlight", { clear = false })
          vim.api.nvim_clear_autocmds({ buffer = bufnr, group = "lsp_document_highlight" })
          vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            group = "lsp_document_highlight",
            buffer = bufnr,
            callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            group = "lsp_document_highlight",
            buffer = bufnr,
            callback = vim.lsp.buf.clear_references,
          })
        end
      end

      -- Setup mason-lspconfig with handlers
      require("mason-lspconfig").setup({
        ensure_installed = {
          "solargraph", -- Ruby language server
          "lua_ls",     -- Lua (for Neovim config)
        },
        automatic_installation = true,
        handlers = {
          -- Default handler for all servers
          function(server_name)
            lspconfig[server_name].setup({
              capabilities = capabilities,
              on_attach = on_attach,
            })
          end,

          -- Custom handler for solargraph
          ["solargraph"] = function()
            lspconfig.solargraph.setup({
              capabilities = capabilities,
              on_attach = on_attach,
              settings = {
                solargraph = {
                  diagnostics = true,
                  formatting = true,
                  completion = true,
                  hover = true,
                  autoformat = false,
                  useBundler = true,
                },
              },
            })
          end,

          -- Custom handler for lua_ls
          ["lua_ls"] = function()
            lspconfig.lua_ls.setup({
              capabilities = capabilities,
              on_attach = on_attach,
              settings = {
                Lua = {
                  diagnostics = {
                    globals = { "vim" },
                  },
                  workspace = {
                    library = vim.api.nvim_get_runtime_file("", true),
                    checkThirdParty = false,
                  },
                  telemetry = {
                    enable = false,
                  },
                },
              },
            })
          end,
        },
      })
    end,
  },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",     -- LSP completion
      "hrsh7th/cmp-buffer",       -- Buffer completion
      "hrsh7th/cmp-path",         -- Path completion
      "hrsh7th/cmp-cmdline",      -- Command line completion
      "L3MON4D3/LuaSnip",         -- Snippet engine
      "saadparwaiz1/cmp_luasnip", -- Snippet completion
      "rafamadriz/friendly-snippets", -- Snippet collection
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      -- Load snippets
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp", priority = 1000 },
          { name = "luasnip", priority = 750 },
          { name = "buffer", priority = 500 },
          { name = "path", priority = 250 },
        }),
        formatting = {
          format = function(entry, vim_item)
            -- Kind icons
            local kind_icons = {
              Text = "",
              Method = "󰆧",
              Function = "󰊕",
              Constructor = "",
              Field = "󰇽",
              Variable = "󰂡",
              Class = "󰠱",
              Interface = "",
              Module = "",
              Property = "󰜢",
              Unit = "",
              Value = "󰎠",
              Enum = "",
              Keyword = "󰌋",
              Snippet = "",
              Color = "󰏘",
              File = "󰈙",
              Reference = "",
              Folder = "󰉋",
              EnumMember = "",
              Constant = "󰏿",
              Struct = "",
              Event = "",
              Operator = "󰆕",
              TypeParameter = "󰅲",
            }
            vim_item.kind = string.format("%s %s", kind_icons[vim_item.kind], vim_item.kind)
            vim_item.menu = ({
              nvim_lsp = "[LSP]",
              luasnip = "[Snippet]",
              buffer = "[Buffer]",
              path = "[Path]",
            })[entry.source.name]
            return vim_item
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
      })

      -- Command line completion
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })

      -- Search completion
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })
    end,
  },
}
