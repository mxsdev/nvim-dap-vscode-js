local dapjsconf = require("dap-vscode-js.config")
local test_utils = require("__dap_js_test_util")
local logger = require("dap-vscode-js.log")

describe("logger", function()
	after_each(function()
		test_utils.reset()
	end)

	describe(".log", function()
		it("doesnt write to log by default", function()
			local old_log = test_utils.read_log()

			test_utils.setup_dapjs({
				log_file_level = false,
			})

			logger.log("Test doesnt write to log by default", vim.log.levels.ERROR)

			local log_content = test_utils.read_log()

			assert.same(#log_content, #old_log)
		end)

		it("writes to log if level set", function()
			test_utils.setup_dapjs({
				log_file_level = vim.log.levels.INFO,
			})

			local old_log = test_utils.read_log()

			local msg = "Test message writes to log if level set"

			logger.log(msg, vim.log.levels.INFO)

			local log_content = test_utils.read_log()

			assert.is.equal(#log_content, #old_log + 1)
			assert.truthy(string.find(log_content[#old_log + 1], msg))
		end)
	end)
end)