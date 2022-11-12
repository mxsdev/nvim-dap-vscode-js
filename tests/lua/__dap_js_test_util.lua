local M = {}

local dap = require("dap")
local dap_bps = require("dap.breakpoints")
local dapjs = require("dap-vscode-js")
local dapjs_utils = require("dap-vscode-js.utils")
local js_session = require("dap-vscode-js.session")
local logger = require("dap-vscode-js.log")

local dap_ns = "dap_breakpoints"

M.id = "___dap_js_test"
local util_id = "___dap_js_test_utils"

local enable_logging = vim.env["DAP_JS_ENABLE_LOGGING"] == "true"

-- local current_session
local current_sessions = {}

function M.clear_listeners()
	for _, time in ipairs({ "before", "after" }) do
		for key, _ in pairs(dap.listeners[time]) do
			dap.listeners[time][key][M.id] = nil
		end
	end
end

function M.clear_config()
	dapjs.setup({}, true)
end

function M.clear_breakpoints()
	dap_bps.clear()
end

function M.reset()
	M.clear_listeners()
	-- M.clear_config()
	M.clear_breakpoints()
	current_sessions = {}
end

function M.set_breakpoint(lnum, bufnr, opts)
	dap_bps.set(opts, bufnr or 0, lnum)
end

function M.add_listener(time, event_or_command, callback)
	dap.listeners[time][event_or_command][M.id] = function(session, ...)
		if not current_sessions[session] then
			return
		end

		callback(session, ...)
	end
end

function M.on_session_end(callback)
	M.add_listener("after", "event_terminated", function(session, ...)
		current_sessions[session] = nil

		local active_sessions = vim.tbl_filter(function(el)
			return js_session.is_session_registered(el)
		end, vim.tbl_keys(current_sessions))

		if #active_sessions == 0 then
			callback(session, ...)
		end
	end)
end

function M.setup_dapjs(config)
	local info = debug.getinfo(2, "Sl")
	local lineinfo = info.short_src

	logger.msg_prefix = string.format("(%s) ", lineinfo)
	
	dapjs.setup(vim.tbl_extend("force", {
		debugger_path = DEBUGGER_PATH,
		log_file_path = LOG_PATH,
		log_file_level = (enable_logging and vim.log.levels.TRACE) or false,
		log_console_level = false,
	}, config or {}))

	dap.listeners.before["event_initialized"][util_id] = function(session)
		current_sessions[session] = true
	end
end

function M.test_file(file)
	return dapjs_utils.join_paths("./tests/js", file)
end

function M.open_test(test)
	vim.cmd(string.format("e %s", M.test_file(test)))
end

function M.get_breakpoint_signs(bufexpr)
	return vim.fn.sign_getplaced(bufexpr, { group = dap_ns })
end

function M.get_terminal_remote(on_update)
	local old_val = dap.defaults.fallback.terminal_win_cmd

	local term_buf = vim.api.nvim_create_buf(false, false)

	dap.defaults.fallback.terminal_win_cmd = function()
		return term_buf
	end

	vim.api.nvim_buf_attach(term_buf, false, {
		on_lines = function(_, _, _, firstline, _, new_lastline)
			local lines = vim.api.nvim_buf_get_lines(term_buf, firstline, new_lastline, true)

			on_update(lines)
		end,
	})

	return function()
		dap.defaults.fallback.terminal_win_cmd = old_val

		vim.schedule(function()
			vim.api.nvim_buf_delete(term_buf, { force = true })
		end)
	end
end

-- see if the file exists
local function file_exists(file)
	local f = io.open(file, "rb")
	if f then
		f:close()
	end
	return f ~= nil
end

-- get all lines from a file, returns an empty
-- list/table if the file does not exist
function M.lines_from(file)
	if not file_exists(file) then
		return {}
	end
	local lines = {}
	for line in io.lines(file) do
		lines[#lines + 1] = line
	end
	return lines
end

function M.read_log(from_test_only)
	from_test_only = from_test_only or true

	local info = debug.getinfo(2, "Sl")
	local lineinfo = info.short_src

	return vim.tbl_filter(function(el)
		return (from_test_only and string.find(el, lineinfo)) or true
	end, M.lines_from(LOG_PATH))
end

return M
