local protocol = require("vim.lsp.protocol")
local validate, schedule, schedule_wrap = vim.validate, vim.schedule, vim.schedule_wrap

local uv = vim.loop
local Client = {}
local is_win = uv.os_uname().version:find("Windows")
self.transport.write(format_message_with_content_length(encoded))
---@private
--- Embeds the given string into a table and correctly computes `Content-Length`.
---
---@param encoded_message (string)
---@returns (table) table containing encoded message and `Content-Length` attribute
--#region
--#region
--#region

-- ================================= PACK RPC ==================================================
--
function Client:encode_and_send(payload)
    -- local _ = log.debug() and log.debug('rpc.send', payload)
    if self.transport.is_closing() then
        return false
    end
    local encoded = vim.json.encode(payload)
    self.transport.write(format_message_with_content_length(encoded))
    return true
end

local function format_message_with_content_length(encoded_message)
    return table.concat({
        "Content-Length: ",
        tostring(#encoded_message),
        "\r\n\r\n",
        encoded_message,
    })
end

-- SAMPLE USAGE
-- function Client:notify(method, params)
--   return self:encode_and_send({
--     jsonrpc = '2.0',
--     method = method,
--     params = params,
--   })
-- end

-- local encoded = vim.json.encode(payload)

-- =================================== connect() - TCP CLIENT FACTORY =============================================

--- Create a LSP RPC client factory that connects via TCP to the given host
--- and port
---
---@param host string
---@param port integer
---@return function
local function connect(host, port)
    return function(dispatchers)
        dispatchers = merge_dispatchers(dispatchers)
        local tcp = uv.new_tcp()
        local closing = false
        local transport = {
            write = function(msg)
                tcp:write(msg)
            end,
            is_closing = function()
                return closing
            end,
            terminate = function()
                if not closing then
                    closing = true
                    tcp:shutdown()
                    tcp:close()
                    dispatchers.on_exit(0, 0)
                end
            end,
        }
        local client = new_client(dispatchers, transport)
        tcp:connect(host, port, function(err)
            if err then
                vim.schedule(function()
                    vim.notify(
                        string.format("Could not connect to %s:%s, reason: %s", host, port, vim.inspect(err)),
                        vim.log.levels.WARN
                    )
                end)
                return
            end
            local handle_body = function(body)
                client:handle_body(body)
            end
            tcp:read_start(create_read_loop(handle_body, transport.terminate, function(read_err)
                client:on_error(client_errors.READ_ERROR, read_err)
            end))
        end)

        return public_client(client)
    end
end

-- ====================================== NEW_CLIENT() ================================================
---@private
---@return RpcClient
local function new_client(dispatchers, transport)
    local state = {
        message_index = 0,
        message_callbacks = {},
        notify_reply_callbacks = {},
        transport = transport,
        dispatchers = dispatchers,
    }
    return setmetatable(state, { __index = Client })
end

-- ====================================== SERVER EXAMPLE ================================================

local server = uv.new_tcp()
server:bind("127.0.0.1", 1337)
server:listen(128, function(err)
    assert(not err, err)
    local client = uv.new_tcp()
    server:accept(client)
    client:read_start(function(err, chunk)
        assert(not err, err)
        if chunk then
            client:write(chunk)
        else
            client:shutdown()
            client:close()
        end
    end)
end)
print("TCP server listening at 127.0.0.1 port 1337")
uv.run() -- an explicit run call is necessary outside of luvit

local conn = uv.new_tcp()

-- ========================================== HANDLE_BODY() CLIENT BUILDER ============================

function Client:handle_body(body)
    local ok, decoded = pcall(vim.json.decode, body, { luanil = { object = true } })
    if not ok then
        self:on_error(client_errors.INVALID_SERVER_JSON, decoded)
        return
    end
    local _ = log.debug() and log.debug("rpc.receive", decoded)

    if type(decoded.method) == "string" and decoded.id then
        local err
        -- Schedule here so that the users functions don't trigger an error and
        -- we can still use the result.
        schedule(function()
            coroutine.wrap(function()
                local status, result
                status, result, err = self:try_call(
                    client_errors.SERVER_REQUEST_HANDLER_ERROR,
                    self.dispatchers.server_request,
                    decoded.method,
                    decoded.params
                )
                local _ = log.debug()
                    and log.debug("server_request: callback result", { status = status, result = result, err = err })
                if status then
                    if result == nil and err == nil then
                        error(
                            string.format(
                                "method %q: either a result or an error must be sent to the server in response",
                                decoded.method
                            )
                        )
                    end
                    if err then
                        assert(
                            type(err) == "table",
                            "err must be a table. Use rpc_response_error to help format errors."
                        )
                        local code_name = assert(
                            protocol.ErrorCodes[err.code],
                            "Errors must use protocol.ErrorCodes. Use rpc_response_error to help format errors."
                        )
                        err.message = err.message or code_name
                    end
                else
                    -- On an exception, result will contain the error message.
                    err = rpc_response_error(protocol.ErrorCodes.InternalError, result)
                    result = nil
                end
                self:send_response(decoded.id, err, result)
            end)()
        end)
        -- This works because we are expecting vim.NIL here
    elseif decoded.id and (decoded.result ~= vim.NIL or decoded.error ~= vim.NIL) then
        -- We sent a number, so we expect a number.
        local result_id = assert(tonumber(decoded.id), "response id must be a number")

        -- Notify the user that a response was received for the request
        local notify_reply_callbacks = self.notify_reply_callbacks
        local notify_reply_callback = notify_reply_callbacks and notify_reply_callbacks[result_id]
        if notify_reply_callback then
            validate({
                notify_reply_callback = { notify_reply_callback, "f" },
            })
            notify_reply_callback(result_id)
            notify_reply_callbacks[result_id] = nil
        end

        local message_callbacks = self.message_callbacks

        -- Do not surface RequestCancelled to users, it is RPC-internal.
        if decoded.error then
            local mute_error = false
            if decoded.error.code == protocol.ErrorCodes.RequestCancelled then
                local _ = log.debug() and log.debug("Received cancellation ack", decoded)
                mute_error = true
            end

            if mute_error then
                -- Clear any callback since this is cancelled now.
                -- This is safe to do assuming that these conditions hold:
                -- - The server will not send a result callback after this cancellation.
                -- - If the server sent this cancellation ACK after sending the result, the user of this RPC
                -- client will ignore the result themselves.
                if result_id and message_callbacks then
                    message_callbacks[result_id] = nil
                end
                return
            end
        end

        local callback = message_callbacks and message_callbacks[result_id]
        if callback then
            message_callbacks[result_id] = nil
            validate({
                callback = { callback, "f" },
            })
            if decoded.error then
                decoded.error = setmetatable(decoded.error, {
                    __tostring = format_rpc_error,
                })
            end
            self:try_call(client_errors.SERVER_RESULT_CALLBACK_ERROR, callback, decoded.error, decoded.result)
        else
            self:on_error(client_errors.NO_RESULT_CALLBACK_FOUND, decoded)
            local _ = log.error() and log.error("No callback found for server response id " .. result_id)
        end
    elseif type(decoded.method) == "string" then
        -- Notification
        self:try_call(
            client_errors.NOTIFICATION_HANDLER_ERROR,
            self.dispatchers.notification,
            decoded.method,
            decoded.params
        )
    else
        -- Invalid server message
        self:on_error(client_errors.INVALID_SERVER_MESSAGE, decoded)
    end
end

-- ============================================= TCP SOCKET PAIR ==========================================
-- Simple read/write with tcp

-- local uv = vim.loop
-- local fds = uv.socketpair(nil, nil, {nonblock=true}, {nonblock=true})
--
-- local sock1 = uv.new_tcp()
-- sock1:open(fds[1])
--
-- local sock2 = uv.new_tcp()
-- sock2:open(fds[2])
--
-- sock1:write("hello")
-- sock2:read_start(function(err, chunk)
--   assert(not err, err)
--   print(chunk)
-- end)
local client = uv.new_tcp()
client:connect("127.0.0.1", 8080, function(err)
    -- check error and carry on.
end)











-- ======================================= PARSE BUFFER ================================================
--
---@private
--- Parses an LSP Message's header
---
---@param header string: The header to parse.
---@return table parsed headers
local function parse_headers(header)
  assert(type(header) == 'string', 'header must be a string')
  local headers = {}
  for line in vim.gsplit(header, '\r\n', true) do
    if line == '' then
      break
    end
    local key, value = line:match('^%s*(%S+)%s*:%s*(.+)%s*$')
    if key then
      key = key:lower():gsub('%-', '_')
      headers[key] = value
    else
      local _ = log.error() and log.error('invalid header line %q', line)
      error(string.format('invalid header line %q', line))
    end
  end
  headers.content_length = tonumber(headers.content_length)
    or error(string.format('Content-Length not found in headers. %q', header))
  return headers
end

-- This is the start of any possible header patterns. The gsub converts it to a
-- case insensitive pattern.
local header_start_pattern = ('content'):gsub('%w', function(c)
  return '[' .. c .. c:upper() .. ']'
end)

---@private
--- The actual workhorse.
local function request_parser_loop()
  local buffer = '' -- only for header part
  while true do
    -- A message can only be complete if it has a double CRLF and also the full
    -- payload, so first let's check for the CRLFs
    local start, finish = buffer:find('\r\n\r\n', 1, true)
    -- Start parsing the headers
    if start then
      -- This is a workaround for servers sending initial garbage before
      -- sending headers, such as if a bash script sends stdout. It assumes
      -- that we know all of the headers ahead of time. At this moment, the
      -- only valid headers start with "Content-*", so that's the thing we will
      -- be searching for.
      -- TODO(ashkan) I'd like to remove this, but it seems permanent :(
      local buffer_start = buffer:find(header_start_pattern)
      local headers = parse_headers(buffer:sub(buffer_start, start - 1))
      local content_length = headers.content_length
      -- Use table instead of just string to buffer the message. It prevents
      -- a ton of strings allocating.
      -- ref. http://www.lua.org/pil/11.6.html
      local body_chunks = { buffer:sub(finish + 1) }
      local body_length = #body_chunks[1]
      -- Keep waiting for data until we have enough.
      while body_length < content_length do
        local chunk = coroutine.yield()
          or error('Expected more data for the body. The server may have died.') -- TODO hmm.
        table.insert(body_chunks, chunk)
        body_length = body_length + #chunk
      end
      local last_chunk = body_chunks[#body_chunks]

      body_chunks[#body_chunks] = last_chunk:sub(1, content_length - body_length - 1)
      local rest = ''
      if body_length > content_length then
        rest = last_chunk:sub(content_length - body_length)
      end
      local body = table.concat(body_chunks)
      -- Yield our data.
      buffer = rest
        .. (
          coroutine.yield(headers, body)
          or error('Expected more data for the body. The server may have died.')
        ) -- TODO hmm.
    else
      -- Get more data since we don't have enough.
      buffer = buffer
        .. (
          coroutine.yield() or error('Expected more data for the header. The server may have died.')
        ) -- TODO hmm.
    end
  end
end


---@private
local function create_read_loop(handle_body, on_no_chunk, on_error)
  local parse_chunk = coroutine.wrap(request_parser_loop)
  parse_chunk()
  return function(err, chunk)
    if err then
      on_error(err)
      return
    end

    if not chunk then
      if on_no_chunk then
        on_no_chunk()
      end
      return
    end

    while true do
      local headers, body = parse_chunk(chunk)
      if headers then
        handle_body(body)
        chunk = ''
      else
        break
      end
    end
  end
end




