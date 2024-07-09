return {
  "nvim-neo-tree/neo-tree.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    vim.keymap.set("n", "<leader>b", ":Neotree filesystem toggle left<CR>", { silent = true })
    require("neo-tree").setup({
      filesystem = {
        components = {
          -- only show last part of path
          name = function(config, node, state)
            local components = require('neo-tree.sources.common.components')
            local name = components.name(config, node, state)
            if node:get_depth() == 1 then
              name.text = name.text:match("([^/]+)$")
            end
            return name
          end,
        },
        hijack_netrw_behavior = "open_default",
        use_libuv_file_watcher = true,
        follow_current_file = {
          enabled = true
        },
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
          never_show = {
            ".git"
          }
        }
      }
    })
  end
}
