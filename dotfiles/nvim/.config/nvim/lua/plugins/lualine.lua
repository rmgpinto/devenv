return {
  "nvim-lualine/lualine.nvim",
  opts = {
    options = {
      theme = "catppuccin",
      padding = 2,
      ignore_focus = { "neo-tree" },
      disabled_filetypes = {
        statusline = {
          "alpha",
          "neo-tree",
        },
        winbar = {
          "alpha",
          "neo-tree"
        }
      }
    }
  }
}
