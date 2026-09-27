require "canon.request.BaseRequest"

--
-- DeleteSysNoticeRequest
--

DeleteSysNoticeRequest = class(BaseRequest)

function DeleteSysNoticeRequest:ctor(params, priority)
    self.endpoint = "deleteSysNotice"
end

function DeleteSysNoticeRequest:onSuccess(data)
  --print("deleteSysNotice success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.DeleteSysNoticeSucceed, data))
end

function DeleteSysNoticeRequest:onError(error)
  BaseRequest.onError(self, error)
end




