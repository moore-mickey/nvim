-- Task runner. Picks up a project's `.vscode/tasks.json` on its own, and
-- `setup()` patches nvim-dap so a launch.json `preLaunchTask` / `postDebugTask`
-- runs the named task around the debug session, as VS Code would.
--
--   :OverseerRun      pick a task to run
--   :OverseerToggle   task list; <CR> on a task for its actions, `o` for output

local overseer = require("overseer")

overseer.setup()

vim.keymap.set("n", "<leader>or", "<cmd>OverseerRun<CR>", { desc = "[O]verseer [R]un task" })
vim.keymap.set("n", "<leader>ot", "<cmd>OverseerToggle<CR>", { desc = "[O]verseer [T]oggle task list" })
