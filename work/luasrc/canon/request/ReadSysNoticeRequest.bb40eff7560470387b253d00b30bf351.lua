require "canon.request.BaseRequest"

--
-- ReadSysNoticeRequest
--

ReadSysNoticeRequest = class(BaseRequest)

function ReadSysNoticeRequest:ctor(params, priority)
    self.endpoint = "readSysNotice"
end

function ReadSysNoticeRequest:onSuccess(data)
  --print("readSysNotice success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.ReadSysNoticeSucceed, data))
end

function ReadSysNoticeRequest:onError(error)
  BaseRequest.onError(self, error)
end




