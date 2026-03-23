local util = require("le-mot-du-jour.util")

local M = {}

function M.create_dashboard_lines(data, config)
	if not data then
		return { "No data" }
	end

	local width = config.width
	local rows = config.rows
	local hl = config.highlights

	local lines = {
		{
			string.gsub(data.word or "", "^%l", string.upper) .. "\n\n",
			hl = hl.word,
			align = "center",
		},
		{
			util.wrap_text(data.definition.def or "", width, "") .. "\n\n",
			hl = hl.last_def,
		},
	}

	if data.definition.meanings then
		for i, meaning in ipairs(data.definition.meanings) do
			if i > rows then
				break
			end
			table.insert(lines, {
				string.format("%d) ", i),
				hl = hl.last_def,
			})
			table.insert(lines, {
				string.format("%s\n", util.wrap_text(meaning, width - 3, "   ")),
				hl = hl.definition,
			})
		end
	end

	if data.translation and data.translation.found then
		table.insert(lines, { "\n" })
		for i, meaning in ipairs(data.translation.def or {}) do
			if i > rows then
				break
			end
			table.insert(lines, {
				util.wrap_text_preserve_newlines(meaning, width - 3, "   "),
				hl = hl.translation,
			})
		end
	end

	if
		data.translation
		and not data.translation.found
		and data.translation.similar
		and #data.translation.similar > 0
	then
		table.insert(lines, { "\nSuggestions:\n", hl = hl.translation })
		table.insert(lines, {
			table.concat(data.translation.similar, ", "),
			hl = hl.translation,
		})
	end

	return lines
end

function M.refresh_dashboard(module_name)
	vim.schedule(function()
		vim.defer_fn(function()
			local ok, dashboard = pcall(require, module_name)
			if ok and dashboard and type(dashboard.update) == "function" then
				dashboard.update()
			end
		end, 300)
	end)
end

return M
