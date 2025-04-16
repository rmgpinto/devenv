return {
  "lewis6991/gitsigns.nvim",
  lazy = false,
  config = function()
    require("gitsigns").setup({})
  end,
  keys = {
    { "<leader>gp", "<cmd>Gitsigns preview_hunk<CR>",              desc = "Gitsigns Preview Hunk", silent = true },
    { "<leader>gb", "<cmd>Gitsigns toggle_current_line_blame<CR>", desc = "Gitsigns Blame",       silent = true },
  }
}
