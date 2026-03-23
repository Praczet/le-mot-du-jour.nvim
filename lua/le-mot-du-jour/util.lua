local M = {}

function M.has_exec(cmd)
	return vim.fn.executable(cmd) == 1
end

function M.notify(msg, level)
	vim.schedule(function()
		vim.notify(msg, level or vim.log.levels.INFO)
	end)
end

function M.read_file(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local content = f:read("*a")
	f:close()
	return content
end

function M.write_file(path, content)
	local f = io.open(path, "w")
	if not f then
		return false
	end
	f:write(content)
	f:close()
	return true
end

function M.run_cmd(argv, callback)
	local stdout = {}
	local stderr = {}

	local jobid = vim.fn.jobstart(argv, {
		stdout_buffered = true,
		stderr_buffered = true,

		on_stdout = function(_, data)
			if data then
				vim.list_extend(stdout, data)
			end
		end,

		on_stderr = function(_, data)
			if data then
				vim.list_extend(stderr, data)
			end
		end,

		on_exit = function(_, code)
			local out = table.concat(stdout, "\n")
			local err = table.concat(stderr, "\n")

			if code == 0 then
				callback(nil, out)
			else
				if err == "" then
					err = "Command failed with exit code " .. code
				end
				callback(err, out)
			end
		end,
	})

	if jobid <= 0 then
		callback("Failed to start command", "")
	end
end

function M.wrap_line(line, width)
	local words = {}
	for w in line:gmatch("%S+") do
		table.insert(words, w)
	end

	local wrapped = {}
	local current = ""

	for _, word in ipairs(words) do
		if current == "" then
			current = word
		elseif #current + #word + 1 > width then
			table.insert(wrapped, current)
			current = word
		else
			current = current .. " " .. word
		end
	end

	if current ~= "" then
		table.insert(wrapped, current)
	end

	return table.concat(wrapped, "\n")
end

function M.wrap_text(text, width, prefix)
	prefix = prefix or ""
	local lines = {}
	local current = ""

	for word in text:gmatch("%S+") do
		if current == "" then
			current = word
		elseif #current + #word + 1 > width then
			table.insert(lines, current)
			current = word
		else
			current = current .. " " .. word
		end
	end

	if current ~= "" then
		table.insert(lines, current)
	end

	return table.concat(lines, "\n" .. prefix)
end

function M.wrap_text_preserve_newlines(text, width, prefix)
	prefix = prefix or ""
	local final_lines = {}

	for line in text:gmatch("([^\n]*)\n?") do
		if line == "" then
			table.insert(final_lines, "")
		else
			table.insert(final_lines, M.wrap_line(line, width))
		end
	end

	return table.concat(final_lines, "\n" .. prefix)
end

return M
