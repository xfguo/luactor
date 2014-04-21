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

ping = Actor(sch, 'ping')
ping.callback = function (self, msg)
    print("ping start")
    for _ = 1,100 do
        self:listen({
            bar = function (msg)
                print(
                    string.format(
                        'msg from:%s cmd:%s msg:%s', 
                        msg.from,
                        msg.cmd,
                        msg.msg
                    )
                )
                self:send({
                    to = "pong",
                    cmd = "foo",
                    msg = "hello",
                })
            end,
        })
    end
end

pong = Actor(sch, 'pong')

pong.callback = function (self, msg)
    print("pong start")
    for _ = 1,100 do
        self:listen({
            foo = function (msg)
                print(
                    string.format(
                        'msg from:%s cmd:%s msg:%s', 
                        msg.from,
                        msg.cmd,
                        msg.msg
                    )
                )
                self:send({
                    to = "ping",
                    cmd = "bar",
                    msg = "world",
                })
            end,
        })
    end
end

--

sch:register_actor('ping', ping)
sch:register_actor('pong', pong)

-- send a fake pong msg to ping to start the ping-pong
sch:push_msg({
    from = 'pong',
    to = 'ping',
    cmd = "bar",
    msg = "world",
})
sch:run()
