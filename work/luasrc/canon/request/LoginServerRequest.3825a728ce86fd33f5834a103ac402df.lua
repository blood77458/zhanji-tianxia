require "canon.request.BaseRequest"

LoginServerRequest = class(BaseRequest)

function LoginServerRequest:ctor(params, priority)
	self.endpoint = "loginServer"
    self.uid = nil
    self.data = nil
    
	Communication:getInstance():putOthers("serverId", self.params.serverId)
end

function LoginServerRequest:onSuccess(data)
	he_log_info("LoginServerRequest success " .. table.serialize(data))
	-- Communication:getInstance():putOthers("serverId", self.params.serverId)
    self:dispatchEvent(Event.new(RequestNotifyEnum.LoginServerSucceed,data))
end

function LoginServerRequest:onError(error)
	self:dispatchEvent(Event.new(RequestNotifyEnum.LoginServerFailed,error))
end

--
GetServerTimeStampRequest = class(BaseRequest)

function GetServerTimeStampRequest:ctor(params, priority)
	self.endpoint = "getServerTimeStamp"
	self.data = nil
	self.params = params
	self.showLoading = false
	self.enableTouch = true
	self.needRetry = false
end

function GetServerTimeStampRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetServerTimeStampSucceed , data ) )
end

function GetServerTimeStampRequest:onError(error)
  BaseRequest.onError(self, error)
end

--
BindAccountRequest = class(BaseRequest)
function BindAccountRequest:ctor(params, priority)
	self.endpoint = "bindAccount"
	self.data = nil
	self.params = params
end

function BindAccountRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.BindAccountSucceed , data ) )
end

function BindAccountRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.BindAccountFailed, error ) )
end