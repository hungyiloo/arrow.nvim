local M = {}

function M.cwd()
  return vim.uv.cwd() or ""
end

function M.git_root()
  local cwd = M.cwd()
  local git_root = vim.fs.find(".git", { path = cwd, upward = true })[1]
  git_root = git_root and vim.fn.fnamemodify(git_root, ":h") or cwd
  return git_root
end

function M.global()
  return "global"
end

function M.git_root_bare()
	local git_bare_root = vim.fn.system("git rev-parse --path-format=absolute --git-common-dir 2>&1")

	if vim.v.shell_error == 0 then
		git_bare_root = git_bare_root:gsub("/%.git\n$", "")
		return git_bare_root:gsub("\n$", "")
	end

	return M.cwd()
end

return M
