local config = require("dap-vscode-js.config")
local dapjs = require("dap-vscode-js")
local test_utils = require("__dap_js_test_util")

describe("test utils", function()
	describe("clear_config", function()
		it("resets config", function()
			local default_debug_path = config.debugger_path

			dapjs.setup({
				debugger_path = "not default",
				other = "key",
			})

			assert.equal(config.debugger_path, "not default")

			test_utils.clear_config()

			assert.equal(default_debug_path, config.debugger_path)
			assert.is_nil(config.other)
		end)
	end)
end)
