
require "canon.request.BaseRequest"

GetRechargeInfoRequest = class(BaseRequest)

function GetRechargeInfoRequest:ctor()
    self.endpoint = "getAccumulateRechargeInfo"
end

function GetRechargeInfoRequest:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.GetRechargeInfoSucceed,data))
end

function GetRechargeInfoRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.GetRechargeInfoFailed,error))
end