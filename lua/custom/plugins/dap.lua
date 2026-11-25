local dap = require("dap")
local ui = require("dapui")
local launch_target = require("custom.launch_target")

-- `mason.setup()` lives in custom.plugins.mason, which pack.lua loads first.
require("mason-nvim-dap").setup();

ui.setup()
require("dap-go").setup()

require("nvim-dap-virtual-text").setup {}

dap.adapters.gdb = {
  type = "executable",
  -- command = "gdb",
  command = "C:\\Users\\bmoore\\Downloads\\gdb-17.1-2-x86_64.pkg\\usr\\bin\\gdb.exe",
  args = { "--interpreter=dap", "--eval-command", } --"set print pretty on" }

}

dap.configurations.c = {
  {
    name = "Launch",
    type = "gdb",
    request = "launch",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '\\', 'file')
    end,
    args = {}, -- provide arguments if needed
    cwd = "${workspaceFolder}",
    stopAtBeginningOfMainSubprogram = false,
  },
  {
    name = "Select and attach to process",
    type = "gdb",
    request = "attach",
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '\\', 'file')
    end,
    pid = function()
      local name = vim.fn.input('Executable name (filter): ')
      return require("dap.utils").pick_process({ filter = name })
    end,
    cwd = '${workspaceFolder}',
  },
  {
    name = 'Attach to gdbserver :1234',
    type = 'gdb',
    request = 'attach',
    target = 'localhost:1234',
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '\\', 'file')
    end,
    cwd = '${workspaceFolder}',
  },
}

-- launch.json names the binary with CMake Tools' launch target, which nvim-dap
-- cannot resolve. Swap in a function, so the pick happens only once a config
-- is actually run rather than whenever the config list is read.
local function defer_launch_target(value)
  if type(value) == "string" and value:find(launch_target.VARIABLE, 1, true) then
    return function()
      return launch_target.expand(value)
    end
  elseif type(value) == "table" then
    for key, item in pairs(value) do
      value[key] = defer_launch_target(item)
    end
  end
  return value
end

local read_launch_json = dap.providers.configs["dap.launch.json"]
dap.providers.configs["dap.launch.json"] = function(bufnr)
  local configs = read_launch_json(bufnr)
  for _, config in ipairs(configs) do
    defer_launch_target(config)
  end
  return configs
end

vim.keymap.set("n", "<leader>dt", dap.toggle_breakpoint)
vim.keymap.set("n", "<leader>dR", dap.run_to_cursor)
vim.keymap.set("n", "<leader>dh", function() require("dapui").eval(nil, { enter = true }) end) -- Evaluate var under cursor
vim.keymap.set("n", "<leader>dc", dap.continue)
vim.keymap.set("n", "<leader>di", dap.step_into)
vim.keymap.set("n", "<leader>do", dap.step_over)
vim.keymap.set("n", "<leader>du", dap.step_out)
-- vim.keymap.set("n", "???", dap.step_back)
vim.keymap.set("n", "<leader>ds", dap.restart)
vim.keymap.set("n", "<leader>dp", dap.stop)

vim.keymap.set("n", "<leader>dT", ui.toggle)

dap.listeners.before.attach.dapui_config = function()
  ui.open()
end
dap.listeners.before.launch.dapui_config = function()
  ui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
  ui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
  ui.close()
end
