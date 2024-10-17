return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      integrations = {
        mason = true,
        neotree = true,
      },
    })
    vim.cmd.colorscheme("catppuccin-mocha")
    -- Highlight String to teal
    vim.cmd([[highlight String guifg=#94e2d5]])
  end,
}
