# LuActor - Actor Model for Lua

一个纯Lua实现的Actor Model的框架。

Lua类的实现来自luci project。

*这个项目的想法受到了gevent、ratchet和@cloudwu的skynet以及其博客文章的启发*

## Requirments

- Lua 5.1

## Features

### Implemented

- 每个Actor支持同时监听多个有限范围的消息，并且可以向任何其他Actor无阻塞的发送消息
- Actor有唯一的ID或名字，作为他人发送消息到自己的标识。
- Scheduler有唯一的队列处理所有其他Actor发来的消息，且一次只处理一个消息。

### TODO

- Actor向Scheduler注册timeout、signal或者fd等事件，事件触发后,Scheduler会发送注册时消息到自己的mailbox
- 广播通过将一条message发给多个Actor实现
- 每个message包含session和type用于实现REQ/RESP等其他模式
  - session用于标识一个有上下文的跨Actor的请求
  - type用于区分请求的类型，REQ or RSP

## Examples

### Ping-Pong

Two actors Ping and Pong receive and send message to each other.

    lua example/pingpang.lua

----

Author: Xiongfei Guo <xfguo@credosemi.com>
