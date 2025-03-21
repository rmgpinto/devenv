vim.cmd("set cursorline")
vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set shiftwidth=2")
vim.cmd("set softtabstop=2")
vim.cmd("set nowrap")
vim.opt.number = true
vim.g.have_nerd_font = false
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.opt.showmode = false
vim.opt.clipboard = "unnamedplus"
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = "⇥ ", space = "·" }
vim.o.termguicolors = true

local opts = { noremap = true, silent = true }
vim.keymap.set("v", "<Tab>", ">gv", opts)
vim.keymap.set("v", "<S-Tab>", "<gv", opts)
vim.keymap.set("n", "<S-l>", ":bnext<CR>", opts)
vim.keymap.set("n", "<S-h>", ":bprevious<CR>", opts)
vim.keymap.set("n", "<leader>mn", ":BufferLineMoveNext<CR>", opts)
vim.keymap.set("n", "<leader>mp", ":BufferLineMovePrev<CR>", opts)
-- Restore cursor position when opening a file
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local line = vim.fn.line
    if line("'\"") > 0 and line("'\"") <= line("$") then
      vim.cmd('normal! g`"')
    end
  end,
})
-- Fix terraform LSP attach
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.tf,*.tfvars",
  callback = function()
    vim.bo.filetype = "terraform"
  end,
})
