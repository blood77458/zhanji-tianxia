require "canon.request.BaseRequest"

AdjustCardAvatarRequest = class(BaseRequest)

--卖出元神
function AdjustCardAvatarRequest:ctor(params, priority)
	self.endpoint = "adjustCardAvatar"
	self.data = nil
	self.params = params
end

function AdjustCardAvatarRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.AdjustCardAvatarSucceed , data ) )
end

function AdjustCardAvatarRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.AdjustCardAvatarFailed , error ) )
end

function AdjustCardAvatarRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = AdjustCardAvatarRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.AdjustCardAvatarSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.AdjustCardAvatarFailed, onFailedHandle)--<<<<< 2
	request:start()
end