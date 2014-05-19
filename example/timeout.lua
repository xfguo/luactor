local actor = require "luactor"

-- Setup reactor---------------------------------------------------------------
local reactor_name = os.getenv("LUACTOR_REACTOR") or 'luaevent'
print('The reactor you use is *'..reactor_name..'*.')

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
