# simple-lua-nvim-plugins
Simple, minimalistic Lua plugins/scripts for NeoVim 0.7.

## Installation

Just download the scripts and move them to the 'lua' folder inside your Neovim config folder.
Then `require` the plugin from your init.lua.

If you are using init.vim, the use `luafile` with the path to the plugin file to load it.

These are very simple and small plugins, that are "good enough" to do what they propose to do.
There's no configuration. There are meant to be used as a starting point for the user.
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

