require "canon.request.BaseRequest"

RefreshSecretShopRequest = class(BaseRequest)

--刷新神秘商店
function RefreshSecretShopRequest:ctor(params, priority)
	self.endpoint = "refreshSecretShop"
	self.data = nil
	self.params = params
end

function RefreshSecretShopRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.RefreshSecretShopSucceed , data ) )
end

function RefreshSecretShopRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.RefreshSecretShopFailed , error ) )
end

function RefreshSecretShopRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = RefreshSecretShopRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.RefreshSecretShopSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.RefreshSecretShopFailed, onFailedHandle)--<<<<< 2
	request:start()
end