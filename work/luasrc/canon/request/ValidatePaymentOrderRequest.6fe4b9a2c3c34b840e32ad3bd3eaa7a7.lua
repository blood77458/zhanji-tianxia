require "canon.request.BaseRequest"

ValidatePaymentOrderRequest = class(BaseRequest)

function ValidatePaymentOrderRequest:ctor(params, priority)
	self.endpoint = "validatePaymentOrder"
	self.data = nil
	self.params = params
end

function ValidatePaymentOrderRequest:onSuccess( data )
    self:dispatchEvent( Event.new( RequestNotifyEnum.ValidatePaymentOrderSucceed , data ) )
end

function ValidatePaymentOrderRequest:onError(error)
    self:dispatchEvent( Event.new( RequestNotifyEnum.ValidatePaymentOrderFailed, error))
end