return {
  "akinsho/bufferline.nvim",
  config = function()
    require("bufferline").setup({})
    local opts = { noremap = true, silent = true }
    vim.keymap.set("n", "<S-l>", ":BufferLineCycleNext<CR>", opts)
    vim.keymap.set("n", "<S-h>", ":BufferLineCyclePrev<CR>", opts)
    vim.keymap.set("n", "<leader>1", ":BufferLineGoToBuffer 1<CR>", opts)
    vim.keymap.set("n", "<leader>2", ":BufferLineGoToBuffer 2<CR>", opts)
    vim.keymap.set("n", "<leader>3", ":BufferLineGoToBuffer 3<CR>", opts)
    vim.keymap.set("n", "<leader>4", ":BufferLineGoToBuffer 4<CR>", opts)
    vim.keymap.set("n", "<leader>5", ":BufferLineGoToBuffer 5<CR>", opts)
    vim.keymap.set("n", "<leader>mn", ":BufferLineMoveNext<CR>", opts)
    vim.keymap.set("n", "<leader>mp", ":BufferLineMovePrev<CR>", opts)
  end,
}
