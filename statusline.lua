-- Simple configuration script to configure statusline.
-- By Rafael Fernandes, 2022. Public Domain.

-- bring global functions to local scope
local f = string.format
local b = string.byte

-- itens of statusline are added to this table in order using the function add_section
-- section is a function that takes 2 arguments: buffer_number and is_window_active
-- and returns a statusline format string
local status = {}
local function add_section(section) table.insert(status, section) end

-- mode display, "color" is the hl-group to be used
local modes = {
	[b 'n'] = { text = "NORMAL", color = "StatusLineNC", },
	[b 'v'] = { text = "VISUAL", color = "Visual", },
	[b 'V'] = { text = "V-LINE", color = "Visual", },
	[b 's'] = { text = "SELECT", color = "Visual", },
	[b 'S'] = { text = "S-LINE", color = "Visual", },
	[b 'i'] = { text = "INSERT", color = "DiffAdd", },
	[b 'R'] = { text = "REPLACE", color = "DiffDelete", },
	[b 'c'] = { text = "COMMAND", color = "DiffText", },
	[b 'r'] = { text = "PROMPT", color = "DiffText", },
	[b 't'] = { text = "TERMINAL", color = "TermCursor", },
	[b '!'] = { text = "RUNNING", color = "IncSearch", },
	[19] = { text = "S-BLOCK", color = "Visual", }, -- CTRL-S
	[22] = { text = "V-BLOCK", color = "Visual", }, -- CTRL-V
}
add_section(function(_, active)
	local mode = modes[b(vim.api.nvim_get_mode().mode)]
	return (mode and active) and f("%%#%s# %s ", mode.color, mode.text) or ""
end)

-- filename and flags
add_section(function(_, active)
	local color = active and "StatusLine" or "StatusLineNC"
	local file_flags = "%(%t%< %h%w%r%m%)"
	return f("%%#%s# %s", color, file_flags)
end)

-- start right side of statusline
add_section(function() return "%=" end)

-- Lsp diagnostics status
local lsp_signs = {}
local function make_diag_format_str(sign)
	local s = vim.fn.sign_getdefined(sign)[1]
	return s and f("%%%%#%s#%%s%s", sign, s.text) or nil
end
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function()
		lsp_signs = { -- In order of 'severity'
			make_diag_format_str "DiagnosticSignError",
			make_diag_format_str "DiagnosticSignWarn",
			make_diag_format_str "DiagnosticSignInfo",
			make_diag_format_str "DiagnosticSignHint",
		}
	end,
})
add_section(function(bufn)
	local diags = vim.diagnostic.get(bufn)
	if #diags == 0 or #lsp_signs == 0 then
		return ""
	end
	local count = { 0, 0, 0, 0 }
	for _, v in ipairs(diags) do
		count[v.severity] = count[v.severity] + 1
	end
	local diags_str = {}
	for i, v in ipairs(count) do
		if v > 0 then
			table.insert(diags_str, f(lsp_signs[i], v))
		end
	end
	table.insert(diags_str, "")
	return table.concat(diags_str, " ")
end)

-- file type, format and encoding
add_section(function(bufn)
	local format = vim.api.nvim_buf_get_option(bufn, "fileformat")
	local encoding = vim.api.nvim_buf_get_option(bufn, "fileencoding")
	local type = vim.api.nvim_buf_get_option(bufn, "filetype")
	local info = f("%%#StatusLineNC# %s │ %s │ %s⏎ ", type, encoding, format)
	return (string.gsub(info, "  │", "")) -- remove empty info and ignore number of replacements
end)

-- ruler with scroll, a list of "frames" for the animation
local scroll = { "▕██▏", "▕▇▇▏", "▕▆▆▏", "▕▅▅▏", "▕▄▄▏", "▕▃▃▏", "▕▂▂▏", "▕▁▁▏", "▕  ▏" }
add_section(function(bufn)
	local pos = vim.fn.line('.', vim.g.statusline_winid)
	local total = vim.api.nvim_buf_line_count(bufn)
	local frame = math.ceil((pos / total) * #scroll)
	return f("%%#CursorLineNr# %%12(%%l:%%2.v%s%%)", scroll[frame])
end)

-- setup statusline function
local function statusline()
	local bufn = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
	local active = vim.g.statusline_winid == vim.api.nvim_get_current_win()
	local status_str = {}
	for _, func in ipairs(status) do
		table.insert(status_str, func(bufn, active))
	end
	return table.concat(status_str)
end

-- export and setup statusline module
local M = {}
local modname = ...
M.statusline = statusline
vim.go.statusline = f([[%%!v:lua.require'%s'.statusline()]], modname)
return M
