-- ==========================================================================
-- 1. SHARED SETTINGS (Runs in both Neovim and VS Code)
-- ==========================================================================
vim.g.mapleader = " " -- Sets the 'Leader' key to Spacebar

-- The Home-Row Escape
vim.keymap.set('i', 'jj', '<Esc>', { desc = 'Exit Insert Mode' })
vim.keymap.set('i', 'jk', '<Esc>', { desc = 'Exit Insert Mode' })

-- Focus Scrolling: Keeps cursor centered while jumping half-pages or searching
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = 'Scroll Down (Centered)' })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = 'Scroll Up (Centered)' })
vim.keymap.set("n", "n", "nzzzv", { desc = 'Next Match (Centered)' })
vim.keymap.set("n", "N", "Nzzzv", { desc = 'Prev Match (Centered)' })

-- Visual Block Dragging: Moves highlighted code blocks up/down with J and K
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = 'Move block down' })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = 'Move block up' })

-- System Clipboard Integration
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = 'Copy to System Clipboard' })
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = 'Paste and Keep Clipboard Content' })

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear Search Highlights' })

-- ==========================================================================
-- 2. ENVIRONMENT SPLIT
-- ==========================================================================
if vim.g.vscode then
	-- ==========================================================================
	-- VS CODE SPECIFIC CONFIGURATION
	-- ==========================================================================
	local vscode = require('vscode')

	-- Save & Quit
	vim.keymap.set('n', '<leader>w', function() vscode.call('workbench.action.files.save') end)
	vim.keymap.set('n', '<leader>q', function() vscode.call('workbench.action.closeActiveEditor') end)
	vim.keymap.set('n', '<leader>c', function() vscode.call('workbench.action.closeActiveEditor') end)

	-- Teleportation (Alt keys mapped to VS Code split navigation)
	vim.keymap.set({ 'n', 'v', 'i' }, '<A-h>', function() vscode.call('workbench.action.navigateLeft') end)
	vim.keymap.set({ 'n', 'v', 'i' }, '<A-j>', function() vscode.call('workbench.action.navigateDown') end)
	vim.keymap.set({ 'n', 'v', 'i' }, '<A-k>', function() vscode.call('workbench.action.navigateUp') end)
	vim.keymap.set({ 'n', 'v', 'i' }, '<A-l>', function() vscode.call('workbench.action.navigateRight') end)

	-- UI & Explorer
	vim.keymap.set('n', '<leader>e', function() vscode.call('workbench.view.explorer') end)
	vim.keymap.set('n', '<leader>sf', function() vscode.call('workbench.action.quickOpen') end)
	vim.keymap.set('n', '<leader>sg', function() vscode.call('workbench.action.findInFiles') end)

	-- LSP & Formatting
	vim.keymap.set('n', 'gd', function() vscode.call('editor.action.revealDefinition') end)
	vim.keymap.set('n', 'gr', function() vscode.call('editor.action.referenceSearch.trigger') end)
	vim.keymap.set('n', 'gi', function() vscode.call('editor.action.goToImplementation') end)
	vim.keymap.set('n', 'K', function() vscode.call('editor.action.showHover') end)
	vim.keymap.set('n', '<leader>rn', function() vscode.call('editor.action.rename') end)
	vim.keymap.set('n', '<leader>ca', function() vscode.call('editor.action.quickFix') end)
	vim.keymap.set('n', '<leader>f', function() vscode.call('editor.action.formatDocument') end)

	-- Diagnostics
	vim.keymap.set('n', '[d', function() vscode.call('editor.action.marker.prev') end)
	vim.keymap.set('n', ']d', function() vscode.call('editor.action.marker.next') end)
	vim.keymap.set('n', '<leader>xx', function() vscode.call('workbench.actions.view.problems') end)

	-- Comments
	vim.keymap.set({ 'n', 'v' }, 'gc', function() vscode.call('editor.action.commentLine') end)
	vim.keymap.set('n', 'gcc', function() vscode.call('editor.action.commentLine') end)
else
	-- ==========================================================================
	-- STANDALONE NEOVIM CONFIGURATION
	-- ==========================================================================
	-- CORE SETTINGS (The Foundations)
	vim.opt.number = true
	vim.opt.relativenumber = true
	vim.opt.cursorline = true
	vim.opt.scrolloff = 8
	vim.opt.termguicolors = true
	vim.opt.cmdheight = 1
	vim.opt.timeoutlen = 300

	vim.opt.tabstop = 4      -- Number of spaces that a literal <Tab> counts for
	vim.opt.shiftwidth = 4   -- Size of an indent (used for >> and << operations)
	vim.opt.expandtab = true -- The magic switch: converts hitting <Tab> into spaces
	vim.opt.softtabstop = 4  -- Makes hitting backspace delete 4 spaces at once

	-- Modern 0.11 OSC 52 Integration
	vim.g.clipboard = {
		name = 'OSC 52',
		copy = {
			['+'] = require('vim.ui.clipboard.osc52').copy('+'),
			['*'] = require('vim.ui.clipboard.osc52').copy('*'),
		},
		paste = {
			['+'] = require('vim.ui.clipboard.osc52').paste('+'),
			['*'] = require('vim.ui.clipboard.osc52').paste('*'),
		},
	}

	-- Save & Quit Shortcuts (Standalone)
	vim.keymap.set('n', '<leader>w', ':w<CR>', { desc = 'Save File' })
	vim.keymap.set('n', '<leader>q', ':q<CR>', { desc = 'Quit Neovim' })

	-- Window Resizing: Use Alt + Arrow keys
	vim.keymap.set('n', '<A-Up>', ':resize +2<CR>', { desc = 'Increase height' })
	vim.keymap.set('n', '<A-Down>', ':resize -2<CR>', { desc = 'Decrease height' })
	vim.keymap.set('n', '<A-Left>', ':vertical resize -2<CR>', { desc = 'Decrease width' })
	vim.keymap.set('n', '<A-Right>', ':vertical resize +2<CR>', { desc = 'Increase width' })
	vim.keymap.set('n', '<C-w>=', '<C-w>=', { desc = 'Equalize splits' })

	-- Insert Mode Navigation (Escapes insert and jumps)
	vim.keymap.set('i', '<A-h>', [[<Esc><C-w>h]], { desc = 'Jump Left from Insert' })
	vim.keymap.set('i', '<A-j>', [[<Esc><C-w>j]], { desc = 'Jump Down from Insert' })
	vim.keymap.set('i', '<A-k>', [[<Esc><C-w>k]], { desc = 'Jump Up from Insert' })
	vim.keymap.set('i', '<A-l>', [[<Esc><C-w>l]], { desc = 'Jump Right from Insert' })

	-- Terminal Mode Navigation (Escapes focus and jumps)
	vim.keymap.set('t', '<A-h>', [[<C-\><C-n><C-w>h]], { desc = 'Jump Left from Term' })
	vim.keymap.set('t', '<A-j>', [[<C-\><C-n><C-w>j]], { desc = 'Jump Down from Term' })
	vim.keymap.set('t', '<A-k>', [[<C-\><C-n><C-w>k]], { desc = 'Jump Up from Term' })
	vim.keymap.set('t', '<A-l>', [[<C-\><C-n><C-w>l]], { desc = 'Jump Right from Term' })

	local function escape_term_to_code()
		local buftype = vim.api.nvim_get_option_value("buftype", { buf = 0 })
		if buftype == "terminal" or vim.api.nvim_win_get_width(0) < 60 then
			vim.cmd('wincmd w')
		end
	end

	vim.keymap.set({ 'n', 't' }, '`', '<cmd>1ToggleTerm direction=float<cr>', { desc = 'Quick Float' })

	vim.keymap.set('n', '<leader>tr', function()
		escape_term_to_code()
		vim.cmd('vert botright 2ToggleTerm direction=vertical size=60')
		vim.opt.cmdheight = 1
	end, { desc = 'Term Right' })

	vim.keymap.set('n', '<leader>td', function()
		escape_term_to_code()
		vim.cmd('botright 3ToggleTerm direction=horizontal size=15')
		vim.opt.cmdheight = 1
	end, { desc = 'Term Down' })

	vim.keymap.set('n', '<leader>tn', '<cmd>tabnew | term<cr>i', { desc = 'New Clean Tab with Terminal' })
	vim.keymap.set('n', '<leader>tx', '<cmd>tabclose<cr>', { desc = 'Close Current Tab' })

	vim.keymap.set('n', '<A-1>', '1gt', { desc = 'Go to Tab 1' })
	vim.keymap.set('n', '<A-2>', '2gt', { desc = 'Go to Tab 2' })
	vim.keymap.set('n', '<A-3>', '3gt', { desc = 'Go to Tab 3' })

	vim.api.nvim_create_autocmd("TermOpen", {
		pattern = "term://*",
		callback = function()
			local opts = { buffer = 0 }
			vim.keymap.set('t', 'jj', [[<C-\><C-n>]], opts)
			vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
		end,
	})

	vim.keymap.set('n', '<leader>f', function()
		vim.lsp.buf.format({ async = true })
		print("File Formatted!")
	end, { desc = 'Format File' })

	-- Format on save is handled by conform.nvim below (see plugin block).
	-- Conform falls back to LSP for filetypes without a configured external
	-- formatter, so this matches the previous behavior plus Prettier for TS/JS.

	-- ==========================================================================
	-- THE MASTER HUD
	-- ==========================================================================
	vim.keymap.set('n', '<leader>?', function()
		local col_w = 43
		local sep   = " │ "

		local function pad(s, w)
			return s .. string.rep(" ", math.max(0, w - #s))
		end

		local left     = {
			"  CORE OPERATIONS",
			"  jj / jk      Escape mode",
			"  `            Float Terminal",
			"  <leader>w    Save File",
			"  <leader>q    Quit Neovim",
			"  <leader>c    Close Buffer",
			"  <leader>f    Format File",
			"  <leader>?    This HUD",
			"",
			"  TELEPORT (ALT)",
			"  Alt+h/j/k/l  Jump Windows",
			"  Alt+1/2/3    Switch Tabs",
			"  Alt+Arrows   Resize Window",
			"  <C-w>=       Equalize Splits",
			"",
			"  TERMINAL & TABS",
			"  <leader>tr   Term Right",
			"  <leader>td   Term Down",
			"  <leader>tn   New Tab + Terminal",
			"  <leader>tx   Close Tab",
			"",
			"  NAVIGATION",
			"  C-o / C-i    Jump Back/Forward",
			"  C-d / C-u    Scroll Centered",
			"  n / N        Search Centered",
			"  [d / ]d      Prev/Next Diagnostic",
			"  <leader>e    File Explorer",
			"",
			"  HOP (Visual Jump)",
			"  <leader>hw   Jump to Word",
			"  <leader>hc   Jump to Char",
			"  <leader>hl   Jump to Line",
		}

		local right    = {
			"  SEARCH & LSP",
			"  <leader>sf   Search Files",
			"  <leader>sg   Live Grep",
			"  :TodoTelescope Search TODOs",
			"  gd           Go to Definition",
			"  gr           Go to References",
			"  gi           Go to Implementation",
			"  K            Hover Docs",
			"  <leader>rn   Rename Symbol",
			"  <leader>ca   Code Action",
			"  <leader>y    Yank to Clipboard",
			"  <leader>p    Paste (keep reg, visual)",
			"  J/K (visual) Move Block Up/Down",
			"",
			"  DIAGNOSTICS",
			"  <leader>xx   Workspace Diagnostics",
			"  <leader>xd   Buffer Diagnostics",
			"  <leader>xq   Quickfix List",
			"",
			"  GIT",
			"  <leader>gd   Diff View",
			"  <leader>gf   File History",
			"  <leader>gc   Close Diff",
			"  <leader>gn   Next Hunk",
			"  <leader>gb   Prev Hunk",
			"  <leader>gp   Preview Hunk",
			"  <leader>gs   Stage Hunk",
			"  <leader>gr   Reset Hunk",
			"",
			"  COMMENTS & SURROUND",
			"  gcc          Toggle Line Comment",
			"  gc (visual)  Block Comment",
			"  ys{m}{c}     Add Surround",
			"  ds{c}        Delete Surround",
			"  cs{o}{n}     Change Surround",
		}

		local total_w  = col_w + #sep + col_w
		local divider  = string.rep("─", total_w)
		local title    = " MASTER ENGINEER CHEAT SHEET "
		local t_pad    = string.rep(" ", math.floor((total_w - #title) / 2))
		local f_note   = "Press <Esc> or q to close"
		local f_pad    = string.rep(" ", math.floor((total_w - #f_note) / 2))

		local contents = { t_pad .. title, divider }

		local rows     = math.max(#left, #right)
		for i = 1, rows do
			table.insert(contents, pad(left[i] or "", col_w) .. sep .. (right[i] or ""))
		end

		table.insert(contents, divider)
		table.insert(contents, f_pad .. f_note)

		local uis      = vim.api.nvim_list_uis()
		local ui       = uis[1] or { width = 120, height = 40 }

		local win_opts = {
			relative  = "editor",
			width     = total_w,
			height    = #contents,
			col       = math.floor((ui.width - total_w) / 2),
			row       = math.floor((ui.height - #contents) / 2),
			style     = "minimal",
			border    = "rounded",
			title     = " Master Cheat Sheet ",
			title_pos = "center",
		}

		local buf      = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, contents)
		local win = vim.api.nvim_open_win(buf, true, win_opts)

		for _, key in ipairs({ 'q', '<Esc>' }) do
			vim.keymap.set('n', key, function()
				if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
			end, { buffer = buf })
		end
	end, { desc = 'Show Master HUD' })

	-- ==========================================================================
	-- PLUGIN MANAGEMENT (Lazy.nvim)
	-- ==========================================================================
	local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
	if not vim.uv.fs_stat(lazypath) then
		vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git",
			"--branch=stable",
			lazypath })
	end
	vim.opt.rtp:prepend(lazypath)

	require("lazy").setup({
		-- UI & Theme
		{ "folke/tokyonight.nvim",      priority = 1000, config = function() vim.cmd([[colorscheme tokyonight]]) end },
		{ "nvim-tree/nvim-web-devicons" },

		-- File Explorer
		{
			"nvim-tree/nvim-tree.lua",
			config = function()
				local api = require("nvim-tree.api")
				local function my_on_attach(bufnr)
					api.config.mappings.default_on_attach(bufnr)
					vim.keymap.set('n', 'C', api.tree.change_root_to_node,
						{ buffer = bufnr, desc = "CD" })
					vim.keymap.set('n', 'U', api.tree.change_root_to_parent,
						{ buffer = bufnr, desc = "Up" })
				end
				require("nvim-tree").setup({
					on_attach = my_on_attach,
					sync_root_with_cwd = true,
					update_focused_file = { enable = true, update_root = true },
				})
				vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = 'Toggle File Explorer' })
			end
		},

		-- Fuzzy Finder
		{ "nvim-lua/plenary.nvim" },
		{
			"nvim-telescope/telescope.nvim",
			dependencies = { "nvim-lua/plenary.nvim", { "nvim-telescope/telescope-fzf-native.nvim", build = "make" } },
			config = function()
				local builtin = require('telescope.builtin')
				vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = 'Search Files' })
				vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = 'Search Grep' })
			end
		},

		-- Syntax Highlighting
		{
			"nvim-treesitter/nvim-treesitter",
			build = ":TSUpdate",
			opts = {
				ensure_installed = { "c", "cpp", "rust", "lua", "vim", "python", "javascript", "typescript", "bash" },
				highlight = { enable = true },
			}
		},

		-- THE BRAINS
		{
			"neovim/nvim-lspconfig",
			dependencies = { "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim" },
			config = function()
				require("mason").setup()
				require("mason-lspconfig").setup({
					ensure_installed = { "lua_ls", "pyright", "ts_ls", "clangd", "bashls", "rust_analyzer" },
				})
				local servers = { "lua_ls", "pyright", "ts_ls", "clangd", "bashls" }
				for _, server in ipairs(servers) do
					if vim.lsp.enable then
						vim.lsp.enable(server)
					else
						require('lspconfig')[server].setup({})
					end
				end
				-- Navigation
				vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'Hover Documentation' })
				vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to Definition' })
				vim.keymap.set('n', 'gr', vim.lsp.buf.references, { desc = 'Go to References' })
				vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { desc = 'Go to Implementation' })
				-- Actions
				vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code Action' })
				vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = 'Rename Symbol' })
				-- Diagnostics
				vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Prev Diagnostic' })
				vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Next Diagnostic' })
			end
		},

		-- RUSTACEAN VIM
		{ 'mrcjkb/rustaceanvim',  version = '^5', lazy = false },

		-- Autocomplete
		{
			"hrsh7th/nvim-cmp",
			dependencies = { "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path" },
			config = function()
				local cmp = require("cmp")
				cmp.setup({
					mapping = cmp.mapping.preset.insert({
						['<CR>']    = cmp.mapping.confirm({ select = true }),
						['<Tab>']   = cmp.mapping.select_next_item(),
						['<S-Tab>'] = cmp.mapping.select_prev_item(),
					}),
					sources = cmp.config.sources({ { name = 'nvim_lsp' }, { name = 'path' } },
						{ { name = 'buffer' } })
				})
			end
		},

		-- Formatter runner (Prettier/etc.). Reads project .prettierrc so the
		-- file matches what VSCode's Prettier-on-save would produce.
		{
			"stevearc/conform.nvim",
			event = { "BufWritePre" },
			cmd = { "ConformInfo" },
			config = function()
				require("conform").setup({
					formatters_by_ft = {
						javascript = { "prettier" },
						javascriptreact = { "prettier" },
						typescript = { "prettier" },
						typescriptreact = { "prettier" },
						json = { "prettier" },
						jsonc = { "prettier" },
						yaml = { "prettier" },
						markdown = { "prettier" },
						html = { "prettier" },
						css = { "prettier" },
						scss = { "prettier" },
					},
					format_on_save = {
						timeout_ms = 2000,
						lsp_format = "fallback",
					},
				})
			end,
		},

		-- UI & UTILS
		{ "tpope/vim-sleuth" },
		{
			"echasnovski/mini.nvim",
			config = function()
				require("mini.statusline").setup()
				require("mini.pairs").setup()
				require("mini.comment").setup()
			end
		},
		{
			"folke/which-key.nvim",
			config = function()
				local wk = require("which-key")
				wk.setup()
				wk.add({
					{ "<leader>g", group = "git" },
					{ "<leader>x", group = "diagnostics" },
					{ "<leader>h", group = "hop" },
					{ "<leader>t", group = "terminal/tabs" },
					{ "<leader>s", group = "search" },
				})
			end
		},
		{
			"akinsho/toggleterm.nvim",
			config = function()
				require("toggleterm").setup({
					open_mapping = [[<c-\>]],
					direction = 'float',
					float_opts = { border = 'rounded' }
				})
			end
		},
		{
			"folke/trouble.nvim",
			config = function()
				require("trouble").setup()
				vim.keymap.set('n', '<leader>xx', '<cmd>Trouble diagnostics toggle<cr>',
					{ desc = 'Workspace Diagnostics' })
				vim.keymap.set('n', '<leader>xd', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',
					{ desc = 'Buffer Diagnostics' })
				vim.keymap.set('n', '<leader>xq', '<cmd>Trouble qflist toggle<cr>',
					{ desc = 'Quickfix List' })
			end
		},
		{ "kylechui/nvim-surround",   config = function() require("nvim-surround").setup() end },
		{
			"smoka7/hop.nvim",
			config = function()
				require("hop").setup()
				vim.keymap.set('n', '<leader>hw', '<cmd>HopWord<cr>', { desc = 'Jump to Word' })
				vim.keymap.set('n', '<leader>hc', '<cmd>HopChar1<cr>', { desc = 'Jump to Char' })
				vim.keymap.set('n', '<leader>hl', '<cmd>HopLine<cr>', { desc = 'Jump to Line' })
			end
		},
		{ "folke/todo-comments.nvim", config = function() require("todo-comments").setup() end },
		{
			"famiu/bufdelete.nvim",
			config = function()
				vim.keymap.set('n', '<leader>c', '<cmd>Bdelete<cr>',
					{ desc = 'Close Buffer' })
			end
		},

		-- Git
		{
			"lewis6991/gitsigns.nvim",
			config = function()
				require("gitsigns").setup()
				local gs = require("gitsigns")
				vim.keymap.set('n', '<leader>gn', gs.next_hunk, { desc = 'Next Hunk' })
				vim.keymap.set('n', '<leader>gb', gs.prev_hunk, { desc = 'Prev Hunk' })
				vim.keymap.set('n', '<leader>gp', gs.preview_hunk, { desc = 'Preview Hunk' })
				vim.keymap.set('n', '<leader>gs', gs.stage_hunk, { desc = 'Stage Hunk' })
				vim.keymap.set('n', '<leader>gr', gs.reset_hunk, { desc = 'Reset Hunk' })
			end
		},
		{
			"sindrets/diffview.nvim",
			dependencies = { "nvim-lua/plenary.nvim" },
			config = function()
				require("diffview").setup()
				vim.keymap.set('n', '<leader>gd', '<cmd>DiffviewOpen<cr>', { desc = 'Diff View' })
				vim.keymap.set('n', '<leader>gf', '<cmd>DiffviewFileHistory %<cr>',
					{ desc = 'File History' })
				vim.keymap.set('n', '<leader>gc', '<cmd>DiffviewClose<cr>', { desc = 'Close Diff' })
			end
		},
		{
			"christoomey/vim-tmux-navigator",
			cmd = {
				"TmuxNavigateLeft",
				"TmuxNavigateDown",
				"TmuxNavigateUp",
				"TmuxNavigateRight",
			},
			keys = {
				{ "<M-h>", "<cmd>TmuxNavigateLeft<cr>" },
				{ "<M-j>", "<cmd>TmuxNavigateDown<cr>" },
				{ "<M-k>", "<cmd>TmuxNavigateUp<cr>" },
				{ "<M-l>", "<cmd>TmuxNavigateRight<cr>" },
			},
		}
	})
end
