
require "canon.request.BaseRequest"

GainAutoClimbRewardRequest = class(BaseRequest)

function GainAutoClimbRewardRequest:ctor()
    self.endpoint = "gainAutoClimbReward"
end

function GainAutoClimbRewardRequest:onSuccess( data )
    --print("GainAutoClimbReward Success: " .. table.serialize(data))
    HeMemDataHolder:setString("GainAutoClimbReward", table.serialize(data));
    self:dispatchEvent(Event.new(RequestNotifyEnum.GainAutoClimbRewardSucceed,data))    
end

function GainAutoClimbRewardRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.GainAutoClimbRewardFailed,error))    
--    BaseRequest.onError(self, error)
end


