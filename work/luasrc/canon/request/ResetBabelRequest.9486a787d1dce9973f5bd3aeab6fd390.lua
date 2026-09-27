
require "canon.request.BaseRequest"

ResetBabelRequest = class(BaseRequest)

function ResetBabelRequest:ctor()
    self.endpoint = "resetBabel"
end

function ResetBabelRequest:onSuccess( data )
    --print("ResetBabel Success: " .. table.serialize(data))
    HeMemDataHolder:setString("ResetBabel", table.serialize(data));
    self:dispatchEvent(Event.new(RequestNotifyEnum.ResetBabelSucceed,data))    
end

function ResetBabelRequest:onError( error )
    self:dispatchEvent(Event.new(RequestNotifyEnum.ResetBabelFailed,error))    
--    BaseRequest.onError(self, error)
end


