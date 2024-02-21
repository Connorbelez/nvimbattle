-- local function setup_luarocks()
-- 	print("TRYING TO FIND PATH")
-- 	local luarocks_path_cmd = "luarocks path --lua-version=5.1"
-- 	local handle = io.popen(luarocks_path_cmd)
-- 	local result = handle:read("*a")
-- 	handle:close()
--
-- 	for path in result:gmatch("([^;]+)") do
-- 		if path:match(".lua") then
-- 			package.path = package.path .. ";" .. path
-- 	    	elseif path:match(".so") then
-- 			package.cpath = package.cpath .. ";" .. path
-- 		end
-- 	end
-- 	print("PATH FOUND??? " .. package.cpath)
-- end

-- setup_luarocks()
-- local luv = require(local luv = require(''))
local uv = vim.loop
local socket_client = require("vbattle.socket_client")
local socket_listen = require("vbattle.socket_client_send")

local M = {}
M.GameRunning = false
-- function M.setup_deps()
-- 	setup_luarocks()
-- end

-- local socket_client = require("vbattle.socket_client")
function M.VT()
	socket_client.VAPIT()
end

M.WriteBuf = nil

M.vtcp = nil

-- local function encode_and_send(payload, transport)
-- 	-- local _ = log.debug() and log.debug('rpc.send', payload)
-- 	-- if self.transport.is_closing() then
-- 	-- 	return false
-- 	-- end
-- 	local encoded = vim.json.encode(payload)
-- 	transport:write(format_message_with_content_length(encoded))
-- 	return true
-- end

local function format_message_with_content_length(encoded_message)
	return table.concat({
		"Content-Length: ",
		tostring(#encoded_message),
		"\r\n\r\n",
		encoded_message,
	})
end

function M.VSOCK()
	local host = "192.168.3.2"
	local port = 80

	M.vtcp = uv.new_tcp()
	M.vtcp:connect(host, port, function(err)
		-- check error and carry on.
	end)

	-- uv.tcp_keepalive(tcp, true, nil)

	-- while true do
	-- M.vtcp:write("TEST")
	local payload = "VALUE TEST"
	local p2 = { ["Foo"] = "value" }
	local data = {
		["Type"] = "request",
		["Action"] = "update",
		-- ["Payload"] = "TEST PAYLOAD",
		Payload = {
			["Seq"] = 1,
			["Lines"] = { ["1"] = "THIS IS  A TEST LINE", ["2"] = "TestLine2" },
			["CursorCol"] = 10,
			["CursorRow"] = 5,
		},
	}
	-- encode_and_send({obj1:"TEST"},M.vtcp)
	-- local packer = vim.mpack.encode(format_message_with_content_length(data))
	local packer = vim.mpack.encode(data)
	print("ENDCODED: ", packer)
	-- local encoded = packer(payload)

	-- M.vtcp:write(format_message_with_content_length(packer))
	M.vtcp:write(packer)
	-- vim.ui.input({ prompt = "enter msg: " }, function(input)
	-- 	M.vtcp.write(input)
	-- end)
	-- end
end

function M.VREAD()
	local chunks = {}

	M.vtcp:read_start(function(err, chunk)
		assert(not err, err)
		print(chunk)
		table.insert(chunks)
	end)
	print("DONE READING")
end

function M.run_socket_client(id)
	-- start()
	-- setup_luarocks()
	-- M.fds = uv.socketpair(nil, nil, { nonblock = true }, { nonblock = true })

	socket_client.start(id)
	socket_listen.startListen(id)
	socket_client.VAPIT()
end

function M.listen(id)
	-- start()
	-- setup_luarocks()
	socket_listen.startListen(id)
end

function M.send()
	-- setup_luarocks()
	socket_client.send("MESSAGE@@@\n")
end

-- socket_client.start()

-- Add this in your init.lua or equivalent
-- vim.api.nvim_create_user_command("SendSocketMessage", function(params)
-- 	socket_client.send(params.args)
-- end, { nargs = 1 })
--
-- vim.api.nvim_create_user_command("SocketStart", socket_client.connect()({ nargs = 0 }))

return M
