util = require "util"

-- Scheduler ------------------------------------------------------------------
Scheduler = util.class()

Scheduler.__init__ = function (self, reactor)
    local Reactor
    if reactor == 'uloop' then
        Reactor = require "reactor.uloop"
    else
        -- for now, default reactor driver is luaevent
        Reactor = require "reactor.luaevent"
    end

    self.mqueue = util.Queue()
    self.reactor = Reactor()
    self.actors = {}
    self.actors_num = 0
    self.threads = {} -- the scheduler coroutine will be "_"
    self.creators = {} -- which actor register the new actor
    self.my_name = 'sch'
end

Scheduler.register_actor = function (self, name, actor, creator)
    if self.actors[name] ~= nil or self.threads[name] ~= nil then
        error("the actor name has been registered")
    end
    self.actors[name] = actor
    self.actors_num = self.actors_num + 1

    -- reference from coxpcall project
    local res, thread = pcall(coroutine.create, actor.callback)
    if not res then
        local newf = function(...) return f(...) end
        thread = coroutine.create(newf)
    end
    self.threads[name] = thread
    self.creators[name] = creator
end

Scheduler.resume_actor = function (self, name, ...)
    local thread = self.threads[name]
    local status, what = util.perform_resume(util.pack, thread, ...)

    -- send the failed actor to its creator. if it creator is
    -- dead, then just destory it.
    if status == false and self.creators[name] ~= nil then
        self:push_msg({
            to = self.creators[name],
            from = self.my_name,
            cmd = "actor_error",
            actor = self.actors[name],
            error = what,
        })
    end

    if coroutine.status(self.threads[name]) == 'dead'
       or status == false then
        self.actors[name] = nil
        self.actors_num = self.actors_num - 1
        self.threads[name] = nil
        self.creators[name] = nil
    end

end

Scheduler.push_msg = function (self, msg)
    -- TODO: if session is nil, create a unique one
    self.mqueue:push(msg)
end

Scheduler.register_fd_event = function (self, from, to, name, fd, event)
    self.reactor:register_fd_event(
        name,
        function (events)
            -- unregister the event if the actor was dead.
            -- 
            --  XXX: what if the name is reused?
            --       or any other problems?
            if self.actors[to] == nil then
                self.reactor:unregister_event(name)
            end
            -- push event message to mqueue
            self.mqueue:push({
                from = from,
                to = to,
                cmd = "fd_event",
                event = event,
                fd = fd,
            })
            self:resume_actor('_', self.actors[to])
        end,
        fd, event
    )
end

Scheduler.register_timeout_cb = function (self, from, to, name, timeout_interval)
    self.reactor:register_timeout_cb(
        name,
        function (events)
            -- unregister the event if the actor was dead.
            -- 
            --  XXX: what if the name is reused?
            --       or any other problems?
            if self.actors[to] == nil then
                self.reactor:unregister_event(name)
            end
            -- push event message to mqueue
            self.mqueue:push({
                from = from,
                to = to,
                cmd = "timeout",
                timeout_interval = timeout_interval,
            })
            self:resume_actor('_', self.actors[to])
        end, timeout_interval
    )
end

Scheduler.unregister_event = function (self, name)
    self.reactor:unregister_event(name)
end

--
-- handle service requested by other actors
--
-- the servie included:
--   - create/destory an actor
--   - register a fd/timeout event
--
Scheduler.handle_service = function (self, msg)
    -- TODO: parameters of msg should be checked.
    if msg.cmd == 'register' then
        if msg.event == 'timeout' then
            self:register_timeout_cb(
                self.my_name,           -- from
                msg.from,               -- to
                msg.ev_name,            -- event name
                msg.timeout             -- timeout
            )
        elseif msg.event == 'fd' then
            local fd_event

            -- convert fd event from string to value
            if msg.fd_event == 'read' then
                fd_event = self.reactor.FD_READ
            elseif msg.fd_event == 'write' then
                fd_event = self.reactor.FD_WRITE
            else
                error("unknown fd event type")
            end

            self:register_fd_event(
                self.my_name,           -- from
                msg.from,               -- to
                msg.ev_name,            -- event name
                msg.fd,                 -- fd
                fd_event                -- fd event
            )
        else
            error("unknown event type when register event")
        end
    elseif msg.cmd == 'create' then
        local new_actor = msg.actor(self, msg.name)
        local creator = msg.from
        self:register_actor(msg.name, new_actor, creator)
        self:resume_actor(msg.name, new_actor, unpack(msg.args or {}))
    end
end

Scheduler.process_mqueue = function (self)
    local finish = false
    while not finish do
        while not self.mqueue:empty() do
            -- TODO: check msg
            local msg
            msg = self.mqueue:pop()
            if msg.to == self.my_name then
                self:handle_service(msg)
            elseif self.threads[msg.to] == nil then
                -- drop this msg
                --
                -- TODO: what we can do before the msg is dropped.
            else
                self:resume_actor(msg.to, msg)
                if self.actors_num <= 0 then
                    self.reactor:cancel()
                    finish = true
                    break
                end
            end
        end
        coroutine.yield()
    end
end

--
-- run scheduler
--
-- TODO: return status string
--
Scheduler.run = function (self)
    -- start threads
    for name, actor in pairs(self.actors) do
        self:resume_actor(name, actor)
    end

    -- reference from coxpcall project
    local res, thread = pcall(coroutine.create, self.process_mqueue)
    if not res then
        local newf = function(...) return f(...) end
        thread = coroutine.create(newf)
    end

    -- the schedular coroutine should have its creator and the
    -- error should be processed.
    self.threads['_'] = thread
    
    self:resume_actor('_', self)

    -- run until there are no actors
    while self.actors_num > 0 do
        self.reactor:run()
    end

    -- TODO: clean up everything
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

