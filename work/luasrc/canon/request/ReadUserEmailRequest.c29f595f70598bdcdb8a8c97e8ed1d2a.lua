require "canon.request.BaseRequest"

--
-- ReadUserEmailRequest
--

ReadUserEmailRequest = class(BaseRequest)

function ReadUserEmailRequest:ctor(params, priority)
    self.endpoint = "readUserEmail"
end

function ReadUserEmailRequest:onSuccess(data)
  print("readUserEmail success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.ReadUserEmailSucceed, data))
end

function ReadUserEmailRequest:onError(error)
  BaseRequest.onError(self, error)
end




