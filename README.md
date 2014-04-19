LuActor - Actor Model for Lua
=============================

一个纯Lua（至少目前）实现的[Actor Model](http://en.wikipedia.org/wiki/Actor_model)的框架。

这个项目的想法受到了以下项目和文章的启发，在此表示感谢

- @cloudwu的[skynet](https://github.com/cloudwu/skynet)以及其[博客](blog.codingnow.com)文章
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

LuActor use a [reactor](http://en.wikipedia.org/wiki/Reactor_pattern) to monitor all external events (Timeout/FD/...).

For now, it (only) support:

- [luaevent](https://github.com/harningt/luaevent)

*reactor.lua* is an abstract layer of the reactor library, so it is very easy to port to others. Like lua-ev/uloop(OpenWrt)/..., or epoll/kqueue/...

Features/Ideas
--------------

### Implemented

- 每个Actor支持同时监听多个有限范围的消息，并且可以向任何其他Actor无阻塞的发送消息
- Actor有唯一的ID或名字，作为他人发送消息到自己的标识。
- Scheduler有唯一的队列处理所有其他Actor发来的消息，且一次只处理一个消息。
- Actor向Scheduler注册timeout、signal或者fd等事件，事件触发后，Scheduler会唤醒对应的Actor
- Scheduler并不负责接收socket等操作，只负责监听和通知相应事件的发生。Actor才负责这一点。

### TODO

- 广播通过将一条message发给多个Actor实现
- 每个message包含session和type用于实现REQ/RESP等其他模式
  - session用于标识一个有上下文的跨Actor的请求
  - type用于区分请求的类型，REQ or RSP
- Scheduler由唯一的，不可占用的name，用于其他actor和Scheduler通信
- 任何Actor可以通过发送指定消息给Scheduler来实现以下功能
  - 新建和销毁一个Actor
  - 新建一个监听fd或者系统信号量的事件，或者一个超时事件

Examples
--------

### Ping-Pong

Two actors **Ping** and **Pong** receive and send message to each other.

    lua example/pingpang.lua

### Echo Server (TCP)

An actor **TcpManager** responses to listen TCP socket, when a new connection is
established, create a new **EchoActor** and let it handle that connection.

Run echo server:

    lua example/echo-server.lua

Then, run:

    telnet 127.0.0.1 8080

You can open multiple telnet to test it.

Author
------

- Xiongfei Guo <xfguo@credosemi.com>
