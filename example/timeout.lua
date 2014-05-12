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

Timeout.callback = function (self)
    print ('Timer Actor start...')
    print ('Register 1s timeout.')
    -- register timeout event
    self:send('sch', 'register', 
        {
            event = 'timeout',          -- event type
            ev_name = self.my_name,     -- event name
            timeout = 1                 -- timeout: 1s
        }
    )

    print ('Wait 1s')
    self:listen({
        timeout = function (msg, from)
            print(
                string.format(
                    'Got message from:%s', 
                    from
                )
            )
        end,
    })
    print ('Time Actor end...')
end

sch:push_msg('sch', 'sch', 'create', 
    {
        name = "timeout",           -- new actor's name
        actor = Timeout,            -- actor class
        args = nil,                 -- arguments
    }
)
sch:run()
