local M = {}

M.defaults = {
	cache_dir = vim.fn.stdpath("data") .. "/mdj",
	rows = 3,
	width = 60,
	dashboard = "snacks.dashboard",
	highlights = {
		word = "key",
		definition = "text",
		last_def = "dir",
		translation = "dir",
	},
}

return M
