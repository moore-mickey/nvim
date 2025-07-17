return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
          library = {
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          },
        },
      },
    },
    config = function()
      local capabilities = require('blink.cmp').get_lsp_capabilities()
      local lspconfig = require("lspconfig")
      lspconfig.lua_ls.setup { capabilities = capabilities }
      -- This is needed now. Wasn't needed during Advent of Neovim, but they changed the default to false
      vim.diagnostic.config({
        virtual_text = true
      })

      lspconfig.clangd.setup({
        capabilities = capabilities,
        cmd = {
          'clangd',
          '--background-index',
          '--clang-tidy',
          '--log=verbose',
          '--query-driver=',
          '--query-driver=arm-none-eabi-gcc'
        },
        root_markers = {
          '.clangd',
          'compile_commands.json'
        },
        filetypes = { 'c', 'cpp', 'h', 'hpp' },
        init_options = {
          fallbackFlags = { '-std=c++17' },
        },
      })

      lspconfig.zls.setup({
        capabilities = capabilities,
        cmd = { 'zls' },
        settings = {
          zls = {
            semantics_tokens = "partial",
          }
        }
      })

      lspconfig.neocmake.setup({
        capabilities = capabilities,
        cmd = { 'neocmakelsp', '--stdio' },
        filetypes = { 'cmake' },
        root_dir = function(fname)
          -- return vim.fs.dirname(vim.fs.find('.git', {path = startpath, upward = true})[1])
          return lspconfig.util.find_git_ancestor(fname)
        end,

      })

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if not client then return end

          ---@diagnostic disable-next-line: missing-parameter
          if client:supports_method('textDocument/formatting') then
            -- Format the current buffer on save
            vim.api.nvim_create_autocmd('BufWritePre', {
              buffer = args.buf,
              callback = function()
                vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
              end,
            })
          end

          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = args.buf, desc = 'LSP: ' .. desc })
          end
          map('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
          map('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
          map('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
          map('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
          map('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
          map('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

          map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
        end,
      })
    end,
  }
}
