require "canon.request.BaseRequest"

--
-- GainSysEmailRewardRequest
--

GainSysEmailRewardRequest = class(BaseRequest)

function GainSysEmailRewardRequest:ctor(params, priority)
    self.endpoint = "gainSysEmailReward"
end

function GainSysEmailRewardRequest:onSuccess(data)
  print("gainSysEmailReward success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainSysEmailRewardSucceed, data))
end

function GainSysEmailRewardRequest:onError(error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainSysEmailRewardFailed, error))
--  BaseRequest.onError(self, error)
end




