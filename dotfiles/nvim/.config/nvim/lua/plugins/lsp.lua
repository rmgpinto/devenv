local servers = {
  "lua_ls",
  "bashls",
  "taplo", -- for toml
  "yamlls",
  "jsonls",
  "terraformls",
  "dockerls",
  "rubocop",
  "herb_ls", -- for erb
  "tailwindcss",
  "ts_ls",
  "biome",
}

return {
  {
    "williamboman/mason.nvim",
    dependencies = {
      "Zeioth/mason-extra-cmds",
      opts = {},
    },
    lazy = false,
    config = function()
      require("mason").setup({})
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    lazy = false,
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = servers,
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      vim.lsp.config("bash_ls", {
        filetypes = { "sh", "bash", "zsh" }
      })
      vim.lsp.config("yamlls", {
        settings = {
          yaml = {
            format = {
              enable = true
            },
            schemaStore = {
              enable = true
            }
          }
        }
      })
      vim.lsp.config("herb_ls", {
        filetypes = { "eruby", "html" }
      })
      -- Enable LSP servers
      vim.lsp.enable(servers)
      -- Enable completion
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client:supports_method("textDocument/completion") then
            vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
          end
          if client.name == "ts_ls" or client.name == "tsserver" then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          elseif client.name == "biome" then
            client.server_capabilities.documentFormattingProvider = true
          end
        end,
      })
      vim.cmd("set completeopt+=noselect")
      -- Enable diagnostics
      vim.diagnostic.config({ virtual_lines = true })
      -- Enable formatting on save
      vim.api.nvim_create_autocmd("BufWritePre", {
        pattern = "*",
        callback = function()
          vim.lsp.buf.format()
        end,
      })
    end,
    keys = {
      { "K",          function() vim.lsp.buf.hover() end,                           desc = "LSP Hover",           {} },
      { "<leader>gd", function() vim.lsp.buf.definition() end,                      desc = "LSP Goto Definition", {} },
      { "<leader>gr", function() require("telescope.builtin").lsp_references() end, desc = "LSP References",      {} },
      { "<leader>gD", function() require("telescope.builtin").diagnostics() end,    desc = "LSP Diagnostics",     {} },
      { "<leader>ca", function() vim.lsp.buf.code_action() end,                     desc = "LSP Code Actions",    {} },
      { "<leader>gf", function() vim.lsp.buf.format() end,                          desc = "LSP Format",          {} },
      { "<leader>lr", "<cmd>LspRestart<cr>",                                        desc = "LSP Restart",         {} },
    }
  }
}
