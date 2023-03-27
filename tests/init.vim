filetype plugin off

set rtp+=.
set rtp+=./lib/plenary.nvim
set rtp+=./lib/nvim-dap
set rtp+=./lib/nvim-dap-ui
set rtp+=./tests

set noswapfile

" let $PLENARY_TEST_TIMEOUT=60000 

runtime! plugin/plenary.vim
lua DEBUGGER_PATH="./lib/vscode-js-debug/dist/src/dapDebugServer.js"
lua LOG_PATH="./lib/dap-vscode-js.log"
