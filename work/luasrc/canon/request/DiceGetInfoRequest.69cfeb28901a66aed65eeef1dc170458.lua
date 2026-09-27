require "canon.request.BaseRequest"

--
-- DiceGetInfoRequest
--

DiceGetInfoRequest = class(BaseRequest)

function DiceGetInfoRequest:ctor(params, priority)
    self.endpoint = "getDiceInfo"
end

function DiceGetInfoRequest:onSuccess(data)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetSilverDiceInfoSucceed, data))
end

function DiceGetInfoRequest:onError(error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetSilverDiceInfoFailed, {retCode = error}))
end