local M = {}

local function execute_rg_command(args)
	local result = vim.system(args, { text = true }):wait()

	if result.code ~= 0 then
		return nil, result.stderr or "Command failed"
	end

	return result.stdout:gsub("\n$", "")
end

function M.find_projects(base_dir, exclude_dirs, max_results)
	local projects = {}

	local max_limit = max_results or 50
	local args = {
		"rg",
		"--files",
		"--glob",
		"**/.git/config",
		"--hidden",
		"--no-ignore",
		base_dir,
	}

	local result = execute_rg_command(args)
	if not result then
		return {}
	end

	local count = 0
	for config_path in result:gmatch("[^\n]+") do
		if count >= max_limit then
			break
		end

		local project_dir = config_path:gsub("/.git/config$", "")
		if project_dir ~= config_path then
			local should_exclude = false
			if exclude_dirs then
				for _, exclude_dir in ipairs(exclude_dirs) do
					local normalized_project = project_dir:gsub("/$", "")
					local escaped_exclude = exclude_dir:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
					local pattern = "/" .. escaped_exclude .. "/"
					local end_pattern = "/" .. escaped_exclude .. "$"

					if normalized_project:find(pattern) or normalized_project:find(end_pattern) then
						should_exclude = true
						break
					end
				end
			end

			if not should_exclude then
				table.insert(projects, project_dir)
				count = count + 1
			end
		end
	end

	return projects
end

return M
