local breakpoints = require("dap.breakpoints")
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

local current_session

describe("pwa-node", function()
	before_each(function()
		test_utils.reset()
		test_utils.setup_dapjs()
	end)

  async.it(
    "wont reject valid breakpoints",
    wrap(function(done)
      test_utils.open_test("test1.ts")
      local bufexpr = vim.api.nvim_get_current_buf()

      local breakpoint_accepted = false
      local breakpoint_stopped = false

      test_utils.set_breakpoint(3, bufexpr)

      test_utils.add_listener("after", "event_breakpoint", function(session, body)
        local bps = breakpoints.get(bufexpr)[bufexpr]

        assert.equal(#bps, 1)

        local bp_signs = test_utils.get_breakpoint_signs(bufexpr)

        assert.equal(#bp_signs, 1)

        for _, bp in ipairs(bp_signs) do
          assert.equal(#bp.signs, 1)

          for _, sign in ipairs(bp.signs) do
            assert.equal("DapBreakpoint", sign.name)
          end
        end

        breakpoint_accepted = true
      end)

      test_utils.add_listener("after", "event_stopped", function(session, body)
        assert.equal(body.reason, "breakpoint")
        breakpoint_stopped = true

        vim.defer_fn(function ()
          dap.continue()
        end, 200)
      end)

      test_utils.add_listener("before", "event_terminated", function ()
        assert.equal(true, breakpoint_accepted)
        assert.equal(true, breakpoint_stopped)

        done()
      end)

      dap.run(launch_config)
    end, 1)
  )
end)
