return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "echasnovski/mini.icons" },
  opts = {
    options = {
      theme = "catppuccin",
      padding = 2,
      globalstatus = true,
      disabled_filetypes = { "alpha" },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { { "branch", color = { gui = "bold" } } },
      lualine_c = {
        { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0.5 } },
        {
          "filename",
          path = 1,
          padding = 0,
          fmt = function(str)
            return string.format("%%#Bold#%s", str)
          end,
        },
      },
      lualine_x = {
        {
          function()
            return ""
          end,
          cond = function()
            local buf_clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
            for _, client in pairs(buf_clients) do
              if client.name == "GitHub Copilot" then
                return true
              end
            end
            return false
          end,
          color = { fg = "#89b4fa" },
          on_click = function()
            vim.api.nvim_command("che lspconfig")
          end,
        },
        {
          function()
            local buf_clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
            if #buf_clients == 0 then
              return "0"
            end
            local clients = 0
            for _, client in pairs(buf_clients) do
              if client.name ~= "GitHub Copilot" then
                clients = clients + 1
              end
            end
            return clients
          end,
          cond = function()
            local buf_clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf() })
            if #buf_clients == 0 then
              return false
            end
            return true
          end,
          icon = { " ", color = { fg = "#89b4fa" } },
          on_click = function()
            vim.api.nvim_command("che lspconfig")
          end,
        },
        { "filetype" },
      },
    },
  },
}
