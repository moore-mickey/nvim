-- The firmware image a debug session or flash task works on -- what VS Code's
-- CMake Tools calls the launch target.

local dap = require("dap")

local M = {}

--- Ask for an .elf below the current directory, looking in build/ first.
---@return string|table Path, or `dap.ABORT` if the pick was cancelled
function M.pick()
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

return M
