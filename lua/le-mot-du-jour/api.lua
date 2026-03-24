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

	local url = "https://fr.wiktionary.org/w/api.php"
	local args = {
		"curl",
		"-fsSL",
		"-G",
		"--data-urlencode",
		"action=query",
		"--data-urlencode",
		"prop=revisions",
		"--data-urlencode",
		"rvprop=content",
		"--data-urlencode",
		"rvslots=main",
		"--data-urlencode",
		"format=json",
		"--data-urlencode",
		"titles=" .. word,
		url,
	}

	util.run_cmd(args, function(err, out)
		if err then
			callback("Failed to fetch definition: " .. err, out)
			return
		end

		local ok, data = pcall(vim.fn.json_decode, out)
		if not ok or not data or not data.query or not data.query.pages then
			callback("Failed to parse Wiktionary JSON", nil)
			return
		end

		local wikitext = ""
		for _, page in pairs(data.query.pages) do
			if page.revisions and page.revisions[1] and page.revisions[1].slots and page.revisions[1].slots.main then
				wikitext = page.revisions[1].slots.main["*"]
				break
			end
		end

		if wikitext == "" then
			callback("Word not found in Wiktionary", nil)
			return
		end

		callback(nil, wikitext)
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
