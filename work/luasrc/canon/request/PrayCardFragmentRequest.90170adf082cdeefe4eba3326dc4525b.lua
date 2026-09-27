require "canon.request.BaseRequest"

--
-- PrayCardFragmentRequest
--

PrayCardFragmentRequest = class(BaseRequest)

function PrayCardFragmentRequest:ctor(params, priority)
    self.endpoint = "prayCardFragment"
end

function PrayCardFragmentRequest:onSuccess(data)
  --print("prayCardFragment success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.PrayCardFragmentSucceed, data))
end

function PrayCardFragmentRequest:onError(error)
  --BaseRequest.onError(self, error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.PrayCardFragmentFailed, {retCode = error}))
end