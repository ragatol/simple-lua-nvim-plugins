-- Simple configuration script to autopair "", '', (), [] and {}
-- By Rafael Fernandes, 2022. Public Domain.

-- bring some functions to local scope
local f = string.format
local t = vim.api.nvim_replace_termcodes
local getcursor = vim.api.nvim_win_get_cursor
local buftext = vim.api.nvim_buf_get_text

-- get next character of the cursor
local function nextchar()
	local row, col = unpack(getcursor(0))
	row = row - 1 -- change from 1 indexed to 0 indexed
	return buftext(0, row, col, row, col + 1, {})[1]
end

-- cursor movement "chars". Use <C-G>U before movement to not break undo
local move_prev = t('<C-G>U<Left>', true, true, true)
local move_next = t('<C-G>U<Right>', true, true, true)

-- functions for pairs with different chars
local function pair_open(pair)
	return f("%s%s", pair, move_prev)
end

local function pair_close(close_char)
	return nextchar() == close_char and move_next or close_char
end

-- function for quotes
local function quote_pair(quote_char)
	return nextchar() == quote_char and move_next or f("%s%s%s", quote_char, quote_char, move_prev)
end

-- functions to add new line between a pair
local newline_between = t('\r<C-O>O', true, true, true)
local normal_newline = t('\r', true, true, true)
local function inside_pair()
	local row,col = unpack(getcursor(0))
	row = row - 1 -- change from 1 indexed to 0 indexed
	local sides = buftext(0,row, col - 1, row, col + 1, {})[1]
	return sides == "()" or sides == "[]" or sides == "{}"
end
local function newline_pair()
	return inside_pair() and newline_between or normal_newline
end

-- pair characters mapping table
local autopairs = {
	['"'] = { callback = function() return quote_pair('"') end; name = "DoubleQuotes"; },
	["'"] = { callback = function() return quote_pair("'") end; name = "SingleQuotes"; },
	['('] = { callback = function() return pair_open("()") end; name = "OpenParentesis"; },
	[')'] = { callback = function() return pair_close(')') end; name = "CloseParentesis"; },
	['['] = { callback = function() return pair_open("[]") end; name = "OpenSquareBracket"; },
	[']'] = { callback = function() return pair_close(']') end; name = "CloseSquareBracket"; },
	['{'] = { callback = function() return pair_open("{}") end; name = "OpenCurlyBracket"; },
	['}'] = { callback = function() return pair_close('}') end; name = "CloseCurlyBracket"; },
	['\r'] = { callback = function() return newline_pair() end; name = "NewlinePair"; },
}

-- export module functions
M = {}
local modname = ...
local map = vim.api.nvim_set_keymap
local map_options = { expr = true; noremap = true }
for lhs, v in pairs(autopairs) do
	M[v.name] = v.callback
	local rhs = f([[v:lua.require'%s'.%s()]], modname, v.name)
	map("i", lhs, rhs, map_options)
end
return M
