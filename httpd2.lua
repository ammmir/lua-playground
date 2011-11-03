local ev = require 'ev'
local socket = require 'socket'

HTTPServer = {
}

function HTTPServer:run(port)
  self.loop = ev.Loop.default
  self.server = socket.bind('127.0.0.1', port)
  self.server:settimeout(0)
  self.clients = {}

  --[[ev.Timer.new(function(loop, timer)
    print("time!")
  end, 1.0, 1.0):start(self.loop)]]--

  ev.IO.new(function(loop, watcher)
    local client = self.server:accept()

    if not client then
      print("NO CLIENT!")
      --watcher:stop(loop)
      return
    end

    client:settimeout(0)
    self.clients[client] = {
      rbuf = {},
      wbuf = {}
    }

    ev.IO.new(function(loop, watcher)
      while true do
        buf, err, partial_buf = client:receive('*l')

        if err == 'closed' then
          watcher:stop(loop)
          print("CLOSED", buf, err, partial_buf)
          self.clients[client] = nil
          client:close()
          return
        elseif err == 'timeout' then
          watcher:stop(loop)
          print("TIMEOUT", buf, err, partial_buf)
          self.clients[client] = nil
          client:shutdown()
          return
        else
          if buf == '' then
            print(self.clients[client].rbuf[1])

            watcher:stop(loop)

            table.insert(self.clients[client].wbuf, 'HTTP/1.0 200 OK\r\n\r\n')

            for i, v in ipairs(self.clients[client].rbuf) do
              table.insert(self.clients[client].wbuf, v .. '\n')
            end

            ev.IO.new(function(loop, watcher)
              buf = table.remove(self.clients[client].wbuf, 1)

              if buf then
                client:send(buf)
              else
                watcher:stop(loop)
                self.clients[client] = nil
                client:shutdown()
              end
            end,
            client:getfd(),
            ev.WRITE):start(loop)
            break
          elseif buf then
            table.insert(self.clients[client].rbuf, buf)
          end
        end
      end
    end,
    client:getfd(),
    ev.READ):start(loop)
  end,
  self.server:getfd(),
  ev.READ):start(self.loop)

  self.loop:loop()
end

HTTPServer:run(8888)
