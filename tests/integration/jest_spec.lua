local async = require("plenary.async.tests")
local wrap = require("plenary.async.async").wrap
local dap = require("dap")
local test_utils = require("__dap_js_test_util")

local workDir = test_utils.test_file("jest")

local launch_config = {
	type = "pwa-node",
	request = "launch",
	name = "Debug Jest Tests",
	-- trace = true,
	runtimeExecutable = "node",
	runtimeArgs = {
		"./node_modules/jest/bin/jest.js",
		"--runInBand",
	},
	rootPath = workDir,
	cwd = workDir,
	console = "integratedTerminal",
	internalConsoleOptions = "neverOpen",
}

describe("pwa-node jest", function()
	before_each(function()
		test_utils.reset()
		test_utils.setup_dapjs()
	end)

	describe("typescript", function()
		async.it(
			"receives stdout from terminal",
			wrap(function(done)
				local terminated = false

				local lines_found = {
					["Tests:       1 failed, 1 passed, 2 total"] = false,
					["Ran all test suites."] = false,
					["Waiting for the debugger to disconnect..."] = false,
				}

				local function try_exit()
					if terminated and vim.tbl_count(lines_found) == 0 then
						done()
					end
				end

				test_utils.get_terminal_remote(function(lines)
					for _, line in ipairs(lines) do
						lines_found[line] = nil
					end

					try_exit()
				end)

				test_utils.open_test("jest/integration.test.ts")

        test_utils.add_listener("before", "event_terminated", function ()
					terminated = true

					try_exit()
				end)

				dap.run(launch_config)
			end, 1)
		)
	end)
end)
