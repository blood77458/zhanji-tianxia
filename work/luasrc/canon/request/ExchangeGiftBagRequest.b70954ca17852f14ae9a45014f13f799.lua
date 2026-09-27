--------------------------------------------------------------------------------
-- ExchangeGiftBagRequest.lua -- 兑换礼包请求
-- author: Jiang Yize
-- date: 2013-11-14
--------------------------------------------------------------------------------

require "canon.request.BaseRequest"

ExchangeGiftBagRequest = class(BaseRequest)

function ExchangeGiftBagRequest:ctor()
  self.endpoint = "exchangeGiftBag"
end

function ExchangeGiftBagRequest:onSuccess(data)
  --print("ExchangeGiftBag Success: " .. table.serialize(data))
  self:dispatchEvent(Event.new(RequestNotifyEnum.ExchangeGiftBagSucceed, data))
end

function ExchangeGiftBagRequest:onError(error)
  self:dispatchEvent(Event.new(RequestNotifyEnum.ExchangeGiftBagFailed, error))
end
