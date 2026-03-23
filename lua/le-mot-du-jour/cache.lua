local util = require("le-mot-du-jour.util")

local M = {}

function M.daily_file(cache_dir)
	return cache_dir .. "/mdj_" .. os.date("%Y%m%d") .. ".json"
end

function M.log_file(cache_dir)
	return cache_dir .. "/mdj_log.json"
end

function M.read_daily(cache_dir)
	local file = M.daily_file(cache_dir)
	local content = util.read_file(file)
	if not content or content == "" then
		return nil
	end

	local ok, data = pcall(vim.fn.json_decode, content)
	if ok then
		return data
	end

	return nil
end

function M.write_daily(cache_dir, data)
	local file = M.daily_file(cache_dir)
	local json_str = vim.fn.json_encode(data)
	local content = json_str

	if util.has_exec("jq") then
		local pretty = vim.fn.system({ "jq", "." }, json_str)
		if vim.v.shell_error == 0 and pretty and pretty ~= "" then
			content = pretty
		end
	end

	return util.write_file(file, content)
end

function M.append_log(cache_dir, date_str, word)
	local file = M.log_file(cache_dir)
	local data = {}

	local content = util.read_file(file)
	if content and content ~= "" then
		local ok, decoded = pcall(vim.fn.json_decode, content)
		if ok and type(decoded) == "table" then
			data = decoded
		end
	end

	table.insert(data, { date = date_str, word = word })

	return util.write_file(file, vim.fn.json_encode(data))
end

return M
