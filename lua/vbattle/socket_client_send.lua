-- local vim = vim
-- local uv = vim.loop -- Access Neovim's event loop
-- local host = "192.168.3.2"
-- local port = 80
-- local M = {}
-- local logBuffer = nil
-- local logBufferName = "LogBuffer"
--
-- local function writeToLogBuffer2(msg)
-- 	-- Use vim.schedule to defer execution to a safe time
-- 	vim.schedule(function()
-- 		if not logBuffer or not vim.api.nvim_buf_is_valid(logBuffer) then
-- 			-- Create a new buffer for logging if it doesn't exist
-- 			logBuffer = vim.api.nvim_create_buf(false, true) -- No file backing, listed
-- 			vim.api.nvim_buf_set_name(logBuffer, logBufferName)
--
-- 			-- Open a new window for the log buffer or use an existing one
-- 			local winId = vim.fn.bufwinid(logBuffer)
-- 			if winId == -1 then -- Buffer is not displayed in any window
-- 				vim.api.nvim_command("vsplit")
-- 				vim.api.nvim_win_set_buf(0, logBuffer)
-- 			end
-- 		end
--
-- 		-- Append the message to the buffer
-- 		-- vim.api.nvim_buf_set_lines(logBuffer, -1, -1, false, { msg })
-- 		--     local bufnr = vim.api.nvim_get_current_buf() -- Get the current buffer number
-- 		-- local replacementText = "This is the new line 1.\nThis is the new line 2."
-- 		-- local lines = vim.split(msg, "\n") -- Split the replacement text into lines
-- 		--        	local data = {
-- 		-- 	["Type"] = "request",
-- 		-- 	["Action"] = action,
-- 		-- 	-- ["Payload"] = "TEST PAYLOAD",
-- 		-- 	Payload = {
-- 		-- 		["Seq"] = seq,
-- 		-- 		["Lines"] = lineTable,
-- 		-- 		["CursorCol"] = col,
-- 		-- 		["CursorRow"] = row,
-- 		-- 	},
-- 		-- }
-- 		--
-- 		local decoded
-- 		if tostring(msg) == "WAIT\n" or tostring(msg) == "READY\n" then
-- 			vim.api.nvim_buf_set_lines(logBuffer, 0, -1, false, { "WAIT" })
-- 			-- return
-- 		end
--
-- 		if not tostring(msg) then
-- 			vim.api.nvim_buf_set_lines(logBuffer, 0, -1, false, { "NOMSG" })
-- 			decoded = { "NOMSG" }
-- 			-- return
-- 		else
-- 			msg = vim.split(msg, "\n")
-- 			local st = tostring(msg)
-- 			-- decoded = vim.mpack:decode(st)
-- 			vim.api.nvim_buf_set_lines(logBuffer, 0, -1, false, msg)
-- 			-- return
-- 		end
-- 		-- Set lines in the buffer
-- 		-- if lines[1] and (string.match(tostring(lines[1]), "^c:(%d+):(%d+)$")) then
-- 		-- 	local row, col = string.match(tostring(lines[1]), "(%d+):(%d+)")
-- 		-- 	row = tonumber(row)
-- 		-- 	col = tonumber(col)
--
-- 		-- if row > 0 then
-- 		-- 	row = row - 1
-- 		-- end
-- 		-- if col > 0 then
-- 		-- 	col = col - 1
-- 		-- end
-- 		if false then
-- 			isCursor = decoded["Action"] == "CR"
-- 			local lines = decoded["Lines"]
-- 			local row = docoded["CursorRow"]
-- 			local col = decoded["CursorCol"]
-- 			if isCursor then
-- 				if M.mid then
-- 					vim.api.nvim_buf_del_extmark(0, M.mark_ns, M.mid)
-- 				end
-- 				if M.mark_ns then
-- 					M.mid = vim.api.nvim_buf_set_extmark(logBuffer, M.mark_ns, row, col, {
-- 						virt_text = { { ">" } },
--
-- 						-- hl_mode = "combine",
-- 						virt_text_pos = "overlay",
-- 						-- ephemeral = true,
-- 					})
-- 				end
-- 			else
-- 				vim.api.nvim_buf_set_lines(logBuffer, 0, -1, false, lines)
-- 			end
-- 		end
-- 	end)
-- end
--
-- local function createBuffer()
-- 	if not logBuffer or not vim.api.nvim_buf_is_valid(logBuffer) then
-- 		-- Create a new buffer for logging if it doesn't exist
-- 		logBuffer = vim.api.nvim_create_buf(false, true) -- No file backing, listed
-- 		vim.api.nvim_buf_set_name(logBuffer, logBufferName)
-- 		vim.api.nvim_command("split")
-- 		vim.api.nvim_win_set_buf(0, logBuffer)
-- 	end
-- end
--
-- M.tcp_handle = nil -- Store the handle of the TCP connection
--
-- function M.startListen(id, tcpl)
-- 	if M.tcp_handle then
-- 		print("Connection already exists.")
-- 		return
-- 	-- Create a new TCP handle
-- 	-- M.mark_ns = vim.api.nvim_create_namespace(id)
-- 	-- local mid = vim.api.nvim_buf_set_extmark(logBuffer, M.mark_ns, 1, 1, {
-- 	-- 	virt_text = { { ">" } },
-- 	--
-- 	-- 	hl_mode = "combine",
-- 		if connect_err then
-- 			-- Handle connection error
-- 			print("Error connecting:", connect_err)
-- 			return
-- 		end
--
-- 		print("Connected to the server.")
--
-- 		-- Send an initial message after connecting
-- 		local initial_message = "R:" .. id
-- 		tcpl:write(M.tcp_handle, initial_message)
--
-- 		-- Read loop
-- 		tcpl:read_start(M.tcp_handle, function(read_err, chunk)
-- 			print("READLOOP")
-- 			if read_err then
-- 				-- Handle read error
-- 				print("Read error:", read_err)
-- 				return
-- 			end
--
-- 			if chunk then
-- 				-- Handle received chunk
-- 				print("Received:", chunk)
--
-- 				writeToLogBuffer2(chunk)
-- 			else
-- 				-- This happens when the connection is closed
-- 				print("Connection closed.")
-- 				tcpl:read_stop(M.tcp_handle)
-- 				tcpl:close(M.tcp_handle)
-- 				M.tcp_handle = nil
-- 			end
-- 		end)
-- 	end)
-- 	-- uv.tcp_keepalive(tcp, true)
-- 	-- local connected, connectionError = tcp:connect(host, port)
-- 	-- if not connected then
-- 	-- 	print("Error connecting to server:", connectionError)
-- 	-- 	return nil, connectionError
-- 	-- end
-- 	-- local send = "R:" .. id
-- 	-- tcpl:write(send)
-- 	-- -- local response, err = tcp:receive()
-- 	-- local datachunks = ""
-- 	-- tcpl:read_start(function(err, chunk)
-- 	-- 	assert(not err, err) -- Check for errors.
-- 	-- 	if chunk then
-- 	-- 		writeToLogBuffer2(chunk)
-- 	-- 		datachunks = datachunks .. tostring(chunk)
-- 	-- 	end
-- 	-- end)
--
-- 	-- Connect to the server
-- 	-- uv.tcp_connect(M.tcp_handle, "192.168.3.2", 80, function(connect_err)
-- 	-- 	if connect_err then
-- 	-- 		-- Handle connection error
-- 	-- 		print("Error connecting:", connect_err)
-- 	-- 		return
-- 	-- 	end
-- 	--
-- 	-- 	print("Connected to the server.")
-- 	--
-- 	-- 	-- Send an initial message after connecting
-- 	-- 	local initial_message = "R:" .. id
-- 	-- 	uv.write(M.tcp_handle, initial_message)
-- 	--
-- 	-- 	-- Read loop
-- 	-- 	uv.read_start(M.tcp_handle, function(read_err, chunk)
-- 	-- 		print("READLOOP")
-- 	-- 		if read_err then
-- 	-- 			-- Handle read error
-- 	-- 			print("Read error:", read_err)
-- 	-- 			return
-- 	-- 		end
-- 	--
-- 	-- 		if chunk then
-- 	-- 			-- Handle received chunk
-- 	-- 			print("Received:", chunk)
-- 	--
-- 	-- 			writeToLogBuffer2(chunk)
-- 	-- 		else
-- 	-- 			-- This happens when the connection is closed
-- 	-- 			print("Connection closed.")
-- 	-- 			uv.read_stop(M.tcp_handle)
-- 	-- 			uv.close(M.tcp_handle)
-- 	-- 			M.tcp_handle = nil
-- 	-- 		end
-- 	-- 	end)
-- 	-- end)
-- end
--
-- return M
local vim = vim
local uv = vim.loop -- Access Neovim's event loop

local M = {}
local logBuffer = nil
local logBufferName = "LogBuffer"

local function writeToLogBuffer2(msg)
	-- Use vim.schedule to defer execution to a safe time
	vim.schedule(function()
		-- if not logBuffer or not vim.api.nvim_buf_is_valid(logBuffer) then
		-- 	-- Create a new buffer for logging if it doesn't exist
		-- 	logBuffer = vim.api.nvim_create_buf(false, true) -- No file backing, listed
		-- 	vim.api.nvim_buf_set_name(logBuffer, logBufferName)
		--
		-- 	-- Open a new window for the log buffer or use an existing one\
		-- 	vim.api.nvim_open_win(0, false, {
		-- 		split = "down",
		-- 		win = 1,
		-- 	})
		-- 	local winId = vim.fn.bufwinid(logBuffer)
		-- 	if winId == -1 then -- Buffer is not displayed in any window
		-- 		-- vim.api.nvim_command("vsplit")
		-- 		vim.api.nvim_win_set_buf(1, logBuffer)
		-- 	end
		-- end

		-- Append the message to the buffer
		-- vim.api.nvim_buf_set_lines(logBuffer, -1, -1, false, { msg })
		--     local bufnr = vim.api.nvim_get_current_buf() -- Get the current buffer number
		-- local replacementText = "This is the new line 1.\nThis is the new line 2."
		-- local lines = vim.split(msg, "\n") -- Split the replacement text into lines
		local action = ""
		local lines = "no\ndata"
		local payload = ""
		-- if msg then
		-- local data = {
		-- 	["Type"] = "request",
		-- 	["Action"] = "request",
		-- 	-- ["Payload"] = "TEST PAYLOAD",
		-- 	Payload = {
		-- 		["Seq"] = 1,
		-- 		["Lines"] = { ["1"] = "asdfadsf" },
		-- 		["CursorCol"] = 1,
		-- 		["CursorRow"] = 1,
		-- 	},
		-- }
		-- local encodedd = vim.mpack.encode(data)
		--
		-- function protDecode(msg)
		--     return vim.mpack.decode(msg)
		-- end
		--
		pcall(function()
			payload = vim.mpack.decode(msg)
			-- print(decode["Type"])
			-- payload = decode["Payload"]
			lines = payload["Lines"]
			-- lineNums = payload["LineNums"]
			action = payload["Action"]
			print(action)

			local row = payload["CRow"]
			local col = payload["CCol"]
			row = tonumber(row)
			col = tonumber(col)
			if row > 0 then
				row = row - 1
			end
			if col > 0 then
				col = col - 1
			end

			if M.mark_ns then
				if M.mid then
					vim.api.nvim_buf_del_extmark(logBuffer, M.mark_ns, M.mid)
				end

				M.mid = vim.api.nvim_buf_set_extmark(logBuffer, M.mark_ns, row, col, {
					virt_text = { { ">" } },
					virt_text_pos = "overlay",
				})
			end
			-- else
			if action ~= "CO" and action ~= "CR" and action ~= "CR\n" then
				lines = vim.split(lines, "\n")
				-- for i, v in ipairs(lines) do
				vim.api.nvim_buf_set_lines(logBuffer, 0, -1, false, lines)
				-- end
			end

			-- print(decode)
		end)
	end)
end

local function createBuffer()
	if not logBuffer or not vim.api.nvim_buf_is_valid(logBuffer) then
		logBuffer = vim.api.nvim_create_buf(false, true) -- No file backing, listed
		vim.api.nvim_buf_set_name(logBuffer, logBufferName)

		-- 			local winId = vim.fn.bufwinid(logBuffer)
		-- Open a new window for the log buffer or use an existing one\
		-- local winId = vim.api.nvim_open_win(logbuffer, false, {
		-- 	split = "above",
		-- 	-- external = "win",
		-- 	win = 0,
		-- })

		local winId = vim.fn.bufwinid(logBuffer)
		if winId == -1 then -- Buffer is not displayed in any window
			-- vim.api.nvim_cmd(vim.api.nvim_parse_cmd("vsplit"))
			vim.api.nvim_command("split")
			vim.api.nvim_win_set_buf(0, logBuffer)
		end
	end
end

M.tcp_handle = nil -- Store the handle of the TCP connection

function M.startListen(id)
	if M.tcp_handle then
		print("Connection already exists.")
		return
	end
	local nsid = "id" .. id
	createBuffer()
	M.mark_ns = vim.api.nvim_create_namespace(tostring(nsid))
	-- Create a new TCP handle
	-- M.mark_ns = vim.api.nvim_create_namespace(id)
	-- local mid = vim.api.nvim_buf_set_extmark(logBuffer, M.mark_ns, 1, 1, {
	-- 	virt_text = { { ">" } },
	--
	-- 	hl_mode = "combine",
	-- 	virt_text_pos = "inline",
	-- 	-- ephemeral = true,
	-- })
	-- vim.api.nvim_buf_del_extmark(0, M.mark_ns, mid)
	M.tcp_handle = uv.new_tcp()

	-- Connect to the server
	uv.tcp_connect(M.tcp_handle, "192.168.3.2", 80, function(connect_err)
		if connect_err then
			-- Handle connection error
			print("Error connecting:", connect_err)
			return
		end

		print("Connected to the server.")

		-- Send an initial message after connecting
		local initial_message = "R:" .. id
		uv.write(M.tcp_handle, initial_message)

		-- Read loop
		uv.read_start(M.tcp_handle, function(read_err, chunk)
			-- print("READLOOP")
			if read_err then
				-- Handle read error
				print("Read error:", read_err)
				return
			end

			if chunk then
				-- Handle received chunk
				-- print("Received:", chunk)
				if not (chunk == "READY\n" or chunk == "READY" or chunk == "WAIT") then
					writeToLogBuffer2(chunk)
					-- local decoded = vim.mpack:decode("TEST")
					-- print(decoded)
				end
			else
				-- This happens when the connection is closed
				print("Connection closed.")
				uv.read_stop(M.tcp_handle)
				uv.close(M.tcp_handle)
				M.tcp_handle = nil
			end
		end)
	end)
end

return M
