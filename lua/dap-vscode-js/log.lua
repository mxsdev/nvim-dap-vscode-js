local M = {}

local config = require("dap-vscode-js.config")

local reverse_log_levels = {}

for key, value in pairs(vim.log.levels) do
	reverse_log_levels[value] = key
end

M.msg_prefix = ""

M.log = function(msg, level, reflect_depth)
	reflect_depth = reflect_depth or 2

	msg = M.msg_prefix .. msg
	
	if config.log_file_level and level >= config.log_file_level and config.log_file_path then
		local fp, err = io.open(config.log_file_path, "a")
		if not fp then
			print(err)
			return
		end

		local info = debug.getinfo(reflect_depth, "Sl")
		local lineinfo = info.short_src .. ":" .. info.currentline

		local str = string.format(
			"[%-6s%s %s] %s: %s\n",
			reverse_log_levels[level],
			os.date(),
			vim.loop.hrtime(),
			lineinfo,
			msg
		)

		fp:write(str)
		fp:close()
	end

	if config.log_console_level and level >= config.log_console_level then
		vim.schedule(function ()
			vim.notify(string.format("[dap-js] %s", msg), level)
		end)
	end
end

M.trace = function(msg, ...)
	return M.log(msg, vim.log.levels.TRACE, ...)
end

M.info = function(msg, ...)
	return M.log(msg, vim.log.levels.INFO, ...)
end

M.debug = function(msg, ...)
	return M.log(msg, vim.log.levels.DEBUG, ...)
end

M.error = function(msg, ...)
	return M.log(msg, vim.log.levels.ERROR, ...)
end

M.warn = function(msg, ...)
	return M.log(msg, vim.log.levels.WARN, ...)
end

return M
