local M = {}

function M.cwd()
	return vim.loop.cwd()
end

function M.git_root()
	local cwd = M.cwd()
	local git_root = vim.fs.find(".git", { path = cwd, upward = true })[1]
	git_root = git_root and vim.fn.fnamemodify(git_root, ":h") or cwd
	return git_root
end

return M
