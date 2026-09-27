require "canon.request.BaseRequest"

--
-- DiceGainRewardRequest
--

DiceGainRewardRequest = class(BaseRequest)

function DiceGainRewardRequest:ctor(params, priority)
    self.endpoint = "gainDiceReward"
end

function DiceGainRewardRequest:onSuccess(data)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainThrowDiceSucceed, data))
end

function DiceGainRewardRequest:onError(error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainThrowDiceFailed, {retCode = error}))
end