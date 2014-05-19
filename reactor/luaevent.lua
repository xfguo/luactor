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

local __register_event = function (name, event_cb, fd, event, timeout)
    if __events[name] ~= nil then
        error("event has been registered")
    end

    __events[name] = __ev_base:addevent(fd, event, 
        function ()
            event_cb()

            -- TODO: here just trigger once, try support trigger persist.
            return timeout and core.LEAVE or nil
        end,
    timeout)
end

luaevent_reactor.register_fd_event = function (name, fd_event_cb, fd, event)
    local events = 0
    -- transform event type
    if event == 'read' then
        events = events + core.EV_READ
    elseif event == 'write' then
        events = events + core.EV_WRITE
    else
        error("unsupport event or nothing to do")
    end

    __register_event(name, fd_event_cb, fd, events)
end

luaevent_reactor.unregister_event = function (name)
    local fd_ev

    if __events[name] == nil then
        error("try to unregister unknown event")
    end

    __events[name]:close()
    __events[name] = nil
end

luaevent_reactor.register_timeout_cb = function (name, timeout_cb, timeout_interval)
    __register_event(name, timeout_cb, nil, core.EV_TIMEOUT, timeout_interval)
end

luaevent_reactor.run = function ()
    __ev_base:loop()
end

luaevent_reactor.cancel = function ()
    -- TODO: impl this method
end

return luaevent_reactor
