return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-live-grep-args.nvim",
    },
    config = function()
      local actions = require("telescope.actions")
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          file_ignore_patterns = {
            "^.git",
            "node_modules",
            "build",
            "dist",
            "yarn.lock",
          },
        },
        pickers = {
          buffers = {
            mappings = {
              i = {
                ["<C-d>"] = actions.delete_buffer + actions.move_to_top,
              },
            },
          },
        },
        extensions = {
          undo = {},
          live_grep_args = {
            auto_quoting = true,
            additional_args = function()
              return { "--hidden" }
            end,
          },
        },
      })
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", function()
        builtin.find_files({ hidden = true })
      end, {})
      vim.keymap.set("n", "<leader> ", function()
        builtin.find_files({ hidden = true })
      end, {})
      vim.keymap.set(
        "n",
        "<leader>fg",
        ':lua require("telescope").extensions.live_grep_args.live_grep_args()<CR>',
        { silent = true }
      )
      telescope.load_extension("live_grep_args")
      vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
      vim.keymap.set("n", "<leader>fr", ":Telescope resume<CR>", { silent = true })
    end,
  },
  {
    "nvim-telescope/telescope-ui-select.nvim",
    config = function()
      require("telescope").setup({
        extensions = {
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
        },
      })
      require("telescope").load_extension("ui-select")
    end,
  },
}
