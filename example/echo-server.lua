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
            -- wait fd event
            fd_event = function (msg)
                -- receive it
                local line, err = self.conn:receive()
                if not err then
                    -- echo back
                    self.conn:send(line .. "\n")

                    -- if got a 'exit' command, send exit message 
                    -- to tcp_manager. later, we will receive a
                    -- exit event.
                    if line == "exit" then
                        self:send({
                            to = 'tcp_manager', 
                            cmd = 'exit'
                        })
                    end
                else
                    -- connection close
                    -- send a message to delete my info
                    self:send({
                        to = 'tcp_manager',
                        cmd = 'echo_actor_finished'
                    })
                    finish = true
                end
            end,

            -- wait an exit message
            exit = function (msg)
                finish = true
                print(string.format('EchoActor[%s] got a exit command.', self.my_name))
            end,
        })
    end

    -- unregister fd event, close and exit
    self.sch:unregister_event(self.my_name)
    self.conn:close()

    print(string.format('EchoActor[%s] end...', self.my_name))
end

--
-- TcpManager
--
-- listen a TCP socket, when new TCP connection established, pass it to a new EchoActor
--
TcpManager = util.class(Actor)

TcpManager.__init__ = function(self, sch, name)
    Actor.__init__(self, sch, name)
    self.active_echo_actors = {}
end

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

    local finish = false
    while not finish do
        -- listen fd event
        self:listen({
            -- wait a fd event
            fd_event = function (msg)
                local conn = self.server:accept()

                -- generate a new name
                local conn_name = 'tcp_conn_'..conn_no
                conn_no = conn_no + 1

                -- create a new EchoActor, then register and start it.
                local conn_actor = EchoActor(self.sch, conn_name, conn)
                self.sch:register_actor(conn_name, conn_actor)
                self.sch:start_actor(conn_name)

                -- attach the name of echo actor to the pool
                self.active_echo_actors[conn_name] = true
            end,

            -- wait finish message from echo actors
            echo_actor_finished = function (msg)
                self.active_echo_actors[msg.from] = nil
            end,

            -- wait an exit message sent from echo actor
            exit = function (msg)
                print('Got Exit Message from '..msg.from)
                print('Send `exit` to all echo actors')
                for echo_actor_name, _ in pairs(self.active_echo_actors) do
                    self:send({
                        to = echo_actor_name,
                        cmd = 'exit'
                    })
                end
                finish = true
            end,
        })
    end

    self.sch:unregister_event(self.my_name)
    self.server:close()
    print('TcpManager end...')
end
-- Main -----------------------------------------------------------------------
local reactor = 'luaevent'
if arg[1] ~= nil then
    if arg[1] == 'uloop' then
        reactor = arg[1]
    elseif arg[1] ~= 'luaevent' then
        error(string.format(
            'unknown reactor: %s, usage:\n\n    %s %s [uloop|luaevent]\n',
            arg[1], arg[-1], arg[0]
        ))
    end
end
print('The reactor you use is *'..reactor..'*.')

sch = Scheduler(reactor)
tcp_manager = TcpManager(sch, "tcp_manager")
sch:register_actor('tcp_manager', tcp_manager)
sch:run()
