local utils = require("dap-vscode-js.utils")

local defaults = {
	node_path = os.getenv("NODE_PATH") or "node",
  debugger_executable = utils.join_paths(utils.get_runtime_dir(), "site/pack/packer/opt/vscode-js-debug/dist/src/dapDebugServer.js"),
  debugger_args = {},
  adapter_executable_config = nil,

	log_file_path = utils.join_paths(utils.get_cache_dir(), "dap_vscode_js.log"),
	log_file_level = false,
	log_console_level = vim.log.levels.WARN,

  -- legacy
  debugger_cmd = nil,
  debugger_path = utils.join_paths(utils.get_runtime_dir(), "site/pack/packer/opt/vscode-js-debug"),
  legacy_flat_debugger = false,
}

local config = vim.deepcopy(defaults)

local function __set_config(settings, force, table)
	local new_config = vim.tbl_extend("force", (force and defaults) or table, settings)

	-- clear current table
	for key, _ in pairs(table) do
		table[key] = nil
	end

	-- set table
	for key, val in pairs(new_config) do
		table[key] = val
	end
end

setmetatable(config, {
	__index = function(table, key)
		if key == "__set_config" then
			return function(settings, force)
				return __set_config(settings, force, table)
			end
		end
	end,
})

return config
