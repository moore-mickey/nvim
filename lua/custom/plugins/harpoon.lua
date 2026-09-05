-- ThePrimeagen/harpoon (harpoon2 branch)
local harpoon = require("harpoon")
-- REQUIRED
harpoon:setup()
-- REQUIRED

-- Add to beginning of list
vim.keymap.set("n", "<leader>A", function() harpoon:list():prepend() end)
-- Add to end of list
vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
-- View List
vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

-- Goto 1-4
vim.keymap.set("n", "<M-1>", function() harpoon:list():select(1) end)
vim.keymap.set("n", "<M-2>", function() harpoon:list():select(2) end)
vim.keymap.set("n", "<M-3>", function() harpoon:list():select(3) end)
vim.keymap.set("n", "<M-4>", function() harpoon:list():select(4) end)

-- Relplace 1-4
vim.keymap.set("n", "<leader><M-1>", function() harpoon:list():replace_at(1) end)
vim.keymap.set("n", "<leader><M-2>", function() harpoon:list():replace_at(2) end)
vim.keymap.set("n", "<leader><M-3>", function() harpoon:list():replace_at(3) end)
vim.keymap.set("n", "<leader><M-4>", function() harpoon:list():replace_at(4) end)
