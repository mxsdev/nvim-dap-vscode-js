local utils = require"dap-vscode-js.utils"

local defaults = {
  node_path = os.getenv("NODE_PATH") or "node",
  debugger_path = utils.join_paths(utils.get_runtime_dir(), 'site/pack/packer/opt/vscode-js-debug'),
}

local config = vim.deepcopy(defaults)

function config.__set_config(settings, force)
  local new_config = vim.tbl_extend('force', (force and defaults) or config, settings)

  -- clear current config
  for key, _ in pairs(config) do
    config[key] = nil
  end 

  -- set config
  for key, val in pairs(new_config) do
    config[key] = val
  end
end

return config
