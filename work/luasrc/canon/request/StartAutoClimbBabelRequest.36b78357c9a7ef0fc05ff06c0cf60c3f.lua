
require "canon.request.BaseRequest"

StartAutoClimbBabelRequest = class(BaseRequest)

function StartAutoClimbBabelRequest:ctor()
    self.endpoint = "startAutoClimbBabel"
end

function StartAutoClimbBabelRequest:onSuccess( data )
    --print("StartAutoClimbBabel Success: " .. table.serialize(data))
    HeMemDataHolder:setString("StartAutoClimbBabel", table.serialize(data));
    self:dispatchEvent(Event.new(RequestNotifyEnum.StartAutoClimbBabelSucceed,data))    
end

function StartAutoClimbBabelRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.StartAutoClimbBabelFailed,error))    
--    BaseRequest.onError(self, error)
end


