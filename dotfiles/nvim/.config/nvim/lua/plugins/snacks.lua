return {
  "folke/snacks.nvim",
  dependencies = { "echasnovski/mini.icons" },
  priority = 1000,
  lazy = false,
  opts = {
    dashboard = {
      enabled = true,
      formats = {
        ---@diagnostic disable-next-line: unused-local
        file = function(item, ctx)
          local fname = vim.fn.fnamemodify(item.file, ":.")
          fname = fname:gsub("^%./", "")
          if #fname > ctx.width then
            return "..." .. string.sub(fname, #fname - ctx.width + 4, #fname)
          end
          return fname
        end,
      },
      sections = {
        { section = "header" },
        { section = "keys",         gap = 1,    padding = 2 },
        { title = "MRU",            padding = 1 },
        { section = "recent_files", cwd = true, limit = 9,  padding = 1 },
        { section = "startup" },
        { pane = 2,                 padding = 7 },
        {
          pane = 2,
          icon = " ",
          desc = "Browse Repo",
          padding = 1,
          key = "b",
          action = function()
            ---@diagnostic disable-next-line: undefined-global
            Snacks.gitbrowse()
          end,
        },
        function()
          local cmds = {
            {
              icon = " ",
              title = "Git Status",
              cmd =
              "git log main -10 --pretty=format:'%h %<(10,trunc)%al %<(35,trunc)%s' | head -n 10 && git fetch origin main --quiet",
              height = 10,
            },
            {
              icon = " ",
              title = "Open PRs",
              cmd = "~/.local/share/mise/shims/gh pr list -L 3",
              key = "p",
              action = function()
                vim.fn.jobstart("~/.local/share/mise/shims/gh pr list --web", { detach = true })
              end,
              height = 7,
            },
          }
          return vim.tbl_map(function(cmd)
            return vim.tbl_extend("force", {
              pane = 2,
              section = "terminal",
              padding = 1,
              ttl = 10,
              indent = 3,
            }, cmd)
          end, cmds)
        end,
      },
    },
    lazygit = {
      enabled = true,
    },
  },
  keys = {
    --{ "<leader>bd", function() Snacks.bufdelete() end, desc = "Delete Buffer" },
    {
      "<leader>gB",
      function()
        ---@diagnostic disable-next-line: undefined-global
        Snacks.gitbrowse()
      end,
      desc = "Git Browse",
      mode = { "n", "v" },
    },
    {
      "<leader>gg",
      function()
        ---@diagnostic disable-next-line: undefined-global
        Snacks.lazygit()
      end,
      desc = "Lazygit",
    },
  },
}
