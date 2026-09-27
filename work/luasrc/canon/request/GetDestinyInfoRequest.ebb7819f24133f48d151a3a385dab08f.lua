
require "canon.request.BaseRequest"

GetDestinyInfoRequest = class(BaseRequest)

function GetDestinyInfoRequest:ctor()
    self.endpoint = "getDestinyInfo"
end

function GetDestinyInfoRequest:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.GetDestinyInfoSucceed,data))    
end

function GetDestinyInfoRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.GetDestinyInfoFailed,error))    
end


