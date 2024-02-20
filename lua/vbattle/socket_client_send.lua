local vim = vim
local uv = vim.loop -- Access Neovim's event loop

local logBuffer = nil
local logBufferName = "LogBuffer"

local function writeToLogBuffer2(msg)
	-- Use vim.schedule to defer execution to a safe time
	vim.schedule(function()
		if not logBuffer or not vim.api.nvim_buf_is_valid(logBuffer) then
			-- Create a new buffer for logging if it doesn't exist
			logBuffer = vim.api.nvim_create_buf(false, true) -- No file backing, listed
			vim.api.nvim_buf_set_name(logBuffer, logBufferName)

			-- Open a new window for the log buffer or use an existing one
			local winId = vim.fn.bufwinid(logBuffer)
			if winId == -1 then -- Buffer is not displayed in any window
				vim.api.nvim_command("vsplit")
				vim.api.nvim_win_set_buf(0, logBuffer)
			end
		end

		-- Append the message to the buffer
		-- vim.api.nvim_buf_set_lines(logBuffer, -1, -1, false, { msg })
		--     local bufnr = vim.api.nvim_get_current_buf() -- Get the current buffer number
		-- local replacementText = "This is the new line 1.\nThis is the new line 2."
		local lines = vim.split(msg, "\n") -- Split the replacement text into lines

		-- Set lines in the buffer
		vim.api.nvim_buf_set_lines(logBuffer, 0, -1, false, lines)

		-- Ensure the window with the log buffer scrolls to the bottom
		local winId = vim.fn.bufwinid(logBuffer)
		if winId ~= -1 then
			vim.api.nvim_win_set_cursor(winId, { vim.api.nvim_buf_line_count(logBuffer), 0 })
		end
	end)
end

local function createBuffer()
	if not logBuffer or not vim.api.nvim_buf_is_valid(logBuffer) then
		-- Create a new buffer for logging if it doesn't exist
		logBuffer = vim.api.nvim_create_buf(false, true) -- No file backing, listed
		vim.api.nvim_buf_set_name(logBuffer, logBufferName)
		vim.api.nvim_command("split")
		vim.api.nvim_win_set_buf(0, logBuffer)
	end
end

local M = {}

M.tcp_handle = nil -- Store the handle of the TCP connection

function M.startListen(id)
	if M.tcp_handle then
		print("Connection already exists.")
		return
	end
	createBuffer()
	-- Create a new TCP handle
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
			print("READLOOP")
			if read_err then
				-- Handle read error
				print("Read error:", read_err)
				return
			end

			if chunk then
				-- Handle received chunk
				print("Received:", chunk)

				writeToLogBuffer2(chunk)
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
