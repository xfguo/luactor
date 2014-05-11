TODO List
=========

- 任何一个Acotr有且只有send和listen两个自有方法用于发送和监听消息，Scheduler的所有其他部分都应该是不可见的。
- 广播通过将一条message发给多个Actor实现
- 每个message包含session和type用于实现REQ/RESP等其他模式
  - session用于标识一个有上下文的跨Actor的请求
  - type用于区分请求的类型，REQ or RSP
- Scheduler由唯一的，不可占用的name，用于其他actor和Scheduler通信
- Scheduler是否有必要支持销毁一个Actor?
- 一个Actor应该只有一个函数入口点，应该取消对Actor.__init__的执行，或是用__init__代替callback。
- 用户无法看到Schedular，也不用声明，Schedular由最开始的Actor创建。
- send操作应该把to和cmd从消息里分离出来。
- sch改为_ ?用来代表系统？
