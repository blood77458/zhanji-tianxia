
require "canon.request.BaseRequest"

GachaCardRequest = class(BaseRequest)

function GachaCardRequest:ctor()
    self.endpoint = "gachaCard"
end

function GachaCardRequest:onSuccess( data )
    --print("GachaCard Success: " .. table.serialize(data))
    HeMemDataHolder:setString("GachaCard", table.serialize(data));
    self:dispatchEvent(Event.new(RequestNotifyEnum.GachaCardSucceed,data))    
end

function GachaCardRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.GachaCardFailed,error))    
--    BaseRequest.onError(self, error)
end


