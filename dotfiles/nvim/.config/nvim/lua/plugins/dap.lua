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
        { "<leader>db", function() require("dap").toggle_breakpoint() end },
        { "<leader>dc", function() require("dap").continue() end },
        { "<leader>dC", function() require("dap").run_to_cursor() end },
        { "<leader>dg", function() require("dap").goto_() end },
        { "<leader>di", function() require("dap").step_into() end },
        { "<leader>dj", function() require("dap").down() end },
        { "<leader>dk", function() require("dap").up() end },
        { "<leader>dl", function() require("dap").run_last() end },
        { "<leader>do", function() require("dap").step_out() end },
        { "<leader>dO", function() require("dap").step_over() end },
        { "<leader>dP", function() require("dap").pause() end },
        { "<leader>dr", function() require("dap").repl.toggle() end },
        { "<leader>ds", function() require("dap").session() end },
        { "<leader>dt", function() require("dap").terminate() end },
        { "<leader>dw", function() require("dap.ui.widgets").hover() end },
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
        local js_based_languages = { "javascript", "typescript" }
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
