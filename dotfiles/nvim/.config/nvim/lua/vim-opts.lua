vim.cmd("set cursorline")
vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set shiftwidth=2")
vim.cmd("set softtabstop=2")
vim.cmd("set nowrap")
vim.cmd("inoremap <S-Tab> <C-D>")
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

-- clear command line 5 seconds after leaving it
local function clear_cmdline()
  vim.api.nvim_command('echo ""')
end
vim.api.nvim_create_augroup("ClearCmdLine", { clear = true })
vim.api.nvim_create_autocmd("CmdlineLeave", {
  group = "ClearCmdLine",
  callback = function()
    vim.defer_fn(clear_cmdline, 10000)
  end
})

local opts = { noremap = true, silent = true }
vim.keymap.set("n", "<A-j>", "<Esc>:m .+1<CR>", opts)
vim.keymap.set("n", "<A-Down>", "<Esc>:m .+1<CR>", opts)
vim.keymap.set("n", "<A-k>", "<Esc>:m .-2<CR>", opts)
vim.keymap.set("n", "<A-Up>", "<Esc>:m .-2<CR>", opts)
vim.keymap.set("n", "<S-l>", ":bnext<CR>", opts)
vim.keymap.set("n", "<S-h>", ":bprevious<CR>", opts)
