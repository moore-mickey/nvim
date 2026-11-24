-- The firmware image a debug session or flash task works on -- what VS Code's
-- CMake Tools calls the launch target.

local dap = require("dap")

local M = {}

--- The placeholder CMake Tools fills in, in both launch.json and tasks.json.
M.VARIABLE = "${command:cmake.launchTargetPath}"

-- Per working directory, so a flash task and the debug session after it get
-- the same image without asking twice.
local selected = {}

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

--- Ask for a launch target and remember it, replacing any earlier choice.
---@return string|table Path, or `dap.ABORT` if nothing usable was picked
function M.select()
  local path = M.pick()
  if type(path) ~= "string" or vim.fn.filereadable(path) == 0 then
    return dap.ABORT
  end
  path = vim.fs.normalize(path)
  selected[vim.fn.getcwd()] = path
  return path
end

--- The remembered launch target, asking only if there is none yet or its
--- file has gone.
---@return string|table Path, or `dap.ABORT`
function M.get()
  local path = selected[vim.fn.getcwd()]
  if path and vim.fn.filereadable(path) == 1 then
    return path
  end
  return M.select()
end

--- Replace `M.VARIABLE` in `str` with the launch target.
---@param str string
---@return string|table `str` expanded, or `dap.ABORT`
function M.expand(str)
  if not str:find(M.VARIABLE, 1, true) then
    return str
  end
  local path = M.get()
  if path == dap.ABORT then
    return path
  end
  return (str:gsub(vim.pesc(M.VARIABLE), function()
    return path
  end))
end

vim.api.nvim_create_user_command("LaunchTarget", function()
  local path = M.select()
  if path ~= dap.ABORT then
    vim.notify("Launch target: " .. vim.fn.fnamemodify(path, ":."))
  end
end, { desc = "Select the .elf that ${command:cmake.launchTargetPath} stands for" })

return M
