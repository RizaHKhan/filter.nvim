local M = {}

---@class filter.Config
---@field setup_keybindings? boolean
---@field keymap? string
---@field debounce? number

---@type filter.Config
local defaults = {
  setup_keybindings = true,
  keymap = "<leader>j",
  debounce = 200,
}

---@type filter.Config
---@diagnostic disable-next-line: missing-fields
M.options = nil

---@return filter.Config
function M.read()
  return M.options or defaults
end

---@param config filter.Config
---@return filter.Config
function M.setup(config)
  M.options = vim.tbl_deep_extend("force", {}, defaults, config or {})

  return M.options
end

return M
