local util = require("le-mot-du-jour.util")

local M = {}

function M.get_daily_word(callback)
	util.run_cmd({ "curl", "-fsSL", "https://trouve-mot.fr/api/daily" }, function(err, out)
		if err then
			callback("Failed to fetch daily word: " .. err, nil)
			return
		end

		local ok, data = pcall(vim.fn.json_decode, out)
		if not ok or not data then
			callback("Failed to parse daily word JSON", nil)
			return
		end

		if data.name and data.name ~= "" then
			callback(nil, data.name, data)
			return
		end

		if vim.islist(data) and data[1] and data[1].name then
			callback(nil, data[1].name, data[1])
			return
		end

		callback("Daily word payload has unexpected shape", nil)
	end)
end

function M.get_definition(word, callback, format)
	if not word or vim.trim(word) == "" then
		callback("Empty word", nil)
		return
	end

	if not util.has_exec("sdcv") then
		callback("sdcv is missing", nil)
		return
	end

	format = format or "plain"
	if format ~= "plain" and format ~= "markdown" then
		format = "plain"
	end

	local shell_cmd = table.concat({
		'sdcv -n -u "XMLittré, ©littre.org" --json ' .. vim.fn.shellescape(word),
		"| jq -r '.[].definition'",
		"| sed '/<\\/div>/q'",
		"| sed -E 's|<span[^>]*>([0-9]+)</span>|<strong>(\\1) </strong>|g'",
		"| sed -E 's|<span[^>]*font-style:italic[^>]*>([^<]+)</span>|<i>\\1</i>|g'",
		'| sed -E \'s/ style="[^"]*"//g\'',
		"| sed -En '1,/<\\/p>/p; /<div>/,/<\\/div>/ { /<p>[[:space:]]*<strong>\\([0-9]+\\)[[:space:]]*<\\/strong>/p }'",
		"| sed -E '/^<p>[[:space:]]*<strong>\\([0-9]+\\)[[:space:]]*<\\/strong>/ { /<\\/p>$/! s/$/<\\/p>/ }'",
		"| pandoc -f html -t " .. vim.fn.shellescape(format),
	}, " ")

	util.run_cmd({ "sh", "-c", shell_cmd }, function(err, out)
		if err then
			callback("Failed to fetch definition: " .. err, out)
			return
		end
		callback(nil, out)
	end)
end

function M.get_translation(word, callback)
	if not word or vim.trim(word) == "" then
		callback("Empty word", nil, nil)
		return
	end

	if util.has_exec("dict") then
		util.run_cmd({ "dict", "-f", "-d", "fd-fra-eng", word }, function(err, out)
			callback(err, out, "dict")
		end)
		return
	end

	if util.has_exec("trans") then
		util.run_cmd({ "trans", "-b", "fr:en", word }, function(err, out)
			callback(err, out, "trans")
		end)
		return
	end

	callback("No translator found (dict / trans missing)", nil, nil)
end

return M
