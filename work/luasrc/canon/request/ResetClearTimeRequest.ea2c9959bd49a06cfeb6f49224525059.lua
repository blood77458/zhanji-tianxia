require "canon.request.BaseRequest"

--
-- ResetClearTimeRequest
--

ResetClearTimeRequest = class(BaseRequest)

function ResetClearTimeRequest:ctor(params, priority)
    self.endpoint = "resetClearTime"
end

function ResetClearTimeRequest:onSuccess(data)
  --print("resetClearTime success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.ResetClearTimeSucceed, data))
end

function ResetClearTimeRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.ResetClearTimeFailed, {retCode = error}))
end