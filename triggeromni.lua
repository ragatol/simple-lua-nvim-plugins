-- Simple plugin for triggering omni-completion automatically.
-- By Rafael Fernandes, 2022. Public Domain.

local f = string.format
local join = table.concat
local r = vim.regex
local pumvisible = vim.fn.pumvisible

-- TRIGGER CONDIDIONS --

--- default "keyword" condition is to call the omnifunc after 3 keyword characters.
-- Each "keyword" character is defined by the 'iskeyword' option.
local keyword = r([[\K\k\{2,}$]])

-- functions to help build other conditions

--- matches text at the start of the line, ignoring whitespace.
--- @param text string|table @text or list of texts to match
local function begins_with(text)
	if type(text) == "table" then
		text = f([[\(%s\)]], join(text, [[\|]]))
	end
	return r(f([[^\M\s\*%s]], text))
end

--- matches text from the start of the current line up to the cursor
--- @param text string|table @text or table of texts to match
local function ends_with(text)
	if type(text) == "table" then
		text = f([[\(%s\)]], join(text, [[\|]]))
	end
	return r(f([[\M%s$]], text))
end

--- matches a keyword followed by one of the operators in a list
--- @param operators table @table with operators to match after a keyword
local function member_access(operators)
	local ops = join(operators, [[\|]])
	return r(f([[\M\(%s\)$]], ops))
end

-- END OF TRIGGER CONDITIONS --

local function line_up_to_cursor()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	row = row - 1 -- convert index base
	return vim.api.nvim_buf_get_text(0, row, 0, row, col, {})[1]
end

local function open_omnifunc(conditions)
	local char = vim.v.char
	if pumvisible() ~= 0 then
		return
	end
	local recent = line_up_to_cursor() .. char
	-- test conditions
	for _, condition in pairs(conditions) do
		if condition:match_str(recent) then
			vim.api.nvim_input('<C-x><C-o>')
			return
		end
	end
end

local function make_triggeromni(conditions)
	return function()
		return open_omnifunc(conditions)
	end
end

-- keys for opening and navigating suggestions
local next_key = '<C-n>'
local prev_key = '<C-p>'
local tab_key = '<Tab>'
local stab_key = '<S-Tab>'

-- functions for tab/s-tab for cicling suggestions

local function next_suggestion()
	return pumvisible() ~= 0 and next_key or tab_key
end

local function prev_suggestion()
	return pumvisible() ~= 0 and prev_key or stab_key
end

-- export
local M = {}

--- setup the auto triggering of the omnifunc in a buffer.
--- @param conditions table @table with conditions to trigger the omnifunc
--- @param bufnr number @[optional] buffer to setup, defaults to current buffer (0).
M.setup = function(conditions, bufnr)
	bufnr = bufnr or 0
	vim.api.nvim_create_autocmd("InsertCharPre", {
		buffer = bufnr,
		callback = make_triggeromni(conditions)
	})
	local keymap_opts = { expr = true, buffer = bufnr }
	vim.keymap.set('i', '<Tab>', next_suggestion, keymap_opts)
	vim.keymap.set('i', '<S-Tab>', prev_suggestion, keymap_opts)
end;

M.conditions = {
	keyword = keyword;
	begins_with = begins_with;
	ends_with = ends_with;
	member_access = member_access;
}

return M
