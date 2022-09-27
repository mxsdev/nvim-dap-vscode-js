local utils = require("dap-vscode-js.utils")
local async = require("plenary.async.tests")
local wrap = require("plenary.async.async").wrap
local config = require("dap-vscode-js.config")
local test_utils = require("__dap_js_test_util")

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

	describe(".get_spawn_cmd", function()
		it("will use debug_cmd when provided", function()
			test_utils.setup_dapjs({
				debugger_cmd = { "a", "b", "c" },
			})

			local cmdname, args = utils.get_spawn_cmd(config)
			assert.same(cmdname, "a")
			assert.same(args, { "b", "c" })
		end)

		it("will error when debug_cmd is invalid", function()
			test_utils.setup_dapjs({
				debugger_cmd = {},
			})

			assert.errors(function()
				utils.get_spawn_cmd(config)
			end)
		end)
	end)
end)
