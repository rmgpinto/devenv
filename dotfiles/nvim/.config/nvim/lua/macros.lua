vim.keymap.set("n", "<leader>ts", function()
  local bufnr = 0
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)
  if not lines or not lines[1] then return end
  local line = lines[1]

  local cs = vim.bo.commentstring
  if not cs or cs == "" or not cs:find("%%s") then
    cs = "# %s"
  end
  local before, after = cs:match("^(.*)%%s(.*)$")
  before = before or "# "
  after = after or ""

  if line:match("git@github.com:TryGhost") then
    local commented = before .. line .. after

    local rewritten = line:gsub("git@github%.com:TryGhost", "../../../")
    rewritten = rewritten:gsub("%?ref=[^\"%s]+", "")

    vim.api.nvim_buf_set_lines(bufnr, row - 1, row, false, { commented, rewritten })
    vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
    return
  end

  if line:match('^%s*source%s*=%s*"%.%./%.%./%.%./') then
    -- delete this line
    vim.api.nvim_buf_set_lines(bufnr, row - 1, row, false, {})

    local prev = vim.api.nvim_buf_get_lines(bufnr, row - 2, row - 1, false)
    if prev and prev[1] then
      local uncommented = prev[1]:gsub("^%s*" .. vim.pesc(before), "", 1)
      uncommented = uncommented:gsub(vim.pesc(after) .. "%s*$", "", 1)
      vim.api.nvim_buf_set_lines(bufnr, row - 2, row - 1, false, { uncommented })
      vim.api.nvim_win_set_cursor(0, { row - 1, 0 })
    end
    return
  end
end, { desc = "Toggle Terraform source line (git <-> local path)" })
