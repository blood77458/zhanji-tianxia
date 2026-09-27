require "canon.request.BaseRequest"

--
-- EmailChangeRequest
--

EmailChangeRequest = class(BaseRequest)

function EmailChangeRequest:ctor(params, priority)
    self.endpoint = "modifyEmail"
end

function EmailChangeRequest:onSuccess(data)
  self:dispatchEvent(Event.new(RequestNotifyEnum.EmailChangeSucceed, data))
end

function EmailChangeRequest:onError(error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.EmailChangeFailed, {retCode = error}))
end