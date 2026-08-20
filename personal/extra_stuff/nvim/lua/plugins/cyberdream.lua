return {
  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,

    config = function()
      require("cyberdream").setup({
        transparent = true,
      })

      vim.cmd.colorscheme("cyberdream")
    end,
  },
}

-- comment the vim.cmd.colorscheme line if u dont wanna use this theme
