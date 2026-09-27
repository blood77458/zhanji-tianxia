
require "canon.request.BaseRequest"

GetUserBagInfo = class(BaseRequest)

function GetUserBagInfo:ctor(params, priority)
    self.endpoint = "getEquips"
end

function GetUserBagInfo:onSuccess(data)
    print("getEquips success: " .. table.serialize(data))
end

function GetUserBagInfo:onError(error)
    BaseRequest.onError(self, error)
end