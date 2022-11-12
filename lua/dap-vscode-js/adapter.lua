local M = {}
local uv = vim.loop
local js_session = require("dap-vscode-js.session")
local utils = require("dap-vscode-js.utils")
local logger = require("dap-vscode-js.log")
local dapjs_config = require("dap-vscode-js.config")
local dap = require("dap")

local function adapter_config(port, mode, proc, start_child)
	return {
		type = "server",
		host = "127.0.0.1",
		port = port,
		id = mode,
		reverse_request_handlers = {
			attachedChildSession = function(parent, request)
				logger.debug(
					string.format(
						"Got attachedChildSession request from port %d to start port %s",
						parent.adapter.port,
						request.arguments.config.__jsDebugChildServer
					)
				)
				logger.trace("attachedChildSession request, port " .. tostring(port) .. ": " .. vim.inspect(request))

				start_child(request, mode, parent, proc)
			end,
		},
	}
end

local function start_child_session(request, mode, parent, proc)
	local body = request.arguments
	local session = nil
	local child_port = tonumber(body.config.__jsDebugChildServer)

	session = require("dap.session"):connect(
		adapter_config(child_port, mode, proc, start_child_session),
		{},
		function(err)
			if err then
				logger.log("DAP connection failed to start: " .. err, vim.log.levels.ERROR)
			else
				logger.debug("Initializing child session on port " .. tostring(child_port))

				session:initialize(body.config)

				js_session.register_session(session, parent, proc)
			end
		end
	)
end

function M.generate_adapter(mode, config)
	config = config or dapjs_config

	return function(callback)
		local proc

		proc = utils.start_debugger(config, function(port, proc)
			logger.debug("Debugger process started on port " .. port)
			
			js_session.register_port(port)
			callback(adapter_config(port, mode, proc, start_child_session))
		end, function(code, signal)
			if code and code ~= 0 then
				logger.error("JS Debugger exited with code " .. code .. "!")
			end
		end, function(err)
			logger.error("Error trying to launch JS debugger: " .. err)
		end, function(chunk)
			-- logger.log("JS Debugger stderr: " .. chunk, vim.log.levels.ERROR)
			logger.error("JS Debugger stderr: " .. chunk)
		end)
	end
end

return M
