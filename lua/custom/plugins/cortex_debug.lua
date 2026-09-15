-- Embedded ARM debugging via the cortex-debug VS Code extension.
--
-- The extension's debug adapter is plain Node, so nvim-dap can drive it
-- directly. `nvim-dap-cortex-debug` supplies the adapter definition plus the
-- GDB-server console, RTT terminals and the memory viewer.
--
--   :checkhealth dap-cortex-debug     node + adapter discovery
--   :CortexDebugMemory <addr> <len>   memory viewer
--   :CortexDebugVarHexModeToggle      hex/natural variable formatting
--
-- Projects that already carry a cortex-debug `.vscode/launch.json` need no
-- setup here: nvim-dap reads launch.json on demand, and `normalize_launch_json`
-- below applies the same key rewrites the VS Code frontend would have.

local dap = require("dap")
local cortex = require("dap-cortex-debug")

local M = {}

-- Highest-sorting glob match, so a toolchain or IDE version bump does not need
-- an edit here. `reject` drops decoys such as a `...-backup` copy sitting next
-- to the real install.
---@param pattern string
---@param reject? string Lua pattern; matching paths are skipped
---@return string? Path without a trailing separator
local function newest_match(pattern, reject)
  local hits = vim.fn.glob(pattern, false, true)
  for i = #hits, 1, -1 do
    local hit = hits[i]
    if not (reject and hit:match(reject)) then
      local last = hit:sub(-1)
      return (last == "/" or last == "\\") and hit:sub(1, -2) or hit
    end
  end
end

-- Mason installs the extension as the `cortex-debug` package; fall back to a
-- VS Code install so a machine without mason still works.
local function extension_path()
  local mason = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "share", "cortex-debug")
  for _, path in ipairs({ mason, "$USERPROFILE/.vscode/extensions/marus25.cortex-debug-*" }) do
    local hit = newest_match(path)
    if hit and vim.fn.filereadable(vim.fs.joinpath(hit, "dist", "debugadapter.js")) == 1 then
      return hit
    end
  end
  -- Let the plugin report the failure through :checkhealth rather than erroring
  -- at startup on a machine that has no ARM debugging set up.
end

-- PEmicro's GDB server ships inside S32 Design Studio.
local function pemicro_server()
  return vim.env.PEMICRO_GDBSERVER
    or newest_match("C:/NXP/S32DS.*/eclipse/plugins/com.pemicro.debug.gdbjtag.pne_*/win32/pegdbserver_console.exe")
    or "pegdbserver_console.exe"
end

-- Bare-metal toolchain. cortex-debug joins this with `toolchainPrefix` and
-- appends `.exe` itself, so this is the `bin` directory, not the gdb binary.
local function arm_toolchain()
  return vim.env.ARM_TOOLCHAIN_PATH
    or newest_match("C:/cab_repos/CMakeForge/Compilers/Windows/gcc-arm-none-eabi-*/bin", "backup")
end

cortex.setup({
  extension_path = extension_path(),
})

-- The adapter bundle console.log()s in a handful of places -- notably every
-- time the PEmicro server type resolves its binary -- which lands in the middle
-- of the DAP stream it carries on stdout and kills nvim-dap's rpc parser. The
-- preload moves the console to stderr; see the script for the gory details.
local console_fix = vim.fs.joinpath(vim.fn.stdpath("config"), "scripts", "cortex-debug-console-to-stderr.js")

-- The adapter interpolates the binary's path straight into the MI command
-- `-file-exec-and-symbols "<path>"` with no escaping, and gdb reads that string
-- with C escape rules. It also resolves a relative path with node's path.join
-- first, which on Windows hands back "C:\Projects\..." -- gdb then swallows the
-- \P, \c and \a and reports the file missing. Absolute and forward-slashed
-- sidesteps both: path.isAbsolute() short-circuits the join, and there is
-- nothing left for gdb to treat as an escape.
---@param path string
---@param cwd string?
---@return string
local function gdb_path(path, cwd)
  path = vim.fs.normalize(path)
  if cwd and not path:match("^%a:") and not path:match("^/") then
    path = vim.fs.normalize(vim.fs.joinpath(vim.fs.normalize(cwd), path))
  end
  return path
end

---@param config dap.Configuration
local function fix_gdb_paths(config)
  if type(config.executable) == "string" then
    config.executable = gdb_path(config.executable, config.cwd)
  end
  -- `symbolFiles` is the multi-binary alternative to `executable`; its entries
  -- reach gdb through the same unescaped interpolation.
  for _, entry in ipairs(config.symbolFiles or {}) do
    if type(entry.file) == "string" then
      entry.file = gdb_path(entry.file, config.cwd)
    end
  end
end

local cortex_adapter = dap.adapters["cortex-debug"]
dap.adapters["cortex-debug"] = function(callback, config)
  cortex_adapter(function(adapter)
    adapter.args = vim.list_extend({ "--require", console_fix }, adapter.args)
    -- Hook in ahead of the plugin's own validation, which runs here too. This
    -- is the first point where nvim-dap has finished expanding
    -- ${workspaceFolder} and evaluating function options, so `cwd` is a real
    -- directory and `executable` a real path.
    local enrich_config = adapter.enrich_config
    adapter.enrich_config = function(conf, on_config)
      fix_gdb_paths(conf)
      enrich_config(conf, on_config)
    end
    callback(adapter)
  end, config)
end

--- Launch config for a PEmicro probe. `device` is required by the `pe` server
--- type; run `pegdbserver_console.exe -devicelist` for the accepted names.
---@param overrides table
---@return table
function M.pe_config(overrides)
  return vim.tbl_deep_extend("force", {
    type = "cortex-debug",
    request = "launch",
    servertype = "pe",
    serverpath = pemicro_server(),
    toolchainPath = arm_toolchain(),
    toolchainPrefix = "arm-none-eabi",
    cwd = "${workspaceFolder}",
    runToEntryPoint = "main",
    swoConfig = { enabled = false },
    rttConfig = cortex.rtt_config(),
  }, overrides or {})
end

-- cortex-debug's VS Code frontend renames several launch.json keys before
-- handing the config to the adapter, and nvim-dap-cortex-debug hard-errors on
-- the old names. Rewrite them so a project's launch.json can stay exactly as
-- VS Code wants it.
local aliases = {
  armToolchainPath = "toolchainPath",
  debugger_args = "debuggerArgs",
  jlinkpath = "serverpath",
  jlinkInterface = "interface",
  openOCDPath = "serverpath",
  runToMain = "runToEntryPoint",
}

---@param config dap.Configuration
local function normalize_launch_json(config)
  if config.type ~= "cortex-debug" then
    return
  end
  for old, new in pairs(aliases) do
    if config[old] ~= nil then
      if config[new] == nil then
        config[new] = config[old]
      end
      config[old] = nil
    end
  end
  -- `runToMain` was a boolean; its replacement names the symbol.
  if config.runToEntryPoint == true then
    config.runToEntryPoint = "main"
  elseif config.runToEntryPoint == false then
    config.runToEntryPoint = nil
  end
  -- Fill in only what the project left unset.
  config.toolchainPath = config.toolchainPath or arm_toolchain()
  if config.servertype == "pe" then
    config.serverpath = config.serverpath or pemicro_server()
  end
end

-- Wrap rather than replace, so this keeps working if nvim-dap changes how
-- launch.json is parsed. Configs are re-read on every `dap.continue()`, so
-- mutating in place here cannot go stale.
local read_launch_json = dap.providers.configs["dap.launch.json"]
dap.providers.configs["dap.launch.json"] = function(bufnr)
  local configs = read_launch_json(bufnr)
  for _, config in ipairs(configs) do
    normalize_launch_json(config)
  end
  return configs
end

-- Fallback for projects with no launch.json: find the firmware ourselves.
local function pick_elf()
  local cwd = vim.fn.getcwd()
  local elfs = vim.fn.glob(cwd .. "/build/**/*.elf", false, true)
  if #elfs == 0 then
    elfs = vim.fn.glob(cwd .. "/**/*.elf", false, true)
  end
  if #elfs == 0 then
    return vim.fn.input("Path to .elf: ", cwd .. "/", "file")
  elseif #elfs == 1 then
    return elfs[1]
  end
  local co, ismain = coroutine.running()
  local ui = require("dap.ui")
  local pick = (co and not ismain) and ui.pick_one or ui.pick_one_sync
  return pick(elfs, "Select .elf: ", function(path)
    return vim.fn.fnamemodify(path, ":.")
  end) or dap.ABORT
end

local function find_svd()
  return vim.fn.glob(vim.fn.getcwd() .. "/*.svd", false, true)[1]
end

local launch = M.pe_config({
  name = "Cortex: launch with PEmicro",
  device = "NXP_S32K3xx_S32K311",
  executable = pick_elf,
  svdFile = find_svd,
})

-- Attaching leaves the target wherever it already is, so there is no entry
-- point to run to. `tbl_deep_extend` cannot express "drop this key".
local attach = M.pe_config(vim.tbl_extend("force", launch, {
  name = "Cortex: attach with PEmicro",
  request = "attach",
}))
attach.runToEntryPoint = nil

local cortex_configs = { launch, attach }

for _, ft in ipairs({ "c", "cpp" }) do
  dap.configurations[ft] = vim.list_extend(dap.configurations[ft] or {}, cortex_configs)
end

return M
