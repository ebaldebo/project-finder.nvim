local health = vim.health or require("health")
local start = health.start or health.report_start
local ok = health.ok or health.report_ok
local error = health.error or health.report_error

local M = {}

function M.check()
	start("project-finder.nvim")

	if vim.fn.executable("rg") == 1 then
		ok("ripgrep found")
	else
		error("ripgrep not found")
	end
end

return M
