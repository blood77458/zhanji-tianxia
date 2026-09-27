require "canon.request.BaseRequest"

RefreshGachaBoxRequest = class(BaseRequest)

--领取邀请好友奖励
function RefreshGachaBoxRequest:ctor(params, priority)
	self.endpoint = "refreshGachaBox"
	self.data = nil
	self.params = params
end

function RefreshGachaBoxRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.RefreshGachaBoxSucceed , data ) )
end

function RefreshGachaBoxRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.RefreshGachaBoxFailed , error ) )
end

function RefreshGachaBoxRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = RefreshGachaBoxRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.RefreshGachaBoxSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.RefreshGachaBoxFailed, onFailedHandle)--<<<<< 2
	request:start()
end