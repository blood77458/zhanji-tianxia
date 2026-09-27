
require "canon.request.BaseRequest"

GetBabelInfoRequest = class(BaseRequest)

function GetBabelInfoRequest:ctor()
    self.endpoint = "getBabelInfo"
end

function GetBabelInfoRequest:onSuccess( data )
    --print("GetBabelInfo Success: " .. table.serialize(data))
    HeMemDataHolder:setString("GetBabelInfo", table.serialize(data));
    self:dispatchEvent(Event.new(RequestNotifyEnum.GetBabelInfoSucceed,data))    
end

function GetBabelInfoRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.GetBabelInfoFailed,error))    
--    BaseRequest.onError(self, error)
end


