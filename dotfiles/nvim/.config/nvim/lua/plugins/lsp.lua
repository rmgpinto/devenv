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
        ensure_installed = {
          "lua_ls",
          "bashls",
          "taplo", -- for toml
          "yamlls",
          "jsonls",
          "terraformls",
          "dockerls",
          "ts_ls",
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      local lspconfig = require("lspconfig")
      lspconfig.lua_ls.setup({})
      lspconfig.bashls.setup({
        filetypes = { "sh", "bash", "zsh" },
      })
      lspconfig.taplo.setup({})
      lspconfig.yamlls.setup({})
      lspconfig.jsonls.setup({})
      lspconfig.terraformls.setup({})
      lspconfig.dockerls.setup({})
      lspconfig.ts_ls.setup({})
      vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
      vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
      vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, {})
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
      vim.keymap.set("n", "<leader>gf", vim.lsp.buf.format, {})
      -- Enable completion
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client:supports_method('textDocument/completion') then
            vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
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
  },
}
