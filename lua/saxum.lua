-- Nvim plugin for saxum: record the time spent on each file
-- Author: Harry Han 
-- License: GPL-3.0

-- This plugin work together with saxum. 
-- When you type, scroll, or change cursor position, the plugin will record the time of each event in seconds since epoch. It also records the file path.

local HOME = os.getenv("HOME")
local lock = false  -- for mutex lock
local initiatilized = false -- when set false, a new log file will be created onto which log is written

local saxum = {}
saxum.logFileName = "saxum.log"
saxum.dataDir = HOME .. "/.cache/saxum"

local function Error(msg)
	vim.api.nvim_err_writeln("saxum error: " .. msg)
end

local function getUnusedFileName()
	local filename = os.time() .. "-" .. math.random(1000, 9999)

	-- if file exists, try again
	while vim.fn.filereadable(saxum.dataDir .. "/" .. filename) == 1 do
		filename = filename .. math.random(0, 9)
	end
	return filename
end

local function appendLnToFile(filepath, line)
	local file, err = io.open(filepath, 'a+')
	if file then
		file:write(line .. "\n")
		file:close()
	else
		Error(err)
	end
end

local function init()
	-- create data directory
	if not vim.fn.isdirectory(saxum.dataDir) then
		vim.fn.mkdir(saxum.dataDir, "p")
	end

	saxum.logFileName = getUnusedFileName()
	local logFilePath = saxum.dataDir .. "/" .. saxum.logFileName
	appendLnToFile(logFilePath, vim.fn.expand("%:p"))
end

local function recordDone()
	if not initiatilized then
		return
	end
	local logFilePath = saxum.dataDir .. "/" .. saxum.logFileName
	appendLnToFile(logFilePath, "DONE")
end

vim.api.nvim_create_autocmd( { "BufWinLeave" }, {
	callback = function()
		recordDone()
	end
})

vim.api.nvim_create_autocmd({ "BufEnter" }, {
	callback = function()
		recordDone()
		initiatilized = false
	end
})

vim.api.nvim_create_autocmd({ "CursorMoved", "TextChanged", "TextChangedI" }, {
	callback = function()
		if not initiatilized then
			init()
			initiatilized = true
		end

		if lock then
			return
		end

		lock = true

		local logFilePath = saxum.dataDir .. "/" .. saxum.logFileName
		appendLnToFile(logFilePath, tostring(os.time()))

		lock = false
	end
})
