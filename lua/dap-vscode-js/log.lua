local M = {}

M.log = function(msg, level)
  vim.notify(msg, level)
end

return M
