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
}

-- create global functions to be called and set keymaps
local map = vim.api.nvim_set_keymap
local autopair_functions = {}
local map_options = { expr = true; noremap = true }
for lhs, v in pairs(autopairs) do
	autopair_functions[v.name] = v.callback
	local rhs = f('v:lua.AutoPair.%s()', v.name)
	map("i", lhs, rhs, map_options)
end

-- export autopair functions to global scope
_G["AutoPair"] = autopair_functions

