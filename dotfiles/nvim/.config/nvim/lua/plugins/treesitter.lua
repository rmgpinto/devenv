return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  opts = {
    ensure_installed = {
      -- Personal
      "vimdoc",
      "lua",
      "bash",
      "toml",
      "yaml",
      "json",
      "terraform",
      "dockerfile",
      "ruby",
      -- Work
      "javascript",
    },
    indent = { enable = true },
    highlight = { enable = true },
  },
}
