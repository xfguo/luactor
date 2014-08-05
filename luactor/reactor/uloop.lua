local uloop = require("uloop")

-- XXX: for uloop, it is global, so only one uloop_reactor instance
--      can be use.
local uloop_reactor = {}

local __events = {}

uloop.init()

uloop_reactor.register_fd_event = function (fd_event_cb, fd, event)
    local events = 0

    -- TODO: support regiser both *read* and *write*.
    if event == 'read' then
        events = events + uloop.ULOOP_READ
    elseif event == 'write' then
        events = events + uloop.ULOOP_WRITE
    else
        error("unsupport event or nothing to do")
    end

    __events[uloop.fd_add(fd, fd_event_cb, events)] = true
end

uloop_reactor.register_timeout_cb = function (timeout_cb, timeout_interval)
    local ti

    -- the time unit of uloop is ms, so convert it to second.
    ti = math.floor(timeout_interval * 1000)
  
    __events[uloop.timer(timeout_cb, ti)] = true
end

uloop_reactor.unregister_event = function (ev_obj)
    if __events[ev_obj] ~= true then
        error("try to unregister unknown event")
    end
    
    __events[ev_obj] = nil
    
    -- for timer event, use cancel to unregister it
    -- for fd event, use delete to unregister it
    if ev_obj.cancel ~= nil then
        ev_obj:cancel()
    else
        ev_obj:delete()
    end
end

uloop_reactor.run = function ()
    uloop.run()
end

uloop_reactor.cancel = function ()
    uloop.cancel()
end

return uloop_reactor
