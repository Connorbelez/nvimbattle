local vim = vim
local uv = vim.loop -- Access Neovim's event loop

local M = {}
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
		if lines[1] and (string.match(tostring(lines[1]), "^c:(%d+):(%d+)$")) then
			local row, col = string.match(tostring(lines[1]), "(%d+):(%d+)")
			row = tonumber(row)
			col = tonumber(col)
			if row > 0 then
				row = row - 1
			end
			if col > 0 then
				col = col - 1
			end
			if M.mid then
				vim.api.nvim_buf_del_extmark(0, M.mark_ns, M.mid)
			end
			if M.mark_ns then
				M.mid = vim.api.nvim_buf_set_extmark(logBuffer, M.mark_ns, row, col, {
					virt_text = { { ">" } },

					-- hl_mode = "combine",
					virt_text_pos = "overlay",
					-- ephemeral = true,
				})
			end
		else
			vim.api.nvim_buf_set_lines(logBuffer, 0, -1, false, lines)
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
