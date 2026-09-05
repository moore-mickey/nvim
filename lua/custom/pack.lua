-- Plugin management with Neovim's built-in plugin manager: |vim.pack| (0.12+).
--
-- Differences from lazy.nvim that shape this file:
--   * No dependency resolution -- every plugin is listed explicitly, and
--     dependencies are listed before the plugins that need them.
--   * No lazy loading -- plugins are added and configured eagerly. What used to
--     be `event = ...` / `ft = ...` / `keys = ...` is simply always loaded.
--   * No `build =` -- build steps run from the `PackChanged` autocmd below.
--   * The lockfile lives at `<stdpath('config')>/nvim-pack-lock.json` and is
--     managed by Nvim. Keep it under version control.
--
-- Useful commands:
--   :lua vim.pack.update()                  -- fetch updates, review, `:w` to apply
--   :lua vim.pack.update(nil, {offline=true}) -- just browse what is installed
--   :lua vim.pack.get()                     -- inspect managed plugins
--   :lua vim.pack.del({ 'name' })           -- remove a plugin from disk

if vim.fn.has("nvim-0.12") ~= 1 then
  error("custom.pack requires Neovim 0.12+ (vim.pack). Use custom.lazy on older versions.")
end

-- Set up mapleader and maplocalleader before plugins are added so that their
-- mappings are correct. Also a good place for other early settings.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local function gh(repo)
  return "https://github.com/" .. repo
end

-- Build hooks (lazy.nvim's `build = ...`). Registered before `vim.pack.add()`
-- so that they also fire on the very first install.
vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("custom-pack-build", { clear = true }),
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if kind ~= "install" and kind ~= "update" then
      return
    end

    if name == "telescope-fzf-native.nvim" then
      vim.notify("pack: building " .. name .. " ...")
      local out = vim.system({ "make" }, { cwd = ev.data.path, text = true }):wait()
      if out.code ~= 0 then
        vim.notify("pack: `make` failed for " .. name .. "\n" .. (out.stderr or ""), vim.log.levels.ERROR)
      end
    elseif name == "nvim-treesitter" then
      -- The command lives in the plugin, so make sure it is loaded first.
      if not ev.data.active then
        vim.cmd.packadd(name)
      end
      vim.cmd("TSUpdate")
    end
  end,
})

vim.pack.add({
  -- Colorscheme -------------------------------------------------------------
  { src = gh("scottmckendry/cyberdream.nvim") },

  -- Shared libraries (former lazy.nvim `dependencies`) -----------------------
  { src = gh("nvim-lua/plenary.nvim") },
  { src = gh("nvim-tree/nvim-web-devicons") },
  { src = gh("nvim-neotest/nvim-nio") },
  { src = gh("rafamadriz/friendly-snippets") },

  -- Tool management ----------------------------------------------------------
  { src = gh("mason-org/mason.nvim") },
  { src = gh("jay-babu/mason-nvim-dap.nvim") },
  { src = gh("WhoIsSethDaniel/mason-tool-installer.nvim") },

  -- Editing / UI -------------------------------------------------------------
  { src = gh("nvim-treesitter/nvim-treesitter") },
  { src = gh("windwp/nvim-autopairs") },
  { src = gh("echasnovski/mini.nvim") },
  { src = gh("danymat/neogen") },
  { src = gh("stevearc/oil.nvim") },
  -- NOTE: carried over from the lazy.nvim spec, which never called
  -- `require('gitsigns').setup()`. Add a config module if you want it active.
  { src = gh("lewis6991/gitsigns.nvim") },
  { src = gh("ThePrimeagen/harpoon"), version = "harpoon2" },

  -- Completion + LSP ---------------------------------------------------------
  { src = gh("saghen/blink.cmp"), version = vim.version.range("1.*") },
  { src = gh("neovim/nvim-lspconfig") },
  { src = gh("folke/lazydev.nvim") },

  -- Telescope ----------------------------------------------------------------
  { src = gh("nvim-telescope/telescope.nvim"), version = "master" },
  { src = gh("nvim-telescope/telescope-fzf-native.nvim") },

  -- Debugging ----------------------------------------------------------------
  { src = gh("mfussenegger/nvim-dap") },
  { src = gh("rcarriga/nvim-dap-ui") },
  { src = gh("leoluz/nvim-dap-go") },
  { src = gh("theHamsta/nvim-dap-virtual-text") },
  { src = gh("jedrzejboczar/nvim-dap-cortex-debug") },
})

pcall(vim.cmd.colorscheme, "cyberdream")

-- Plugin configuration. Order matters: dependencies configure first, and each
-- module is isolated so a single broken config does not abort the whole init.
local configs = {
  "mason",
  "blink",
  "lsp",
  "telescope",
  "treesitter",
  "mini",
  "oil",
  "harpoon",
  "autopairs",
  "doxygen",
  "dap",
}

for _, name in ipairs(configs) do
  local mod = "custom.plugins." .. name
  local ok, err = pcall(require, mod)
  if not ok then
    vim.notify(("pack: failed to load %s\n%s"):format(mod, err), vim.log.levels.ERROR)
  end
end
