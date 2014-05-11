LuActor - Actor Model for Lua
=============================

[![Build Status](https://travis-ci.org/xfguo/luactor.svg?branch=master)](https://travis-ci.org/xfguo/luactor) [![Coverage Status](https://coveralls.io/repos/xfguo/luactor/badge.png?branch=master)](https://coveralls.io/r/xfguo/luactor?branch=master)

一个纯Lua（至少目前）实现的[Actor Model](http://en.wikipedia.org/wiki/Actor_model)的框架。

这个项目的想法受到了以下项目和文章的启发，在此表示感谢

- [@cloudwu](https://github.com/cloudwu)的[skynet](https://github.com/cloudwu/skynet)以及其[博客](blog.codingnow.com)文章
- [gevent](http://www.gevent.org/)
- [ratchet](https://github.com/icgood/ratchet)

另外

- Lua类的实现来自[LuCI Project](http://luci.subsignal.org)

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
  - luaevent v0.4.3 has been tested, older verison may have some issuses (At least for v0.3.2 on Ubuntu 12.04). So please make sure you have the right version of luaevent.
- [libubox:uloop](https://github.com/xfguo/libubox)
  - NOTE: **uloop** is a part of libubox which is design for OpenWrt(a GLib like library). For now, it just test with the modified version of libubox. Since the lua binding of uloop is missing the fd operation part.

`reactor.lua` is an abstract layer of the reactor library, so it is very easy to port to others. Like lua-ev/uloop(OpenWrt)/..., or epoll/kqueue/...

Features/Ideas
--------------

### Implemented

- 每个Actor支持同时监听有限个消息，并且可以向任何其他Actor无阻塞的发送消息
- Actor有唯一的ID或名字，作为他人发送消息到自己的标识。
- Scheduler有唯一的队列处理所有其他Actor发来的消息，且一次只处理一个消息。
- Actor向Scheduler注册timeout、signal或者fd等事件，事件触发后，Scheduler会唤醒对应的Actor
- Scheduler并不负责接收socket等操作，只负责监听和通知相应事件的发生。Actor才负责真实事件的处理。
- 任何Actor可以通过发送指定消息给Scheduler来实现以下功能
  - 新建一个Actor
  - 新建一个监听fd或者系统信号量的事件，或者一个超时事件
- 错误处理：
  - 如果一个Actor出错了，那么Schedular在捕获这个错误之后销毁对应的Actor。-
  - 而在销毁之前，Schedular会发送相关的错误消息和Actor自身到创建这个Actor的父Actor，由父Actor进行一些错误的处理和善后工作。
  - 如果最初被Scheduler被创建的Actor出错了，则直接raise这个错误，由上一级处理。

### TODO

See `TODO.md`

Examples
--------

### Ping-Pong

Two actors **Ping** and **Pong** receive and send message to each other.

    lua example/pingpang.lua [luaevent|uloop] # choose the reactor here

### Timeout

An actor register a **timeout** event, then wait a timeout message.

    lua example/timeout.lua [luaevent|uloop] # choose the reactor here

### Echo Server (TCP)

An actor **TcpManager** responses to listen TCP socket, when a new connection is
established, create a new **EchoActor** and let it handle that connection.

Run echo server:

    lua example/echo-server.lua [luaevent|uloop] # choose the reactor here

Then, run:

    telnet 127.0.0.1 8080

You can open multiple telnet to test it. 
    
Some operations for echo server.
  - If `exit` is send to echo server, all actors will **exit**.
  - If `raise` is send to echo server, the actor will raise an error but **TcpManager** will handle it.

Author
------

- Xiongfei Guo <xfguo@credosemi.com>
