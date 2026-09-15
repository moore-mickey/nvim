local dap = require("dap")
local ui = require("dapui")

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


vim.keymap.set("n", "<leader>dt", dap.toggle_breakpoint)
vim.keymap.set("n", "<leader>dR", dap.run_to_cursor)
vim.keymap.set("n", "<leader>dh", function() require("dapui").eval(nil, { enter = true }) end) -- Evaluate var under cursor
vim.keymap.set("n", "<leader>dc", dap.continue)
vim.keymap.set("n", "<leader>di", dap.step_into)
vim.keymap.set("n", "<leader>do", dap.step_over)
vim.keymap.set("n", "<leader>du", dap.step_out)
-- vim.keymap.set("n", "???", dap.step_back)
vim.keymap.set("n", "<leader>ds", dap.restart)

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
