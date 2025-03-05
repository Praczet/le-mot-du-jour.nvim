local M = {}

-- Default configuration
local config = {
	cache_dir = vim.fn.stdpath("data") .. "/mdj", -- Default cache folder in Neovim's data directory
	highlights = {
		word = "WordOfDayWord", -- Default highlight (guifg=#ff9e64)
		definition = "WordOfDayDefinition", -- Default highlight (guifg=#d0d0d0)
		translation = "WordOfDayTranslation", -- Default highlight (guifg=#7abaff)
	},
	dashboard = "Snacks.Dashboard", -- Default dashboard module (if available)
}

-- Allow users to override the defaults
function M.setup(user_config)
	if user_config then
		config = vim.tbl_deep_extend("force", config, user_config)
	end
	-- Ensure the cache directory exists.
	vim.fn.mkdir(config.cache_dir, "p")
end

-- 1. Get a random word from the API
function M.get_random_word()
	local response = vim.fn.system("curl -s https://trouve-mot.fr/api/random")
	local words = vim.fn.json_decode(response)
	if words and #words > 0 then
		return words[1].name -- e.g. "chat"
	else
		vim.notify("Failed to get random word", vim.log.levels.ERROR)
		return nil
	end
end

-- 2. Get the definition using your sdcv pipeline
function M.get_definition(word, callback)
	if not word then
		return
	end
	local cmd = string.format(
		"sdcv -n -u \"XMLittré, ©littre.org\" --json  %s | jq -r '.[].definition' | sed '/<\\/div>/q' | sed -E 's|<span[^>]*>([0-9]+)</span>|<strong>(\\1) </strong>|g' | sed -E 's|<span[^>]*font-style:italic[^>]*>([^<]+)</span>|<i>\\1</i>|g' | sed -E 's/ style=\"[^\"]*\"//g' | sed -En '1,/<\\/p>/p; /<div>/,/<\\/div>/ { /<p>[[:space:]]*<strong>\\([0-9]+\\)[[:space:]]*<\\/strong>/p }' | sed -E '/^<p>[[:space:]]*<strong>\\([0-9]+\\)[[:space:]]*<\\/strong>/ { /<\\/p>$/! s/$/<\\/p>/ }' | pandoc -f html -t markdown",
		word
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
			vim.notify("Definition error: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
		end,
	})
end

-- 3. Get the translation using dict
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
			vim.notify("Translation error: " .. table.concat(data, "\n"), vim.log.levels.ERROR)
		end,
	})
end

-- 4. Display the word of the day with full definition and translation
function M.display_word_of_day()
	local word = M.get_random_word()
	if not word then
		return
	end
	M.get_definition(word, function(definition)
		M.get_translation(word, function(translation)
			-- Format the display using custom highlight groups.
			local display_text = string.format(
				"%%#%s#%s\n%%#%s#%s\n%%#%s#%s",
				config.highlights.word,
				vim.fn.capitalize(word),
				config.highlights.definition,
				definition,
				config.highlights.translation,
				translation
			)
			-- For now, simply echo the result in Neovim.
			vim.api.nvim_echo({ { display_text, "Normal" } }, false, {})

			-- Cache the current result.
			local mdj_file = config.cache_dir .. "/mdj.json"
			local history_file = config.cache_dir .. "/mdj_history.json"
			local data = { word = word, definition = definition, translation = translation }
			local f = io.open(mdj_file, "w")
			if f then
				f:write(vim.fn.json_encode(data))
				f:close()
			end
			local fh = io.open(history_file, "a")
			if fh then
				fh:write(vim.fn.json_encode(data) .. "\n")
				fh:close()
			end
		end)
	end)
end

-- 5. (Future) Add the word of the day to the dashboard.
function M.add_to_dashboard()
	local ok, dashboard = pcall(require, config.dashboard)
	if not ok then
		vim.notify("Dashboard module not found", vim.log.levels.WARN)
		return
	end

	local word = M.get_random_word()
	if not word then
		return
	end
	M.get_definition(word, function(definition)
		M.get_translation(word, function(translation)
			local display_text = string.format(
				"%%#%s#%s\n%%#%s#%s\n%%#%s#%s",
				config.highlights.word,
				vim.fn.capitalize(word),
				config.highlights.definition,
				definition,
				config.highlights.translation,
				translation
			)
			dashboard.add_item(display_text)
		end)
	end)
end

-- Create a user command to update the word of the day.
vim.api.nvim_create_user_command("MdjUpdate", function()
	M.display_word_of_day()
end, {})

return M
