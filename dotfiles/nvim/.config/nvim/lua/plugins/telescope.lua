return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim"
    },
    config = function()
      local actions = require "telescope.actions"
      require("telescope").setup({
        defaults = {
          file_ignore_patterns = {
            "^.git",
            "node_modules",
            "build",
            "dist",
            "yarn.lock"
          }
        },
        pickers = {
          buffers = {
            mappings = {
              i = {
                ["<C-d>"] = actions.delete_buffer + actions.move_to_top
              }
            }
          }
        },
        extensions = {
          undo = {
          }
        }
      })
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", function() builtin.find_files({ hidden = true }) end, {})
      vim.keymap.set("n", "<leader> ", function() builtin.find_files({ hidden = true }) end, {})
      vim.keymap.set("n", "<leader>fg",
        function() builtin.live_grep({ additional_args = function() return { "--hidden" } end }) end, {})
      vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
      vim.keymap.set("n", "<leader>fr", ":Telescope resume<CR>", {})
    end
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
    config = function()
      require("telescope").setup {
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown {}
          }
        }
      }
      require("telescope").load_extension("ui-select")
    end
  }
}
