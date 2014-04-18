util = require "util"

Queue = util.class()

Queue.__init__ = function (self)
    self.__queue = {}
    self.first = 0
    self.last = -1
end

Queue.push = function (self, value)
    local first = self.first - 1
    self.first = first
    self.__queue[first] = value
end
    
Queue.pop = function (self)
    local last = self.last
    if self.first > last then error("queue is empty") end
    local value = self.__queue[last]
    self.__queue[last] = nil         -- to allow garbage collection
    self.last = last - 1
    return value
end

Queue.empty = function (self)
    return self.first > self.last and true or false
end
