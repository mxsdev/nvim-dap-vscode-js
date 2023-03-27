local M = {}
local utils = require("dap-vscode-js.utils")
-- local logger = require("dap-vscode-js.log")
local dapjs_config = require("dap-vscode-js.config")

function M.generate_adapter(_, user_config)
	user_config = user_config or dapjs_config

	return function(on_config, config, parent)
    local target = config["__pendingTargetId"]
    if target and parent then
      local adapter = parent.adapter
      on_config({
        type = "server",
        host = "localhost",
        port = adapter.port
      })
    else
      local debug_executable = user_config.adapter_executable_config

      if not debug_executable then
        local debugger_path = user_config.debugger_executable

        if not utils.file_exists(debugger_path) then
          -- TODO: show user to README.md with directions 
          error("Debugger entrypoint file '" .. debugger_path .. "' does not exist. Did it build properly?")
        end

        local debugger_cmd_args = { debugger_path, "${port}" }

        for _, arg in ipairs(user_config.debugger_args or {}) do
          table.insert(debugger_cmd_args, arg)
        end

        debug_executable = {
          command = user_config.node_path,
          args = debugger_cmd_args,
        }
      end

      on_config({
        type = "server",
        host = "localhost",
        port = "${port}",
        executable = debug_executable
      })
    end
  end
end

return M
