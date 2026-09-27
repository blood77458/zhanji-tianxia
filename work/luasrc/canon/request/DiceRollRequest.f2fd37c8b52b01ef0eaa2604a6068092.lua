require "canon.request.BaseRequest"

--
-- DiceRollRequest
--

DiceRollRequest = class(BaseRequest)

function DiceRollRequest:ctor(params, priority)
    self.endpoint = "throwDice"
end

function DiceRollRequest:onSuccess(data)
  self:dispatchEvent(Event.new(RequestNotifyEnum.ThrowDiceSucceed, data))
end

function DiceRollRequest:onError(error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.ThrowDiceFailed, {retCode = error}))
end