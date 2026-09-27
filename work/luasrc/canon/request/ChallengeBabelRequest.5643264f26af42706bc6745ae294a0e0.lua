
require "canon.request.BaseRequest"

ChallengeBabelRequest = class(BaseRequest)

function ChallengeBabelRequest:ctor()
    self.endpoint = "challengeBabel"
end

function ChallengeBabelRequest:onSuccess( data )
    --print("ChallengeBabel Success: " .. table.serialize(data))
    HeMemDataHolder:setString("ChallengeBabel", table.serialize(data));
    self:dispatchEvent(Event.new(RequestNotifyEnum.ChallengeBabelSucceed,data))    
end

function ChallengeBabelRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.ChallengeBabelFailed,error))    
--    BaseRequest.onError(self, error)
end


