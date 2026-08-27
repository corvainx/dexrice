local function get_shell()
	--	local shell = os.getenv("SHELL") or ""
	--	local known = { "fish", "zsh", "bash", "nu" }

	--	for _, s in ipairs(known) do
	--		if shell:match(s) then
	--			return s
	--		end
	--	end

	--	for _, s in ipairs({ "fish", "zsh", "bash" }) do
	--		if vim.fn.executable(s) == 1 then
	--			return s
	--		end
	--	end

	return "bash"
end

vim.api.nvim_create_autocmd("TermOpen", {
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
		vim.opt_local.statuscolumn = ""
	end,
})

vim.keymap.set("n", "<leader>r", function()
	local ft = vim.bo.filetype
	local file = vim.fn.expand("%:p")
	local name = vim.fn.expand("%:t:r")
	local shell = get_shell()

	local commands = {
		go = string.format("go run %s", vim.fn.shellescape(file)),
		python = string.format("python3 %s; %s", vim.fn.shellescape(file), shell),
		c = string.format("gcc %s -o /tmp/%s && /tmp/%s; %s", vim.fn.shellescape(file), name, name, shell),
		cpp = string.format("g++ %s -o /tmp/%s && /tmp/%s; %s", vim.fn.shellescape(file), name, name, shell),
		java = string.format(
			"mkdir -p /tmp/java-run/%s && javac -d /tmp/java-run/%s %s && java -cp /tmp/java-run/%s %s; %s",
			name,
			name,
			vim.fn.shellescape(file),
			name,
			name,
			shell
		),
	}
	local cmd = commands[ft]
	if not cmd then
		vim.notify("No runner for: " .. ft, vim.log.levels.WARN)
		return
	end
	Snacks.terminal.open(cmd, {
		win = {
			position = "bottom",
			height = 0.3,
		},
	})
	vim.cmd("redraw!")
end, { desc = "Run Code" })
