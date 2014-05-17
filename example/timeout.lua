local actor = require "luactor"

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

local timeout = function ()
    print ('Timer Actor start...')
    print ('Register 1s timeout.')
    -- register timeout event
    actor.register_event(
        'timeout',      -- event type
        't1',           -- event name
        1               -- event parameters
    )

    print ('Wait 1s')
    actor.wait({
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

timer = actor.create('timeout', timeout)

actor.start(timer)

actor.run()
