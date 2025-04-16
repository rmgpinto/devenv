return {
  {
    "jay-babu/mason-nvim-dap.nvim",
    lazy = true,
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = { "js" },
      automatic_installation = true,
      handlers = {}
    },
  },
  {
    {
      "rcarriga/nvim-dap-ui",
      dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
      config = function()
        require("dapui").setup({})
      end
    },
    {
      "mfussenegger/nvim-dap",
      lazy = true,
      dependencies = {
        "jay-babu/mason-nvim-dap.nvim",
        "rcarriga/nvim-dap-ui",
      },
      keys = {
        { "<leader>dB", function() require("drp").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end },
        { "<leader>db", function() require("dap").toggle_breakpoint() end,                                   desc = "DAP Toggle Breakpoint" },
        { "<leader>dc", function() require("dap").continue() end,                                            desc = "DAP Continue" },
        { "<leader>dC", function() require("dap").run_to_cursor() end,                                       desc = "DAP Run to Cursor" },
        { "<leader>dg", function() require("dap").goto_() end,                                               desc = "DAP Goto" },
        { "<leader>di", function() require("dap").step_into() end,                                           desc = "DAP Step Into" },
        { "<leader>dj", function() require("dap").down() end,                                                desc = "DAP Down" },
        { "<leader>dk", function() require("dap").up() end,                                                  desc = "DAP Up" },
        { "<leader>dl", function() require("dap").run_last() end,                                            desc = "DAP Run Last" },
        { "<leader>do", function() require("dap").step_out() end,                                            desc = "DAP Step Out" },
        { "<leader>dO", function() require("dap").step_over() end,                                           desc = "DAP Step Over" },
        { "<leader>dP", function() require("dap").pause() end,                                               desc = "DAP Pause" },
        { "<leader>dr", function() require("dap").repl.toggle() end,                                         desc = "DAP Repl" },
        { "<leader>ds", function() require("dap").session() end,                                             desc = "DAP Session" },
        { "<leader>dt", function() require("dap").terminate() end,                                           desc = "DAP Terminate" },
        { "<leader>dw", function() require("dap.ui.widgets").hover() end,                                    desc = "DAP Hover" },
      },
      config = function()
        local dap = require("dap")
        local dapui = require("dapui")
        dap.listeners.before.attach.dapui_config = function()
          dapui.open()
        end
        dap.listeners.before.launch.dapui_config = function()
          dapui.open()
        end
        dap.listeners.before.event_terminated.dapui_config = function()
          dapui.close()
        end
        dap.listeners.before.event_exited.dapui_config = function()
          dapui.close()
        end
        dap.adapters["pwa-node"] = {
          type = "server",
          host = "localhost",
          port = "${port}",
          executable = {
            command = "node",
            args = { vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js", "${port}" },
          }
        }
        dap.configurations["javascript"] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file",
            program = "${file}",
            cwd = "${workspaceFolder}"
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}"
          },
        }
        dap.configurations["typescript"] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch compiled file (TS)",
            program = "${workspaceFolder}/dist/${fileBasenameNoExtension}.js",
            cwd = "${workspaceFolder}",
            sourceMaps = true,
            protocol = "inspector",
            outFiles = { "${workspaceFolder}/dist/**/*.js" },
            preLaunchTask = function()
              local handle = io.popen("yarn build")
              ---@diagnostic disable-next-line: need-check-nil
              handle:close()
            end
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}"
          }
        }
      end
    }
  }
}
