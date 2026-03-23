local M = {}

function M.parse_definitions(text)
	local result = { def = "", meanings = {} }

	if not text or vim.trim(text) == "" then
		return result
	end

	local first_num = text:find("%(%d+%)")
	if not first_num then
		result.def = vim.trim(text)
		return result
	end

	result.def = vim.trim(text:sub(1, first_num - 1))

	local pos = first_num
	while true do
		local start_pos, finish_pos = text:find("(%(%d+%))", pos)
		if not start_pos then
			break
		end

		local next_marker = text:find("\n%(", finish_pos + 1)
		local defn
		if next_marker then
			defn = text:sub(finish_pos + 1, next_marker - 1)
		else
			defn = text:sub(finish_pos + 1)
		end

		defn = vim.trim(defn)
		if #defn > 0 then
			table.insert(result.meanings, defn)
		end

		if next_marker then
			pos = next_marker + 1
		else
			break
		end
	end

	return result
end

function M.parse_dict_translation(output)
	local result = { def = {}, found = false, similar = {} }

	if not output or output == "" then
		return result
	end

	local lines = {}
	for line in output:gmatch("([^\n]+)") do
		table.insert(lines, line)
	end

	local no_def = false
	for _, line in ipairs(lines) do
		if line:find("No definitions found for", 1, true) then
			no_def = true
			break
		end
	end

	if no_def then
		if output:find("perhaps you mean:", 1, true) then
			local capture = false
			for _, line in ipairs(lines) do
				if line:find("perhaps you mean:", 1, true) then
					capture = true
				elseif capture then
					local suggestion = line:match("dict%.org%s+%d+%s+fd%-fra%-eng%s+(%S+)")
					if suggestion then
						table.insert(result.similar, suggestion)
					end
				end
			end
		end
		return result
	end

	result.found = true
	local current_def = {}

	for _, line in ipairs(lines) do
		if line:match("^%d+ definitions? found") then
		elseif line:match("^dict%.org") then
			if #current_def > 0 then
				table.insert(result.def, table.concat(current_def, "\n"))
				current_def = {}
			end
		else
			if line:match("^%s") then
				table.insert(current_def, vim.trim(line))
			end
		end
	end

	if #current_def > 0 then
		table.insert(result.def, table.concat(current_def, "\n"))
	end

	return result
end

function M.parse_trans_translation(output)
	local result = { def = {}, found = false, similar = {} }

	if not output or vim.trim(output) == "" then
		return result
	end

	result.found = true
	table.insert(result.def, vim.trim(output))
	return result
end

function M.parse_translation_output(output, backend)
	if backend == "dict" then
		return M.parse_dict_translation(output)
	end
	return M.parse_trans_translation(output)
end

return M
