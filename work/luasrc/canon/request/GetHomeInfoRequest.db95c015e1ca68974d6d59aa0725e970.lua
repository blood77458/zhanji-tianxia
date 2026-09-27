--------------------------------------------------------------------------------
-- GetHomeInfo.lua -- 获取主页信息请求
-- author: Jiang Yize
-- date: 2013-10-18
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

GetHomeInfoRequest = class(BaseRequest)

function GetHomeInfoRequest:ctor()
  self.endpoint = "getHomeInfo"
  self.showLoading = false
  self.enableTouch = true
  self.needRetry = false
end

function GetHomeInfoRequest:onSuccess(data)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetHomeInfoSucceed, data))
end

function GetHomeInfoRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetHomeInfoFailed, {retCode = error}))
end