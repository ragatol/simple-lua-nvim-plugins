-- Simple configuration script to insert "", '', (), [] or {} around a selection.
-- By Rafael Fernandes, 2023. Public Domain.

-- Import functions
local getmarkpos = vim.fn.getpos
local settext = vim.api.nvim_buf_set_text
local gettext = vim.api.nvim_buf_get_text
local map = vim.keymap.set
local esc_key = vim.api.nvim_replace_termcodes("<Esc>", true, true, true)
local sendkey = vim.api.nvim_feedkeys

-- pairs table
local char_pairs = {
	['"'] = { first = '"', last = '"' },
	["'"] = { first = "'", last = "'" },
	["("] = { first = '(', last = ')' },
	["["] = { first = '[', last = ']' },
	["{"] = { first = '{', last = '}' },
}

-- insert fist and last characters around selected text
local function add_pairs(first, last)
	local _, row1, col1, _ = unpack(getmarkpos("v"))
	local _, row2, col2, _ = unpack(getmarkpos("."))
	if row2 < row1 or (row1 == row2 and col1 > col2) then
		-- start and end are flipped
		row1, row2 = row2, row1
		col1, col2 = col2, col1
	end
	row1, row2 = row1 - 1, row2 - 1 -- from 1 indexed to 0 indexed
	-- position before the visual selection
	col1 = col1 - 1
	-- check if the "last" position is not the end of the line
	local last_char = gettext(0, row2, col2 - 1, row2, col2, {})[1]
	if last_char ~= "" then
		-- not at the end of line, position it after visual selection
		col2 = col2 + 1
	end
	settext(0, row1, col1, row1, col1, { first })
	settext(0, row2, col2, row2, col2, { last })
	sendkey(esc_key, "n", false)
end

-- setup keybinding for visual mode
for key, value in pairs(char_pairs) do
	map("v", '<Leader>' .. key, function() add_pairs(value.first, value.last) end)
end
