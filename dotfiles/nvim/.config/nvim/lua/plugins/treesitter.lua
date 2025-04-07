return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  opts = {
    ensure_installed = {
      "vimdoc",
      "lua",
      "bash",
      "toml",
      "yaml",
      "json",
      "terraform",
      "dockerfile",
      "javascript",
    },
    indent = { enable = true },
    highlight = { enable = true },
  }
}
