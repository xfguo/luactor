util = require "util"
require "queue"
Reactor = require "reactor.luaevent"

-- Scheduler -----------------------------------------------------------------
Scheduler = util.class()

Scheduler.__init__ = function (self)
    self.mqueue = Queue()
    self.reactor = Reactor()
    self.actors = {}
    self.threads = {}
    self.hub = nil -- the scheduler coroutine
end

Scheduler.register_actor = function (self, name, actor)
    if self.actors[name] ~= nil or self.threads[name] ~= nil then
        error("the actor name has been registered")
    end
    self.actors[name] = actor

    thread = coroutine.create(actor.callback)
    self.threads[name] = thread
end

Scheduler.start_actor = function (self, name)
    status, what = coroutine.resume(self.threads[name], self.actors[name])
    -- TODO: process status and what
    return status, what
end

Scheduler.push_msg = function (self, msg)
    -- TODO: if session is nil, create a unique one
    self.mqueue:push(msg)
end

Scheduler.register_fd_event = function (self, from, to, name, fd, event)
    self.reactor:register_fd_event(
        name,
        function (events)
            -- push event message to mqueue
            self.mqueue:push({
                from = from,
                to = to,
                cmd = "fd_event",
                event = event,
                fd = fd,
            })
            coroutine.resume(self.hub)
        end,
        fd,
        event
    )
end

Scheduler.register_timeout_cb = function (self, from, to, name, timeout_interval)
    self.reactor:register_timeout_cb(
        name,
        function (events)
            -- push event message to mqueue
            self.mqueue:push({
                from = from,
                to = to,
                cmd = "timeout",
                timeout_interval = timeout_interval,
            })
            coroutine.resume(self.hub)
        end,
        fdevent
    )
end

Scheduler.unregister_event = function (self, name)
    self.reactor:unregister_event(name)
end

Scheduler.process_mqueue = function (self)
    while true do
        while not self.mqueue:empty() do
            -- TODO: check msg
            local msg
            msg = self.mqueue:pop()
            status, what = coroutine.resume(self.threads[msg.to], msg)
            if status == false then
                table.remove(self.threads, name)
                table.remove(self.actors, name)
            end
        end
        coroutine.yield()
    end
end

Scheduler.run = function (self)
    -- start threads
    for name, _ in pairs(self.threads) do
        self:start_actor(name)
    end

    self.hub = coroutine.create(self.process_mqueue)
    coroutine.resume(self.hub, self)
    self.reactor:run()
end

-- Actor ---------------------------------------------------------------------

Actor = util.class()

Actor.__init__ = function (self, sch, name)
    self.my_name = name
    self.sch = sch -- scheduler
end

Actor.send = function (self, msg)
    msg.from = self.my_name
    self.sch.push_msg(self.sch, msg) -- return the session
end

Actor.listen = function (self, what)
    -- what is the set of the msg you want listen
    msg = coroutine.yield(what)
    what[msg.cmd](msg)
    -- TODO: handle unknown message cmd
end

Actor.callback = function (self, msg)
    error('callback is not implemented')
end

