filetype plugin off

set rtp+=.
set rtp+=./lib/plenary.nvim
set rtp+=./lib/nvim-dap
set rtp+=./lib/nvim-dap-ui
set rtp+=./tests

let $PLENARY_TEST_TIMEOUT=2000 

runtime! plugin/plenary.vim
lua DEBUGGER_PATH="./lib/vscode-js-debug"
