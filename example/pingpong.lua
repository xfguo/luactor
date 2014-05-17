local actor = require "luactor"

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

-- Example -------------------------------------------------------------------

print('The reactor you use is *'..reactor..'*.')

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
