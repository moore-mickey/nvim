-- Deferred to the first insert, matching the old `event = "InsertEnter"`.
vim.api.nvim_create_autocmd("InsertEnter", {
  once = true,
  group = vim.api.nvim_create_augroup("custom-autopairs", { clear = true }),
  callback = function()
    require("nvim-autopairs").setup {}
  end,
})
