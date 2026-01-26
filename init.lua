-- Mickey nvim

require("custom.lazy")
-- require("custom.pack")

local vo = vim.opt

vo.shiftwidth = 4
vo.clipboard = "unnamedplus"
vo.number = true
vo.relativenumber = true
vo.expandtab = true
vim.opt_global.scrolloff = 10
vim.o.wrap = false
vo.smartcase = true
vo.ignorecase = true


vim.keymap.set("n", "<space><space>x", "<cmd>source %<CR>")
vim.keymap.set("n", "<space>x", ":.lua<CR>")
vim.keymap.set("v", "<space>x", ":lua<CR>")

vim.keymap.set("n", "<M-j>", "<cmd>cnext<CR>")
vim.keymap.set("n", "<M-k>", "<cmd>cprev<CR>")

-- Highlight when yanking (copying) text
-- Try it with `yap` in normal mode
-- See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})
vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('custom-term-open', { clear = true }),
  callback = function()
    vo.number = false
    vo.relativenumber = false
  end,
})

-- local job_id = 0
vim.keymap.set("n", "<space>st", function()
  vim.cmd.new()
  vim.cmd.term()
  vim.cmd.wincmd("J")
  vim.api.nvim_win_set_height(0, 15)

  -- job_id = vim.bo.channel
end)

-- vim.keymap.set("n", "<space>example", function()
--   -- make
--   -- gcc
--   vim.fn.chansend(job_id, { "echo 'hi'\r\n" })
-- end)
--
vim.keymap.set("n", "-", "<cmd>Oil<CR>")
