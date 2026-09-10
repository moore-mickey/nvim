require('telescope').setup {
  pickers = {
    find_files = {
      theme = "ivy"
    }
  },
  extensions = {
    fzf = {}
  }
}

require('telescope').load_extension('fzf')

vim.keymap.set("n", "<space>fh", require('telescope.builtin').help_tags)
vim.keymap.set("n", "<space>fd", require('telescope.builtin').find_files)
vim.keymap.set("n", "<space>en", function()
  require('telescope.builtin').find_files {
    cwd = vim.fn.stdpath("config")
  }
end)
vim.keymap.set("n", "<space>ep", function()
  require('telescope.builtin').find_files {
    -- `vim.pack` clones plugins here, see `:help vim.pack-directory`
    cwd = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt")
  }
end)
vim.keymap.set("n", "<space>ff", require('telescope.builtin').current_buffer_fuzzy_find)

vim.keymap.set("n", "<space>fp", require('telescope.builtin').git_files)
vim.keymap.set("n", "<space>fgs", require('telescope.builtin').git_status)
vim.keymap.set("n", "<space>ld", require('telescope.builtin').diagnostics)

require "custom.telescope.multigrep".setup()
