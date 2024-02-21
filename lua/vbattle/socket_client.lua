-- Import the LuaSocket library
-- local socket = require("vbattle.deps.luasocket.src.socket")
-- local socketCorePath = "./deps/luasocket/src/socket-3.1.0.so"
-- vim.opt.runtimepath:prepend(socketCorePath)
-- package.cpath = socketCorePath .. "/?.so;" .. package.cpath
local socket = require("vbattle.deps.sock.socket")
local uv = vim.loop
-- Server details
local host = "192.168.3.2"
local port = 80 -- Adjusted to match the Go server port
local serverAddress = host .. ":" .. port
-- local mpack = require("rpc")
local M = {}
M.seq = 0
-- Persistant TCP socket connection
M.tcp = nil
M.Ready = false
local function encodeRequest(action, seq, lines, col, row)
	local lineTable = {}

	-- for index, value in ipairs(lines) do
	-- 	lineTable[tostring(index)] = value
	-- end
	local lineJoin = table.concat(lines, "\n")
	local data = {
		["Type"] = "request",
		["Action"] = action,
		-- ["Payload"] = "TEST PAYLOAD",
		Payload = {
			["Seq"] = seq,
			["Lines"] = lineJoin,
			["CursorCol"] = col,
			["CursorRow"] = row,
			["LineFrom"] = 0,
			["LineTo"] = -1,
		},
	}
	return vim.mpack.encode(data)
end
function M.HandleVimMotion()
	if M.tcp then
		local cVal = vim.api.nvim_win_get_cursor(0)

		-- local data = {
		-- 	reqType = "request",
		-- 	action = "update",
		--
		-- 	payload = {
		-- 		seq = M.seq,
		-- 		lines = AllLines,
		-- 		cursorCol = cVal.col,
		-- 		cursorRow = cVal.row,
		-- 	},
		-- }
		-- local cstring = "c"
		-- for k, v in ipairs(cVal) do
		-- 	cstring = cstring .. ":" .. v
		-- end
		-- local packedData = vim.mpack.encode(data)
		local tmp = { "Vim\nMotion" }
		local encodedData = encodeRequest("CR", M.seq, tmp, tonumber(cVal[2]), tonumber(cVal[1]))
		M.send(encodedData)
	end
end

M.WriteBuf = nil
M.WriteBufName = "GameWindow"

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
	-- writebuffer = vim.api.nvim_create_buf(false, true) -- no file backing, listed
	--
	-- vim.api.nvim_buf_set_name(writebuffer, writebuffername)
	--
	-- local winid = vim.fn.bufwinid(writebuffer)
	-- if winid == -1 then -- buffer is not displayed in any window
	-- 	-- vim.api.nvim_command("vsplit")
	-- 	vim.api.nvim_win_set_buf(0, writebuffer)
	-- end
	local winId = vim.fn.bufwinid(M.WriteBuf)
	vim.api.nvim_buf_attach(M.WriteBuf, false, {
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
			--
			-- table.insert(events, {
			-- 	["line"] = tTable[#tTable - 1],
			-- 	["char"] = tTable[#tTable],
			-- })
			--
			-- estring = ""
			-- local lins = vim.api.nvim_buf_get_lines(0, lastline, tTable[#tTable - 1], false)
			-- for k, v in ipairs(lins) do
			-- 	estring = estring .. " " .. k .. ":" .. v
			-- end

			-- print(lastline, estring)
			local cursorPos = vim.api.nvim_win_get_cursor(0)
			-- local cursorString = ""
			-- for k, v in ipairs(cursorPos) do
			-- 	cursorString = cursorString .. k .. "," .. v
			-- end

			local AllLines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
			-- local outS = ""

			-- type NvimReq struct {
			--     reqType string
			--     action string
			--     payload = struct {
			--         seq = int
			--         lines = map[int]string
			--         cursorCol = int
			--         cursorRow = int
			--     }
			-- }
			-- local data = {
			-- 	reqType = "request",
			-- 	action = "update",
			--
			-- 	payload = {
			-- 		seq = M.seq,
			-- 		lines = AllLines,
			-- 		cursorCol = cursorPos.col,
			-- 		cursorRow = cursorPos.row,
			-- 	},
			-- }
			local encodedData = encodeRequest("update", M.seq, AllLines, tonumber(cursorPos[2]), tonumber(cursorPos[1]))

			-- for k, v in ipairs(AllLines) do
			-- 	outS = outS .. v .. "\n"
			-- end
			if M.tcp then
				-- M.tcp:write(encodedData)
				print("Send to server: ", encodedData)
				M.send(encodedData)
				print("Sendtoserver c" .. encodedData)
			else
				print("no connection to server")
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
	-- local tcp = assert(socket.tcp())
	local tcp = uv.new_tcp()
	tcp:connect(host, port)
	-- uv.tcp_keepalive(tcp, true)
	-- local connected, connectionError = tcp:connect(host, port)
	-- if not connected then
	-- 	print("Error connecting to server:", connectionError)
	-- 	return nil, connectionError
	-- end
	local send = "S:" .. id
	tcp:write(send)
	tcp:read_start(function(err, chunk)
		if chunk then
			print("CHUNK: ", chunk, "\n")
		end
	end)

	M.WriteBuf = vim.api.nvim_create_buf(false, true) -- No file backing, listed
	vim.api.nvim_buf_set_name(M.WriteBuf, M.WriteBufName)

	local winId = vim.fn.bufwinid(M.WriteBuf)
	if winId == -1 then -- Buffer is not displayed in any window
		-- vim.api.nvim_cmd(vim.api.nvim_parse_cmd("vsplit"))
		-- vim.api.nvim_command("split")
		vim.api.nvim_win_set_buf(0, M.WriteBuf)
	end
	-- Set the socket as persistant
	M.tcp = tcp
	-- M.VAPIT()
	return tcp
end

-- Add a function to send messages
function M.send(message)
	if not M.tcp then
		print("Socket is not connected.")
		return
	end

	local success, err = M.tcp:write(message) -- Ensure message ends with a newline or as required
	if not success then
		print("Failed to send message:", err)
	else
		-- print("Message sent:", message)
	end
end

return M
