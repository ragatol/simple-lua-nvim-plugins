# simple-lua-nvim-plugins
Simple, minimalistic Lua plugins/scripts for NeoVim 0.7.

Each has less than 100 lines of code and are meant to be read and modified by the user.

## Installation

Just download the scripts and move them to the 'lua' folder inside your Neovim config folder.
Then `require` the plugin from your init.lua.

If you are using init.vim, the use `luafile` with the path to the plugin file to load it.

These are very simple and small plugins, that are "good enough" to do what they propose to do,
meant to be used as a starting point for the user.
Using them with a plugin manager is not recommended.

Neovim 0.7+ is required.

## Available Plugins

### autopairs.lua

A simple implementation of autopairs. When typing the first character of a pair, it automatically
types the closing character and places the cursor between them. If the next character after the cursor
is the closing character, typing it will just move the cursor past it.

There's no auto-formatting, and it's not aware of any context, but most of the time the user really wants
to type these pairs so it helps much more than it doesn't.

The script provides functions to easily create pairs, so you can customize what pairs you want.

By default, it does "", '', (), [] and {}.

### statusline.lua

A simple implementation of a custom statusline.

It shows the current MODE, file name, attributes, type, encoding and format, and cursor position with a pseudo "scrollbar",
so you can find where in the file you are in a glance.

Instead of using custom hl-groups, it uses some of the basic ones, so even if you use one of the builtin colorschemes, it looks ok and consistent.

### triggeromni.lua

A very simple "autocomplete" plugin, that triggers the omni-completion based on a set
of conditions. Depends on neovim lsp and lspconfig.

To use it, require the plugin, and then setup the conditions in the `on_attach` function of lspconfig for each lsp client/server using the `setup` function.

Here's my config file as an example:

```lua
local lspconfig = require "lspconfig"
local comp = require "triggeromni"

-- table with conditions for auto triggering omni-completion for each lsp client
local comp_conditions = {
	sumneko_lua = {
		comp.conditions.keyword;
		comp.conditions.member_access({'.',':'});
		};
	clangd = {
		comp.conditions.keyword;
		comp.conditions.member_access({'.','::';'->'});
		comp.conditions.begins_with("#");
		vim.regex([[^#include \("\|<\)]]);
	};
	jedi_language_server = {
		comp.conditions.keyword;
		comp.conditions.member_access({'.'});
		comp.conditions.begins_with('from ');
		vim.regex('import ');
	};
}

local function setup_lsp_mappings(client, bufnr)
	local api = vim.api
	local setoption = api.nvim_buf_set_option
	local setkeymap = api.nvim_buf_set_keymap
	local opts = { noremap = true, silent = true }

	-- setup completion
	setoption(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
	comp.setup(comp_conditions[client.name],bufnr)

	-- setup other keymaps
	setkeymap(bufnr, 'n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
	setkeymap(bufnr, 'n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
	setkeymap(bufnr, 'n', '<Leader>h', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
	setkeymap(bufnr, 'n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
	setkeymap(bufnr, 'n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
	setkeymap(bufnr, 'n', '<Leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
	setkeymap(bufnr, 'n', '<Leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
	setkeymap(bufnr, 'n', '<Leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
	setkeymap(bufnr, 'n', '<Leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
	setkeymap(bufnr, 'n', '<Leader>r', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
	setkeymap(bufnr, 'n', '<Leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
	setkeymap(bufnr, 'n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
	setkeymap(bufnr, 'n', '<Leader>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
end

-- python jedi language server configuration
lspconfig.jedi_language_server.setup {
	on_attach = setup_lsp_mappings,
}

-- clang lsp configuration
lspconfig.clangd.setup {
	on_attach = setup_lsp_mappings,
}

-- sumneko_lua lsp configuration
local lua_runtime_path = vim.split(package.path, ';')
table.insert(lua_runtime_path, "lua/?.lua")
table.insert(lua_runtime_path, "lua/?/init.lua")

lspconfig.sumneko_lua.setup {
	on_attach = setup_lsp_mappings,
	settings = {
		Lua = {
			runtime = {
				version = 'LuaJIT',
				path = lua_runtime_path
			},
			diagnostics = {
				globals = { 'vim' },
			},
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
			},
			telemetry = {
				enable = false,
			}
		}
	}
}
```

