require "canon.request.BaseRequest"

--
-- GetDailyActiveInfoRequest
--

GetDailyActiveInfoRequest = class(BaseRequest)

function GetDailyActiveInfoRequest:ctor(params, priority)
    self.endpoint = "getDailyActiveInfo"
end

function GetDailyActiveInfoRequest:onSuccess(data)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetDailyActiveInfoSucceed, data))
end

function GetDailyActiveInfoRequest:onError(error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetDailyActiveInfoFailed, {retCode = error}))
end