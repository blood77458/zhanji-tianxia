require "canon.request.BaseRequest"

--
-- GainArenaScoreByRankRequest
--

GainArenaScoreByRankRequest = class(BaseRequest)

function GainArenaScoreByRankRequest:ctor(params, priority)
    self.endpoint = "gainArenaScoreByRank"
end

function GainArenaScoreByRankRequest:onSuccess(data)
  --print("gainArenaScoreByRank success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainArenaScoreByRankSucceed, data))
end

function GainArenaScoreByRankRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GainArenaScoreByRankFailed, {retCode = error}))
end

