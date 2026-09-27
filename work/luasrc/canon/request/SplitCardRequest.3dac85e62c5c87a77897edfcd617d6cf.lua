require "canon.request.BaseRequest"

--
-- SplitCardRequest
--

SplitCardRequest = class(BaseRequest)

function SplitCardRequest:ctor(params, priority)
  self.endpoint = "splitCard"
end

function SplitCardRequest:onSuccess(data)
  --print("SplitCardRequest success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.SplitCardSucceed, data))
end

function SplitCardRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.SplitCardFailed, error))
end