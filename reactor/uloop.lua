local util = require("util")
local AbstractReactor = require("reactor")
local uloop = require("uloop")

local UloopReactor = util.class(AbstractReactor)

UloopReactor.__init__ = function (self)
    AbstractReactor.__init__(self)
    -- XXX: for uloop, it is global, so only one UloopReactor instance
    --      can be use.
    uloop.init()
    self.__events = {}
end

UloopReactor.__check_event_name = function (self, name)
    if self.__events[name] ~= nil then
        error("event has been registered")
    end
end

UloopReactor.register_fd_event = function (self, name, fd_event_cb, fd, event)
    local events = 0

    self:__check_event_name(name)

    -- transform event type
    if event == self.FD_READ then
        events = uloop.ULOOP_READ
    elseif event == self.FD_WRITE then
        events = uloop.ULOOP_WRITE
    else
        error("unsupport event or nothing to do")
    end

    self.__events[name] = uloop.fd_add(fd, fd_event_cb, events)
end

UloopReactor.register_timeout_cb = function (self, name, timeout_cb, timeout_interval)
    local ti
    self:__check_event_name(name)

    -- the time unit of uloop is ms, so convert it to second.
    ti = math.floor(timeout_interval * 1000)
  
    self.__events[name] = uloop.timer(timeout_cb, ti)
end

UloopReactor.unregister_event = function (self, name)
    if self.__events[name] == nil then
        error("try to unregister unknown event")
    end

    self.__events[name]:cancel()
    self.__events[name] = nil
end

UloopReactor.run = function (self)
    uloop.run()
end

UloopReactor.cancel = function (self)
    uloop.cancel()
end

return UloopReactor
