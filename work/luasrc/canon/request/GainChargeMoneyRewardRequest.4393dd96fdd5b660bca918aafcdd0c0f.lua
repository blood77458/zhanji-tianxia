require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

GainChargeMoneyRewardRequest = class(BaseRequest)

function GainChargeMoneyRewardRequest:ctor()
  self.endpoint = METHOD_GAINCHARGEMONEYREWARD
end

function GainChargeMoneyRewardRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainChargeMoneyRewardSucceed, data))
end

function GainChargeMoneyRewardRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainChargeMoneyRewardFailed, error))
end