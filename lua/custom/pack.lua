-- Plugin management via Neovim's built-in manager. See `:help vim.pack`.
--
-- Plugins are cloned into `stdpath("data")/site/pack/core/opt` and their exact
-- revisions are tracked in `nvim-pack-lock.json` next to this config.
--
--   :lua vim.pack.update()                          update all, review, `:w` to accept / `:q` to discard
--   :lua vim.pack.update({ "oil.nvim" })            update one
--   :lua vim.pack.update(nil, { offline = true })   browse what is installed, no network
--   :lua vim.pack.del({ "oil.nvim" })               remove from disk
--   :lua =vim.pack.get()                            inspect managed plugins

-- Leader must be set before plugins load so their mappings resolve correctly.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local gh = function(repo)
  return "https://github.com/" .. repo
end

-- Run `fn` now if Nvim has finished starting, otherwise once it has. Build
-- steps need the plugin's `plugin/` files sourced, which only happens after
-- init.lua is done.
local function when_ready(fn)
  if vim.v.vim_did_enter == 1 then
    return fn()
  end
  vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = fn })
end

local pack_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt")

-- Blocking on purpose: a build has to finish before anything `require`s the
-- plugin it belongs to.
local function make(name)
  local out = vim.system({ "make" }, { cwd = vim.fs.joinpath(pack_dir, name), text = true }):wait()
  if out.code ~= 0 then
    vim.notify(name .. ": `make` failed\n" .. (out.stderr or ""), vim.log.levels.ERROR)
  end
end

local function fzf_native_is_built()
  local dir = vim.fs.joinpath(pack_dir, "telescope-fzf-native.nvim", "build")
  for _, lib in ipairs({ "libfzf.dll", "libfzf.so", "libfzf.dylib" }) do
    if vim.uv.fs_stat(vim.fs.joinpath(dir, lib)) then
      return true
    end
  end
  return false
end

-- Replaces lazy.nvim's `build = ...`. Registered before `vim.pack.add()` below
-- so the hooks also fire on a first-time install.
local build = {
  ["telescope-fzf-native.nvim"] = function()
    make("telescope-fzf-native.nvim")
  end,
  ["nvim-treesitter"] = function()
    when_ready(function() vim.cmd.TSUpdate() end)
  end,
}

vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("custom-pack-build", { clear = true }),
  callback = function(ev)
    if ev.data.kind ~= "install" and ev.data.kind ~= "update" then
      return
    end
    local hook = build[ev.data.spec.name]
    if hook then
      hook(ev.data.path)
    end
  end,
})

-- One `add()` call so first-time installs all clone in parallel.
vim.pack.add({
  -- Colorscheme
  gh("scottmckendry/cyberdream.nvim"),

  -- Editing / UI
  gh("echasnovski/mini.nvim"),
  gh("stevearc/oil.nvim"),
  gh("nvim-tree/nvim-web-devicons"),
  gh("windwp/nvim-autopairs"),
  gh("lewis6991/gitsigns.nvim"), -- self-initializes via its own plugin/ file
  gh("danymat/neogen"),
  { src = gh("ThePrimeagen/harpoon"), version = "harpoon2" },

  -- Treesitter: the config below uses the `main` branch API, so pin it there
  -- rather than following whatever the default branch becomes.
  { src = gh("nvim-treesitter/nvim-treesitter"), version = "main" },

  -- Completion. Tagged releases ship prebuilt fuzzy-matcher binaries.
  { src = gh("saghen/blink.cmp"), version = vim.version.range("1.*") },
  gh("rafamadriz/friendly-snippets"),

  -- LSP
  gh("neovim/nvim-lspconfig"),
  gh("folke/lazydev.nvim"),

  -- Telescope
  { src = gh("nvim-telescope/telescope.nvim"), version = "master" },
  gh("nvim-lua/plenary.nvim"),
  gh("nvim-telescope/telescope-fzf-native.nvim"),

  -- Tooling / debugging
  gh("mason-org/mason.nvim"),
  gh("mfussenegger/nvim-dap"),
  gh("rcarriga/nvim-dap-ui"),
  gh("theHamsta/nvim-dap-virtual-text"),
  gh("nvim-neotest/nvim-nio"),
  gh("leoluz/nvim-dap-go"),
  gh("jay-babu/mason-nvim-dap.nvim"),
  gh("WhoIsSethDaniel/mason-tool-installer.nvim"),
  gh("jedrzejboczar/nvim-dap-cortex-debug"),
}, {
  -- Install without prompting, the way lazy.nvim used to. Progress is still
  -- reported, and `vim.pack.update()` always asks before changing anything.
  confirm = false,
})

-- Safety net. During a bulk first install `PackChanged` does not reliably fire
-- for every plugin, and telescope's `load_extension("fzf")` further down hard
-- errors if the compiled library is missing. Cheap stat, so just check.
if not fzf_native_is_built() then
  make("telescope-fzf-native.nvim")
end

-- `vim.pack` has no dependency graph, so configure in dependency order:
-- treesitter before neogen, blink before lsp (capabilities), mason before dap.
for _, mod in ipairs({
  "colorscheme",
  "mini",
  "treesitter",
  "blink",
  "lsp",
  "telescope",
  "oil",
  "harpoon",
  "autopairs",
  "doxygen",
  "mason",
  "dap",
}) do
  require("custom.plugins." .. mod)
end
