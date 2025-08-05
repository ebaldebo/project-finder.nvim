local M = {}

local git_detector = require("project-finder.detectors.git")

local PLUGIN_NAME = "project-finder"

local default_config = {
	exclude_dirs = {
		".local",
		".cache",
		".npm",
		".cargo",
		"node_modules",
		".git",
		".vscode",
		".docker",
	},
	max_results = 50,
	search_root = vim.fn.expand("~"),
	detectors = {
		git = { enabled = true },
	},
}

local config = {}

local function check_ripgrep_available()
	return vim.fn.executable("rg") == 1
end

local function validate_config(user_config)
	if user_config.max_results and type(user_config.max_results) ~= "number" then
		vim.notify(PLUGIN_NAME .. ": max_results must be a number", vim.log.levels.WARN)
		user_config.max_results = nil
	end

	if user_config.search_root then
		if type(user_config.search_root) ~= "string" then
			vim.notify(PLUGIN_NAME .. ": search_root must be a string", vim.log.levels.WARN)
			user_config.search_root = nil
		else
			local expanded_root = vim.fn.expand(user_config.search_root)
			if vim.fn.isdirectory(expanded_root) == 0 then
				vim.notify(
					PLUGIN_NAME .. ": search_root directory does not exist: " .. user_config.search_root,
					vim.log.levels.WARN
				)
				user_config.search_root = nil
			end
		end
	end

	if user_config.exclude_dirs and type(user_config.exclude_dirs) ~= "table" then
		vim.notify(PLUGIN_NAME .. ": exclude_dirs must be a table", vim.log.levels.WARN)
		user_config.exclude_dirs = nil
	end
end

function M.setup(user_config)
	user_config = user_config or {}
	validate_config(user_config)
	config = vim.tbl_deep_extend("force", default_config, user_config)

	if not check_ripgrep_available() then
		vim.notify(PLUGIN_NAME .. ": ripgrep not found", vim.log.levels.ERROR)
	end
end

local function run_detectors()
	local all_projects = {}

	if config.detectors and config.detectors.git and config.detectors.git.enabled then
		local git_projects = git_detector.find_projects(config.search_root, config.exclude_dirs, config.max_results)
		for _, project in ipairs(git_projects) do
			table.insert(all_projects, project)
		end
	end

	return all_projects
end

local function remove_duplicate_projects(project_paths)
	local unique_projects = {}
	local seen = {}

	for _, project_path in ipairs(project_paths) do
		if not seen[project_path] then
			seen[project_path] = true
			table.insert(unique_projects, project_path)
		end
	end

	return unique_projects
end

function M.find_projects()
	local ok, project_paths = pcall(run_detectors)
	if not ok then
		vim.notify(PLUGIN_NAME .. ": error finding projects: " .. project_paths, vim.log.levels.ERROR)
		return {}
	end

	local unique_projects = remove_duplicate_projects(project_paths)
	table.sort(unique_projects)
	return unique_projects
end

local function create_display_name(project_path)
	return project_path:gsub(vim.fn.expand("~"), "~")
end

function M.get_display_projects()
	local project_paths = M.find_projects()
	local display_names = {}

	for _, project_path in ipairs(project_paths) do
		local display_name = create_display_name(project_path)
		table.insert(display_names, display_name)
	end

	return display_names, project_paths
end

local function expand_home_path(path_with_tilde)
	return path_with_tilde:gsub("^~", vim.fn.expand("~"))
end

function M.change_to_project(project_path)
	if not project_path or project_path == "" then
		vim.notify(PLUGIN_NAME .. ": invalid project path", vim.log.levels.ERROR)
		return
	end

	local full_path = expand_home_path(project_path)
	if vim.fn.isdirectory(full_path) == 0 then
		vim.notify(PLUGIN_NAME .. ": project directory does not exist: " .. project_path, vim.log.levels.ERROR)
		return
	end

	local ok, result = pcall(vim.cmd, "cd " .. vim.fn.fnameescape(full_path))
	if not ok then
		vim.notify(PLUGIN_NAME .. ": failed to change directory: " .. result, vim.log.levels.ERROR)
		return
	end

	vim.notify("Changed to project: " .. project_path)
end

function M.get_config()
	return vim.deepcopy(config)
end

return M
