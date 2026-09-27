
require "canon.request.BaseRequest"

SpiritConcentrateRequest = class(BaseRequest)

function SpiritConcentrateRequest:ctor()
    self.endpoint = "spiritConcentrate"
end

function SpiritConcentrateRequest:onSuccess( data )
    self:dispatchEvent(Event.new(RequestNotifyEnum.SpiritConcentrateSucceed,data))    
end

function SpiritConcentrateRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.SpiritConcentrateFailed,error))    
end


