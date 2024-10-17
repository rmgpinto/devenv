return {
  "akinsho/bufferline.nvim",
  config = function()
    require("bufferline").setup({
      options = {
        offsets = {
          {
            filetype = "neo-tree",
            text_align = "left",
          },
        },
      },
    })
  end,
}
