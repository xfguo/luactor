LuActor - Actor Model for Lua
=============================

[![Build Status](https://travis-ci.org/xfguo/luactor.svg?branch=master)](https://travis-ci.org/xfguo/luactor) [![Coverage Status](https://coveralls.io/repos/xfguo/luactor/badge.png?branch=master)](https://coveralls.io/r/xfguo/luactor?branch=master)

A pure Lua (at least for now) [Actor Model](http://en.wikipedia.org/wiki/Actor_model) framework.

**Luactor** is based on **coroutine** in Lua.

Inspired by these projects and articles, thanks for all of them.

- [@cloudwu](https://github.com/cloudwu)'s [skynet](https://github.com/cloudwu/skynet) and his [blog](http://blog.codingnow.com).
- [gevent](http://www.gevent.org/)
- [ratchet](https://github.com/icgood/ratchet)

License
-------

Licensed under the Apache License, Version 2.0. See *LICENSE*.

Dependencies
------------

- Lua 5.1
- A reactor library. (See *Reactor/Dispatcher Driver*)

*(I don't test it but Lua 5.2 might work.)*

### Reactor/Dispatcher Driver

**LuActor** use a [**reactor**](http://en.wikipedia.org/wiki/Reactor_pattern) to monitor all external events (Timeout/FD/...).

For now, it support:

- [luaevent](https://github.com/harningt/luaevent)
  - luaevent v0.4.3 has been tested, older verison may have some issues (At least for v0.3.2 on Ubuntu 12.04). So please make sure you have the right version of luaevent.
- [libubox:uloop](https://github.com/xfguo/libubox)
  - NOTE: **uloop** is a part of libubox which is design for OpenWrt(a GLib like library). For now, it just test with the modified version of libubox. Since the lua binding of uloop is missing the fd operation part.

`reactor/reactor_template.lua` is a template of the reactor library. If you are using other event-driven library(eg. lua-ev/uloop(OpenWrt)/..., or epoll/kqueue/...), you just need implement the methods in this file.

**Any other patch or pull request of a reactor implementation is welcome.**

How to Use
----------

### Summary

All the methods are contained within a lua *table* (like *coroutine*).

The methods include:

- `create` - create an actor
- `start` - start an actor
- `register_event` - register an event
- `unregister_event` - unregister an event
- `send` - send a message to another actor
- `wait` - wait a message
- `run` - run

### Loading the library

Before you use **luactor**, you should set the environment variable `LUACTOR_REACTOR` to `luaevent` or `uloop` to choose the **reactor**. If `LUACTOR_REACTOR` is not set, the default **rector** is `luaevent` for now.

    local actor = require "luactor"

### Create a new actor

To create a new actor:

    new_actor_obj = actor.create(name, f)

- `name` is the actor's name, and is unique, which is for receiving message from other actor.
- `f` is the Lua function.

### Start the actor

After you create an actor, you can just start it.

    actor.start(actor_obj, ...)

- `actor_obj` is the return value when you run `actor.create`.
- `...` is the arguments you want to pass to the function when you registered it.

### Send a message to another actor **unblocked**

To send a message, a lua object of any type, to another actor.

    actor.send(receiver, command, message)

- `receiver` is the name of an actor when it created.
- `command` is a string for declare a message type.
- `message` is the message object you want to send to *receiver*. It could be any type of lua object, include nil.

### Wait and handle a message **blocked**

Use `actor.wait` like:

    actor.wait({
        command1 =
            function (message, sender)
                -- handle message
            end,
        [
        command2 =
            function (message, sender)
            end,
        ...
        ]
    })

`actor.wait` accept a Lua table which the *key* is the command it want to receive and the *value* is a Lua function to process the message.



### Register and Unregister an Event

An *actor* can register a fd/timeout event, so when that event is triggered. **luactor** will send a message to the *actor*. The `command` of the message is `fd` or `timeout`.

To register an event:

    actor.register(ev_type, ev_name, ...)

- `ev_type` is the type of the event. For now, **luactor** support `fd` or `timeout`.
- `ev_name` is the unique name of this event in the actor. if the event triggerd, *luactor* will send a message to the actor which the command is the *ev_name*.
- `...` is the arguments of event register.
  - For `fd` event, it accept `fd` and `event` two arguments. `fd` is the file descriptor. `event` is the event type you want to trigger, can be `'read'` or `'write'`.
  - For `timeout` event, only one argument `timeout` is needed.

To unregister the event:

    actor.unregister(ev_name)

- `ev_name` is the unique name when registered.

### Start running

To let all actors start running, just:

    actor.run()

This method will be blocked until all the actors exited.

Examples
--------

Make sure you set the environment variable `LUACTOR_REACTOR` to choose the **reactor**, see chapter **Loading the library**.

### Ping-Pong

Two actors **ping** and **pong** receive and send message to each other.

    lua example/pingpang.lua

### Timeout

An actor register a **timeout** event, then wait a timeout message.

    lua example/timeout.lua

### Echo Server (TCP)

An actor **tcp_manager** responses to listen TCP socket, when a new connection is
established, create a new **echo_actor** and let it handle that connection.

Run echo server:

    lua example/echo-server.lua

Then, run:

    telnet 127.0.0.1 8080

You can open multiple telnet to test it. 

Some operations for echo server.
  - If `exit` is send to echo server, all actors will **exit**.
  - If `raise` is send to echo server, the actor will raise an error but **tcp_manager** will handle it.

Author
------

- Xiongfei Guo <xfguo@credosemi.com>
