local utils = require("dap-vscode-js.utils")
local async = require("plenary.async.tests")
local wrap = require("plenary.async.async").wrap
-- local async = require"dap-vscode-js-tests.utils".async

describe("dap-vscode-js.utils", function()
	describe(".start_debugger", function()
		async.it(
			"can start successfully",
			wrap(function(done)
				utils.start_debugger({
					debugger_path = DEBUGGER_PATH,
					node_path = "node",
				}, function()
					done()
				end, function(code, signal)
					assert.falsy(code)
				end, function(err)
					assert.falsy(err)
				end, function(err)
					error(err)
				end)
			end, 1)
		)
	end)
end)
