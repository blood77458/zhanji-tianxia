require "canon.request.BaseRequest"

--
-- GetMultiplayserBossInfoRequest
--

GetMultiplayserBossInfoRequest = class(BaseRequest)

function GetMultiplayserBossInfoRequest:ctor(params, priority, forbidLoading)
    self.endpoint = "getMultiplayserBossInfo"
    if forbidLoading then
      self.showLoading = false
      self.enableTouch = true
      self.needRetry = false
    end
end

function GetMultiplayserBossInfoRequest:onSuccess(data)
  --print("getMultiplayserBossInfo success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetMultiplayserBossInfoSucceed, data))
end

function GetMultiplayserBossInfoRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetMultiplayserBossInfoFailed, {retCode = error}))
end