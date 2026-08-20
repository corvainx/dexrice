return {
  {
    "zenbones-theme/zenbones.nvim",
    dependencies = { "rktjmp/lush.nvim" },
    lazy = false,
    priority = 1000,
    -- config = function()
    --   vim.o.background = "dark"
    --   vim.g.zenbones_darkness = "stark" -- 'stark' or 'warm', stark = darkest
    --   vim.cmd.colorscheme("zenbones")
    --   local lush = require("lush")
    --   local base = require("zenbones")
    --   local specs = lush.parse(function()
    --     return {
    --       Normal({ base.Normal, bg = "#0a0a0a" }),
    --       NormalNC({ base.Normal, bg = "#0a0a0a" }),
    --       SignColumn({ base.Normal, bg = "#0a0a0a" }),
    --
    --       -- neo-tree
    --       NeoTreeNormal({ base.Normal, bg = "#0a0a0a" }),
    --       NeoTreeNormalNC({ base.Normal, bg = "#0a0a0a" }),
    --       NeoTreeEndOfBuffer({ base.Normal, bg = "#0a0a0a" }),
    --
    --       -- snacks.explorer / picker
    --       SnacksPicker({ base.Normal, bg = "#0a0a0a" }),
    --       SnacksPickerList({ base.Normal, bg = "#0a0a0a" }),
    --       SnacksPickerBorder({ base.Normal, bg = "#0a0a0a" }),
    --       SnacksPickerInput({ base.Normal, bg = "#0a0a0a" }),
    --       SnacksPickerBox({ base.Normal, bg = "#0a0a0a" }),
    --     }
    --   end)
    --   lush.apply(specs)
    -- end,
  },
}

-- uncomment everything above to use this theme
