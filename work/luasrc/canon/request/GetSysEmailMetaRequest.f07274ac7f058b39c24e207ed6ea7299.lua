require "canon.request.BaseRequest"

--
-- GetSysEmailMetaRequest
--

GetSysEmailMetaRequest = class(BaseRequest)

function GetSysEmailMetaRequest:ctor(params, priority)
    self.endpoint = "getSysEmailMeta"
end

function GetSysEmailMetaRequest:onSuccess(data)
  print("getSysEmailMeta success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.GetSysEmailMetaSucceed, data))
end

function GetSysEmailMetaRequest:onError(error)
  BaseRequest.onError(self, error)
end




