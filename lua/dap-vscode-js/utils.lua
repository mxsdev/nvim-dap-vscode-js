local uv = vim.loop
local path_sep = uv.os_uname().version:match("Windows") and "\\" or "/"
local breakpoints = require("dap.breakpoints")

local M = {}

function M.get_runtime_dir()
	local lvim_runtime_dir = os.getenv("NVIM_RUNTIME_DIR")
	if not lvim_runtime_dir then
		-- when nvim is used directly
		return vim.call("stdpath", "data")
	end
	return lvim_runtime_dir
end

function M.get_cache_dir()
	return vim.call("stdpath", "cache")
end

function M.join_paths(...)
	local result = table.concat({ ... }, path_sep)
	return result
end

function M.dap_breakpoint_by_state(state)
	local bps = breakpoints.get()

	for bufnr, linebps in pairs(bps) do
		for _, bp in ipairs(linebps) do
			if bp.state == state then
				bp.bufnr = bufnr
				return bp
			end
		end
	end
end

local function schedule_wrap_safe(func)
	return (func and vim.schedule_wrap(func)) or function(...) end
end

local function file_exists(name)
	local f = io.open(name, "r")
	if f ~= nil then
		io.close(f)
		return true
	else
		return false
	end
end

local function debugger_entrypoint(debugger_path)
	return M.join_paths(debugger_path, "out/src/vsDebugServer.js")
end

---@param config Settings
local function get_spawn_cmd(config)
	if config.debugger_cmd then
		return assert(config.debugger_cmd[1], "debugger_cmd is empty"), { unpack(config.debugger_cmd, 2) }
	end
	local entrypoint = debugger_entrypoint(config.debugger_path)

	if not file_exists(entrypoint) then
		error("Debugger entrypoint file '" .. entrypoint .. "' does not exist. Did it build properly?")
	end
	return config.node_path, { entrypoint }
end

function M.start_debugger(config, on_launch, on_exit, on_error, on_stderror)
	on_launch = schedule_wrap_safe(on_launch)
	on_exit = schedule_wrap_safe(on_exit)
	on_error = schedule_wrap_safe(on_error)
	on_stderror = schedule_wrap_safe(on_stderror)

	local stdin = uv.new_pipe(false)
	local stdout = uv.new_pipe(false)
	local stderr = uv.new_pipe(false)
	local handle, pid_or_err

	local exit = function(code, signal)
		stdin:close()
		stdout:close()
		stderr:close()
		handle:close()
		handle:kill(9)

		on_exit(code, signal)
	end

	local ok, cmd, args = pcall(get_spawn_cmd, config)
	if not ok then
		on_error(cmd)
		return
	end

	handle, pid_or_err = uv.spawn(cmd, {
		args = args,
		stdio = { stdin, stdout, stderr },
		detached = true,
	}, function(code, signal)
		exit(code, signal)
	end)

	if not handle then
		on_error(pid_or_err)
		return
	end

	local proc = { exit = exit, pid = pid_or_err, handle = handle }

	stdout:read_start(function(err, chunk)
		assert(not err, err)
		if not chunk then
			return
		end

		local port = chunk:gsub("\n", "")
		on_launch(port, proc)
	end)

	stderr:read_start(function(err, chunk)
		if not chunk then
			return
		end

		on_stderror(chunk)
	end)

	return proc
end

M.get_spawn_cmd = get_spawn_cmd
return M
