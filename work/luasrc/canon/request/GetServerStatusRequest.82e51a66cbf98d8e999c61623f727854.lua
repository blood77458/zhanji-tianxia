require "canon.request.BaseRequest"

GetServerStatusRequest = class(BaseRequest)

function GetServerStatusRequest:ctor(params, priority)
	self.endpoint = "getServerStatus"
end

function GetServerStatusRequest:onSuccess(data)
	he_log_info("GetServerStatusRequest success " .. table.serialize(data))
end

function GetServerStatusRequest:onError(error)
	BaseRequest.onError(self, error)
end

