require "canon.request.BaseRequest"

--
-- ReadSysEmailRequest
--

ReadSysEmailRequest = class(BaseRequest)

function ReadSysEmailRequest:ctor(params, priority)
    self.endpoint = "readSysEmail"
end

function ReadSysEmailRequest:onSuccess(data)
  print("readSysEmail success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.ReadSysEmailSucceed, data))
end

function ReadSysEmailRequest:onError(error)
  BaseRequest.onError(self, error)
end




