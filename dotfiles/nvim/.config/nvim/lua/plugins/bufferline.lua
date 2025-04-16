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
    { "<S-l>",      "<cmd>BufferLineCycleNext<CR>",    desc = "Bufferline Cycle Next",  silent = true },
    { "<S-h>",      "<cmd>BufferLineCyclePrev<CR>",    desc = "Bufferline Cycle Prev",  silent = true },
    { "<leader>mn", "<cmd>BufferLineMoveNext<CR>",     desc = "Bufferline Move Next",   silent = true },
    { "<leader>mp", "<cmd>BufferLineMovePrev<CR>",     desc = "Bufferline Move Prev",   silent = true },
    { "<leader>1",  "<cmd>BufferLineGoToBuffer 1<CR>", desc = "Bufferline Goto Buffer 1", silent = true },
    { "<leader>2",  "<cmd>BufferLineGoToBuffer 2<CR>", desc = "Bufferline Goto Buffer 2", silent = true },
    { "<leader>3",  "<cmd>BufferLineGoToBuffer 3<CR>", desc = "Bufferline Goto Buffer 3", silent = true },
    { "<leader>4",  "<cmd>BufferLineGoToBuffer 4<CR>", desc = "Bufferline Goto Buffer 4", silent = true },
    { "<leader>5",  "<cmd>BufferLineGoToBuffer 5<CR>", desc = "Bufferline Goto Buffer 5", silent = true },
    { "<leader>6",  "<cmd>BufferLineGoToBuffer 6<CR>", desc = "Bufferline Goto Buffer 6", silent = true },
    { "<leader>7",  "<cmd>BufferLineGoToBuffer 7<CR>", desc = "Bufferline Goto Buffer 7", silent = true },
    { "<leader>8",  "<cmd>BufferLineGoToBuffer 8<CR>", desc = "Bufferline Goto Buffer 8", silent = true },
    { "<leader>9",  "<cmd>BufferLineGoToBuffer 9<CR>", desc = "Bufferline Goto Buffer 9", silent = true },
  }
}
