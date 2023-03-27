local js_adapter = require("dap-vscode-js.legacy.adapter")
local js_session = require("dap-vscode-js.legacy.session")
local js_dap = require("dap-vscode-js.dap")

local M = {}

--- Whether or not to use legacy module 
--- @param config Settings 
--- @return boolean 
function M.use_legacy(config)
  -- TODO: figure out if `startDebugging` is supported
  return config.legacy_flat_debugger
end

function M.setup(config)
  -- js_session.setup_hooks("dap-vscode-js", config)
  -- js_dap.attach_adapters(config, js_adapter.generate_adapter)
end

return M
