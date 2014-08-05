--
-- the luaevent reactor driver
--

-- we just use the luaevent.core but not its high-level i/f.
local luaevent = require "luaevent"
local core = luaevent.core

local luaevent_reactor = {}

-- event core
local __ev_base = core.new()

-- registered events pool
local __events = {}

local __register_event = function (event_cb, fd, event, timeout)
    local new_ev_obj

    new_ev_obj = __ev_base:addevent(fd, event, 
        function ()
            event_cb()

            -- TODO: here just trigger once, try support trigger persist.
            return timeout and core.LEAVE or nil
        end,
    timeout)

    __events[new_ev_obj] = true
    return new_ev_obj
end

luaevent_reactor.register_fd_event = function (fd_event_cb, fd, ev_type)
    local events = 0
    -- transform event type
    -- TODO: support regiser both *read* and *write*.
    if ev_type == 'read' then
        events = events + core.EV_READ
    elseif ev_type == 'write' then
        events = events + core.EV_WRITE
    else
        error("unsupport event type or nothing to do")
    end

    return __register_event(fd_event_cb, fd, events)
end

luaevent_reactor.register_timeout_cb = function (timeout_cb, timeout_interval)
    return __register_event(timeout_cb, nil, core.EV_TIMEOUT, timeout_interval)
end

luaevent_reactor.unregister_event = function (ev_obj)
    if __events[ev_obj] ~= true then
        error("try to unregister unknown event")
    end

    __events[ev_obj] = nil
    ev_obj:close()
end

luaevent_reactor.run = function ()
    __ev_base:loop()
end

luaevent_reactor.cancel = function ()
    -- TODO: impl this method
end

return luaevent_reactor
