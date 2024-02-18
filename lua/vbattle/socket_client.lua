-- Import the LuaSocket library
-- local socket = require("vbattle.deps.luasocket.src.socket")
-- local socketCorePath = "./deps/luasocket/src/socket-3.1.0.so"
-- vim.opt.runtimepath:prepend(socketCorePath)
-- package.cpath = socketCorePath .. "/?.so;" .. package.cpath
local socket = require("socket")
-- Server details
local host = "192.168.3.19"
local port = 80 -- Adjusted to match the Go server port
local serverAddress = host .. ":" .. port

local M = {}

-- Persistant TCP socket connection
M.tcp = nil

function M.start()
	-- If the socket connection is already established, return it
	if M.tcp then
		print("TCP EXISTs")
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
	if not success then
		print("Failed to send message:", err)
	else
		print("Message sent:", message)
	end
end

return M
