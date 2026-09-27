local SOCKET_TICK_TIME = 0.1 			-- check socket data interval
local SOCKET_RECONNECT_TIME = 5			-- socket reconnect try interval
local SOCKET_CONNECT_FAIL_TIMEOUT = 10	-- socket failure timeout

local STATUS_CLOSED = "closed"
local STATUS_NOT_CONNECTED = "Socket is not connected"
local STATUS_ALREADY_CONNECTED = "already connected"
local STATUS_ALREADY_IN_PROGRESS = "Operation already in progress"
local STATUS_TIMEOUT = "timeout"

local socket = require("socket.core")

--
-- SocketTCP
--
SocketTCP = class()

SocketTCP.EVENT_DATA = "SOCKET_TCP_DATA"
SocketTCP.EVENT_CLOSE = "SOCKET_TCP_CLOSE"
SocketTCP.EVENT_CLOSED = "SOCKET_TCP_CLOSED"
SocketTCP.EVENT_CONNECTED = "SOCKET_TCP_CONNECTED"
SocketTCP.EVENT_CONNECT_FAILURE = "SOCKET_TCP_CONNECT_FAILURE"

function SocketTCP:ctor(__host, __port, __retryConnectWhenFailure)
  self.host = __host
  self.port = __port
	self.tickScheduler = nil			-- timer for data
	self.reconnectScheduler = nil		-- timer for reconnect
	self.connectTimeTickScheduler = nil	-- timer for connect timeout
	self.name = 'SocketTCP'
	self.tcp = nil
	self.isRetryConnect = __retryConnectWhenFailure
	self.isConnected = false
end

function SocketTCP:setName( __name )
	self.name = __name
end

function SocketTCP:setTickTime(__time)
	SOCKET_TICK_TIME = __time
end

function SocketTCP:setReconnTime(__time)
	SOCKET_RECONNECT_TIME = __time
end

function SocketTCP:setConnFailTime(__time)
	SOCKET_CONNECT_FAIL_TIMEOUT = __time
end

function SocketTCP:connect(__host, __port, __retryConnectWhenFailure)
	if __host then self.host = __host end
	if __port then self.port = __port end
	if __retryConnectWhenFailure ~= nil then self.isRetryConnect = __retryConnectWhenFailure end
	assert(self.host or self.port, "Host and port are necessary!")
	self.tcp = socket.tcp()
	self.tcp:settimeout(0)

	local function __checkConnect()
		local __succ = self:_connect() 
		if __succ then
			self:_onConnected()
		end
		return __succ
	end

	if not __checkConnect() then
		-- check whether connection is success
		-- the connection is failure if socket isn't connected after SOCKET_CONNECT_FAIL_TIMEOUT seconds
		local __connectTimeTick = function ()
			if self.isConnected then return end
			self.waitConnect = self.waitConnect or 0
			self.waitConnect = self.waitConnect + SOCKET_TICK_TIME
			if self.waitConnect >= SOCKET_CONNECT_FAIL_TIMEOUT then
				self.waitConnect = nil
				self:close()
				self:_connectFailure()
			end
			__checkConnect()
		end
		self.connectTimeTickScheduler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(__connectTimeTick,SOCKET_TICK_TIME, false)
	end
end

function SocketTCP:send(__data)
	return self.tcp:send(__data)
end

function SocketTCP:close()
	self.tcp:close()
  self.isConnected = false
	if self.connectTimeTickScheduler then 
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.connectTimeTickScheduler)
    self.connectTimeTickScheduler = nil
  end
	if self.tickScheduler then 
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.tickScheduler)
    self.tickScheduler = nil
  end
	if self.reconnectScheduler then 
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.reconnectScheduler)
    self.reconnectScheduler = nil
  end
  NotificationManager:dispatchEvent(Event.new(SocketTCP.EVENT_CLOSE))
end

-- disconnect on user's own initiative.
function SocketTCP:disconnect()
	self:_disconnect()
	self.isRetryConnect = false -- initiative to disconnect, no reconnect.
end

function SocketTCP:dispose()
  if self.tcp then
    self.tcp:close()
  end
	if self.connectTimeTickScheduler then 
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.connectTimeTickScheduler)
    self.connectTimeTickScheduler = nil
  end
	if self.tickScheduler then 
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.tickScheduler)
    self.tickScheduler = nil
  end
	if self.reconnectScheduler then 
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.reconnectScheduler)
    self.reconnectScheduler = nil
  end
end

--------------------
-- private
--------------------

--- When connect a connected socket server, it will return "already connected"
-- @see: http://lua-users.org/lists/lua-l/2009-10/msg00584.html
function SocketTCP:_connect()
	local __succ, __status = self.tcp:connect(self.host, self.port)
	return __succ == 1 or __status == STATUS_ALREADY_CONNECTED
end

function SocketTCP:_disconnect()
	self.isConnected = false
	self.tcp:shutdown()
  NotificationManager:dispatchEvent(Event.new(SocketTCP.EVENT_CLOSED))
end

function SocketTCP:_onDisconnect()
	self.isConnected = false
  NotificationManager:dispatchEvent(Event.new(SocketTCP.EVENT_CLOSED))
	self:_reconnect()
end

-- connecte success, cancel the connection timerout timer
function SocketTCP:_onConnected()
	self.isConnected = true
  NotificationManager:dispatchEvent(Event.new(SocketTCP.EVENT_CONNECTED))
	if self.connectTimeTickScheduler then 
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.connectTimeTickScheduler)
    self.connectTimeTickScheduler = nil
  end

	local __tick = function()
		while true do
			local __body, __status, __partial = self.tcp:receive("*a")	-- read the package body
			--print("body:", __body, "__status:", __status, "__partial:", __partial)
      if __status == STATUS_CLOSED or __status == STATUS_NOT_CONNECTED then
        self:close()
        if self.isConnected then
          self:_onDisconnect()
        else 
          self:_connectFailure()
        end
        return
      end
      if 	(__body and string.len(__body) == 0) or
				(__partial and string.len(__partial) == 0) then 
        return 
      end
			if __body and __partial then __body = __body .. __partial end
      NotificationManager:dispatchEvent(Event.new(SocketTCP.EVENT_DATA, {data=(__partial or __body), partial=__partial, body=__body}))
		end
	end

	-- start to read TCP data
	self.tickScheduler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(__tick, SOCKET_TICK_TIME, false)
end

function SocketTCP:_connectFailure(status)
  NotificationManager:dispatchEvent(Event.new(SocketTCP.EVENT_CONNECT_FAILURE))
	self:_reconnect()
end

-- if connection is initiative, do not reconnect
function SocketTCP:_reconnect(__immediately)
	if not self.isRetryConnect then return end
	if __immediately then self:connect() return end
	if self.reconnectScheduler then 
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.reconnectScheduler)
    self.reconnectScheduler = nil
  end
	local __doReConnect = function ()
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.reconnectScheduler)
    self.reconnectScheduler = nil
		self:connect()
	end
	self.reconnectScheduler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(__doReConnect, SOCKET_RECONNECT_TIME, false)
end
