-- Module table
local M = {}

-- Configuration table
local config = {
	cache_dir = vim.fn.stdpath("data") .. "/mdj", -- Directory for caching data
	highlights = {
		word = "key", -- Highlight group for words
		definition = "text", -- Highlight group for definitions
		last_def = "dir", -- Highlight group for last definition
		translation = "dir", -- Highlight group for translations
	},
	dashboard = "snacks.dashboard", -- Dashboard module name
	rows = 3, -- Number of rows to display
	width = 60, -- Width of the display
}

local cached_mdj = nil
M.cached_mdj = nil

-- Appends a log entry to the log file.
-- @param date_str The date string.
-- @param word The word to log.
local function append_log(date_str, word)
	local log_file = config.cache_dir .. "/mdj_log.json"
	local data = {}

	if vim.loop.fs_stat(log_file) then
		local f = io.open(log_file, "r")
		if f then
			local content = f:read("*a")
			f:close()
			if content and #content > 0 then
				data = vim.fn.json_decode(content) or {}
			end
		end
	end

	table.insert(data, { date = date_str, word = word })

	local f2 = io.open(log_file, "w")
	if f2 then
		f2:write(vim.fn.json_encode(data))
		f2:close()
	else
		vim.notify("Could not write to log file: " .. log_file, vim.log.levels.ERROR)
	end
end

-- Parses the output from the translation service.
-- @param output The raw output string from the translation service.
-- @return A table containing the parsed translation data.
local function parse_translation_output(output)
	local result = { def = {}, founded = false, similar = {} }
	local lines = {}
	for line in output:gmatch("([^\n]+)") do
		table.insert(lines, line)
	end

	local no_def = false
	for _, line in ipairs(lines) do
		if line:find("No definitions found for") then
			no_def = true
			break
		end
	end

	if no_def then
		result.founded = false
		if output:find("perhaps you mean:") then
			local capture = false
			for _, line in ipairs(lines) do
				if line:find("perhaps you mean:") then
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
	else
		result.founded = true
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
end

-- Parses the definitions from the given text.
-- @param text The text containing definitions.
-- @return A table containing the parsed definitions.
local function parse_definitions(text)
	local result = { def = "", meanings = {} }
	local first_num = text:find("%(%d+%)")
	if not first_num then
		result.def = vim.trim(text)
		return result
	end

	result.def = vim.trim(text:sub(1, first_num - 1))

	local pos = first_num
	while true do
		local start, finish, num = text:find("(%(%d+%))", pos)
		if not start then
			break
		end

		local next_marker = text:find("\n%(", finish + 1)
		local defn
		if next_marker then
			defn = text:sub(finish + 1, next_marker - 1)
		else
			defn = text:sub(finish + 1)
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

-- Wraps the given text to the specified width.
-- @param text The text to wrap.
-- @param width The maximum width of each line.
-- @param prefix The prefix to add to each line.
-- @return The wrapped text.
local function wrap_text(text, width, prefix)
	local lines = {}
	local line = ""

	for word in text:gmatch("%S+") do
		if line == "" then
			line = word
		else
			if #line + #word + 1 > width then
				table.insert(lines, line)
				line = word
			else
				line = line .. " " .. word
			end
		end
	end

	if line ~= "" then
		table.insert(lines, line)
	end

	return table.concat(lines, "\n" .. prefix)
end

-- Wraps a single line of text to the specified width.
-- @param line The line of text to wrap.
-- @param width The maximum width of each line.
-- @param prefix The prefix to add to each line.
-- @return The wrapped line.
local function wrap_line(line, width, prefix)
	local words = {}
	for w in line:gmatch("%S+") do
		table.insert(words, w)
	end

	local wrapped_lines = {}
	local current = ""

	for _, word in ipairs(words) do
		if current == "" then
			current = word
		else
			if #current + #word + 1 > width then
				table.insert(wrapped_lines, current)
				current = word
			else
				current = current .. " " .. word
			end
		end
	end

	if current ~= "" then
		table.insert(wrapped_lines, current)
	end

	return table.concat(wrapped_lines, "\n")
end

-- Wraps the given text to the specified width, preserving newlines.
-- @param text The text to wrap.
-- @param width The maximum width of each line.
-- @param prefix The prefix to add to each line.
-- @return The wrapped text with preserved newlines.
local function wrap_text_preserve_newlines(text, width, prefix)
	local final_lines = {}

	for line in text:gmatch("([^\n]*)\n?") do
		if line == "" then
			table.insert(final_lines, "")
		else
			table.insert(final_lines, wrap_line(line, width))
		end
	end
	return table.concat(final_lines, "\n" .. prefix)
end

-- Creates the dashboard lines based on the cached data.
-- @param width The width of the dashboard.
local function create_dashbord_lines(width)
	width = width or config.width
	if not M.cached_mdj then
		return
	end
	cached_mdj = {
		{
			string.gsub(M.cached_mdj.word, "^%l", string.upper) .. "\n\n",
			hl = config.highlights.word,
			-- width = width,
			align = "center",
		},
		{
			wrap_text(M.cached_mdj.definition.def, width, "") .. "\n\n",
			hl = config.highlights.last_def,
		},
	}
	if M.cached_mdj.definition.meanings then
		for row, meaning in ipairs(M.cached_mdj.definition.meanings) do
			if row > config.rows then
				break
			end
			table.insert(cached_mdj, { string.format("%s) ", row), hl = config.highlights.last_def })
			table.insert(cached_mdj, {
				string.format("%s\n", wrap_text(meaning, width - 3, "   ")),
				hl = config.highlights.definition,
			})
		end
	end
	if M.cached_mdj.translation.founded then
		table.insert(cached_mdj, { "\n" })
		for row, meaning in ipairs(M.cached_mdj.translation.def) do
			if row > config.rows then
				break
			end
			table.insert(cached_mdj, {
				string.format("%s", wrap_text_preserve_newlines(meaning, width - 3, "   ")),
				hl = config.highlights.translation,
			})
		end
	end
end

-- Fetches a random word from the API.
-- @return The random word, or nil if the request fails.
function M.get_random_word()
	local response = vim.fn.system("curl -s https://trouve-mot.fr/api/random")
	local words = vim.fn.json_decode(response)
	if words and #words > 0 then
		return words[1].name
	else
		vim.notify("Failed to get random word", vim.log.levels.ERROR)
		return nil
	end
end

-- Fetches the definition of a word.
-- @param word The word to define.
-- @param callback The callback function to call with the definition.
-- @param format The format of the definition (default: "plain").
function M.get_definition(word, callback, format)
	if not word then
		return
	end
	local cmd = string.format(
		"sdcv -n -u \"XMLittré, ©littre.org\" --json  %s | jq -r '.[].definition' | sed '/<\\/div>/q' | sed -E 's|<span[^>]*>([0-9]+)</span>|<strong>(\\1) </strong>|g' | sed -E 's|<span[^>]*font-style:italic[^>]*>([^<]+)</span>|<i>\\1</i>|g' | sed -E 's/ style=\"[^\"]*\"//g' | sed -En '1,/<\\/p>/p; /<div>/,/<\\/div>/ { /<p>[[:space:]]*<strong>\\([0-9]+\\)[[:space:]]*<\\/strong>/p }' | sed -E '/^<p>[[:space:]]*<strong>\\([0-9]+\\)[[:space:]]*<\\/strong>/ { /<\\/p>$/! s/$/<\\/p>/ }' | pandoc -f html -t %s",
		word,
		format or "plain"
	)
	vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			local output = table.concat(data, "\n")
			if callback then
				callback(output)
			end
		end,
		on_stderr = function(_, data)
			if #data == 1 and data[1] == "" then
				return
			end
			if callback then
				callback(data)
			end
		end,
	})
end

-- Fetches the word of the day for the dashboard.
-- @param width The width of the dashboard.
-- @return The cached data or a loading message.
function M.get_mdj_for_dashboard(width)
	if cached_mdj then
		return cached_mdj
	else
		config.width = width or config.width
		M.get_word_of_day(function(data)
			if not data then
				cached_mdj = "No data"
			else
				create_dashbord_lines()
			end
			vim.schedule(function()
				vim.defer_fn(function()
					local ok, dashboard = pcall(require, "snacks.dashboard")
					if ok and dashboard and type(dashboard.update) == "function" then
						dashboard.update()
					else
						vim.notify("Snacks.Dashboard module not available", vim.log.levels.WARN)
					end
				end, 500)
			end)
		end)
		return "Loading word of the day..."
	end
end

-- Creates the word of the day and caches it.
-- @param callback The callback function to call with the word of the day data.
-- @param forWord The specific word to use (optional).
function M.create_word_of_day(callback, forWord)
	local word = forWord or M.get_random_word()
	if not word then
		return
	end
	M.get_definition(word, function(definition)
		definition = parse_definitions(definition)
		M.get_translation(word, function(translation)
			translation = parse_translation_output(translation)
			local data = {
				word = word,
				definition = definition,
				translation = translation,
			}
			local date_str = os.date("%Y%m%d")
			local file = config.cache_dir .. "/mdj_" .. date_str .. ".json"
			local f = io.open(file, "w")
			M.cached_mdj = data
			create_dashbord_lines()
			if f then
				local json_str = vim.fn.json_encode(data)
				local pretty_json = vim.fn.system({ "jq", "." }, json_str)
				f:write(pretty_json)
				f:close()
			else
				vim.notify("Could not write cache file: " .. file, vim.log.levels.ERROR)
			end
			append_log(os.date("%Y-%m-%d"), word)
			if callback then
				callback(data)
			end
		end)
	end)
end

-- Fetches the word of the day from the cache or creates a new one.
-- @param callback The callback function to call with the word of the day data.
-- @return The word of the day data.
function M.get_word_of_day(callback)
	local date_str = os.date("%Y%m%d")
	local file = config.cache_dir .. "/mdj_" .. date_str .. ".json"
	if vim.loop.fs_stat(file) then
		local f = io.open(file, "r")
		if f then
			local content = f:read("*a")
			f:close()
			local data = vim.fn.json_decode(content)
			if callback then
				callback(data)
			end
			M.cached_mdj = data
			create_dashbord_lines()
			return data
		else
			vim.notify("Cannot read cache file: " .. file, vim.log.levels.ERROR)
		end
	else
		M.create_word_of_day(callback)
	end
end

-- Fetches the translation of a word.
-- @param word The word to translate.
-- @param callback The callback function to call with the translation.
function M.get_translation(word, callback)
	if not word then
		return
	end
	local cmd = string.format("dict -f -d fd-fra-eng %s", word)
	vim.fn.jobstart(cmd, {
		stdout_buffered = true,
		on_stdout = function(_, data)
			local output = table.concat(data, "\n")
			if callback then
				callback(output)
			end
		end,
		on_stderr = function(_, data)
			if #data == 1 and data[1] == "" then
				return
			end
			if callback then
				callback(data)
			end
		end,
	})
end

-- Sets up the module with the user configuration.
-- @param user_config The user configuration table.
function M.setup(user_config)
	if user_config then
		config = vim.tbl_deep_extend("force", config, user_config)
	end
	vim.api.nvim_create_user_command("MotDuJourUpdate", function(opts)
		local forWord = (opts.args ~= "" and opts.args) or nil
		M.create_word_of_day(function(data)
			vim.notify(string.format("Word of the day updated: %s", data.word), vim.log.levels.INFO)
			local ok, dashboard = pcall(require, "snacks.dashboard")
			if ok and dashboard and type(dashboard.update) == "function" then
				dashboard.update()
			end
		end, forWord)
	end, {
		nargs = "?",
	})
	vim.fn.mkdir(config.cache_dir, "p")
end

-- Return the module table
return M
