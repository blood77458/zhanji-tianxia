require "canon.request.BaseRequest"

--
-- DeleteUserEmailRequest
--

DeleteUserEmailRequest = class(BaseRequest)

function DeleteUserEmailRequest:ctor(params, priority)
    self.endpoint = "deleteUserEmail"
end

function DeleteUserEmailRequest:onSuccess(data)
  --print("deleteUserEmail success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.DeleteUserEmailSucceed, data))
end

function DeleteUserEmailRequest:onError(error)
  BaseRequest.onError(self, error)
end




