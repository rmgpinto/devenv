return {
  {
    "williamboman/mason.nvim",
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
          "taplo", -- for toml
          "yamlls",
          "jsonls",
          "terraformls",
          "dockerls"
          -- Work
        }
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      local lspconfig = require("lspconfig")
      -- Personal
      lspconfig.lua_ls.setup({})
      lspconfig.taplo.setup({})
      lspconfig.yamlls.setup({})
      lspconfig.jsonls.setup({})
      lspconfig.terraformls.setup({})
      lspconfig.dockerls.setup({})
      -- Work
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
      vim.keymap.set('n', '<leader>gd', vim.lsp.buf.definition, {})
      vim.keymap.set('n', '<leader>gr', vim.lsp.buf.references, {})
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, {})
      vim.cmd [[autocmd BufWritePre * lua vim.lsp.buf.format()]]
    end
  }
}
