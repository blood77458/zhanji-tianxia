require "canon.request.BaseRequest"

GetSecretShopListRequest = class(BaseRequest)

--获得神秘商店列表
function GetSecretShopListRequest:ctor(params, priority)
	self.endpoint = "getSecretShopList"
	self.data = nil
	self.params = params
end

function GetSecretShopListRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetSecretShopListSucceed , data ) )
end

function GetSecretShopListRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetSecretShopListFailed , error ) )
end

function GetSecretShopListRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local params = {}--<<<<< 3
	local request = GetSecretShopListRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GetSecretShopListSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.GetSecretShopListFailed, onFailedHandle)--<<<<< 2
	request:start()
end