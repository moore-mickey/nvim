require("mason").setup {
  ui = {
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗"
    }
  }
}

-- `mason-tool-installer` was already in the plugin list but never configured,
-- so mason's packages were only ever installed by hand. Pin the ones this
-- config actually requires at load time; cortex-debug is the debug adapter
-- `custom.plugins.cortex_debug` looks for under `mason/share/`.
require("mason-tool-installer").setup {
  ensure_installed = { "cortex-debug" },
}
