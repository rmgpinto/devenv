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
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local lspconfig = require("lspconfig")
      -- Personal
      lspconfig.lua_ls.setup({
        capabilities = capabitilies })
      lspconfig.bashls.setup({
        filetypes = { "sh", "bash", "zsh" },
        capabilities = capabitilies
      })
      lspconfig.taplo.setup({ capabilities = capabitilies })
      lspconfig.yamlls.setup({ capabilities = capabitilies })
      lspconfig.jsonls.setup({ capabilities = capabitilies })
      lspconfig.terraformls.setup({ capabilities = capabitilies })
      lspconfig.dockerls.setup({ capabilities = capabitilies })
      -- Work
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
      vim.keymap.set('n', '<leader>gd', vim.lsp.buf.definition, {})
      vim.keymap.set('n', '<leader>gr', vim.lsp.buf.references, {})
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, {})
      vim.cmd [[autocmd BufWritePre * lua vim.lsp.buf.format()]]
    end
  }
}
