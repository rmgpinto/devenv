return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  config = function()
    require("catppuccin").setup({
      integrations = {
        copilot_vim = true,
        dap = true,
        dap_ui = true,
        gitsigns = true,
        mason = true,
        native_lsp = {
          enabled = true,
        },
        treesitter = true,
        telescope = {
          enabled = true
        },
        snacks = {
          enabled = true
        },
        which_key = true
      }
    })
    vim.cmd.colorscheme("catppuccin-mocha")
    -- Highlight String to teal
    vim.cmd([[highlight String guifg=#94e2d5]])
  end,
}
