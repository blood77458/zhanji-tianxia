require "canon.request.BaseRequest"

WantedActivityExchangeRequest = class(BaseRequest)

function WantedActivityExchangeRequest:ctor()
    self.endpoint = "exchangeItem"
end

function WantedActivityExchangeRequest:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.WantedActivityExchangeRequestSucceed,data))
end

function WantedActivityExchangeRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.WantedActivityExchangeRequestFailed,error))
end