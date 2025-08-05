local M = {}

local function execute_rg_command(args)
	local result = vim.system(args, { text = true }):wait()

	if result.code ~= 0 and (not result.stdout or result.stdout == "") then
		return nil, result.stderr or "Command failed"
	end

	return result.stdout and result.stdout:gsub("\n$", "") or ""
end

local function search_git_configs(search_path)
	local args = {
		"rg",
		"--files",
		"--glob",
		"**/.git/config",
		"--hidden",
		"--no-ignore",
		search_path,
	}
	return execute_rg_command(args)
end

function M.find_projects(base_dir, include_dirs, max_results)
	local projects = {}
	local max_limit = max_results or 50
	local count = 0

	local search_paths = {}
	if not include_dirs or #include_dirs == 0 then
		table.insert(search_paths, base_dir)
	else
		for _, include_dir in ipairs(include_dirs) do
			local search_path = base_dir .. "/" .. include_dir
			if vim.fn.isdirectory(search_path) == 1 then
				table.insert(search_paths, search_path)
			end
		end
	end

	for _, search_path in ipairs(search_paths) do
		if count >= max_limit then
			break
		end

		local result = search_git_configs(search_path)
		if result then
			for config_path in result:gmatch("[^\n]+") do
				if count >= max_limit then
					break
				end
				local project_dir = config_path:gsub("/.git/config$", "")
				if project_dir ~= config_path then
					table.insert(projects, project_dir)
					count = count + 1
				end
			end
		end
	end

	return projects
end

return M
