local M = {}
local dap = require("dap")
local js_adapter = require("dap-vscode-js.adapter")

local DAP_TYPES = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" }

local function filter_adapters(list)
	return vim.tbl_filter(function(el)
		return vim.tbl_contains(DAP_TYPES, el)
	end, list)
end

function M.attach_adapters(config)
	local adapter_list = filter_adapters(config.adapters or DAP_TYPES)

	for _, adapter in ipairs(adapter_list) do
		dap.adapters[adapter] = js_adapter.generate_adapter(adapter, config)
	end
end

return M
