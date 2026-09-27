require "hecore.display.Director"
require "canon.request.Communication"
require "canon.request.BaseRequest"
require "canon.request.GetServerStatusRequest"
require "canon.request.LoginServerRequest"
require "canon.request.GetUserBagInfo"


local function testCreateUser()
    local params = {avatarId=1,nickName="11111",inviteCode=""}
    local request = CreateUser.new(params, rpc.SendingPriority.kHigh)
    request:start()
end

local function testGetUserBagInfo()
    local params = {}
    local request = GetUserBagInfo.new(params, rpc.SendingPriority.kHigh)
    request:start()
end

local function testGetServerStatus()
	local params = {}
	local request = GetServerStatusRequest.new(params, rpc.SendingPriority.kHigh)
	request:start()
end

local function afterLoginServer(event)
  testGetUserBagInfo()
end

local function testLoginServer()
	local params = {}
	local request = LoginServerRequest.new(params, rpc.SendingPriority.kHigh)
    request:addEventListener(RequestNotifyEnum.LoginServerSucceed, afterLoginServer)
	request:start()
end

local function initCommunicatonSuccess()
	he_log_info("init Communication success")
	-- need regist event handler after init success
	Communication:getInstance():registEventHandler("TestEventHandler")
	--test
	testGetServerStatus()
	testLoginServer()
end

local function initCommunicaton()
	local comm = Communication:getInstance()
	local function initCommunicatonError(event)
		comm:removeEventListener(CommunicationInitEvent.kComplete, initCommunicatonSuccess)
		comm:removeEventListener(CommunicationInitEvent.kInitSessionError, initCommunicatonError)
		comm:removeEventListener(CommunicationInitEvent.kLoginError, initCommunicatonError)
		-- TODO prompt and retry
		CCMessageBox(event.name, "init Communication error")
	end
	comm:addEventListener(CommunicationInitEvent.kInitSessionError, initCommunicatonError)
	comm:addEventListener(CommunicationInitEvent.kLoginError, initCommunicatonError)
	comm:addEventListener(CommunicationInitEvent.kComplete, initCommunicatonSuccess)
	comm:init()
end

local function startGame()
	initCommunicaton()
end

startGame()


