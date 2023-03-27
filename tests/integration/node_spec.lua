local async = require("plenary.async.tests")
local wrap = require("plenary.async.async").wrap
local dap = require("dap")
local test_utils = require("__dap_js_test_util")

local launch_config = {
	type = "pwa-node",
	request = "launch",
	name = "Launch file",
	program = "${file}",
	cwd = "${workspaceFolder}",
}

describe("pwa-node", function()
	before_each(function()
		test_utils.reset()
		test_utils.setup_dapjs()
	end)

	describe("typescript", function()
		async.it(
			"can be debugged with simple config",
			wrap(function(done)
				test_utils.open_test("test1.ts")

				local console = {}

				local output_happened = false
				local termination_happened = false

				local function try_exit()
					if output_happened and termination_happened then
						done()
					end
				end

				test_utils.add_listener("before", "event_output", function(session, body)
					if body.category == "stdout" then
						table.insert(console, body.output)
					end

					if #console >= 3 then
						assert.same(console, { "4\n", "2\n", "6\n" })
						output_happened = true
					end

					try_exit()
				end)

        test_utils.add_listener("before", "event_terminated", function ()
          termination_happened = true
          try_exit()
        end)

				dap.run(launch_config)
			end, 1)
		)
	end)
end)
