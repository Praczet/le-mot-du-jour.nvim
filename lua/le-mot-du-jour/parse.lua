local M = {}

function M.clean_wikicode(text)
	if not text then
		return ""
	end

	-- Remove references and comments
	text = text:gsub("<ref[^>]*>.-</ref>", "")
	text = text:gsub("<ref[^>]*/>", "")
	text = text:gsub("<!%-%-.-%-%->", "")

	-- Extract text from Links: [[Target|Label]] -> Label
	text = text:gsub("%[%[([^|%]]+)%|([^%]]+)%]%]", "%2")
	-- Links: [[Target]] -> Target
	text = text:gsub("%[%[([^%]]+)%]%]", "%1")

	-- Preserve specific templates' text
	text = text:gsub("{{lien%|([^}|]+)[^}]*}}", "%1")
	text = text:gsub("{{l%|[^|]+%|([^}|]+)[^}]*}}", "%1")
	text = text:gsub("{{w%|([^}|]+)[^}]*}}", "%1")

	-- Format domain templates into parens
	text = text:gsub("{{term%|([^}|]+)[^}]*}}", "(%1)")
	text = text:gsub("{{lexique%|([^}|]+)[^}]*}}", "(%1)")
	text = text:gsub("{{domaine%|([^}|]+)[^}]*}}", "(%1)")
	text = text:gsub("{{figuré.-}}", "(figuré)")
	text = text:gsub("{{populaire.-}}", "(populaire)")
	text = text:gsub("{{spécialement.-}}", "(spécialement)")
	text = text:gsub("{{par analogie.-}}", "(par analogie)")
	text = text:gsub("{{par extension.-}}", "(par extension)")

	-- Clean all other templates safely (run multiple times to handle nesting)
	for _ = 1, 3 do
		text = text:gsub("{{[^{}]-}}", "")
	end

	-- Clean Wiki formatting (bold, italic) and leftover HTML
	text = text:gsub("'''", "")
	text = text:gsub("''", "")
	text = text:gsub("<[^>]+>", "")

	-- Clean up weird spacing or empty parentheses
	text = text:gsub("%(%s*%)", "")
	text = text:gsub("%s+", " ")
	text = vim.trim(text)

	-- Capitalize the first letter
	if #text > 0 then
		text = text:sub(1, 1):upper() .. text:sub(2)
	end

	return text
end

function M.parse_definitions(text)
	local result = { def = "", meanings = {} }

	if not text or vim.trim(text) == "" then
		return result
	end

	-- Isolate the French section
	local fr_section = text:match("==%s*{{langue|fr}}%s*==(.*)")
	if not fr_section then
		fr_section = text:match("==%s*Français%s*==(.*)")
	end

	if not fr_section then
		fr_section = text
	else
		-- Stop at the next major section level
		local next_section = fr_section:find("\n==[^=]")
		if next_section then
			fr_section = fr_section:sub(1, next_section - 1)
		end
	end

	-- Extract definitions starting with '#' but not '#:' (examples) or '#*' (quotes)
	local definitions = {}
	for line in fr_section:gmatch("\n# ([^:*][^\n]*)") do
		local clean = M.clean_wikicode(line)
		if clean and #clean > 0 then
			table.insert(definitions, clean)
		end
	end

	if #definitions > 0 then
		result.def = definitions[1]
		for i = 2, #definitions do
			table.insert(result.meanings, definitions[i])
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
