-- neovim/nvim-lspconfig (+ folke/lazydev.nvim)

-- lazydev was a lazy.nvim dependency with `ft = 'lua'`; it only kicks in for
-- Lua buffers anyway, so setting it up eagerly is equivalent.
require('lazydev').setup {
  library = {
    { path = "${3rd}/luv/library", words = { "vim%.uv" } },
  },
}

local capabilities = require('blink.cmp').get_lsp_capabilities()

vim.lsp.enable('lua_ls')
vim.diagnostic.config({
  virtual_text = true
})

--- clangd / C / C++ / CPP / CXX LSP
vim.lsp.config('clangd',
  {
    capabilities = capabilities,
    cmd = {
      'clangd',
      '--background-index',
      '--clang-tidy',
      '--log=verbose',
      '--header-insertion=iwyu',
      '--limit-results=0',
      -- '--query-driver=arm-none-eabi'
      -- '--compile-commands-dir=build'
    },
    root_markers = {
      -- '.clang-tidy',
      -- '.clang-format',
      -- 'compile_commands.json',
      '.clangd',
      -- 'compile_flags.txt',
      -- '.git'
    },
    filetypes = { 'c', 'cpp', },
    init_options = {
      fallbackFlags = { '-std=c++20' },
    },
  })
vim.lsp.enable('clangd')

--- Zig LSP
vim.lsp.config('zls',
  {
    capabilities = capabilities,
    cmd = { 'C:/tools/zls/zls/zig-out/bin/zls.exe' },
    settings = {
      zls = {
        semantics_tokens = "partial",
      }
    }
  })
vim.lsp.enable('zls')

--- CMake LSP
vim.lsp.config('neocmakelsp',
  {
    capabilities = capabilities,
    cmd = { 'neocmakelsp', '--stdio' },
    filetypes = { 'cmake' },
    -- root_dir = function(fname)
    --   return vim.lsp.util.root_pattern(unpack({ '.git', 'build', 'cmake' }))(fname)
    -- end,
    init_options = {
      format = {
        enable = true
      },
      lint = {
        enable = true
      }
    }
  })
vim.lsp.enable('neocmakelsp')

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

    local builtin = require('telescope.builtin')

    map('gd', builtin.lsp_definitions, '[G]oto [D]efinition')
    map('gr', builtin.lsp_references, '[G]oto [R]eferences')
    map('gI', builtin.lsp_implementations, '[G]oto [I]mplementation')
    map('<leader>D', builtin.lsp_type_definitions, 'Type [D]efinition')
    map('<leader>dS', builtin.lsp_document_symbols, '[D]ocument [S]ymbols')
    map('<leader>ws', builtin.lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

    map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')
    -- vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {buffer = 0})

    map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
    map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

    vim.keymap.set('n', '<leader>do', function()
      vim.diagnostic.open_float { border = "single", max_width = 120, max_height = 50 }
    end, { desc = 'Floating [D]iagnostics [O]pen' })
    vim.keymap.set('n', '<leader>oh', function()
      vim.lsp.buf.hover { border = "single", max_width = 120, max_height = 50 }
    end, { desc = '[O]pen [H]over' })
  end,
})
