-- Simple configuration script to autopair "", '', (), [] and {}
-- By Rafael Fernandes, 2022. Public Domain.

-- bring some functions to local scope
local t = function(keys) return vim.api.nvim_replace_termcodes(keys, true, true, true) end
local getcursor = vim.api.nvim_win_get_cursor
local buftext = vim.api.nvim_buf_get_text
local is_keyword_char = vim.regex([[\k]])

-- checks if the character before the cursor is a keyword character
local function prev_keyword()
	local row, col = unpack(getcursor(0))
	row = row - 1 -- change from 1 indexed to 0 indexed
	local prev_char = buftext(0, row, col - 1, row, col, {})[1]
	return is_keyword_char:match_str(prev_char)
end

-- get next character of the cursor
local function nextchar()
	local row, col = unpack(getcursor(0))
	row = row - 1 -- change from 1 indexed to 0 indexed
	return buftext(0, row, col, row, col + 1, {})[1]
end

-- cursor movement "chars". Use <C-G>U before movement to not break undo
local move_prev = t('<C-G>U<Left>')
local move_next = t('<C-G>U<Right>')

-- functions for pairs with different chars
local function pair_open(pair)
	return pair .. move_prev
end

local function pair_close(close_char)
	return nextchar() == close_char and move_next or close_char
end

-- quotes
local function quote_pair(quote_char)
	local next_c = nextchar()
	-- don't double quote if the quote is being typed following a word
	if prev_keyword() and next_c ~= quote_char then
		return quote_char
	end
	return next_c == quote_char and move_next or quote_char .. quote_char .. move_prev
end

-- functions to add new line between a pair
local newline_between = t('\r<C-O>O')
local normal_newline = t('\r')
local function inside_pair()
	local row, col = unpack(getcursor(0))
	if (col == 0) then return false end
	row = row - 1 -- change from 1 indexed to 0 indexed
	local sides = buftext(0, row, col - 1, row, col + 1, {})[1]
	return sides == "()" or sides == "[]" or sides == "{}"
end

local function newline_pair()
	return inside_pair() and newline_between or normal_newline
end

-- setup pair characters mapping table
local autopairs = {
	['"'] = function() return quote_pair('"') end,
	["'"] = function() return quote_pair("'") end,
	['('] = function() return pair_open("()") end,
	[')'] = function() return pair_close(')') end,
	['['] = function() return pair_open("[]") end,
	[']'] = function() return pair_close(']') end,
	['{'] = function() return pair_open("{}") end,
	['}'] = function() return pair_close('}') end,
	['\r'] = function() return newline_pair() end,
}

-- export module functions
local M = {}
local map = vim.keymap.set
local map_options = { expr = true, noremap = true }
for lhs, rhs in pairs(autopairs) do
	map("i", lhs, rhs , map_options)
end
return M
