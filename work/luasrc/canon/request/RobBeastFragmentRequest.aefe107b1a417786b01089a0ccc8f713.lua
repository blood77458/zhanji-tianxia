require "canon.request.BaseRequest"

--
-- RobBeastFragmentRequest
--

RobBeastFragmentRequest = class(BaseRequest)

function RobBeastFragmentRequest:ctor(params, priority)
    self.endpoint = "robBeastFragment"
end

function RobBeastFragmentRequest:onSuccess(data)
  --print("robBeastFragment success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.RobBeastFragmentSucceed, data))
end

function RobBeastFragmentRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.RobBeastFragmentFailed, {retCode = error}))
end