local uloop = require("uloop")

-- XXX: for uloop, it is global, so only one uloop_reactor instance
--      can be use.
local uloop_reactor = {}

local __events = {}

uloop.init()

local __check_event_name = function (name)
    if __events[name] ~= nil then
        error("event has been registered")
    end
end

uloop_reactor.register_fd_event = function (name, fd_event_cb, fd, event)
    local events = 0

    __check_event_name(name)

    if event == 'read' then
        events = events + uloop.ULOOP_READ
    elseif event == 'write' then
        events = events + uloop.ULOOP_WRITE
    else
        error("unsupport event or nothing to do")
    end

    __events[name] = uloop.fd_add(fd, fd_event_cb, events)
end

uloop_reactor.register_timeout_cb = function (name, timeout_cb, timeout_interval)
    local ti
    __check_event_name(name)

    -- the time unit of uloop is ms, so convert it to second.
    ti = math.floor(timeout_interval * 1000)
  
    __events[name] = uloop.timer(timeout_cb, ti)
end

uloop_reactor.unregister_event = function (name)
    if __events[name] == nil then
        error("try to unregister unknown event")
    end
    
    -- for timer event, use cancel to unregister it
    -- for fd event, use delete to unregister it
    if self.__events[name].cancel ~= nil then
        self.__events[name]:cancel()
    else
        self.__events[name]:delete()
    end
    
    __events[name] = nil
end

uloop_reactor.run = function ()
    uloop.run()
end

uloop_reactor.cancel = function ()
    uloop.cancel()
end

return uloop_reactor
