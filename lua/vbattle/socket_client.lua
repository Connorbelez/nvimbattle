-- Import the LuaSocket library
-- local socket = require("vbattle.deps.luasocket.src.socket")
-- local socketCorePath = "./deps/luasocket/src/socket-3.1.0.so"
-- vim.opt.runtimepath:prepend(socketCorePath)
-- package.cpath = socketCorePath .. "/?.so;" .. package.cpath
local socket = require("vbattle.deps.sock.socket")
-- Server details
local host = "192.168.3.2"
local port = 80 -- Adjusted to match the Go server port
local serverAddress = host .. ":" .. port

local M = {}

-- Persistant TCP socket connection
M.tcp = nil
function M.HandleVimMotion()
	if M.tcp then
		local cVal = vim.api.nvim_win_get_cursor(0)

		local cstring = ""
		for k, v in ipairs(cVal) do
			cstring = cstring .. " " .. k .. ":" .. v
		end
		M.send(cstring)
	end
end

function M.VAPIT()
	-- print(vim.fn.printf("Hello from %s", "Lua"))
	-- local reversed_list = vim.fn.reverse({ "a", "b", "c" })
	-- -- vim.print(reversed_list) -- { "c", "b", "a" }
	-- local function print_stdout(chan_id, data, name)
	-- 	print(data[1])
	-- end
	-- vim.fn.jobstart("ls", { on_stdout = print_stdout })
	-- print(vim.fn.printf("Hello from %s", "Lua"))

	local LastChange = {}
	-- vim.b.
	-- local startOffset = table.getn(self.instructions) + 1
	-- local len = table.getn(self.lastRendered)
	vim.api.nvim_create_autocmd({ "CursorMoved" }, {
		pattern = "*",
		callback = M.HandleVimMotion,
	})
	-- local lines = vim.api.nvim_buf_get_lines(0, 0, 2, false)
	events = {}
	vim.api.nvim_buf_attach(0, false, {
		on_lines = function(...)
			table.insert(events, { ... })
			-- for k,v in pairs(events) do
			--     print("EVENTS")
			local tTable = { ... }
			-- print("EVENTS",tTable,#tTable,tTable[#tTable],tTable[#tTable-1])
			local estring = ""

			local lastline = 1
			if #LastChange > 1 then
				lastline = LastChange[#LastChange]["line"]
			end

			table.insert(events, {
				["line"] = tTable[#tTable - 1],
				["char"] = tTable[#tTable],
			})

			estring = ""
			local lins = vim.api.nvim_buf_get_lines(0, lastline, tTable[#tTable - 1], false)
			for k, v in ipairs(lins) do
				estring = estring .. " " .. k .. ":" .. v
			end

			-- print(lastline, estring)
			local cursorPos = vim.api.nvim_win_get_cursor(0)
			local cursorString = ""
			for k, v in ipairs(cursorPos) do
				cursorString = cursorString .. k .. "," .. v
			end

			local AllLines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
			local outS = ""

			for k, v in ipairs(AllLines) do
				outS = outS .. v .. "\n"
			end
			if M.tcp then
				M.send(outS)
				-- print("Send to server: ", estring)
				-- M.send(cursorString)
				-- print("Sendtoserver c" .. cursorString)
				-- else
				-- print("no connection to server")
			end

			-- for _,v in ipairs(tTable) do
			--   estring = estring .." ".. v
			-- end
			-- print(estring)
			--   for ik,iv in pairs(events[#events]) do
			--     print(ik,iv)
			-- end
			-- local ls = vim.api.nvim_buf_get_lines(
			--
			-- )
		end,
	})
	-- print("LINES: ", lines)
	-- for key, val in pairs(lines) do
	-- 	print(key, val)
	-- end
	-- log.info("Buffer:getGameLines", vim.inspect(lines))
end

function M.start(id)
	-- print("ID: ", id)
	-- If the socket connection is already established, return it
	if M.tcp then
		-- print("TCP EXISTs")
		return M.tcp
	end

	print("STARTING")
	-- Create a TCP socket and connect to the server
	local tcp = assert(socket.tcp())
	local connected, connectionError = tcp:connect(host, port)
	if not connected then
		print("Error connecting to server:", connectionError)
		return nil, connectionError
	end
	local send = "S:" .. id
	tcp:send(send)
	local response, err = tcp:receive()
	print("recieve: ", response, " err: ", err)
	print("Connected to server at " .. serverAddress)

	-- Set the socket as persistant
	M.tcp = tcp
	return tcp
end

-- Add a function to send messages
function M.send(message)
	if not M.tcp then
		print("Socket is not connected.")
		return
	end

	local success, err = M.tcp:send(message .. "\n") -- Ensure message ends with a newline or as required
	-- if not success then
	-- 	print("Failed to send message:", err)
	-- else
	-- 	-- print("Message sent:", message)
	-- end
end

return M
