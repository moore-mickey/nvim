require("claude-code").setup {
  window = {
    split_ratio = 0.4,
    position = "botright",
  },
  git = {
    -- Open Claude at the repo root rather than the buffer's directory.
    use_git_root = true,
  },
  keymaps = {
    toggle = {
      -- The plugin defaults to <C-,>, which most terminals (Windows Terminal
      -- included) never deliver to Nvim.
      normal = "<leader>cc",
      -- Not a <leader> map: in terminal mode every keystroke is text you are
      -- typing at Claude, and "<space>cc" appears in ordinary prose.
      terminal = "<M-c>",
      variants = {
        continue = "<leader>cC",
        resume = "<leader>cr",
        verbose = "<leader>cV",
      },
    },
    window_navigation = true,
    scrolling = true,
  },
}
