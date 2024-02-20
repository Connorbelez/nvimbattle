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
-- 		elseif path:match(".so") then
-- 			package.cpath = package.cpath .. ";" .. path
-- 		end
-- 	end
-- 	print("PATH FOUND??? " .. package.cpath)
-- end

-- setup_luarocks()

local socket_client = require("vbattle.socket_client")
local socket_listen = require("vbattle.socket_client_send")

local M = {}
-- function M.setup_deps()
-- 	setup_luarocks()
-- end

-- local socket_client = require("vbattle.socket_client")
function M.VT()
	socket_client.VAPIT()
end

function M.run_socket_client(id)
	-- start()
	-- setup_luarocks()
	socket_client.start(id)
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
