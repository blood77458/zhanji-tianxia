require "canon.request.SocketTCP"
require "canon.request.GetSocketServerRequest"
require "canon.constants.MethodDict"
--[[
local socket_address = "10.130.130.27"
local socket_port = 443

local socket_address = "10.130.140.198"
local socket_port = 443
]]
local compress_size_level = 2048
local get_server_info_interval = 10
--
-- TCPManager
--

TCPManager = class()
local _sharedInstance = nil
function TCPManager:sharedInstance()
	if not _sharedInstance then
		_sharedInstance = TCPManager.new()
	end
	return _sharedInstance
end

function TCPManager:ctor(  )
  self.socket_address = nil
  self.socket_port = nil
  self.token = nil
  self.getServerInfoEntry = nil
  self._socket = nil
  self._data = nil
  
  local function onStatus(event)
    self:statusChanged(event)
  end
  local function onData(event)
    self:dataReceived(event)
  end
  NotificationManager:addEventListener(SocketTCP.EVENT_CONNECTED, onStatus)
  NotificationManager:addEventListener(SocketTCP.EVENT_CLOSE, onStatus)
  NotificationManager:addEventListener(SocketTCP.EVENT_CLOSED, onStatus)
  NotificationManager:addEventListener(SocketTCP.EVENT_CONNECT_FAILURE, onStatus)
  NotificationManager:addEventListener(SocketTCP.EVENT_DATA, onData)
  
  local function globalErrorCallback()
    --print("_____________globalErrorCallback")
    self:closeConnect()
  end
  NotificationManager:addEventListener("GLOBAL_ERROR", globalErrorCallback)
  
  local function notificationHandler(name)
    if("APP_ENTER_BACKGROUND" == name) then
      self:closeConnect()
    elseif("APP_ENTER_FOREGROUND" == name) then
      self:connectToServer()
    end
  end
  CCNotificationCenter:sharedNotificationCenter():registerScriptObserver(notificationHandler)
  
  local function networkErrorCallback(evt)
    if evt.data.method ~= "getSocketServer" then
      return
    end
    local function retryFunc()
      if self.retryEntry then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.retryEntry)
        self.retryEntry = nil
      end
      self:connectToServer()
    end
    if not self.retryEntry then
      self.retryEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(retryFunc, 4.0, false)
    end
  end
  NotificationManager:addEventListener("NETWORK_ERROR", networkErrorCallback)
end

function TCPManager:connectToServer()
  if self._socket and self._socket.isConnected then
    return
  end
  local function getSocketServerSucceed(event)
    if self.getServerInfoEntry then
      CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.getServerInfoEntry)
      self.getServerInfoEntry = nil
    end
    print(table.tostring(event.data))
    self.socket_address = event.data.serverAddress
    self.socket_port = event.data.serverPort
    self.token = event.data.token
    if not self._data then
      self._data = SocketTCPData:create()
    else
      self._data:resetData()
    end
    
    local function connectSocket()
      if self.socketConnectEntry then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.socketConnectEntry)
        self.socketConnectEntry = nil
      end
      self._socket = SocketTCP.new(self.socket_address, self.socket_port, false)
      self._socket:connect()
    end
    if not self.socketConnectEntry then
      self.socketConnectEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(connectSocket, 1.0, false)
    end
  end
  local function getSocketServerFailed(event)
    local function getServerInfo()
      self:connectToServer()
    end
    if not self.getServerInfoEntry then
      self.getServerInfoEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(getServerInfo, get_server_info_interval, false)
    end
  end
  local params = {}
  local request = GetSocketServerRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.GetSocketServerSucceed, getSocketServerSucceed)
  request:addEventListener(RequestNotifyEnum.GetSocketServerFailed, getSocketServerFailed)
  request:start() 
  
  
end

function TCPManager:dispose()
  if self.retryEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.retryEntry)
  end
end

function TCPManager:closeConnect()
  if self._socket then
    self._socket:close()
  end
  if self.getServerInfoEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.getServerInfoEntry)
    self.getServerInfoEntry = nil
  end
  if self.socketConnectEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.socketConnectEntry)
    self.socketConnectEntry = nil
  end
end

function TCPManager:sendData(data)
  local bodyData = amf3.encode(data)
  local compressed = false
  if string.len(bodyData) >= compress_size_level then
    bodyData = compress(bodyData)
    compressed = true
  end
  bodyData = SocketTCPData:constructSendData(bodyData, compressed)
  return self._socket:send(bodyData)
end

function TCPManager:statusChanged(event)
  print(event.name)
  if event.name == SocketTCP.EVENT_CONNECTED then
    local aData = {serverAddress = self.socket_address, serverPort = self.socket_port, token = self.token, uid = tonumber(DataManager.getCurrUser().uid), method = MethodDict.METHOD_LOGIN}
    self:sendData(aData)
  elseif event.name == SocketTCP.EVENT_CLOSE then
    --
  elseif (event.name == SocketTCP.EVENT_CLOSED) or (event.name == SocketTCP.EVENT_CONNECT_FAILURE) then
    self:connectToServer()
  end
end

function TCPManager:dataReceived(event)
  --print("____date received: " .. string.len(event.data.data) .. " bytes")
  self._data:insertData(event.data.data)
  local bodyData
  local compressed
  while(true) do
    bodyData, compressed = self._data:getPieceOfData()
    if bodyData then
      if compressed then
        bodyData = uncompress(bodyData)
      end
      bodyData = amf3.decode(bodyData)
      
      --print(table.tostring(bodyData))
      if (bodyData.method == MethodDict.METHOD_LOGIN) and (bodyData.retCode ~= 0) then
        self:closeConnect()
        self:connectToServer()
      else
        --通知外界
        NotificationManager:dispatchEvent(Event.new(bodyData.method, bodyData))
      end
    else
      break
    end
  end
end

