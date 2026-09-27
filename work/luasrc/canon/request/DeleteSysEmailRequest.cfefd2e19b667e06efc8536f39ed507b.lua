require "canon.request.BaseRequest"

--
-- DeleteSysEmailRequest
--

DeleteSysEmailRequest = class(BaseRequest)

function DeleteSysEmailRequest:ctor(params, priority)
    self.endpoint = "deleteSysEmail"
end

function DeleteSysEmailRequest:onSuccess(data)
  --print("deleteSysEmail success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.DeleteSysEmailSucceed, data))
end

function DeleteSysEmailRequest:onError(error)
  BaseRequest.onError(self, error)
end




