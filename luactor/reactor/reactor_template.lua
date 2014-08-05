--
-- Reactor Interface
--
-- This is an fake model of a reactor or dispatcher, based on reactor
-- pattern. There are many event-driven based libraries,
-- eg. libevent(luaevent), libev(lua-ev), uloop(OpenWrt) and so on.
--
-- This interface provide an template of the reactor/dispatcher,
-- so it is easy to port to any other system.
--
-- A dispather can hold multiple transports.
--
-- Any reactor MUST follow this interface.
--

local your_reactor = {}

--
-- method to register a fd event
--
-- return the event object which is used to unregister
--
your_reactor.register_fd_event = function (fd_event_cb, fd, event)
    error('Method not implemented.')
end

--
-- method to register a timeout event
--
-- return the event object which is used to unregister
--
your_reactor.register_timeout_cb = function (timeout_cb, timeout_interval)
    error('Method not implemented.')
end

--
-- method to unregister a timeout or fd event
--
your_reactor.unregister_event = function (ev_obj)
    error('Method not implemented.')
end

--
-- run the reactor to start listen all events
--
your_reactor.run = function ()
    error('Method not implemented.')
end

--
-- cancel the reactor
--
your_reactor.cancel = function ()
    error('Method not implemented.')
end

return your_reactor
