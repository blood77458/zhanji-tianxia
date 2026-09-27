require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

ReplaceMatrixGridRequest = class(BaseRequest)

function ReplaceMatrixGridRequest:ctor()
  self.endpoint = METHOD_REPLACEMATRIXGRID
end

function ReplaceMatrixGridRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.ReplaceMatrixGridSucceed, data))
end

function ReplaceMatrixGridRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.ReplaceMatrixGridFailed, error))
end