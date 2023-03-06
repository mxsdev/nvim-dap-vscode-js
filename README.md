# nvim-dap-vscode-js

[nvim-dap](https://github.com/mfussenegger/nvim-dap) adapter for [vscode-js-debug](https://github.com/microsoft/vscode-js-debug). 

## Adapters

Every platform supported by vscode is provided. This includes:

| Adapter             | Platform          | Support     |
|---------------------|-------------------|-------------|
| `pwa-node`          | Node.js           | Full        |
| `pwa-chrome`        | Chrome            | Partial[^1] |
| `pwa-msedge`        | Edge              | Untested    |
| `node-terminal`     | Node.js           | Untested    |
| `pwa-extensionHost` | VSCode Extensions | Untested    |

## Installation

### Plugin

Supports packer, vim-plug, etc. With packer, for example:

```lua
use { "mxsdev/nvim-dap-vscode-js", requires = {"mfussenegger/nvim-dap"} }
```

### Debugger

You must download and build a copy of [vscode-js-debug](https://github.com/microsoft/vscode-js-debug) in order to use this plugin. 

#### With Packer

```lua
use {
  "microsoft/vscode-js-debug",
  opt = true,
  run = "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out" 
}
```

#### Manually

```bash
git clone https://github.com/microsoft/vscode-js-debug
cd vscode-js-debug
npm install --legacy-peer-deps
npx gulp vsDebugServerBundle
mv dist out
```

> **Note**: The upstream build process has changed sometime since the creation of this repo. If the above scripts don't work, please make sure you're using the latest version of `vscode-js-debug`. Otherwise, feel free to file an issue!

## Setup

```lua
require("dap-vscode-js").setup({
  -- node_path = "node", -- Path of node executable. Defaults to $NODE_PATH, and then "node"
  -- debugger_path = "(runtimedir)/site/pack/packer/opt/vscode-js-debug", -- Path to vscode-js-debug installation.
  -- debugger_cmd = { "js-debug-adapter" }, -- Command to use to launch the debug server. Takes precedence over `node_path` and `debugger_path`.
  adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' }, -- which adapters to register in nvim-dap
  -- log_file_path = "(stdpath cache)/dap_vscode_js.log" -- Path for file logging
  -- log_file_level = false -- Logging level for output to file. Set to false to disable file logging.
  -- log_console_level = vim.log.levels.ERROR -- Logging level for output to console. Set to false to disable console output.
})

for _, language in ipairs({ "typescript", "javascript" }) do
  require("dap").configurations[language] = {
    ... -- see below
  }
end
```

Note that if vscode-js-debug was installed without packer, its root folder location must be set manually in `debugger_path`.

### Configurations

See [here](https://github.com/microsoft/vscode-js-debug/blob/main/OPTIONS.md) for all custom configuration options.

#### Node.js

```lua
{
  {
    type = "pwa-node",
    request = "launch",
    name = "Launch file",
    program = "${file}",
    cwd = "${workspaceFolder}",
  },
  {
    type = "pwa-node",
    request = "attach",
    name = "Attach",
    processId = require'dap.utils'.pick_process,
    cwd = "${workspaceFolder}",
  }
}
```

#### Jest[^2]

```lua
{
  {
    type = "pwa-node",
    request = "launch",
    name = "Debug Jest Tests",
    -- trace = true, -- include debugger info
    runtimeExecutable = "node",
    runtimeArgs = {
      "./node_modules/jest/bin/jest.js",
      "--runInBand",
    },
    rootPath = "${workspaceFolder}",
    cwd = "${workspaceFolder}",
    console = "integratedTerminal",
    internalConsoleOptions = "neverOpen",
  }
}
```

You may also want to check out [neotest-jest](https://github.com/haydenmeade/neotest-jest), which supports this plugin out of the box.

#### Mocha

```lua
{
  {
    type = "pwa-node",
    request = "launch",
    name = "Debug Mocha Tests",
    -- trace = true, -- include debugger info
    runtimeExecutable = "node",
    runtimeArgs = {
      "./node_modules/mocha/bin/mocha.js",
    },
    rootPath = "${workspaceFolder}",
    cwd = "${workspaceFolder}",
    console = "integratedTerminal",
    internalConsoleOptions = "neverOpen",
  }
}
```

## Planned Features

 - [ ] Integration with [neotest-jest](https://github.com/haydenmeade/neotest-jest)
 - [ ] Support for switching between child sessions

## Credits

I would like to say a huge thank you to [Jens Claes](https://github.com/entropitor), whose dotfiles this plugin is based off of, and to all members who contributed to [this issue](https://github.com/microsoft/vscode-js-debug/issues/902) - the insight gained from this was paramount to the success of this project.

[^1]: The debugger runs and attaches, however breakpoints may be rejected.
[^2]: See [here](https://github.com/microsoft/vscode-js-debug/issues/214#issuecomment-572686921) for more details on running jest
