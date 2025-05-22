local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " "

require("lazy").setup({
	{ "tpope/vim-repeat", event = "VeryLazy" },
	{
		-- debug print variables
		"andrewferrier/debugprint.nvim",
		event = "VeryLazy",
		version = "*",
		opts = {
			move_to_debugline = true,
			print_tag = "here",
			keymaps = {
				normal = {
					plain_below = "<leader>dl",
					plain_above = "g?P",
					variable_below = "<leader>dd",
					variable_above = "g?V",
					variable_below_alwaysprompt = nil,
					variable_above_alwaysprompt = nil,
					textobj_below = "g?o",
					textobj_above = "g?O",
					toggle_comment_debug_prints = nil,
					delete_debug_prints = nil,
				},
				visual = {
					variable_below = "<leader>dd",
					variable_above = "g?V",
				},
			},
			commands = {
				toggle_comment_debug_prints = "ToggleCommentDebugPrints",
				delete_debug_prints = "DeleteDebugPrints",
			},
		},
	},
	{
		"stevearc/oil.nvim",
		---@module 'oil'
		---@type oil.SetupOpts
		opts = {},
		-- Optional dependencies
		-- dependencies = { { "echasnovski/mini.icons", opts = {} } },
		-- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
		-- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
		lazy = false,
	},
	{
		"nvim-treesitter/nvim-treesitter",
		version = false, -- last release is way too old and doesn't work on Windows
		build = ":TSUpdate",
		event = { "VeryLazy" },
		opts = { ensure_installed = "all", highlight = { enable = false } },
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		init = function()
			-- disable rtp plugin, as we only need its queries for mini.ai
			-- In case other textobject modules are enabled, we will load them
			-- once nvim-treesitter is loaded
			require("lazy.core.loader").disable_rtp_plugin("nvim-treesitter-textobjects")
		end,
	},
	{
		"folke/flash.nvim",
		event = "VeryLazy",
		enabled = true,
		opts = {
			label = {
				-- uppercase = false,
				exclude = "S",
			},
			jump = {
				-- automatically jump when there is only one match
				autojump = true,
			},
			modes = {
				search = {
					enabled = false,
				},
				char = {
					enabled = false,
					keys = { "f", "F", ";", "," },
					label = { exclude = "hjkliardco" },
				},
			},
		},
		-- stylua: ignore
		keys = {
			{ "s",     mode = { "n", "x", "o" }, function() require("flash").jump() end,              desc = "Flash" },
			{ "S",     mode = { "n", "x", "o" }, function() require("flash").treesitter() end,        desc = "Flash Treesitter" },
			{ "r",     mode = "o",               function() require("flash").remote() end,            desc = "Remote Flash" },
			{ "R",     mode = { "o", "x" },      function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
			{ "<c-s>", mode = { "c" },           function() require("flash").toggle() end,            desc = "Toggle Flash Search" },
		}
,
	},
	{
		-- required for cmd + l
		"vscode-neovim/vscode-multi-cursor.nvim",
		event = "VeryLazy",
		opts = {},
	},
	{
		-- expand <C-a>/<C-x> toggles increments
		"nat-418/boole.nvim",
		opts = {
			mappings = {
				increment = "<C-a>",
				decrement = "<C-x>",
			},
		},
		event = "VeryLazy",
	},
	{
		-- surround with selection highlight
		"kylechui/nvim-surround",
		opts = {
			keymaps = {
				visual = "T",
			},
		},
		version = "*", -- Use for stability; omit to use `main` branch for the latest features
		event = "VeryLazy",
	},
	{
		"ckolkey/ts-node-action",
		dependencies = { "nvim-treesitter" },
		config = function()
			local ts_node_action = require("ts-node-action")
			ts_node_action.setup({
				tsx = ts_node_action.node_actions.typescriptreact,
			})
		end,
		keys = {
			{
				"<leader>ss",
				'<cmd>lua require("ts-node-action").node_action()<cr>',
				desc = "Toggle node action under cursor",
			},
		},
	},
	{
		"echasnovski/mini.ai",
		event = "VeryLazy",
		dependencies = { "nvim-treesitter-textobjects" },
		opts = function()
			local ai = require("mini.ai")
			return {
				n_lines = 500,
				custom_textobjects = {
					o = ai.gen_spec.treesitter({
						a = { "@block.outer", "@conditional.outer", "@loop.outer" },
						i = { "@block.inner", "@conditional.inner", "@loop.inner" },
					}, {}),
					f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
					c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
					-- line
					L = function(ai_type)
						local line_num = vim.fn.line(".")
						local line = vim.fn.getline(line_num)
						-- Select `\n` past the line for `a` to delete it whole
						local from_col, to_col = 1, line:len() + 1
						if ai_type == "i" then
							if line:len() == 0 then
								-- Don't remove empty line
								from_col, to_col = 0, 0
							else
								-- Ignore indentation for `i` textobject and don't remove `\n` past the line
								from_col = line:match("^%s*()")
								to_col = line:len()
							end
						end

						return { from = { line = line_num, col = from_col }, to = { line = line_num, col = to_col } }
					end,
					-- buffer
					B = function(ai_type)
						local n_lines = vim.fn.line("$")
						local start_line, end_line = 1, n_lines
						if ai_type == "i" then
							-- Skip first and last blank lines for `i` textobject
							local first_nonblank, last_nonblank = vim.fn.nextnonblank(1), vim.fn.prevnonblank(n_lines)
							start_line = first_nonblank == 0 and 1 or first_nonblank
							end_line = last_nonblank == 0 and n_lines or last_nonblank
						end

						local to_col = math.max(vim.fn.getline(end_line):len(), 1)
						return { from = { line = start_line, col = 1 }, to = { line = end_line, col = to_col } }
					end,
				},
			}
		end,
	},
	{
		-- i motion
		-- <count>ai  An Indentation level and line above.
		-- <count>ii  Inner Indentation level (no line above).
		-- <count>aI  An Indentation level and lines above/below.
		-- <count>iI  Inner Indentation level (no lines above/below).
		"michaeljsmith/vim-indent-object",
	},
	{
		-- generate github links
		"ruifm/gitlinker.nvim",
		-- event = "BufRead",
		dependencies = "nvim-lua/plenary.nvim",
		config = function()
			require("gitlinker").setup({
				opts = {
					add_current_line_on_normal_mode = true,
					action_callback = require("gitlinker.actions").open_in_browser,
					print_url = true,
					mappings = nil,
				},
				callbacks = {
					["github-nbcu.com"] = function(url_data)
						-- fix github.com-nbcu
						url_data.host = "github.com"

						if url_data.repo:find("/bff") then
							url_data.rev = "master"
						end

						return require("gitlinker.hosts").get_github_type_url(url_data)
					end,
				},
			})
		end,
		keys = {
			{
				"<leader>gy",
				function()
					require("gitlinker").get_buf_range_url("n")
				end,
				desc = "Create github link",
			},
			{
				"<leader>gy",
				function()
					require("gitlinker").get_buf_range_url("v")
				end,
				mode = "v",
				desc = "Create github link",
			},
		},
	},
	{
		"LunarVim/bigfile.nvim",
		opts = {},
	},
})

-- Options
vim.o.clipboard = "unnamedplus" -- system clipboard
vim.o.ignorecase = true -- Ignore case in searches / ?
vim.o.relativenumber = true -- Relative line numbers
-- vim.o.undofile = true -- Save undo history

----------------- Keymaps

-- Window Management
vim.keymap.set({ "n", "v" }, "<c-h>", "<cmd>lua require('vscode-neovim').action('workbench.action.navigateLeft')<cr>")
vim.keymap.set({ "n", "v" }, "<c-l>", "<cmd>lua require('vscode-neovim').action('workbench.action.navigateRight')<cr>")
vim.keymap.set({ "n", "v" }, "<c-j>", "<cmd>lua require('vscode-neovim').action('workbench.action.navigateDown')<cr>")
vim.keymap.set({ "n", "v" }, "<c-k>", "<cmd>lua require('vscode-neovim').action('workbench.action.navigateUp')<cr>")
vim.keymap.set("n", "<leader>cw", "<cmd>lua require('vscode-neovim').action('workbench.action.closeActiveEditor')<CR>")
vim.keymap.set(
	"n",
	"<leader>cs",
	"<cmd>lua require('vscode-neovim').action('workbench.action.closeEditorsAndGroup')<CR>"
)
vim.keymap.set("n", "<leader>cW", "<cmd>lua require('vscode-neovim').action('workbench.action.closeWindow')<CR>")
vim.keymap.set("n", "<leader>k", "<cmd>lua require('vscode-neovim').action('workbench.action.keepEditor')<CR>")
vim.keymap.set("n", "<leader>b", "<cmd>lua require('vscode-neovim').action('workbench.action.toggleAuxiliaryBar')<CR>")
vim.keymap.set("n", "L", "<cmd>lua require('vscode-neovim').action('workbench.action.nextEditor')<CR>")
vim.keymap.set("n", "H", "<cmd>lua require('vscode-neovim').action('workbench.action.previousEditor')<CR>")
vim.keymap.set(
	"n",
	"<leader>e",
	"<cmd>lua require('vscode-neovim').action('workbench.action.toggleSidebarVisibility')<CR>"
)
vim.keymap.set({ "n", "v" }, "<leader>E", "<cmd>lua require('vscode-neovim').action('workbench.view.explorer')<CR>")

-- vim.keymap.set({ "n", "v" }, "<leader>E", "<cmd>Oil<cr><CR>")

vim.keymap.set("n", "<leader>cab", "<cmd>lua require('vscode-neovim').action('workbench.action.closeOtherEditors')<CR>")
vim.keymap.set("n", "<leader>caw", function()
	require("vscode-neovim").action("workbench.action.closeSidebar")
	require("vscode-neovim").action("workbench.action.closeAuxiliaryBar")
end)
vim.keymap.set("n", "<leader>;", "<cmd>lua require('vscode-neovim').action('vsnetrw.open')<CR>")

-- vim.keymap.set("n", "<leader>;", function()
-- 	-- open a new terminal editor
-- 	-- cd to the current buffer directory
-- 	-- run a command: nvim .
-- 	require("vscode-neovim").call("workbench.action.createTerminalEditor")
-- 	local cwd = vim.fn.expand("%:p:h")
-- 	require("vscode-neovim").call("workbench.action.terminal.sendSequence", { args = { text = "cd " .. cwd .. "\n" } })
-- 	require("vscode-neovim").call("workbench.action.terminal.sendSequence", { args = { text = "nvim .\n" } })
-- end)

-- AI
vim.keymap.set(
	{ "n" },
	"<tab>",
	"<cmd>lua require('vscode-neovim').action('editor.action.inlineSuggest.triggerInlineEditExplicit')<cr>"
)
vim.keymap.set("n", "<leader>aa", "<cmd>lua require('vscode-neovim').action('workbench.action.openQuickChat')<CR>")
vim.keymap.set("n", "<leader>aA", "<cmd>lua require('vscode-neovim').action('workbench.panel.chat')<CR>")
vim.keymap.set("v", "<leader>ac", "<cmd>lua require('vscode-neovim').action('github.copilot.chat.generateDocs')<CR>")
vim.keymap.set(
	"n",
	"<leader>at",
	"<cmd>lua require('vscode-neovim').action('github.copilot.interactiveEditor.generateTests')<CR>"
)
vim.keymap.set("v", "<leader>aa", "<cmd>lua require('vscode-neovim').action('inlineChat.start')<CR>")

-- Files navigation
vim.keymap.set("n", "<leader>fI", "<cmd>lua require('vscode-neovim').action('workbench.action.showAllSymbols')<CR>")
vim.keymap.set("n", "<leader>fi", "<cmd>lua require('vscode-neovim').action('workbench.action.gotoSymbol')<CR>")
vim.keymap.set("n", "<leader>fs", "<cmd>lua require('vscode-neovim').action('workbench.action.gotoSymbol')<CR>")
vim.keymap.set({ "n", "v" }, "<leader>ff", "<cmd>lua require('vscode-neovim').action('workbench.action.quickOpen')<CR>")
vim.keymap.set({ "n", "v" }, "<leader>fa", "<cmd>lua require('vscode-neovim').action('florencio.openFiles')<CR>")
vim.keymap.set("n", "<leader>fw", "<cmd>lua require('vscode-neovim').action('workbench.action.quickTextSearch')<CR>")
vim.keymap.set("v", "<leader>fw", "<cmd>lua require('vscode-neovim').action('workbench.action.findInFiles')<CR>")
vim.keymap.set("n", "<leader>fW", "<cmd>lua require('vscode-neovim').action('florencio.searchInFiles')<CR>")
vim.keymap.set("n", "<leader>FW", "<cmd>lua require('vscode-neovim').action('florencio.searchInFilesEditorCWD')<CR>")
-- vim.keymap.set("n", "<leader>fW", "<cmd>lua require('vscode-neovim').action('workbench.view.search')<CR>")
vim.keymap.set("n", "<leader>fg", "<cmd>lua require('vscode-neovim').action('florencio.openChangedFiles')<CR>")
vim.keymap.set(
	"n",
	"<leader>j",
	"<cmd>lua require('vscode-neovim').action('workbench.action.showAllEditorsByMostRecentlyUsed')<CR>"
)

vim.keymap.set("n", "<leader>nf", "<cmd>lua require('vscode-neovim').action('create-relative-file.create')<CR>")

-- Harpoon
vim.keymap.set("n", "<leader>m", "<cmd>lua require('vscode-neovim').action('vscode-harpoon.addEditor')<CR>")
vim.keymap.set("n", "<leader>h", "<cmd>lua require('vscode-neovim').action('vscode-harpoon.editorQuickPick')<CR>")
vim.keymap.set("n", "<leader>H", "<cmd>lua require('vscode-neovim').action('vscode-harpoon.editEditors')<CR>")

-- Git
vim.keymap.set("n", "<leader>gG", "<cmd>lua require('vscode-neovim').action('workbench.view.scm')<CR>")
vim.keymap.set("n", "<leader>gg", "<cmd>lua require('vscode-neovim').action('florencio.weztermLazyGit')<CR>")
-- vim.keymap.set("n", "<leader>gg", "<cmd>lua require('vscode-neovim').action('florencio.lazygit')<CR>")
vim.keymap.set("n", "<leader>gb", "<cmd>lua require('vscode-neovim').action('gitlens.toggleFileBlame')<CR>")
-- vim.keymap.set("n", "<leader>gy", "<cmd>lua require('vscode-neovim').action('extension.openInGitHub')<CR>")
vim.keymap.set("n", "<leader>gp", "<cmd>lua require('vscode-neovim').action('editor.action.dirtydiff.next')<CR>")
vim.keymap.set("n", "<leader>gP", "<cmd>lua require('vscode-neovim').action('git.pull')<CR>")
vim.keymap.set("n", "<leader>gr", "<cmd>lua require('vscode-neovim').action('git.revertSelectedRanges')<CR>")
vim.keymap.set("n", "<leader>gR", "<cmd>lua require('vscode-neovim').action('git.clean')<CR>")
vim.keymap.set("n", "<leader>gc", "<cmd>lua require('vscode-neovim').action('workbench.scm.focus')<CR>")

-- Toggles
vim.keymap.set("n", "<leader>tw", "<cmd>lua require('vscode-neovim').action('editor.action.toggleWordWrap')<CR>")
vim.keymap.set("n", "<leader>TT", "<cmd>lua require('vscode-neovim').action('workbench.action.toggleZenMode')<CR>")
vim.keymap.set("n", "<leader>z", "<cmd>lua require('vscode-neovim').action('workbench.action.toggleZenMode')<CR>")
vim.keymap.set(
	"n",
	"<leader>tc",
	"<cmd>lua require('vscode-neovim').action('workbench.action.toggleCenteredLayout')<CR>"
)
vim.keymap.set("n", "<leader>tt", "<cmd>lua require('vscode-neovim').action('workbench.actions.view.problems')<CR>")

-- Runs, Tasks
vim.keymap.set("n", ",r", "<cmd>lua require('vscode-neovim').action('workbench.action.tasks.runTask')<CR>")
vim.keymap.set("n", ",bb", "<cmd>lua require('vscode-neovim').action('editor.debug.action.toggleBreakpoint')<CR>")

-- Marks
vim.keymap.set("n", "<leader>dm", "<cmd>delmarks!<CR>")

-- Splits
vim.keymap.set("n", "<leader>sv", "<cmd>lua require('vscode-neovim').action('workbench.action.splitEditor')<cr>")
vim.keymap.set(
	"n",
	"<leader>sh",
	"<cmd>lua require('vscode-neovim').action('workbench.action.splitEditorOrthogonal')<cr>"
)
vim.keymap.set("n", "<leader>sm", function()
	require("vscode-neovim").action("workbench.action.toggleMaximizeEditorGroup")
	require("vscode-neovim").action("workbench.action.closeAuxiliaryBar")
end)

-- new lines
vim.keymap.set("n", "] ", "o<ESC>k")
vim.keymap.set("n", "[ ", "O<ESC>j")

-- hightlight current word without moving to the next
vim.keymap.set("n", "*", "*N")

vim.keymap.set({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>")

-- Editing
vim.keymap.set("v", "y", "mcy`c") -- yank without moving cursor, using marks
vim.keymap.set("v", "<C-p>", "y'>p")
vim.keymap.set("x", "p", "P") -- paste and select pasted text
vim.keymap.set("n", "gp", "p`]") -- paste line below and move cursor to the end of the pasted text
vim.keymap.set("v", "<CR>", "<cmd>lua require('vscode-neovim').action('editor.action.smartSelect.expand')<CR>")
vim.keymap.set("n", "<BS>", "ciw")
vim.keymap.set("v", "<leader>i", "<esc>`<i", { desc = "Insert at beginning selection" })
vim.keymap.set(
	{ "n", "v" },
	"<leader>fm",
	"<cmd>lua require('vscode-neovim').action('editor.action.formatDocument')<CR>"
)

-- Surrounds keymaps
vim.keymap.set("n", '<leader>S"', 'ysiW"', { desc = "Surround word with double quotes", remap = true })
vim.keymap.set("n", "<leader>S`", "ysiW`", { desc = "Surround word with accent quotes", remap = true })
vim.keymap.set("n", "<leader>S'", "ysiW'", { desc = "Surround word with single quotes", remap = true })
vim.keymap.set("n", '<leader>s"', 'ysiw"', { desc = "Surround word with double quotes", remap = true })
vim.keymap.set("n", "<leader>s'", "ysiw'", { desc = "Surround word with single quotes", remap = true })
vim.keymap.set("n", "<leader>s`", "ysiw`", { desc = "Surround word with accent quotes", remap = true })
-- visual shorcuts
vim.keymap.set("v", "'", "T'", { desc = "Surround word with single quotes", remap = true })
vim.keymap.set("v", '"', 'T"', { desc = "Surround word with double quotes", remap = true })
vim.keymap.set("v", "`", "T`", { desc = "Surround word with accent quotes", remap = true })
-- visual mode, nvimp-surround supports S', S", S>, etc

-- ]] and [[
vim.keymap.set("n", "[q", "<cmd>lua require('vscode-neovim').action('search.action.focusPreviousSearchResult')<CR>")
vim.keymap.set("n", "]q", "<cmd>lua require('vscode-neovim').action('search.action.focusNextSearchResult')<CR>")
vim.keymap.set("n", "[r", "<cmd>lua require('vscode-neovim').action('references-view.prev')<CR>")
vim.keymap.set("n", "]r", "<cmd>lua require('vscode-neovim').action('references-view.next')<CR>")
vim.keymap.set("n", "[e", "<cmd>lua require('vscode-neovim').action('florencio.goToPreviousError')<CR>")
vim.keymap.set("n", "]e", "<cmd>lua require('vscode-neovim').action('florencio.goToNextError')<CR>")
vim.keymap.set("n", "]d", "<cmd>lua require('vscode-neovim').action('florencio.goToNextDiagnostic')<CR>")
vim.keymap.set("n", "[d", "<cmd>lua require('vscode-neovim').action('florencio.goToPreviousDiagnostic')<CR>")
vim.keymap.set("n", "]w", "<cmd>lua require('vscode-neovim').action('florencio.goToNextWarning')<CR>")
vim.keymap.set("n", "[w", "<cmd>lua require('vscode-neovim').action('florencio.goToPreviousWarning')<CR>")
vim.keymap.set("n", "[c", "<cmd>lua require('vscode-neovim').action('workbench.action.editor.previousChange')<CR>")
vim.keymap.set("n", "]c", "<cmd>lua require('vscode-neovim').action('workbench.action.editor.nextChange')<CR>")
vim.keymap.set("n", "[m", "['")
vim.keymap.set("n", "]m", "]'")

-- Markdown Preview
vim.keymap.set("n", "<leader>pp", function()
	require("vscode-neovim").action("markdown.showPreviewToSide")
	require("vscode-neovim").action("workbench.action.focusLeftGroup")
end)

vim.keymap.set("n", "<leader>pc", function()
	require("vscode-neovim").action("workbench.action.focusRightGroup")
	require("vscode-neovim").action("workbench.action.closeActiveEditor")
end)

-- cycle between buffers
-- vim.keymap.set("n", "<leader><space>", "<c-^>", { desc = "Cycle between buffers" } )

-- Comments
vim.keymap.set({ "n", "v" }, "<leader>/", "<cmd>lua require('vscode-neovim').action('editor.action.commentLine')<cr>")

-- LSP
vim.keymap.set({ "n", "v" }, "<leader>la", "<cmd>lua require('vscode-neovim').action('editor.action.quickFix')<cr>")
vim.keymap.set("n", "<leader>lA", "<cmd>lua require('vscode-neovim').action('editor.action.showContextMenu')<cr>")
vim.keymap.set("n", "<leader>lr", "<cmd>lua require('vscode-neovim').action('editor.action.rename')<cr>")
vim.keymap.set("n", "<leader>lR", "<cmd>lua require('vscode-neovim').action('editor.action.renameFile')<cr>")
vim.keymap.set("n", "<leader>lR", "<cmd>lua require('vscode-neovim').action('editor.action.renameFile')<cr>")
vim.keymap.set("n", "gI", "<cmd>lua require('vscode-neovim').action('editor.action.goToImplementation')<cr>")
vim.keymap.set("n", "gr", "<cmd>lua require('vscode-neovim').action('editor.action.goToReferences')<cr>")
vim.keymap.set("n", "gd", "<cmd>lua require('vscode-neovim').action('editor.action.peekDefinition')<cr>")
vim.keymap.set("n", "gt", "<cmd>lua require('vscode-neovim').action('editor.action.goToTypeDefinition')<cr>")

-- Don't yank empty lines into the main register
vim.keymap.set("n", "dd", function()
	if vim.api.nvim_get_current_line():match("^%s*$") then
		return '"_dd'
	else
		return "dd"
	end
end, { expr = true })

-- rebind 'i' to do a smart-indent if its a blank line
vim.keymap.set("n", "i", function()
	if #vim.fn.getline(".") == 0 then
		return [["_cc]]
	else
		return "i"
	end
end, { expr = true })

-- Better indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Languages
vim.keymap.set("n", "<leader>ou", "<cmd>lua require('vscode-neovim').action('typescript.removeUnusedImports')<CR>")
vim.keymap.set("n", "<leader>oa", function()
	require("vscode-neovim").action(
		"editor.action.sourceAction",
		{ args = { kind = "source.addMissingImports", apply = "first" } }
	)
end)

-- Autocommands
vim.cmd([[au TextYankPost * silent! lua vim.highlight.on_yank()]])
vim.cmd([[au InsertEnter * set nu nornu]]) -- disable relative numbers in insert mode
vim.cmd([[au InsertLeave * set nu rnu]])

-- Multi Cursor
vim.keymap.set({ "n", "x", "i" }, "<C-n>", function()
	require("vscode-multi-cursor").addSelectionToNextFindMatch()
end)

-- makes * and # work on visual mode too.
vim.api.nvim_exec(
	[[
  function! g:VSetSearch(cmdtype)
    let temp = @s
    norm! gv"sy
    let @/ = '\V' . substitute(escape(@s, a:cmdtype.'\'), '\n', '\\n', 'g')
    let @s = temp
  endfunction

  xnoremap * :<C-u>call g:VSetSearch('/')<CR>/<C-R>=@/<CR><CR>
  xnoremap # :<C-u>call g:VSetSearch('?')<CR>?<C-R>=@/<CR><CR>
]],
	false
)
