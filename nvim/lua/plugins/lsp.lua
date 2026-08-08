return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = {
        enabled = false,
      },

      servers = {
        clangd = {},
        pyright = {},
        gopls = {},
        rust_analyzer = {},
        jdtls = {},
      },
    },
  },
}
