local M = {}
local uv = vim.loop
local js_session = require"dap-vscode-js.session"
local utils = require"dap-vscode-js.utils"
local logger = require"dap-vscode-js.log"

local function gen_cwd(user_config, config)
  if not user_config.cwd then
    if config.cwd then
      return config.cwd
    end

    return uv.cwd()
  else
    if type(user_config.cwd) == "function" then
      return user_config.cwd(config)
    else
      return user_config.cwd
    end
  end
end

local function generate_config_enricher(user_config)
  return function(config, on_config)
    config.cwd = gen_cwd(user_config, config)

    on_config(config)
  end
end

local function start_child_session(request, proc, config)
  local body = request.arguments
  local session = nil
  local child_port = tonumber(body.config.__jsDebugChildServer)

  session = require("dap.session"):connect(
    { host = "127.0.0.1", port = child_port },
    { },
    function(err)
      if err then
        logger.log("DAP connection failed to start: " .. err, vim.log.levels.ERROR)
      else
        session:initialize(body.config)
        js_session.register_session(session, proc, child_port)
      end
    end
  )
end

local function adapter_config(port, proc, user_config)
  return {
    type = "server",
    host = "127.0.0.1",
    port = port,
    enrich_config = generate_config_enricher(user_config),
    reverse_request_handlers = {
      attachedChildSession = function(_, request)
        start_child_session(request, proc, user_config)
      end,
    },
  }
end

function M.generate_adapter(config, mode)
  return function (callback)
    local proc

    proc = utils.start_debugger(
      config,
      function(port, proc)
        callback(adapter_config(port, proc, config))
      end,
      function(code, signal)
        if proc then
          js_session.unregister_proc(proc)
        end

        if code and code ~= 0 then
          logger.log("JS Debugger exited with code " .. code .. "!", vim.log.levels.ERROR)
        end
      end, 
      function (err)
        logger.log("Error trying to launch JS debugger: " .. err, vim.log.levels.ERROR)
      end,
      function (chunk)
        logger.log("JS Debugger stderr: " .. chunk, vim.log.levels.ERROR)
      end
    )
  end
end

return M
