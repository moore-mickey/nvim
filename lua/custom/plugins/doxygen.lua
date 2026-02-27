return {
  {
    "danymat/neogen",
    config = function()
      local ng = require('neogen')
      require('nvim-treesitter')
      ng.setup {}

      vim.keymap.set('n', '<leader>nf', function() ng.generate({ type = "func" }) end)
      vim.keymap.set('n', '<leader>nF', function() ng.generate({ type = "file" }) end)
      vim.keymap.set('n', '<leader>nc', function() ng.generate({ type = "class" }) end)
      return true
    end,
    -- keys = {
    --   { "<leader>nf", require('neogen').generate({ type = "func" }) },
    --   { "<leader>nF", require('neogen').generate({ type = "file" }) },
    --   { "<leader>nc", require('neogen').generate({ type = "class" }) },
    -- },
    -- keys = { { "<leader>nf", ":lua require('neogen').generate(type = "func ")<CR>", "Generate annotations for current function" } },
    enabled = true,
  },
}
