local actor = require "luactor"

local reactor_name = os.getenv("LUACTOR_REACTOR") or 'luaevent'
print('The reactor you use is *'..reactor_name..'*.')

local ping = function ()
    -- ping-pong for 1 second
    actor.register_event(
        'timeout',      -- event type
        'stop',           -- event name
        1               -- event parameters
    )
    print("ping start")
    local finish = false
    while not finish do
        actor.wait({
            bar = function (msg, sender)
                print(string.format('msg from:%s msg:%s', sender, msg))
                actor.send("pong", "foo", "hello")
            end,
            timeout = function (msg, sender)
                actor.send("pong", "exit")
                finish = true
                print("End")
            end
        })
    end
end

local pong = function ()
    print("pong start")
    local finish = false
    while not finish do
        actor.wait({
            foo = function (msg, sender)
                print(string.format('msg from:%s msg:%s', sender, msg))
                actor.send("ping", "bar", "world")
            end,
            timeout = function (msg, sender)
                finish = true
                print("End Received")
            end
        })
    end
end

pinger = actor.create('ping', ping)
ponger = actor.create('pong', pong)

actor.start(pinger)
actor.start(ponger)

actor.send('ping', 'bar', 'world')

actor.run()
