local M = {}

function M.setup(mod)
	vim.api.nvim_create_user_command("MotDuJourUpdate", function(opts)
		local word = opts.args ~= "" and opts.args or nil

		mod.create_word_of_day(function(data)
			if data and data.word then
				vim.notify(("Word of the day updated: %s"):format(data.word), vim.log.levels.INFO)
			end
		end, word)
	end, {
		nargs = "?",
	})
end

return M
