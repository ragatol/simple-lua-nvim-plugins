-- Simple configuration script to configure statusline.
-- By Rafael Fernandes, 2022. Public Domain.

-- bring global functions to local scope
local f = string.format
local b = string.byte

-- mode display, "color" is the hl-group to be used
local modes = {
	[ b'n' ] = { text = "NORMAL", color = "StatusLineNC", },
	[ b'v' ] = { text = "VISUAL", color = "Visual", },
	[ b'V' ] = { text = "V-LINE", color = "Visual", },
	[ b's' ] = { text = "SELECT", color = "Visual", },
	[ b'S' ] = { text = "S-LINE", color = "Visual", },
	[ b'i' ] = { text = "INSERT", color = "DiffAdd", },
	[ b'R' ] = { text = "REPLACE", color = "DiffDelete", },
	[ b'c' ] = { text = "COMMAND", color = "DiffText", },
	[ b'r' ] = { text = "PROMPT", color = "DiffText", },
	[ b't' ] = { text = "TERMINAL", color = "TermCursor", },
	[ b'!' ] = { text = "RUNNING", color = "IncSearch", },
	[  19  ] = { text = "S-BLOCK", color = "Visual", }, -- CTRL-S
	[  22  ] = { text = "V-BLOCK", color = "Visual", }, -- CTRL-V
}

local function curmode()
	local m = modes[b(vim.api.nvim_get_mode().mode)]
	return m and f("%%#%s# %s ", m.color, m.text) or ""
end

-- file type, format and encoding
local function fileinfo()
	local bufn = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
	local format = vim.api.nvim_buf_get_option(bufn, "fileformat")
	local encoding = vim.api.nvim_buf_get_option(bufn, "fileencoding")
	local type = vim.api.nvim_buf_get_option(bufn, "filetype")
	local info = f("%%#StatusLineNC# %s │ %s │ %s⏎ ", type, encoding, format)
	return string.gsub(info, "  │", "") -- remove empty info
end

-- ruler with scroll, a list of "frames" for the animation
local scroll = { "▕██▏", "▕▇▇▏", "▕▆▆▏", "▕▅▅▏", "▕▄▄▏", "▕▃▃▏", "▕▂▂▏", "▕▁▁▏", "▕  ▏" }

local function make_ruler()
	local bufn = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
	local pos = vim.fn.line('.', vim.g.statusline_winid)
	local total = vim.api.nvim_buf_line_count(bufn)
	local c = math.ceil((pos / total) * #scroll)
	return f("%%#CursorLineNr# %%12(%%l:%%2.v%s%%)", scroll[c])
end

-- setup statusline function
local function statusline()
	local active = vim.g.statusline_winid == vim.api.nvim_get_current_win()
	local mode = active and curmode() or "" -- do not show mode in inactive windows
	local color = active and "StatusLine" or "StatusLineNC"
	local name = "%(%t%< %h%w%r%m%)"
	return f("%s%%#%s# %s%%=%s%s", mode, color, name, fileinfo(), make_ruler())
end

-- export and setup statusline module
local M = {}
local modname = ...
M.statusline = statusline
vim.go.statusline = f([[%%!v:lua.require'%s'.statusline()]], modname)
return M
