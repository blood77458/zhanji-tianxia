require "canon.request.BaseRequest"

--
-- SendUserEmailRequest
--

SendUserEmailRequest = class(BaseRequest)

function SendUserEmailRequest:ctor(params, priority)
    self.endpoint = "sendUserEmail"
end

function SendUserEmailRequest:onSuccess(data)
  print("sendUserEmail success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.SendUserEmailSucceed, data))
end

function SendUserEmailRequest:onError(error)
  BaseRequest.onError(self, error)
end




