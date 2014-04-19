--
-- TCP Echo Server Example
--
-- Reference luasocket example :
--     http://w3.impa.br/~diego/software/luasocket/introduction.html
--

require "actor"
util = require "util"
local socket = require("socket")

-- Actors ---------------------------------------------------------------------

--
-- EchoActor
--
-- handle a TCP connection, echo back everything
--
EchoActor = util.class(Actor)

EchoActor.__init__ = function(self, sch, name, conn)
    Actor.__init__(self, sch, name)
    self.conn = conn
end

EchoActor.callback = function(self)
    print(string.format('EchoActor[%s] start...', self.my_name))

    -- register fd event for new data coming
    self.sch:register_fd_event(
        self.my_name,           -- from
        self.my_name,           -- to
        self.my_name,           -- event name
        self.conn,              -- accepted socket
        sch.reactor.FD_READ     -- event
    )

    local finish = false
    while not finish do
        -- listen fd event
        self:listen({
            fd_event = function (msg)
                -- receive it
                local line, err = self.conn:receive()
                if not err then
                    -- echo back
                    self.conn:send(line .. "\n")
                else
                    -- connection close
                    finish = true
                end
            end,
        })
    end

    -- unregister fd event, close and exit
    print(string.format('EchoActor[%s] end...', self.my_name))
    self.conn:close()
    self.sch:unregister_event(self.my_name) -- FIXME: why I can't print after this line?
end

--
-- TcpManager
--
-- listen a TCP socket, when new TCP connection established, pass it to a new EchoActor
--
TcpManager = util.class(Actor)

TcpManager.callback = function (self, msg)
    local conn_no = 0

    print('TcpManager start...')
    print("Use `telnet localhost 8080` to test it")
    
    self.server = assert(socket.bind("*", 8080))

    -- register fd event for new connection
    self.sch:register_fd_event(
        self.my_name,       -- from
        self.my_name,       -- to
        self.my_name,       -- event name
        self.server,        -- accepted socket
        sch.reactor.FD_READ -- event
    )

    while true do
        -- listen fd event
        self:listen({
            fd_event = function (msg)
                local conn = self.server:accept()
                
                -- generate a new name
                local conn_name = 'tcp_conn_'..conn_no
                conn_no = conn_no + 1

                -- create a new EchoActor, then register and start it.
                local conn_actor = EchoActor(self.sch, conn_name, conn)
                self.sch:register_actor(conn_name, conn_actor)
                self.sch:start_actor(conn_name)
            end,
        })
    end
end
-- Main -----------------------------------------------------------------------

sch = Scheduler()
tcp_manager = TcpManager(sch, "tcp_manager")
sch:register_actor('tcp_manager', tcp_manager)
sch:run()
