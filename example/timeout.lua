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

timeout = Actor(sch, 'timeout')
timeout.callback = function (self, msg)
    print ('Timer Actor start...')
    print ('Register 1s timeout.')
    -- register fd event for new data coming
    self.sch:register_timeout_cb(
        self.my_name,           -- from
        self.my_name,           -- to
        "timeout",              -- event name
        1                       -- timeout interval
    )
    
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

sch:register_actor('timeout', timeout)
sch:run()
