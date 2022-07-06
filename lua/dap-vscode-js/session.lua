local M = {}
local utils = require("dap-vscode-js.utils")
local breakpoints = require("dap.breakpoints")
local dap = require("dap")
local dap_utils = require("dap.utils")

local sessions = {}

local function get_proc_sessions(pid)
	return vim.tbl_filter(function(session_data)
		return session_data.handle and session_data.pid == pid
	end, sessions)
end

function M.register_session(session, root_proc, port)
	if vim.tbl_count(get_proc_sessions(root_proc.pid)) == 0 then
		dap.set_session(session)
	end

	sessions[session] = {
		proc = root_proc,
		port = port,
		is_main = (vim.tbl_count(get_proc_sessions(root_proc.pid)) == 0),
	}
end

function M.unregister_session(session)
	sessions[session] = nil

	-- should exit process here ???
end

function M.unregister_proc(proc)
	for session, _ in pairs(get_proc_sessions(proc.pid)) do
		M.unregister_session(session)
	end
end

local function session_proc(session)
	if not sessions[session] then
		return nil
	end

	return sessions[session].proc
end

local function session_is_main(session)
	if not sessions[session] then
		return nil
	end

	return sessions[session].is_main
end

local function session_entry(session, entry)
	if not sessions[session] then
		-- sessions[session] = { }
		return nil
	end

	if not sessions[session][entry] then
		sessions[session][entry] = {}
	end

	return sessions[session][entry]
end

local function session_variables(session)
	return session_entry(session, "variables")
end

local function clear_session_variables(session)
	if sessions[session] then
		sessions[session]["variables"] = nil
	end
end

local function session_breakpoints(session)
	return session_entry(session, "breakpoints")
end

function M.setup_hooks(plugin_id)
	local function set_variable_listener(session, err, body, request)
		if err then
			return
		end

		local variables = session_variables(session)
		if not variables then
			return
		end

		local key = body.variablesReference
		local value = body.value

		if not key or not value then
			return
		end
		variables[key] = { value = value, evaluateName = request.expression, name = request.name }
	end

	dap.listeners.before["setVariable"][plugin_id] = set_variable_listener
	dap.listeners.before["setExpression"][plugin_id] = set_variable_listener

	dap.listeners.before["variables"][plugin_id] = function(session, err, body, request)
		if err then
			return
		end

		local variables = session_variables(session)

		if not variables or not variables[session] then
			return
		end

		for _, var in ipairs(body.variables) do
			local info = variables[session][var.variablesReference]

			if info and (var.evaluateName == info.evaluateName or var.name == info.name) then
				var.value = info.value
			end
		end
	end

	dap.listeners.before["setBreakpoints"][plugin_id] = function(session, err, body, request)
		if err then
			return
		end

		local session_bps = session_breakpoints(session)

		if not session_bps then
			return
		end

		for i, bp in ipairs(body.breakpoints) do
			table.insert(session_bps, bp)

			if not bp.verified then
				bp.verified = true
				local old_message = bp.message
				bp.message = nil

				vim.defer_fn(function()
					if not bp.verified then
						bp.message = old_message

						local bp_info = utils.dap_breakpoint_by_state(bp)

						breakpoints.set_state(bp_info.bufnr, bp_info.line, bp)

						if bp.message then
							dap_utils.notify("Breakpoint rejected: " .. bp.message)
						end
					end
				end, 50)
			end
		end
	end

	dap.listeners.after["event_breakpoint"][plugin_id] = function(session, body)
		if body.reason ~= "changed" then
			return
		end

		local bp = body.breakpoint

		if bp.id then
			for _, xbp in ipairs(session_breakpoints(session) or {}) do
				if xbp.id == bp.id then
					bp.verified = xbp.verified
				end
			end
		end
	end

	dap.listeners.after["event_terminated"][plugin_id] = function(session)
		local proc = session_proc(session)

		if not proc then
			return
		end

		if session_is_main(session) then
			proc.exit()
		end

		M.unregister_session(session)
	end

	dap.listeners.after["event_exited"][plugin_id] = function(session)
		M.unregister_session(session)
	end

	for _, command in ipairs({
		"next",
		"continue",
		"restart",
		"launch",
		"restartFrame",
		"stepBack",
		"stepIn",
		"stepOut",
	}) do
		dap.listeners.before[command][plugin_id] = function(session, _, body, request)
			clear_session_variables(session)
		end
	end
end

return M
