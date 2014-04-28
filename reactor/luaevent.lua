local util = require("util")
local AbstractReactor = require("reactor")
local luaevent = require "luaevent"
local core = luaevent.core

local LuaeventReactor = util.class(AbstractReactor)

--
-- FIXME: the return value of a callback may delete that event
--

LuaeventReactor.__init__ = function (self)
    AbstractReactor.__init__(self)
    self.__ev_base = core.new()
    self.__events = {}
end

LuaeventReactor.__register_event = function (self, name, fd_event_cb, fd, event, timeout)
    if self.__events[name] ~= nil then
        error("event has been registered")
    end

    self.__events[name] = self.__ev_base:addevent(fd, event, fd_event_cb, timeout)
end

LuaeventReactor.register_fd_event = function (self, name, fd_event_cb, fd, event)
    local events = 0
    -- transform event type
    if event == self.FD_READ then
        events = events + core.EV_READ
    elseif event == self.FD_WRITE then
        events = events + core.EV_WRITE
    else
        error("unsupport event or nothing to do")
    end

    self:__register_event(name, fd_event_cb, fd, events)
end

LuaeventReactor.unregister_event = function (self, name)
    local fd_ev

    if self.__events[name] == nil then
        error("try to unregister unknown event")
    end

    self.__events[name]:close()
    self.__events[name] = nil
end

LuaeventReactor.register_timeout_cb = function (self, name, timeout_cb, timeout_interval)
    self:__register_event(name, timeout_cb, nil, core.EV_TIMEOUT, timeout_interval)
end

LuaeventReactor.run = function (self)
    self.__ev_base:loop()
end

LuaeventReactor.cancel = function (self)
    -- TODO: impl this method
end

return LuaeventReactor
