-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- disable markdown preview
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.opt_local.conceallevel = 0
  end,
})
