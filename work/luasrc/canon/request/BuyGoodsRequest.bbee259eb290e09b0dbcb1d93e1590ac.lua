require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"

BuyGoodsRequest = class(BaseRequest)

function BuyGoodsRequest:ctor()
  self.endpoint = METHOD_BUYGOODS
end

function BuyGoodsRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.BuyGoodsSucceed, data))
end

function BuyGoodsRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.BuyGoodsFailed, error))
end