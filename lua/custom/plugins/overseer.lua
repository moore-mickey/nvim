-- Task runner. Picks up a project's `.vscode/tasks.json` on its own, and
-- `setup()` patches nvim-dap so a launch.json `preLaunchTask` / `postDebugTask`
-- runs the named task around the debug session, as VS Code would.
--
--   :OverseerRun      pick a task to run
--   :OverseerToggle   task list; <CR> on a task for its actions, `o` for output

local overseer = require("overseer")
local launch_target = require("custom.launch_target")

overseer.setup()

-- Overseer leaves ${command:...} variables as they are. Fill in CMake Tools'
-- launch target ahead of its own substitution. `replace_vars` is internal, but
-- it recurses through the module table, so this sees every string of a task.
local variables = require("overseer.vscode.variables")
local replace_vars = variables.replace_vars
variables.replace_vars = function(str, ...)
  if type(str) == "string" then
    local expanded = launch_target.expand(str)
    if type(expanded) == "string" then
      str = expanded
    else
      -- Left in place, so the task fails on it visibly.
      vim.notify("No launch target selected for: " .. str, vim.log.levels.WARN)
    end
  end
  return replace_vars(str, ...)
end

vim.keymap.set("n", "<leader>or", "<cmd>OverseerRun<CR>", { desc = "[O]verseer [R]un task" })
vim.keymap.set("n", "<leader>ot", "<cmd>OverseerToggle<CR>", { desc = "[O]verseer [T]oggle task list" })
