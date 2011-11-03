local socket = require("socket")
local io = require("io")

HTTPServer = {
}

function HTTPServer:run(port)
  self.server = socket.bind("127.0.0.1", port)
  self.server:setoption("reuseaddr", true)
  self.server:settimeout(0.01)
  self.clients = {}
  print("Listening on http://127.0.0.1:" .. port .. "/")

  self.BLOB = ''

  for line in io.lines('../../star-wars.txt') do
    self.BLOB = self.BLOB .. line
  end

  self:mainLoop()
end

function HTTPServer:handleConnection(client)
  local line, err = client:receive()

  if not err then
    client:send(line .. "\n")
  end

  client:close()
end

function HTTPServer:mainLoop()
  local socks = {}
  local clients = {}

  function accept()
    local sock = self.server:accept()

    if sock then
      sock:settimeout(0.01)
      table.insert(socks, sock)
      clients[sock] = {
        data = '',
        wbuf = ''
      }
    end

    coroutine.yield()
    return accept()
  end

  function flush_writes(_sock)
    _, ready = socket.select(nil, {_sock}, 0.1)

    for _, sock in ipairs(ready) do
      print("SOCK READY", sock)

      if #clients[sock].wbuf > 0 then
        print("SENDING", clients[sock].wbuf)

        err, emsg, bytes = sock:send(clients[sock].wbuf)
        -- print(err, emsg, bytes)
      end
    end

    _sock:close()
  end

  function dispatch()
    ready = socket.select(socks, nil, 0.1)

    for _, sock in ipairs(ready) do
      data, err = sock:receive()

      if data ~= nil then
        if data == "" then
          print('REQUEST:', clients[sock].data)
          clients[sock].wbuf = 'HTTP/1.0 200 OK\r\n\r\n' .. clients[sock].data
          flush_writes(sock)
        else
          clients[sock].data = clients[sock].data .. data .. "\r\n"
        end
      end

      coroutine.yield()
      return dispatch()
    end

    coroutine.yield()
    return dispatch()
  end

  local coroutines = {
    coroutine.create(function() accept() end),
    coroutine.create(function() dispatch() end)
  }

  while true do
    for _, co in ipairs(coroutines) do
      coroutine.resume(co)
    end
  end

  self.server:close()

--[[
  reading = {self.server}
  while true do
    local input = socket.select(reading)
    print('input', input)

    if input ~= nil then
      local client = input:accept()

      co = coroutine.create(function()
        print "  handling connection..."
        self:handleConnection(client)
      end)

      coroutine.resume(co)
    end
  end
]]--
end

-- run our webserver
HTTPServer:run(8888)
