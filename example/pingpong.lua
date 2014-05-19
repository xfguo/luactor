local actor = require "luactor"

local reactor_name = os.getenv("LUACTOR_REACTOR") or 'luaevent'
print('The reactor you use is *'..reactor_name..'*.')

local ping = function ()
    print("ping start")
    for _ = 1,100 do
        actor.wait({
            bar = function (msg, sender)
                print(string.format('msg from:%s msg:%s', sender, msg))
                actor.send("pong", "foo", "hello")
            end,
        })
    end
end

local pong = function ()
    print("pong start")
    for _ = 1,100 do
        actor.wait({
            foo = function (msg, sender)
                print(string.format('msg from:%s msg:%s', sender, msg))
                actor.send("ping", "bar", "world")
            end,
        })
    end
end

pinger = actor.create('ping', ping)
ponger = actor.create('pong', pong)

actor.start(pinger)
actor.start(ponger)

actor.send('ping', 'bar', 'world')

actor.run()
