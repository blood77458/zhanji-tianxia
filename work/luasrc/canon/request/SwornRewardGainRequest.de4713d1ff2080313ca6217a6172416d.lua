require "canon.request.BaseRequest"

SwornRewardGainRequest = class(BaseRequest)

function SwornRewardGainRequest:ctor()
  self.endpoint = "gainSwornReward"
end

function SwornRewardGainRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.SwornRewardGainSucceed, data))
end

function SwornRewardGainRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.SwornRewardGainFailed, error))
end