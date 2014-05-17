--
-- TCP Echo Server Example
--
-- Reference luasocket example :
--     http://w3.impa.br/~diego/software/luasocket/introduction.html
--

local actor = require "luactor"
local socket = require("socket")

-- Actors ---------------------------------------------------------------------

--
-- EchoActor
--
-- handle a TCP connection, echo back everything
--
local echo_actor_func = function(conn, name)
    print(string.format('EchoActor[%s] start...', name))

    -- register fd event for new data coming
    actor.register_event(
        'fd',                       -- event type
        name,                       -- event name
        conn,                       -- fd want to listen
        'read'                      -- fd event type
    )

    local finish = false
    while not finish do
        -- listen fd event
        actor.wait({
            -- wait fd event
            fd_event = function (msg)
                -- receive it
                local line, err = conn:receive()
                if not err then
                    -- echo back
                    conn:send(line .. "\n")

                    -- if got a 'exit' command, send exit message
                    -- to tcp_manager. later, we will receive a
                    -- exit event.
                    if line == "exit" then
                        actor.send('tcp_manager', 'exit')
                    elseif line == "raise" then
                        error("raise error")
                    end
                else
                    -- connection close
                    -- send a message to delete my info
                    actor.send('tcp_manager', 'echo_actor_finished')
                    finish = true
                end
            end,

            -- wait an exit message
            exit = function (msg)
                finish = true
                print(string.format('EchoActor[%s] got a exit command.', name))
            end,
        })
    end

    -- unregister fd event, close and exit
    actor.unregister_event(name)
    conn:close()

    print(string.format('EchoActor[%s] end...', name))
end

--
-- TcpManager
--
-- listen a TCP socket, when new TCP connection established, pass it to a new EchoActor
--
tcp_manager_func = function ()
    local active_echo_actors = {}
    local accepted_conns = {}
    local conn_no = 0

    print('TcpManager start...')
    print("Use `telnet localhost 48888` to test it")

    local server = assert(socket.bind("*", 48888))

    -- register fd event for accept new connection
    actor.register_event(
        'fd',               -- event type
        'tcp_manager',      -- event name
        server,             -- fd want to listen
        'read'              -- fd event type
    )

    local finish = false
    while not finish do
        -- listen fd event
        actor.wait({
            -- wait a fd event
            fd_event = function (msg)
                local conn = server:accept()

                -- generate a new name
                local conn_name = 'tcp_conn_'..conn_no
                conn_no = conn_no + 1

                -- create a new EchoActor by send a message to scheduler
                local new_echo_actor = actor.create(
                    conn_name,           -- new actor's name
                    echo_actor_func      -- actor function
                )

                -- start the new echo actor
                actor.start(new_echo_actor, conn, conn_name)

                -- attach the name of echo actor to the pool
                active_echo_actors[conn_name] = true

                -- hold the accepted connections for error handling
                accepted_conns[conn_name] = conn
            end,

            -- wait finish message from echo actors
            echo_actor_finished = function (msg, sender)
                active_echo_actors[sender] = nil
                accepted_conns[sender] = nil
            end,

            -- handle the error of echo actor
            -- close the connection and unregister the related events.
            actor_error = function (msg)
                local failed_echo_actor_name = msg.actor.name
                actor.unregister_event(failed_echo_actor_name)
                accepted_conns[failed_echo_actor_name]:close()
                print(string.format(
                    'Echo actor: [%s] failed: \ntrace:\n\t%s\nerror: %s',
                    failed_echo_actor_name,
                    string.gsub(msg.error[1], '\n', '\n\t'),
                    msg.error[2]
                ))
            end,

            -- wait an exit message sent from echo actor
            exit = function (msg, sender)
                print('Got Exit Message from '..sender)
                print('Send `exit` to all echo actors')
                for echo_actor_name, _ in pairs(active_echo_actors) do
                    actor.send(echo_actor_name, 'exit')
                end
                finish = true
            end,
        })
    end

    actor.unregister_event('tcp_manager')
    server:close()
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

tcp_manager = actor.create('tcp_manager', tcp_manager_func)

actor.start(tcp_manager)

actor.run()
