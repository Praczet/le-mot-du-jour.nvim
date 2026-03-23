local config_mod = require("le-mot-du-jour.config")
local util = require("le-mot-du-jour.util")
local api = require("le-mot-du-jour.api")
local parse = require("le-mot-du-jour.parse")
local cache = require("le-mot-du-jour.cache")
local dashboard = require("le-mot-du-jour.dashboard")
local commands = require("le-mot-du-jour.commands")

local M = {}

M.config = vim.deepcopy(config_mod.defaults)
M.cached_mdj = nil
M.dashboard_lines = nil

local function set_data(data)
	M.cached_mdj = data
	M.dashboard_lines = dashboard.create_dashboard_lines(data, M.config)
end

function M.get_mdj_for_dashboard(width)
	if width then
		M.config.width = width
	end

	if M.dashboard_lines then
		return M.dashboard_lines
	end

	M.get_word_of_day(function(data)
		if data then
			set_data(data)
		else
			M.dashboard_lines = { "No data" }
		end
		dashboard.refresh_dashboard(M.config.dashboard)
	end)

	return { "Loading word of the day..." }
end

function M.create_word_of_day(callback, forced_word)
	local after_word = function(word)
		if not word then
			util.notify("No word available", vim.log.levels.ERROR)
			if callback then
				callback(nil)
			end
			return
		end

		api.get_definition(word, function(def_err, def_raw)
			if def_err then
				util.notify(def_err, vim.log.levels.WARN)
			end

			local definition = parse.parse_definitions(def_raw or "")

			api.get_translation(word, function(trans_err, trans_raw, backend)
				if trans_err then
					util.notify(trans_err, vim.log.levels.WARN)
				end

				local translation = parse.parse_translation_output(trans_raw or "", backend)

				local data = {
					word = word,
					definition = definition,
					translation = translation,
					date = os.date("%Y-%m-%d"),
				}

				set_data(data)

				local ok = cache.write_daily(M.config.cache_dir, data)
				if not ok then
					util.notify("Could not write cache file", vim.log.levels.ERROR)
				end

				cache.append_log(M.config.cache_dir, os.date("%Y-%m-%d"), word)

				if callback then
					callback(data)
				end

				dashboard.refresh_dashboard(M.config.dashboard)
			end)
		end)
	end

	if forced_word and vim.trim(forced_word) ~= "" then
		after_word(forced_word)
		return
	end

	api.get_daily_word(function(err, word)
		if err then
			util.notify(err, vim.log.levels.ERROR)
			if callback then
				callback(nil)
			end
			return
		end
		after_word(word)
	end)
end

function M.get_word_of_day(callback)
	local data = cache.read_daily(M.config.cache_dir)
	if data then
		set_data(data)
		if callback then
			callback(data)
		end
		return data
	end

	M.create_word_of_day(callback)
	return nil
end

function M.setup(user_config)
	if user_config then
		M.config = vim.tbl_deep_extend("force", M.config, user_config)
	end

	vim.fn.mkdir(M.config.cache_dir, "p")
	commands.setup(M)
end

return M
