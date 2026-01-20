return {
  {
    "kkoomen/vim-doge",
    enabled = false,
  },
  {
    "Zeioth/dooku.nvim",
    event = "VeryLazy",
    -- opts = {
    --   project_root = {'.git'},
    --   on_bufwrite_generate = true,
    -- },
    enabled = false,
  },
  {
    "danymat/neogen",
    config = true,
    keys = { { "<leader>ng", ":lua require('neogen').generate()<CR>", "Generate annotations for current function" } },
    enabled = true,
  },
}
