-- Simple plugin for triggering omni-completion automatically.
-- By Rafael Fernandes, 2022. Public Domain.

local f = string.format
local join = table.concat
local r = vim.regex

--- default "keyword" condition is to call the omnifunc after 3 keyword characters.
--	Each "keyword" character is defined by the 'iskeyword' option.
local keyword = r([[\K\k\{2,}$]])

-- functions to help build other conditions

--- matches text at the start of the line, ignoring whitespace.
-- @param text text or table of texts to match
local function begins_with(text)
	if type(text) == "table" then
		text = f([[\(%s\)]], join(text,[[\|]]))
	end
	return r(f([[^\M\s\*%s]],text))
end

--- matches text from the start of the current line up to the cursor
-- @param text text or table of texts to match
local function ends_with(text)
	if type(text) == "table" then
		text = f([[\(%s\)]], join(text,[[\|]]))
	end
	return r(f([[\M%s$]],text))
end

--- matches a keyword followed by one of the operators in a list
-- @param operators table with operators to match after a keyword
local function member_access(operators)
	local ops = join(operators,[[\|]])
	return r(f([[\M\K\k\*\(%s\)$]],ops))
end

-- utility function to get the line up to the cursor
local function line_up_to_cursor()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	row = row - 1 -- convert index base
	return vim.api.nvim_buf_get_text(0,row,0,row,col,{})[1]
end

-- function to check if we need to call omnifunc
local function open_omnifunc(conditions)
	local char = vim.v.char
	if vim.fn.pumvisible() ~= 0 then
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

-- function to build our triggeromni for a specific list of conditions
local function make_triggeromni(conditions)
	return function()
		return open_omnifunc(conditions)
	end
end

-- export
local modname = ...
M = {}

-- keys for opening and navigating the completion menu
local t = vim.api.nvim_replace_termcodes
local next_key = t('<C-n>',true,true,true)
local prev_key = t('<C-p>',true,true,true)
local tab_key = t('<Tab>',true,true,true)
local stab_key = t('<S-Tab>',true,true,true)
-- rhs of tab/s-tab keymaps
local rhs_next = f([[v:lua.require'%s'.next()]], modname)
local rhs_prev = f([[v:lua.require'%s'.prev()]], modname)

--- setup the auto triggering of the omnifunc in a buffer.
-- @param conditions table with conditions to trigger the omnifunc
-- @param bufnr (optional) buffer to setup, defaults to current buffer (0).
M.setup = function(conditions, bufnr)
	bufnr = bufnr == nil and 0 or bufnr
	vim.api.nvim_create_autocmd( "InsertCharPre", {
		buffer = bufnr,
		callback = make_triggeromni(conditions)
	})
	local keymap_opts = { expr = true, buffer = bufnr }
	vim.keymap.set('i', '<Tab>', rhs_next, keymap_opts)
	vim.keymap.set('i', '<S-Tab>', rhs_prev, keymap_opts)
end;

M.next = function()
	return vim.fn.pumvisible() ~= 0 and next_key or tab_key
end;

M.prev = function()
	return vim.fn.pumvisible() ~= 0 and prev_key or stab_key
end;

M.conditions = {
	keyword = keyword;
	begins_with = begins_with;
	ends_with = ends_with;
	member_access = member_access;
}

return M
