
require "canon.request.BaseRequest"

CreateUserRequest = class(BaseRequest)

function CreateUserRequest:ctor()
    self.endpoint = "createUser"
end

function CreateUserRequest:onSuccess( data )
    --print("createUser success: " .. table.serialize(data))
	--Communication:getInstance():putOthers("serverId", self.params.serverId)
    self:dispatchEvent(Event.new(RequestNotifyEnum.CreateUserSucceed,data))    
end

function CreateUserRequest:onError( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.CreateUserFailed,data))
end