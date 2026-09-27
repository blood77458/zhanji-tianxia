require "canon.request.BaseRequest"

--
-- GetSocketServerRequest
--

GetSocketServerRequest = class(BaseRequest)

function GetSocketServerRequest:ctor(params, priority)
    self.endpoint = "getSocketServer"
    self.showLoading = false
    self.enableTouch = true
    self.needRetry = false
end

function GetSocketServerRequest:onSuccess(data)
  --print("getSocketServer success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetSocketServerSucceed, data))
end

function GetSocketServerRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetSocketServerFailed, {retCode = error}))
end