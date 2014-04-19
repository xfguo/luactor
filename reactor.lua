local util = require "util"

--
-- Reactor Interface
--
-- This is an abstract model of a reactor or dispatcher, based on reactor
-- pattern. There are many event-driven based libraries,
-- eg. libevent(luaevent), libev(lua-ev), uloop(OpenWrt) and so on.
--
-- This interface provide an abstract layer of the reactor/dispatcher,
-- so it is easy to port to any other system.
--
-- A dispather can hold multiple transports.
--
-- Any reactor MUST follow this interface.
--

local AbstractReactor = util.class()

--
-- Event type of fd events
--
AbstractReactor.FD_READ = 1
AbstractReactor.FD_WRITE = 2

AbstractReactor.__init__ = function (self)
end

--
-- method to register a fd event
--
-- add name argument for easy debuging
--
AbstractReactor.register_fd_event = function (self, name, fd_event_cb, fd, event)
    error('Method not implemented.')
end

--
-- method to unregister a timeout or fd event
--
AbstractReactor.unregister_event = function (self, name)
    error('Method not implemented.')
end

--
-- method to register a timeout event
--
AbstractReactor.register_timeout_cb = function (self, name, timeout_cb, timeout_interval)
    error('Method not implemented.')
end

--
-- run the reactor to start listen all events
--
AbstractReactor.run = function (self)
    error('Method not implemented.')
end

return AbstractReactor
