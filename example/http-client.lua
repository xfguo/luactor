--
-- HTTP Client Example
--

local actor = require "luactor"
local socket = require("socket")

-- Actors ---------------------------------------------------------------------

--
-- HttpClient
--
-- listen a TCP socket, when new TCP connection established, pass it to a new EchoActor
--

local http_client_func = function ()
    print('HTTP Client start...')

    local client = assert(socket.tcp())
    
    print(client:connect("127.0.0.1", 3333))
    -- register fd event for HTTP response
    actor.register_event(
        'fd',               -- event type
        'http_response',    -- event name
        client,             -- fd want to listen
        'read'              -- fd event type
    )

    client:send("GET / HTTP/1.1\r\n")
    client:send("\r\n")

    local finish = false
    local parse_state = nil
    while not finish do
        actor.wait({
            -- wait a fd event
            http_response = function (msg)
                while not finish do
                    if parse_state == nil then
                        resp, err = client:receive("*l")
                        if resp ~= nil then
                            else
                        end
                    end
                    resp, err = client:receive("*l")
                    if resp == nil then
                        finish = true
                        -- TODO: do more things here
                        print("ERROR:" .. err)
                    else
                        print(resp)
                    end
                end
            end,
        })
    end

    actor.unregister_event('http_response')
    client:close()
    print('HTTP Client end...')
end

-- Main -----------------------------------------------------------------------
local reactor_name = os.getenv("LUACTOR_REACTOR") or 'luaevent'
print('The reactor you use is *'..reactor_name..'*.')

http_client = actor.create('http_client', http_client_func)

actor.start(http_client)

actor.run()
