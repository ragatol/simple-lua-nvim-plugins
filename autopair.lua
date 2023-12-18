-- Simple configuration script to autopair "", '', (), [] and {}
-- By Rafael Fernandes, 2022. Public Domain.

-- bring some functions to local scope
local getcursor = vim.api.nvim_win_get_cursor
local buftext = vim.api.nvim_buf_get_text
local is_keyword_char = vim.regex([[\k]])

-- checks if the character before and/or after the cursor is a keyword character
local function near_keyword()
	local row, col = unpack(getcursor(0))
	row = row - 1 -- change from 1 indexed to 0 indexed
	local end_col = vim.fn.col('$')
	return is_keyword_char:match_line(0, row, col - 1, col + 1 == end_col and col or col + 1)
end

-- get next character of the cursor
local function nextchar()
	local row, col = unpack(getcursor(0))
	row = row - 1 -- change from 1 indexed to 0 indexed
	return buftext(0, row, col, row, col + 1, {})[1]
end

-- cursor movement "chars". Use <C-G>U before movement to not break undo
local move_prev = "<C-G>U<Left>"
local move_next = "<C-G>U<Right>"

-- open and close pairs
local function pair_open(pair)
	return pair .. move_prev
end

local function pair_close(close_char)
	return nextchar() == close_char and move_next or close_char
end

-- quote pair if not next to a keyword
local function quote_pair(quote_char)
	local next_c = nextchar()
	if near_keyword() and next_c ~= quote_char then
		return quote_char
	end
	return next_c == quote_char and move_next or quote_char .. quote_char .. move_prev
end

-- functions to add new line between a pair
local newline_between = "\r<C-O>O"
local normal_newline = "\r"
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
local map_options = { expr = true }
for lhs, rhs in pairs(autopairs) do
	map("i", lhs, rhs , map_options)
end
return M
