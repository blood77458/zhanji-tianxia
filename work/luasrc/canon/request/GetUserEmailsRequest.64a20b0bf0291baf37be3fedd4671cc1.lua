require "canon.request.BaseRequest"

--
-- GetUserEmailsRequest
--

GetUserEmailsRequest = class(BaseRequest)

function GetUserEmailsRequest:ctor(params, priority)
    self.endpoint = "getUserEmails"
end

function GetUserEmailsRequest:onSuccess(data)
  print("getUserEmails success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetUserEmailsSucceed, data))
end

function GetUserEmailsRequest:onError(error)
  BaseRequest.onError(self, error)
end




