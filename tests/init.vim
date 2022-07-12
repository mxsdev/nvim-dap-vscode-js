filetype plugin off

set rtp+=.
set rtp+=./lib/plenary.nvim
set rtp+=./lib/nvim-dap
set rtp+=./lib/nvim-dap-ui
set rtp+=./tests

" let $PLENARY_TEST_TIMEOUT=60000 

runtime! plugin/plenary.vim
lua DEBUGGER_PATH="./lib/vscode-js-debug"
lua LOG_PATH="./lib/dap-vscode-js.log"
