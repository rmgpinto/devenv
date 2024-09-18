return {
  "akinsho/bufferline.nvim",
  config = function()
    local bufferline = require("bufferline")
    bufferline.setup({
      options = {
        always_show_bufferline = false,
        offsets = {
          {
            filetype = "neo-tree",
            text = "",
            highlight = "",
            text_align = "left",
          }
        }
      }
    })
  end
}
