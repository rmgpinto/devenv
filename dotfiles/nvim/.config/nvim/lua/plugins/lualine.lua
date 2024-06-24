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
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch" },
      lualine_c = {
        { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0.5 } },
        { "filename", path = 1,         padding = 0,    fmt = function(str) return string.format('%%#Bold#%s', str) end }
      },
      lualine_x = {
        { "encoding", separator = "", padding = 0 },
        { "filetype", separator = "" }
      }
    }
  }
}
