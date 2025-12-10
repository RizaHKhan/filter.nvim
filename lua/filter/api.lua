local M = {
  _ = {},
}

local config = require("filter.config")

---@class filter.FilterOpts
---@field lines? string[]
---@field filetype? string

--- Opens a filter buffer similar to kulala.nvim
---@param opts? filter.FilterOpts
function M.open_filter(opts)
  opts = opts or {}

  local c = config.read()

  -- Get source content
  local source_bufnr = vim.api.nvim_get_current_buf()
  local lines = opts.lines

  if not lines then
    -- Check if in visual mode to get selection
    local mode = vim.fn.mode()
    if mode == "v" or mode == "V" or mode == "\22" then -- \22 is <C-v>
      local start_pos = vim.fn.getpos("'<")
      local end_pos = vim.fn.getpos("'>")
      lines = vim.api.nvim_buf_get_lines(source_bufnr, start_pos[2] - 1, end_pos[2], false)
    else
      lines = vim.api.nvim_buf_get_lines(source_bufnr, 0, -1, false)
    end
  end

  -- Detect filetype
  local filetype = opts.filetype
  if not filetype then
    filetype = vim.api.nvim_get_option_value("filetype", { buf = source_bufnr })
  end

  -- Determine which tool to use (jq for json, yq for yaml)
  local tool = "jq"
  local result_ft = "json"
  if filetype == "yaml" or filetype == "yml" then
    tool = "yq"
    result_ft = "yaml"
  end

  -- Close existing filter buffer if open
  if M._.filter_bufnr and vim.api.nvim_buf_is_valid(M._.filter_bufnr) then
    vim.api.nvim_buf_delete(M._.filter_bufnr, { force = true })
  end
  if M._.result_bufnr and vim.api.nvim_buf_is_valid(M._.result_bufnr) then
    vim.api.nvim_buf_delete(M._.result_bufnr, { force = true })
  end

  -- Create new buffer for filter UI
  local bufnr = vim.api.nvim_create_buf(false, true)
  M._.filter_bufnr = bufnr

  -- Create result buffer
  local result_bufnr = vim.api.nvim_create_buf(false, true)
  M._.result_bufnr = result_bufnr
  vim.api.nvim_set_option_value("filetype", result_ft, { buf = result_bufnr })
  vim.api.nvim_set_option_value("modifiable", false, { buf = result_bufnr })

  -- Set buffer options
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = bufnr })
  vim.api.nvim_set_option_value("swapfile", false, { buf = bufnr })
  vim.api.nvim_set_option_value("filetype", result_ft, { buf = bufnr })

  -- Open in a new split
  vim.cmd("rightbelow vsplit")
  vim.api.nvim_win_set_buf(0, bufnr)

  -- Set initial content with filter line
  local filter_line = string.format("%s Filter: .", tool:upper())
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { filter_line, "", "--- Results ---" })

  -- Store the source data and tool
  M._.source_lines = lines
  M._.tool = tool
  M._.result_ft = result_ft

  -- Set up keymaps
  local function apply_filter()
    local first_line = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1]
    local filter = first_line:match("^%w+ Filter:%s*(.*)$") or "."

    if filter == "" then
      filter = "."
    end

    -- Run the filter
    local Job = require("plenary.job")
    Job:new({
      command = tool,
      args = { filter },
      writer = M._.source_lines,
      on_exit = vim.schedule_wrap(function(j, code)
        if code == 0 then
          local results = j:result()
          vim.api.nvim_set_option_value("modifiable", true, { buf = result_bufnr })
          vim.api.nvim_buf_set_lines(result_bufnr, 0, -1, false, results)
          vim.api.nvim_set_option_value("modifiable", false, { buf = result_bufnr })

          -- Update the results section in filter buffer
          vim.api.nvim_buf_set_lines(bufnr, 2, -1, false, results)
        else
          local errors = j:stderr_result()
          vim.api.nvim_set_option_value("modifiable", true, { buf = result_bufnr })
          vim.api.nvim_buf_set_lines(result_bufnr, 0, -1, false, errors)
          vim.api.nvim_set_option_value("modifiable", false, { buf = result_bufnr })

          -- Update with errors
          vim.api.nvim_buf_set_lines(bufnr, 2, -1, false, errors)
        end
      end),
    }):start()
  end

  -- Apply filter on Enter in first line
  vim.keymap.set("n", "<CR>", function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    if cursor[1] == 1 then
      apply_filter()
    end
  end, { buffer = bufnr, silent = true })

  vim.keymap.set("i", "<CR>", function()
    local cursor = vim.api.nvim_win_get_cursor(0)
    if cursor[1] == 1 then
      apply_filter()
      return "<Esc>"
    end
    return "<CR>"
  end, { buffer = bufnr, expr = true, silent = true })

  -- Close buffer on q
  vim.keymap.set("n", "q", function()
    if M._.filter_bufnr and vim.api.nvim_buf_is_valid(M._.filter_bufnr) then
      vim.api.nvim_buf_delete(M._.filter_bufnr, { force = true })
    end
    if M._.result_bufnr and vim.api.nvim_buf_is_valid(M._.result_bufnr) then
      vim.api.nvim_buf_delete(M._.result_bufnr, { force = true })
    end
  end, { buffer = bufnr, silent = true })

  -- Yank results
  vim.keymap.set("n", "y", function()
    local results = vim.api.nvim_buf_get_lines(bufnr, 2, -1, false)
    vim.fn.setreg('"', table.concat(results, "\n"))
    vim.notify("Results yanked to clipboard", vim.log.levels.INFO)
  end, { buffer = bufnr, silent = true })

  -- Position cursor on filter line on the period
  local dot_pos = filter_line:find("%.")
  vim.api.nvim_win_set_cursor(0, { 1, dot_pos - 1 })

  -- Run initial filter
  vim.schedule(function()
    apply_filter()
  end)
end

return M
