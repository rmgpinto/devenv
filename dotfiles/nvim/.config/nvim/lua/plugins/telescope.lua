return {
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release",
      },
      "echasnovski/mini.icons",
      "nvim-telescope/telescope-live-grep-args.nvim",
      "nvim-telescope/telescope-file-browser.nvim",
      "debugloop/telescope-undo.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
    },
    lazy = false,
    config = function()
      local actions = require("telescope.actions")
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          file_ignore_patterns = {
            "%.git$",
            "^.git/.*",
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
          live_grep_args = {
            auto_quoting = true,
            additional_args = function()
              return { "--hidden" }
            end,
          },
          file_browser = {
            hijack_netrw = true,
            grouped = true,
            hide_parent_dir = true,
            collapse_dirs = true,
            hidden = { file_browser = true, folder_browser = true },
            sorting_strategy = "ascending",
          },
          undo = {
            layout_strategy = "vertical",
            layout_config = {
              preview_height = 0.8,
            },
            entry_format = "#$ID, $STAT, $TIME",
          },
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
        },
      })
      telescope.load_extension("live_grep_args")
      telescope.load_extension("file_browser")
      telescope.load_extension("undo")
      telescope.load_extension("ui-select")
    end,
    keys = {
      {
        "<leader> ",
        function()
          -- The check for cached pickers comes from Telescope's source code, link below.
          -- https://github.com/nvim-telescope/telescope.nvim/blob/2eca9ba22002184ac05eddbe47a7fe2d5a384dfc/lua/telescope/builtin/__internal.lua#L135-L136
          local state = require("telescope.state")
          local cached_pickers = state.get_global_key("cached_pickers")
          if cached_pickers == nil or vim.tbl_isempty(cached_pickers) then
            require("telescope.builtin").find_files({ hidden = true })
          else
            local resume = false
            ---@diagnostic disable-next-line: unused-local
            for k, v in ipairs(cached_pickers) do
              if v.prompt_title == "Find Files" or v.prompt_title == "Live Grep (Args)" then
                resume = true
              end
            end
            if resume then
              require("telescope.builtin").resume()
            else
              require("telescope.builtin").find_files({ hidden = true })
            end
          end
        end,
        desc = "Telescope",
        silent = true
      },
      { "<leader>ff", function() require("telescope.builtin").find_files({ hidden = true }) end,      desc = "Telescope Find Files",       silent = true },
      { "<leader>fb", function() require("telescope.builtin").buffers() end,                          desc = "Telescope Buffers",          silent = true },
      { "<leader>fh", function() require("telescope.builtin").help_tags() end,                        desc = "Telescope Help Tags",        silent = true },
      { "<leader>fr", function() require("telescope.builtin").resume() end,                           desc = "Telescope Resume",           silent = true },
      { "<leader>fg", function() require("telescope").extensions.live_grep_args.live_grep_args() end, desc = "Telescope Live Grep (Args)", silent = true },
      {
        "<leader>bb",
        function()
          -- The check for cached pickers comes from Telescope's source code, link below.
          -- https://github.com/nvim-telescope/telescope.nvim/blob/2eca9ba22002184ac05eddbe47a7fe2d5a384dfc/lua/telescope/builtin/__internal.lua#L135-L136
          local state = require("telescope.state")
          local cached_pickers = state.get_global_key("cached_pickers")
          if cached_pickers == nil or vim.tbl_isempty(cached_pickers) then
            require("telescope").extensions.file_browser.file_browser()
          else
            local resume = false
            ---@diagnostic disable-next-line: unused-local
            for k, v in ipairs(cached_pickers) do
              if v.prompt_title == "File Browser" then
                resume = true
              end
            end
            if resume then
              require("telescope.builtin").resume()
            else
              require("telescope").extensions.file_browser.file_browser()
            end
          end
        end,
        desc = "Telescope File Browser",
        silent = true
      },
      {
        "<leader>fu",
        function()
          require("telescope").extensions.undo.undo()
        end,
        desc = "Telescope Undo",
        silent = true
      }
    }
  }
}
