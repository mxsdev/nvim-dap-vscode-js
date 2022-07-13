local breakpoints = require("dap.breakpoints")
local async = require("plenary.async.tests")
local wrap = require("plenary.async.async").wrap
local dapjs = require("dap-vscode-js")
local js_session = require("dap-vscode-js.session")
local dap = require("dap")
local test_utils = require("__dap_js_test_util")
local config = require("dap-vscode-js.config")
local utils = require("dap-vscode-js.utils")

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

local neotest_launch_config = {
	args = {
		-- "--config=/Users/maxstoumen/Projects/test/jest.config.js",
		"--config=" .. utils.join_paths(workDir, "jest.config.js"),
		"--no-coverage",
		"--testLocationInResults",
		"--verbose",
		"--json",
		-- "--outputFile=/var/folders/d2/yrk2x5gd6dq4z2t3d7v3t0880000gn/T/nvim.maxstoumen/oIW7qq/0.json",
		"--testNamePattern='test 2$'",
		-- "/Users/maxstoumen/Projects/test/jest.test.ts",
		utils.join_paths(workDir, "integration.test.ts"),
	},
	console = "integratedTerminal",
	internalConsoleOptions = "neverOpen",
	name = "Debug Jest Tests",
	request = "launch",
	-- runtimeExecutable = "/Users/maxstoumen/Projects/test/node_modules/.bin/jest",
	runtimeExecutable = utils.join_paths(workDir, "node_modules/.bin/jest"),
	type = "pwa-node",
	cwd = "${workspaceFolder}",
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
				local clear = nil

				local terminated = false

				local lines_found = {
					["Tests:       1 failed, 1 passed, 2 total"] = false,
					["Ran all test suites."] = false,
					["Waiting for the debugger to disconnect..."] = false,
				}

				local function try_exit()
					if terminated and vim.tbl_count(lines_found) == 0 then
						done()

						clear()
					end
				end

				clear = test_utils.get_terminal_remote(function(lines)
					for _, line in ipairs(lines) do
						lines_found[line] = nil
					end

					try_exit()
				end)

				test_utils.open_test("jest/integration.test.ts")

				test_utils.on_session_end(function()
					terminated = true

					try_exit()
				end)

				dap.run(launch_config)
			end, 1)
		)

		describe("with neotest config", function()
			async.it(
				"can acknowledge and continue from breakpoints",
				wrap(function(done)
					test_utils.open_test("jest/integration.test.ts")

					local bp_line = 10

					test_utils.set_breakpoint(bp_line)

					local initial_buffer = vim.api.nvim_get_current_buf()

					local did_stop = false

					test_utils.add_listener("after", "event_stopped", function(session, body)
						assert.equal(body.reason, "breakpoint")

						did_stop = true
					end)

					local did_stacktrace = false

					-- we must wait for stackTrace event before continuing
					-- because the nvim-dap flow goes like this:
					--    event_stopped -> threads -> stackTrace -> allow continuing
					test_utils.add_listener("after", "stackTrace", function(session)
						if not did_stop or did_stacktrace then
							return
						end

						did_stacktrace = true

						assert.equal(vim.api.nvim_get_current_buf(), initial_buffer)

						local bp_signs = test_utils.get_pos_breakpoint_signs(0)

						assert.same(bp_signs, {
							{
								bufnr = initial_buffer,
								signs = {
									{
										group = "dap_pos",
										id = 1,
										lnum = bp_line,
										name = "DapStopped",
										priority = 12,
									},
								},
							},
						})

						dap.continue()
					end)

					test_utils.on_session_end(function()
						assert.equal(did_stop, true)

						local bpsigns = test_utils.get_breakpoint_signs(0)

						assert.same(bpsigns, {
							{
								bufnr = initial_buffer,
								signs = {
									{
										group = "dap_breakpoints",
										id = 1,
										lnum = bp_line,
										name = "DapBreakpoint",
										priority = 11,
									},
								},
							},
						})

						done()
					end)

					dap.run(neotest_launch_config)
				end, 1)
			)
		end)
	end)
end)
