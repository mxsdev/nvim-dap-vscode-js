local breakpoints = require("dap.breakpoints")
local async = require("plenary.async.tests")
local wrap = require("plenary.async.async").wrap
local dapjs = require("dap-vscode-js")
local dap = require("dap")
local test_utils = require("__dap_js_test_util")
local config = require("dap-vscode-js.config")

local launch_config = {
	type = "pwa-node",
	request = "launch",
	name = "Launch file",
	program = "${file}",
}

local current_session

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

				test_utils.add_listener("after", "event_terminated", function(session, body)
					termination_happened = true

					try_exit()
				end)

				dap.run(launch_config)
			end, 1)
		)

		async.it(
			"wont reject valid breakpoints",
			wrap(function(done)
				test_utils.open_test("test1.ts")
				local bufexpr = vim.api.nvim_get_current_buf()

				test_utils.set_breakpoint(3, bufexpr)

				test_utils.add_listener("after", "event_stopped", function(session, body)
					assert.equal(body.reason, "breakpoint")

					vim.defer_fn(function()
						local bps = breakpoints.get(bufexpr)[bufexpr]

						assert.equal(#bps, 1)
						assert.truthy(bps[1].state.__verified)
						assert.equal(bps[1].state.__verified, bps[1].state.verified)

						local bp_signs = test_utils.get_breakpoint_signs(bufexpr)

						for _, bp in ipairs(bp_signs) do
							for _, sign in ipairs(bp.signs) do
								assert.equal(sign.name, "DapBreakpoint")
							end
						end

						dap.continue()
					end, config.verify_timeout + 1)
				end)

				test_utils.add_listener("after", "event_terminated", function(session, body)
					done()
				end)

				dap.run(launch_config)
			end, 1)
		)

    async.it(
      "will reject breakpoints if verify_timeout unset",
      wrap(function(done)
        test_utils.open_test("test1.ts")

				test_utils.set_breakpoint(3, 0)

        dapjs.setup({
         verify_timeout = false
        }, false)


				test_utils.add_listener("after", "event_stopped", function(session, body)
          vim.defer_fn(function()
            dap.continue()
          end, 10)
        end)

        test_utils.add_listener("after", "event_terminated", function(session, body)
          local bp_signs = test_utils.get_breakpoint_signs(0)

          for _, bp in ipairs(bp_signs) do
            for _, sign in ipairs(bp.signs) do
              assert.equal(sign.name, "DapBreakpointRejected")
            end
          end

          done()
        end)

        dap.run(launch_config)
      end, 1)
    )
	end)
end)
