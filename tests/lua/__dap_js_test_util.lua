local M = {}

local dap = require("dap")
local dap_bps = require("dap.breakpoints")
local dapjs = require("dap-vscode-js")
local dapjs_utils = require("dap-vscode-js.utils")

local dap_ns = "dap_breakpoints"

M.id = "___dap_js_test"
local util_id = "___dap_js_test_utils"

local current_session

function M.clear_listeners()
	for _, time in ipairs({ "before", "after" }) do
		for key, _ in pairs(dap.listeners[time]) do
			dap.listeners[time][key][M.id] = nil
		end
	end
end

function M.clear_config()
	dapjs.setup({}, true)
end

function M.clear_breakpoints()
	dap_bps.clear()
end

function M.reset()
	M.clear_listeners()
	M.clear_config()
	M.clear_breakpoints()
end

function M.set_breakpoint(lnum, bufnr, opts)
	dap_bps.set(opts, bufnr or 0, lnum)
end

function M.add_listener(time, event_or_command, callback)
	dap.listeners[time][event_or_command][M.id] = function(session, ...)
		if session ~= current_session then
			return
		end

		callback(session, ...)
	end
end

function M.setup_dapjs(config)
	dapjs.setup(vim.tbl_extend("force", {
		debugger_path = DEBUGGER_PATH,
	}, config or {}))

	dap.listeners.before["event_initialized"][util_id] = function(session)
		current_session = session
	end
end

function M.test_file(file)
	return dapjs_utils.join_paths("./tests/js", file)
end

function M.open_test(test)
	vim.cmd(string.format("e %s", M.test_file(test)))
end

function M.get_breakpoint_signs(bufexpr)
	return vim.fn.sign_getplaced(bufexpr, { group = dap_ns })
end

function M.get_terminal_remote(on_update)
  local old_val = dap.defaults.fallback.terminal_win_cmd

  local term_buf = vim.api.nvim_create_buf(false, false)

  dap.defaults.fallback.terminal_win_cmd = function ()
    return term_buf
  end

  vim.api.nvim_buf_attach(term_buf, false, {
    on_lines = function (_, _, _, firstline, _, new_lastline)
      local lines = vim.api.nvim_buf_get_lines(term_buf, firstline, new_lastline, true)

      on_update(lines)
    end
  })

  return function ()
    dap.defaults.fallback.terminal_win_cmd = old_val

    vim.schedule(function ()
      vim.api.nvim_buf_delete(term_buf, { force = true })
    end)
  end
end

return M
