require "canon.request.BaseRequest"

--
-- DiceChangeLuckRequest
--

DiceChangeLuckRequest = class(BaseRequest)

function DiceChangeLuckRequest:ctor(params, priority)
    self.endpoint = "changeDiceLuck"
end

function DiceChangeLuckRequest:onSuccess(data)
  self:dispatchEvent(Event.new(RequestNotifyEnum.ChangeThrowDiceLuckSucceed, data))
end

function DiceChangeLuckRequest:onError(error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.ChangeThrowDiceLuckFailed, {retCode = error}))
end