return {
  "akinsho/bufferline.nvim",
  lazy = false,
  config = function()
    require("bufferline").setup({
      options = {
        numbers = "ordinal",
        diagnostics = "nvim_lsp",
        diagnostics_indicator = function(count, level)
          local icon = level:match("error") and " " or " "
          return " " .. icon .. count
        end
      }
    })
  end,
  keys = {
    { "<S-l>",      "<cmd>BufferLineCycleNext<CR>",    silent = true },
    { "<S-h>",      "<cmd>BufferLineCyclePrev<CR>",    silent = true },
    { "<leader>1",  "<cmd>BufferLineGoToBuffer 1<CR>", silent = true },
    { "<leader>2",  "<cmd>BufferLineGoToBuffer 2<CR>", silent = true },
    { "<leader>3",  "<cmd>BufferLineGoToBuffer 3<CR>", silent = true },
    { "<leader>4",  "<cmd>BufferLineGoToBuffer 4<CR>", silent = true },
    { "<leader>5",  "<cmd>BufferLineGoToBuffer 5<CR>", silent = true },
    { "<leader>mn", "<cmd>BufferLineMoveNext<CR>",     silent = true },
    { "<leader>mp", "<cmd>BufferLineMovePrev<CR>",     silent = true },
  }
}
