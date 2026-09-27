require "canon.request.BaseRequest"

WantedActivityGetWantedInfoRequest = class(BaseRequest)

function WantedActivityGetWantedInfoRequest:ctor()
    self.endpoint = "getWantedInfo"
end

function WantedActivityGetWantedInfoRequest:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.WantedActivityGetWantedInfoRequestSucceed,data))
end

function WantedActivityGetWantedInfoRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.WantedActivityGetWantedInfoRequestFailed,error))
end