require "canon.request.BaseRequest"

ExchangeSecretShopRequest = class(BaseRequest)

--神秘商店兑换
function ExchangeSecretShopRequest:ctor(params, priority)
	self.endpoint = "exchangeSecretShop"
	self.data = nil
	self.params = params
end

function ExchangeSecretShopRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.ExchangeSecretShopSucceed , data ) )
end

function ExchangeSecretShopRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.ExchangeSecretShopFailed , error ) )
end

function ExchangeSecretShopRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = Data--<<<<< 3
	local request = ExchangeSecretShopRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.ExchangeSecretShopSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.ExchangeSecretShopFailed, onFailedHandle)--<<<<< 2
	request:start()
end