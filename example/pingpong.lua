require "actor"

-- Example -------------------------------------------------------------------
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

Ping = util.class(Actor)
Ping.callback = function (self)
    print("ping start")
    for _ = 1,100 do
        self:listen({
            bar = function (msg, from)
                print(string.format('msg from:%s msg:%s', from, msg))
                self:send("pong", "foo", "hello")
            end,
        })
    end
end

Pong = util.class(Actor)

Pong.callback = function (self, msg)
    print("pong start")
    for _ = 1,100 do
        self:listen({
            foo = function (msg, from)
                print(string.format('msg from:%s msg:%s', from, msg))
                self:send("ping", "bar", "world")
            end,
        })
    end
end

-- create Ping and Pong actors by send messages to scheduler
sch:push_msg('sch', 'sch', 'create', 
    {
        name = "ping",              -- new actor's name
        actor = Ping,               -- actor class
        args = nil,                 -- arguments
    }
)

sch:push_msg('sch', 'sch', 'create',
    {
        name = "pong",              -- new actor's name
        actor = Pong,               -- actor class
        args = nil,                 -- arguments
    }
)


-- send a fake pong msg to ping to start the ping-pong
sch:push_msg('pong', 'ping', "bar", "world")
sch:run()
