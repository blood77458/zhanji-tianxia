
require "canon.request.BaseRequest"

GachaCardFreeRequest = class(BaseRequest)

function GachaCardFreeRequest:ctor()
    self.endpoint = "gachaCardFree"
end

function GachaCardFreeRequest:onSuccess( data )
    --print("GachaCardFree Success: " .. table.serialize(data))
    HeMemDataHolder:setString("GachaCardFree", table.serialize(data));
    self:dispatchEvent(Event.new(RequestNotifyEnum.GachaCardFreeSucceed,data))    
end

function GachaCardFreeRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.GachaCardFreeFailed,error))    
--    BaseRequest.onError(self, error)
end


