local ng = require('neogen')
require('nvim-treesitter')
ng.setup {}

vim.keymap.set('n', '<leader>nf', function() ng.generate({ type = "func" }) end)
vim.keymap.set('n', '<leader>nF', function() ng.generate({ type = "file" }) end)
vim.keymap.set('n', '<leader>nc', function() ng.generate({ type = "class" }) end)
