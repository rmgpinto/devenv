return {
  {
    "williamboman/mason.nvim",
    dependencies = {
      "Zeioth/mason-extra-cmds", opts = {}
    },
    lazy = false,
    config = function()
      require("mason").setup({})
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    lazy = false,
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          -- Personal
          "lua_ls",
          "bashls",
          "taplo", -- for toml
          "yamlls",
          "jsonls",
          "terraformls",
          "dockerls",
          "ruby_lsp",
          -- Work
          "ts_ls"
        }
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local lspconfig = require("lspconfig")
      -- Personal
      lspconfig.lua_ls.setup({ capabilities = capabilities })
      lspconfig.bashls.setup({
        filetypes = { "sh", "bash", "zsh" },
        capabilities = capabilities
      })
      lspconfig.taplo.setup({ capabilities = capabilities })
      lspconfig.yamlls.setup({ capabilities = capabilities })
      lspconfig.jsonls.setup({ capabilities = capabilities })
      lspconfig.terraformls.setup({ capabilities = capabilities })
      lspconfig.dockerls.setup({ capabilities = capabilities })
      lspconfig.ruby_lsp.setup({ capabilities = capabilities })
      -- Work
      lspconfig.ts_ls.setup({ capabilities = capabilities })
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
      vim.keymap.set('n', '<leader>gd', vim.lsp.buf.definition, {})
      vim.keymap.set('n', '<leader>gr', vim.lsp.buf.references, {})
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, {})
      vim.cmd [[autocmd BufWritePre * lua vim.lsp.buf.format()]]
    end
  }
}
