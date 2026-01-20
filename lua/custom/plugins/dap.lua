return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "leoluz/nvim-dap-go",
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
      "mason-org/mason.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    config = function()
      local dap = require("dap")
      local ui = require("dapui")

      -- require("mason").setup()
      -- require("mason-tool-installer").setup { ensure_installed = ensure_installed }

      ui.setup()
      require("dap-go").setup()

      require("nvim-dap-virtual-text").setup {
        display_callback = function(variable)
          local name = string.lower(variable.name)
          local value = string.lower(variable.value)
          if name:match "secret" or name:match "api" or value:match "secret" or value:match "api" then
            return "*****"
          end
          if #variable.value > 15 then
            return " " .. string.sub(variable.value, 1, 15) .. "... "
          end
          return " " .. variable.value
        end,
      }

      local dap_cortex_debug = require("dap-cortex-debug")
      dap.configurations.cpp = {
        dap_cortex_debug.s32k311evb_config {
          cwd = "${workspaceFolder}",
          executable = "${workspaceFolder}/build/s32k3_simple_main.elf",
          name = "Debug DevKit with PE",
          request = "launch",
          type = "cortex-debug-debug",
          runToEntryPoint = "main",
          showDevDebugOutput = "parsed",
          serverType = "pe",
          device = "NXP_S32K3xx_S32K311",
          svdFile = "${workspaceFolder}/S32K311_M7.svd",
          serverPath = "C:/NXP/S32DS.3.6.3/eclipse/plugins/com.pemicro.debug.gdbjtag.pne_6.0.2.202505211545/win32/pegdbserver_console.exe",
        },
      }
      dap.configurations.c = dap.configurations.cpp

      vim.keymap.set("n", "<leader>dt", dap.toggle_breakpoint)
      vim.keymap.set("n", "<leader>dR", dap.run_to_cursor)
      vim.keymap.set("n", "<leader>d?", function() require("dapui").eval(nil, { enter = true }) end) -- Evaluate var under cursor
      vim.keymap.set("n", "<leader>dc", dap.continue)
      vim.keymap.set("n", "<leader>di", dap.step_into)
      vim.keymap.set("n", "<leader>do", dap.step_over)
      vim.keymap.set("n", "<leader>du", dap.step_out)
      -- vim.keymap.set("n", "???", dap.step_back)
      vim.keymap.set("n", "<leader>ds", dap.restart)

      dap.listeners.before.attach.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        ui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        ui.close()
      end
    end,
  }
}
-- return {
--   "mfussenegger/nvim-dap",
--   enable = true,
--   keys = {
--     {
--       "<leader>dR",
--       function()
--         require("dap").run_to_cursor()
--       end,
--       desc = "Run to Cursor",
--     },
--     {
--       "<leader>dp",
--       function()
--         require("dap").pause.toggle()
--       end,
--       desc = "Pause DAP",
--       -- Add more Keymaps from bernardassan/awesome-neovim/blob/master/lua/plugins/dap.lua
--     },
--     {
--       "<leader>dU",
--       function()
--         require("dapui").toggle()
--       end,
--       desc = "Toggle UI",
--     },
--     {
--       "<leader>dt",
--       function()
--         require("dap").toggle_breakpoint()
--       end,
--       desc = "Toggle Breakpoint",
--     },
--     {
--       "<leader>dc",
--       function()
--         require("dap").continue()
--       end,
--       desc = "Continue",
--     },
--     {
--       "<leader>ds",
--       function()
--         require("dap").continue() -- TODO: ? Should this be something else???
--       end,
--       desc = "Start",
--     },
--     {
--       "<leader>dd",
--       function()
--         require("dap").continue()
--       end,
--       desc = "Disconnect",
--     },
--     {
--       "<leader>dg",
--       function()
--         require("dap").session()
--       end,
--       desc = "Get Session",
--     },
--     {
--       "<leader>dh",
--       function()
--         require("dap.ui.widgets").hover()
--       end,
--       desc = "Hover Variables",
--     },
--     {
--       "<leader>di",
--       function()
--         require("dap").step_into()
--       end,
--       desc = "Step Into",
--     },
--     {
--       "<leader>do",
--       function()
--         require("dap").step_over()
--       end,
--       desc = "Step Over",
--     },
--     {
--       "<leader>du",
--       function()
--         require("dap").step_out()
--       end,
--       desc = "Step Out",
--     },
--     {
--       "<leader>dq",
--       function()
--         require("dap").close()
--       end,
--       desc = "Quit",
--     },
--     {
--       "<leader>dx",
--       function()
--         require("dap").terminate()
--       end,
--       desc = "Terminate",
--     },
--     {
--       "<leader>dl",
--       function()
--         require("dap").run_last()
--       end,
--       silent = true,
--       desc = "Run Last",
--     },
--   },
--   dependencies = {
--     {
--       "rcarriga/nvim-dap-ui",
--       lazy = true,
--       opts = {
--         icons = {
--           expanded = "▾",
--           collapsed = "▸",
--           current_frame = "▸",
--         },
--         mappings = {
--           expand = { "<CR>", "<2-LeftMouse>" },
--           open = "o",
--           remove = "d",
--           edit = "e",
--           repl = "r",
--           toggle = "t",
--         },
--         expand_lines = vim.fn.has("nvim-0.7") == 1,
--         layouts = {
--           {
--             elements = {
--               { id = "scopes", size = 0.4 },
--               "breakpoints",
--               "stacks",
--               "watches",
--             },
--             size = 40,
--             position = "left",
--           },
--           {
--             elements = {
--               "repl",
--               -- "console",
--             },
--             size = 0.25,
--             position = "bottom",
--           },
--         },
--         controls = {
--           enabled = true,
--           element = "repl",
--           icons = {
--             pause = "",
--             play = "",
--             step_into = "",
--             step_over = "",
--             step_out = "",
--             step_back = "",
--             run_last = "↻",
--             terminate = "",
--           },
--         },
--         floating = {
--           max_height = nil,
--           max_width = nil,
--           border = "single",
--           mappings = {
--             close = { "q", "<Esc>" },
--           },
--         },
--         windows = { indent = 1 },
--         render = {
--           max_type_length = nil,
--           max_value_lines = 100,
--         },
--       },
--       config = function(_, opts)
--         local dapui = require("dapui")
--         dapui.setup(opts)
--
--         local dap = require("dap")
--         dap.listeners.after.event_initialzed["dapui_config"] = function()
--           dapui.open()
--         end
--         dap.listeners.before.event_terminated["dapui_config"] = function()
--           dapui.close()
--         end
--         dap.listeners.before.event_exited["dapui_config"] = function()
--           dapui.close()
--         end
--       end,
--     },
--   },
--   config = function()
--     local dap = require("dap")
--
--     -- dap.adapters.gdb = {
--     --   type = "executable",
--     --   command = "gdb",
--     --   args = { "-i", "dap" },
--     -- }
--     --
--     -- TODO: Add cortex
--     dap.adapters.cortex = {
--       type = "executable",
--       command = "node",
--       args = { "C:/Users/bmoore/.vscode/extensions/marus25.cortex-debug-1.12.1/dist/debugadapter.js" },
--       options = { detached = false },
--     }
--
--     -- dap.configurations.cpp = {
--     --   {
--     --     name = "Launch",
--     --     type = "lldb",
--     --     request = "launch",
--     --     program = function()
--     --       return vim.fn.input(
--     --         "Path to executable: ",
--     --         vim.fn.getcwd() .. "/",
--     --         "file"
--     --       )
--     --     end,
--     --     cwd = "${workspaceFolder}",
--     --     stopOnEntry = false,
--     --     args = {},
--     --   },
--     --   {
--     --     name = "Attach to process",
--     --     type = "cpp", -- Adjust to match adapter name
--     --     request = "attach",
--     --     pid = require("dap.utils").pick_process,
--     --     args = {},
--     --   },
--     -- }
--     -- dap.configurations.c = dap.configurations.cpp
--     -- dap.configurations.zig = {
--     --   {
--     --     name = "Launch",
--     --     type = "gdb",
--     --     request = "launch",
--     --     program = function()
--     --       return vim.fn.input(
--     --         "Path to executable: ",
--     --         vim.fn.getcwd() .. "/zig-out/bin/",
--     --         "file"
--     --       )
--     --     end,
--     --     cwd = "$workspaceFolder}",
--     --     console = "integratedTerminal",
--     --   }
--     -- }
--   end
-- }
