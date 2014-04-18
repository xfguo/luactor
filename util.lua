--[[
LuCI - Utility library

Description:
Several common useful Lua functions

License:
Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

]]--

local string = require "string"
local getmetatable, setmetatable = getmetatable, setmetatable
local tostring, type, assert = tostring, type, assert
local ipairs, pairs, next, loadstring = ipairs, pairs, next, loadstring
local error = error

module("util")

-- Pythonic string formatting extension
--
getmetatable("").__mod = function(a, b)
	if not b then
		return a
	elseif type(b) == "table" then
		for k, _ in pairs(b) do if type(b[k]) == "userdata" then b[k] = tostring(b[k]) end end
		return a:format(unpack(b))
	else
		if type(b) == "userdata" then b = tostring(b) end
		return a:format(b)
	end
end


--
-- Class helper routines
--

-- Instantiates a class
local function _instantiate(class, ...)
	local inst = setmetatable({}, {__index = class})

	if inst.__init__ then
		inst:__init__(...)
	end

	return inst
end

--- Create a Class object (Python-style object model).
-- The class object can be instantiated by calling itself.
-- Any class functions or shared parameters can be attached to this object.
-- Attaching a table to the class object makes this table shared between
-- all instances of this class. For object parameters use the __init__ function.
-- Classes can inherit member functions and values from a base class.
-- Class can be instantiated by calling them. All parameters will be passed
-- to the __init__ function of this class - if such a function exists.
-- The __init__ function must be used to set any object parameters that are not shared
-- with other objects of this class. Any return values will be ignored.
-- @param base	The base class to inherit from (optional)
-- @return		A class object
-- @see			instanceof
-- @see			clone
function class(base)
	return setmetatable({}, {
		__call  = _instantiate,
		__index = base,
	})
end

--- Test whether the given object is an instance of the given class.
-- @param object	Object instance
-- @param class		Class object to test against
-- @return			Boolean indicating whether the object is an instance
-- @see				class
-- @see				clone
function instanceof(object, class)
	local meta = getmetatable(object)
	while meta and meta.__index do
		if meta.__index == class then
			return true
		end
		meta = getmetatable(meta.__index)
	end
	return false
end
