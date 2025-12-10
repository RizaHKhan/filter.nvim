local M = {}

local api = require("filter.api")

-- Main function to open filter buffer
M.open_filter = api.open_filter

---@param config filter.Config
function M.setup(config)
  local c = require("filter.config").setup(config)

  -- Set up default keybindings if enabled
  if c.setup_keybindings then
    vim.keymap.set("n", c.keymap, function()
      M.open_filter()
    end, { desc = "Open JQ/YQ Filter" })

    vim.keymap.set("v", c.keymap, function()
      M.open_filter()
    end, { desc = "Filter selected JSON/YAML" })
  end
end

return M
