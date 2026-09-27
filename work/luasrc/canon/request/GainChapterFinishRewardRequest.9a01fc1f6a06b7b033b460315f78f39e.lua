require "canon.request.BaseRequest"

--
-- GainChapterFinishRewardRequest
--

GainChapterFinishRewardRequest = class(BaseRequest)

function GainChapterFinishRewardRequest:ctor(params, priority)
    self.endpoint = "gainChapterFinishReward"
end

function GainChapterFinishRewardRequest:onSuccess(data)
  --print("gainChapterFinishReward success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainChapterFinishRewardSucceed, data))
end

function GainChapterFinishRewardRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainChapterFinishRewardFailed, {retCode = error}))
end