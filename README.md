# project-finder.nvim

Find and switch between projects in Neovim

## Features
- Auto-detect projects using ripgrep
- Configurable search directories  
- Integration with any fuzzy finder

## Installation

### Neovim 0.12+ (native package manager)
```lua
vim.pack.add({
    "https://github.com/ebaldebo/project-finder.nvim",
})

require("project-finder").setup()
```

### lazy.nvim
```lua
{
  "ebaldebo/project-finder.nvim",
  config = function()
    require("project-finder").setup()
  end,
}
```

### packer.nvim
```lua
use {
  "ebaldebo/project-finder.nvim",
  config = function()
    require("project-finder").setup()
  end,
}
```

## Usage

### Basic Example
```lua
vim.keymap.set("n", "<leader>fp", function()
    local display_projects, project_paths = require("project-finder").get_display_projects()
    vim.ui.select(display_projects, {
        prompt = "Projects> ",
    }, function(selected)
        if selected then
            for i, display_name in ipairs(display_projects) do
                if display_name == selected then
                    require("project-finder").change_to_project(project_paths[i])
                    break
                end
            end
        end
    end)
end)
```

### With fzf-lua
```lua
vim.keymap.set("n", "<leader>fp", function()
    local display_projects, project_paths = require("project-finder").get_display_projects()
    require("fzf-lua").fzf_exec(display_projects, {
        prompt = "Projects> ",
        actions = {
            ["default"] = function(selected)
                if #selected > 0 then
                    local selected_display = selected[1]
                    for i, display_name in ipairs(display_projects) do
                        if display_name == selected_display then
                            require("project-finder").change_to_project(project_paths[i])
                            break
                        end
                    end
                end
            end,
        },
    })
end)
```

## Configuration

### Default Config
```lua
require("project-finder").setup({
    include_dirs = {
        "Developer",
        "Projects", 
        "Code",
        "src",
        "workspace",
        "repos",
        "git",
        ".config",
        "Documents/GitHub",
        "Documents/Projects",
    },
    max_results = 50,
    search_root = "~",
    detectors = {
        git = { enabled = true },
    },
})
```

### Options
| Option | Description | Default |
| --- | --- | --- |
| `include_dirs` | Directories to search within (replaces defaults) | See above |
| `max_results` | Maximum number of projects to return | `50` |
| `search_root` | Root directory to start search | `~` |
| `detectors.git.enabled` | Enable Git project detection | `true` |

## Requirements
- [ripgrep](https://github.com/BurntSushi/ripgrep) (rg command)
