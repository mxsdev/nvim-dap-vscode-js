---@tag dap-vscode-js

---@class Settings @Plugin configuration options
---@field node_path string: Path of node executable. Defaults to $NODE_PATH, and then "node"
---@field debugger_path string: Path to vscode-js-debug. Defaults to (runtimedir)/site/pack/packer/opt/vscode-js-debug
---@field debugger_cmd string[]?: The command to use to launch the debug server. This option takes precedence over both `node_path` and `debugger_path`.
---@field adapters string[]: List of adapters to configure. Options are 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost'. Defaults to all. See https://github.com/microsoft/vscode-js-debug/blob/main/OPTIONS.md for configuration options.

local config = require("dap-vscode-js.config")
local js_session = require("dap-vscode-js.session")
local js_dap = require("dap-vscode-js.dap")

local dapjs = {}

---Setup adapter and/or configs
---@param settings string
function dapjs.setup(settings, force)
	config.__set_config(settings, force or true)
	js_session.setup_hooks("dap-vscode-js", config)
	js_dap.attach_adapters(config)
end

return dapjs
