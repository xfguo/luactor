require "actor"

-- Setup reactor---------------------------------------------------------------
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

Timeout = util.class(Actor)

Timeout.callback = function (self, msg)
    print ('Timer Actor start...')
    print ('Register 1s timeout.')
    -- register timeout event
    self:send({
        to = 'sch',                 -- to
        cmd = 'register',           -- register command
        event = 'timeout',          -- event type
        ev_name = self.my_name,     -- event name
        timeout = 1                 -- timeout: 1s
    })

    print ('Wait 1s')
    self:listen({
        timeout = function (msg)
            print(
                string.format(
                    'Got message:%s', 
                    msg.cmd
                )
            )
        end,
    })
    print ('Time Actor end...')
end

sch:push_msg({
    to = 'sch',                 -- to
    cmd = 'create',             -- register command
    name = "timeout",           -- new actor's name
    actor = Timeout,            -- actor class
    args = nil,                 -- arguments
})
sch:run()
