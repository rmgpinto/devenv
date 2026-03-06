return {
  "polarmutex/git-worktree.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    require("telescope").load_extension("git_worktree")
    vim.keymap.set("n", "gw", function()
      require("telescope").extensions.git_worktree.git_worktree(require("telescope.themes").get_dropdown({}))
    end, { desc = "Worktrees" })
  end,
}
