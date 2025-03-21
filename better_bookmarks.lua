-- "better_bookmarks.lua" 
-- VLC Extension basic structure (template): ----------------
-- https://code.videolan.org/videolan/vlc/-/tree/master/share/lua

function descriptor()
	return {
		title = "Better Bookmarks",
		version = "2.5.3.21",
		author = "Valentin Cotta",
		url = 'https://github.com/vc0tta/better-bookmarks-vlc-extension',
		shortdesc = "Better Bookmarks",
		description = "A VLC Lua extension for creating, managing, and navigating video time bookmarks, saved as `.bmk` files alongside video files."
	}
end

function activate()
	-- this is where extension starts
	-- for example activation of extension opens custom dialog box:
	create_dialog()
end
function deactivate()
	-- what should be done on deactivation of extension
end
function close()
	-- function triggered on dialog box close event
	-- for example to deactivate extension on dialog box close:
	vlc.deactivate()
end

-- GPT-4o prompt : lua microseconds to hh:mm:ss.mmm and reverse
function microsecondsToHMS(microseconds)
	-- Convert microseconds to seconds
	local total_seconds = tonumber(microseconds) / 1e6

	-- Calculate hours, minutes, seconds, and milliseconds
	local hours = math.floor(total_seconds / 3600)
	total_seconds = total_seconds % 3600
	local minutes = math.floor(total_seconds / 60)
	total_seconds = total_seconds % 60
	local seconds = math.floor(total_seconds)
	local milliseconds = math.floor((total_seconds - seconds) * 100)

	-- Format the output as hh:mm:ss.mm
	return string.format("%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
end
function hmsToMicroseconds(timeString)
	-- Use pattern matching to extract hours, minutes, seconds, and milliseconds
	local hours, minutes, seconds, milliseconds = timeString:match("(%d+):(%d+):(%d+).(%d+)")
	
	-- Convert extracted values to numbers
	hours = tonumber(hours) or 0
	minutes = tonumber(minutes) or 0
	seconds = tonumber(seconds) or 0
	milliseconds = tonumber(milliseconds) or 0

	-- Calculate total microseconds
	local total_microseconds = (hours * 3600 + minutes * 60 + seconds) * 1e6 + milliseconds * 10

	return total_microseconds
end
-- AI laziness end

local lines_table = {}

function loadList()
	-- clear list control
	w2:clear()
	-- get associated .bmk (bookmarks) file
	local filePath = vlc.strings.make_path(vlc.input.item():uri()) .. ".bmk"	
	-- reset lines table
	lines_table = {}
	-- add lines to table
	for line in io.lines(filePath) do
		table.insert(lines_table, tonumber(line))
	end
	-- sort asc chronologically
	table.sort(lines_table)
	-- add to list control
	for i, l in ipairs(lines_table) do
		w2:add_value(microsecondsToHMS(l), i)
	end
end

function create_dialog()
	w = vlc.dialog("Better Bookmarks")
	-- w1 = w:add_text_input("Hello world!", 1, 1, 3, 1)
	w2 = w:add_list(1, 2, 3, 1)
	w3 = w:add_button("Jump to time",click_Load, 1, 3, 1, 1)
	w4 = w:add_button("Add bookmark",click_Add, 2, 3, 1, 1)
	w5 = w:add_button("Remove bookmark",click_Del, 3, 3, 1, 1)
	
	loadList()
end

function click_Add()	
	-- get associated .bmk (bookmarks) file
	local filePath = vlc.strings.make_path(vlc.input.item():uri()) .. ".bmk"
	local file, err = io.open(filePath, "a")
		-- append current position to .bmk file
		local current_pos = vlc.var.get(vlc.object.input(), "time")
		file:write(current_pos .. "\n")
	file:close()
	
	loadList()
end

function click_Load()
	-- get selected time in list
	local selection = w2:get_selection()
	for id,value in pairs(selection) do
		-- vlc go to time command
		vlc.var.set(vlc.object.input(), "time", lines_table[id])
		-- resume play
		-- vlc.playlist.play()
		break
	end
	-- w:hide()
end

function click_Del()
	-- get selected index
	local selection = w2:get_selection()
	for id,value in pairs(selection) do
		-- remove from table 
		table.remove(lines_table,id)
		break
	end
	
	-- get associated .bmk (bookmarks) file
	local filePath = vlc.strings.make_path(vlc.input.item():uri()) .. ".bmk"
	-- delete file
	os.remove(filePath)
	local file, err = io.open(filePath, "a")
		-- write table
		for i, l in ipairs(lines_table) do
			file:write(l .. "\n")
		end
	file:close()
	
	-- refresh list
	loadList()
end


