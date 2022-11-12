---@tag dap-vscode-js

---@class Settings @Plugin configuration options
---@field node_path string: Path of node executable. Defaults to $NODE_PATH, and then "node"
---@field debugger_path string: Path to vscode-js-debug. Defaults to (runtimedir)/site/pack/packer/opt/vscode-js-debug
---@field debugger_cmd string[]: The command to use to launch the debug server. This option takes precedence over both `node_path` and `debugger_path`.
---@field adapters string[]: List of adapters to configure. Options are 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost'. Defaults to all. See https://github.com/microsoft/vscode-js-debug/blob/main/OPTIONS.md for configuration options.
---@field log_file_path string: Log file path. Defaults to (stdpath cache)/dap_vscode_js.log
---@field log_file_level number: Logging level for output to file. Set to false to disable file logging. Default is false.
---@field log_console_level number: Logging level for output to console. Set to false to disable console output. Default is vim.log.levels.ERROR.

local config = require("dap-vscode-js.config")
local js_session = require("dap-vscode-js.session")
local js_dap = require("dap-vscode-js.dap")
local logger = require("dap-vscode-js.log")

local dapjs = {}

---Setup adapter and/or configs
---@param settings Settings
---@param force boolean?
function dapjs.setup(settings, force)
	config.__set_config(settings, force or true)
	js_session.setup_hooks("dap-vscode-js", config)
	js_dap.attach_adapters(config)

	logger.debug("Plugin initialized!")
end

return dapjs
