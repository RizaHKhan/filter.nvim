# filter.nvim

A simple, kulala.nvim-inspired filter buffer for interactively filtering JSON and YAML data using `jq` and `yq` in Neovim.

## Features

- Simple filter buffer interface inspired by [kulala.nvim](https://neovim.getkulala.net/)
- Automatic detection of JSON/YAML files
- Filter entire files or visual selections
- Real-time filtering with jq/yq
- Easy keybindings: press Enter to apply filter
- Quick yank results to clipboard

## Installation

### `lazy.nvim`

```lua
{
  "your-username/filter.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("filter").setup()
  end,
}
```

## Configuration

### Default Setup

The plugin works out of the box with sensible defaults:

```lua
require("filter").setup({
  setup_keybindings = true,  -- Automatically set up <leader>j keybinding (default: true)
  keymap = "<leader>j",      -- The keymap to use (default: "<leader>j")
  debounce = 200,           -- Debounce time in ms (default: 200)
})
```

### Manual Keybindings

If you prefer to set up keybindings manually, disable automatic setup:

```lua
require("filter").setup({
  setup_keybindings = false,
})

-- Then set up your own keybindings
vim.keymap.set("n", "<leader>j", function()
  require("filter").open_filter()
end, { desc = "Open JQ/YQ Filter" })

vim.keymap.set("v", "<leader>j", function()
  require("filter").open_filter()
end, { desc = "Filter selected JSON/YAML" })
```

## Usage

### Filter entire file

1. Open a JSON or YAML file
2. Press `<leader>j` (or your custom keymap)
3. A split buffer opens with a filter line at the top: `JQ Filter: .` or `YQ Filter: .`
4. Edit the filter query and press `<CR>` (Enter) to apply
5. Results appear below the filter line

### Filter visual selection

1. Select JSON/YAML text in visual mode (v, V, or Ctrl-v)
2. Press `<leader>j`
3. The selected text will be filtered in the new buffer

### Filter Buffer Keybindings

When the filter buffer is open:

- `<CR>` (Enter) - Apply the filter (when cursor is on filter line)
- `q` - Close the filter buffer
- `y` - Yank results to clipboard

### Example Filters

For JSON files (uses `jq`):
```
JQ Filter: .users[0].name
JQ Filter: .[] | select(.age > 25)
JQ Filter: .items | map(.price)
JQ Filter: keys
```

For YAML files (uses `yq`):
```
YQ Filter: .metadata.name
YQ Filter: .spec.containers[0].image
YQ Filter: .data
```

## How It Works

- The plugin automatically detects the filetype (JSON or YAML)
- For JSON files, it uses `jq` for filtering
- For YAML files, it uses `yq` for filtering
- Results are updated in real-time as you modify the filter
- The filter buffer shows both the filter input and results in a single view
- Cursor automatically positions after the `.` for easy editing

## Requirements

- Neovim 0.8+
- `jq` command-line tool for JSON filtering
- `yq` command-line tool for YAML filtering (optional, only needed for YAML files)
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## Inspiration

This plugin is inspired by [kulala.nvim](https://neovim.getkulala.net/)'s filter response feature, which provides a clean and simple way to filter API responses. filter.nvim brings that same simplicity to filtering JSON and YAML files.

## License

MIT
