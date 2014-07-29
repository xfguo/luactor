-- 
-- Luactor - A pure Lua "Actor Model" framework
--

--============================================================================
-- An actor need a reactor for event trigger.
--
-- get the choose of reactor from environment variable.
local reactor_env = os.getenv("LUACTOR_REACTOR")
local reactor
if reactor_env == 'uloop' then
    reactor = require "luactor.reactor.uloop"
else
    -- for now, default reactor driver is luaevent
    reactor = require "luactor.reactor.luaevent"
end
--============================================================================
-- declare internal objects
local __reactor             -- reactor object
local __mqueue              -- message queue
local __actors              -- actor object pool
local __actors_num          -- number of actors
local __lut_thread_actor    -- thread to actor look-up table

--============================================================================
-- helper methods for luactor

local pack = table.pack or function(...) return {n = select("#", ...), ...} end

------------------------------------------------------------------------------
-- open a coroutine safely (for lua 5.1)
-- modified from coxpcall project
--
-- Coroutine safe xpcall and pcall versions modified for luactor
--
-- Encapsulates the protected calls with a coroutine based loop, so errors can
-- be dealed without the usual Lua 5.x pcall/xpcall issues with coroutines
-- yielding inside the call to pcall or xpcall.
--
-- Authors: Roberto Ierusalimschy and Andre Carregal
-- Contributors: Thomas Harning Jr., Ignacio Burgueño, Fabio Mascarenhas
--
-- Copyright 2005 - Kepler Project (www.keplerproject.org)
-------------------------------------------------------------------------------

local handle_return_value = function (err, co, status, ...)
    if not status then
        return false, err(debug.traceback(co, (...)), ...)
    end
    return true, ...
end

local perform_resume = function (err, co, ...)
    return handle_return_value(err, co, coroutine.resume(co, ...))
end

local safe_coroutine_create = function(f)
    local res, thread = pcall(coroutine.create, f)
    if not res then
        local newf = function(...) return f(...) end
        thread = coroutine.create(newf)
    end
    return thread
end

--------------------------------------------------------------------------------
-- Simple Queue

local queue = {}

queue.new = function()
    return {first = 0, last = -1}
end

queue.push = function (q, value)
    local first = q.first - 1
    q.first = first
    q[first] = value
end
    
queue.pop = function (q)
    local last = q.last
    if q.first > last then error("queue is empty") end
    local value = q[last]
    q[last] = nil         -- to allow garbage collection
    q.last = last - 1
    return value
end

queue.empty = function (q)
    return q.first > q.last and true or false
end

-------------------------------------------------------------------------------
-- get running actor's object
local get_myself = function ()
    local myself_thread = coroutine.running()
    local me = __lut_thread_actor[myself_thread]
    -- TODO: what if I am main thread
    return me
end

-------------------------------------------------------------------------------
-- resume an actor and handle its error.
local resume_actor = function (actor, ...)
    local actor = actor
    if type(actor) == 'string' then
        actor = __actors[actor]
    end

    local me = get_myself()
    local status, err = perform_resume(pack, actor.thread, ...)
    -- send the failed actor to its creator. if it creator is
    -- dead, then just destory it.
    if status == false and actor.creator ~= nil then
        queue.push(__mqueue, {
            '_',                   -- sender
            actor.creator,         -- receiver
            "actor_error",         -- command
            {
                actor = actor,
                error = err,
            }                      -- error message
        })
    end

    -- if an actor is dead or failed, destory the relevant info.
    if coroutine.status(actor.thread) == 'dead'
       or status == false
    then
        __actors[actor.name] = nil
        __actors_num = __actors_num - 1
        __lut_thread_actor[actor.thread] = nil
    end
end

------------------------------------------------------------------------------
-- event register handlers
local event_handlers = {
    timeout = function(sender, receiver, ev_name, timeout_interval)
        __reactor.register_timeout_cb(
            ev_name,
            function (events)
                -- unregister the event if the actor was dead.
                --
                --  XXX: what if the name is reused?
                --       or any other problems?
                if __actors[receiver] == nil then
                    __reactor.unregister_event(ev_name)
                end
                -- push event message to __mqueue
                queue.push(__mqueue, {sender, receiver, "timeout",
                    {
                        timeout_interval = timeout_interval,
                    }
                })
                resume_actor('_')
            end, timeout_interval
        )
    end,
    fd = function(sender, receiver, ev_name, fd, event)
        __reactor.register_fd_event(
            ev_name,
            function (events)

                -- unregister the event if the actor was dead.
                --
                --  XXX: what if the name is reused?
                --       or any other problems?
                if __actors[receiver] == nil then
                    __reactor.unregister_event(ev_name)
                end
                -- push event message to __mqueue
                queue.push(__mqueue, {sender, receiver, "fd_event",
                    {
                        event = event,
                        fd = fd,
                    }
                })
                resume_actor('_')
            end,
            fd, event
        )
    end,
}

------------------------------------------------------------------------------
-- schedular coroutine
-- 
-- process the message queue until it's empty, then yield out.
local process_mqueue = function ()
    local finish = false
    while not finish do
        -- process the message in the queue one by one until empty.
        while not queue.empty(__mqueue) do
            local sender, receiver, command, message = unpack(queue.pop(__mqueue))
            if __actors[receiver] == nil then
                -- drop this message
                -- TODO: what we can do before the message is dropped.
            else
                resume_actor(receiver, sender, command, message)

                -- if there is no running actor, everything should be done.
                if __actors_num <= 0 then
                    __reactor.cancel()
                    finish = true
                    break
                end
            end
        end
        -- yield out to mainthread to wait next event.
        coroutine.yield()
    end
end

--============================================================================
-- Luactor methods
--
-- like *coroutine*, all *luactor* method are contained within a table.

local actor = {}

------------------------------------------------------------------------------
-- initialize internal objects
__reactor = reactor       -- reactor object
__mqueue = queue.new()    -- message queue
__actors = {}             -- actor object pool
__actors_num = 0          -- number of actors
__lut_thread_actor = {}   -- thread to actor look-up table

------------------------------------------------------------------------------
-- create an actor
actor.create = function (name, f, ...)
    if __actors[name] ~= nil then
        error("the actor name has been registered")
    end

    local new_actor = {}
    new_actor.name = name
    __actors_num = __actors_num + 1

    local thread = safe_coroutine_create(f)

    new_actor.thread = thread

    local me = get_myself()
    new_actor.creator = me and me.name

    -- save the actor to the global table
    __actors[name] = new_actor
    __lut_thread_actor[thread] = new_actor

    return new_actor
end

------------------------------------------------------------------------------
-- send a message to another actor
-- 
-- XXX: should we yield out when receive a message?
actor.send = function (receiver, command, message)
    local me = get_myself()

    -- didn't check receiver's name because it might be create later.

    -- push message to global message queue
    queue.push(__mqueue, {
        me and me.name or "_",  -- sender
        receiver,               -- receiver
        command,                -- command
        message,                -- message
    })

end

------------------------------------------------------------------------------
-- wait a message
actor.wait = function (handlers)
    -- handlers is the set of the message you want listen
    local sender, command, message = coroutine.yield()
    if command ~= nil
       and handlers[command] ~= nil
       -- XXX:how to make sure handlers[command] is function like?
    then
        handlers[command](message, sender)
    else
        -- XXX: should we raise an error here? or, we can return a
        --      command `__unknown` or `__index` as a *meta method*.
        error("unknown message command type")
    end
end

------------------------------------------------------------------------------
-- register an event
actor.register_event = function (ev_type, ev_name, ...)
    local me = get_myself()
    local event_handler = event_handlers[ev_type]

    if event_handler ~= nil then
        -- XXX: any other possibilities for sender and receiver?
        event_handler('_', me.name, ev_name, ...)
    else
        error('unknonw event type: '..ev_type)
    end
end

------------------------------------------------------------------------------
-- unregister an event
actor.unregister_event = function (ev_name)
    __reactor.unregister_event(ev_name)
end

------------------------------------------------------------------------------
-- start an actor
actor.start = function (actor, ...)
    resume_actor(actor, ...)
end

------------------------------------------------------------------------------
-- run schedular and event loop
actor.run = function ()
    local thread = safe_coroutine_create(process_mqueue)

    local schedular_actor = {}
    schedular_actor.name = '_'
    schedular_actor.thread = thread

    __lut_thread_actor[thread] = schedular_actor

    -- TODO: the schedular coroutine should have its creator and the
    -- error should be processed.
    -- schedular_actor.creater = ?

    __actors['_'] = schedular_actor
    resume_actor(schedular_actor)

    -- run until there are no __actors
    while __actors_num > 0 do
        __reactor.run()
    end

    -- TODO: clean up everything
end

return actor
