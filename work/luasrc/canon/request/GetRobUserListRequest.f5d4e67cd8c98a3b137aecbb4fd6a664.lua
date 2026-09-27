require "canon.request.BaseRequest"

--
-- GetRobUserListRequest
--

GetRobUserListRequest = class(BaseRequest)

function GetRobUserListRequest:ctor(params, priority)
    self.endpoint = "getRobUserList"
end

function GetRobUserListRequest:onSuccess(data)
  --print("getRobUserList success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetRobUserListSucceed, data))
end

function GetRobUserListRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetRobUserListFailed, {retCode = error}))
end