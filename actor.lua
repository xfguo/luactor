util = require "util"
require "queue"

-- Scheduler -----------------------------------------------------------------
Scheduler = util.class()

Scheduler.__init__ = function (self)
    self.mqueue = Queue()
--    self.reactor = event.Reactor()
    self.actors = {}
    self.threads = {}
end

Scheduler.register_actor = function (self, name, actor)
    if self.actors[name] ~= nil or self.threads[name] ~= nil then
        error("the actor name has been registered")
    end
    self.actors[name] = actor

    thread = coroutine.create(actor.callback)
    self.threads[name] = thread
end

Scheduler.push_msg = function (self, msg)
    -- TODO: if session is nil, create a unique one
    self.mqueue:push(msg)
end

Scheduler.run = function (self)
    -- start threads
    for name, thread in pairs(self.threads) do
        status, what = coroutine.resume(self.threads[name], self.actors[name])
        -- TODO: proc status
    end

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

