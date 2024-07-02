return {
  "mbbill/undotree",
  config = function()
    vim.g.undotree_WindowLayout = 3
    vim.g.undotree_SetFocusWhenToggle = 1
    vim.keymap.set("n", "<leader>u", ":UndotreeToggle<CR>", { silent = true })
    vim.keymap.set("n", "<leader>fu", ":UndotreeToggle<CR>", { silent = true })
  end
}
