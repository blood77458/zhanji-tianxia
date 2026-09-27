require "canon.request.BaseRequest"

UnlockSubAttributeRequest = class(BaseRequest)

--解锁元神副属性
function UnlockSubAttributeRequest:ctor(params, priority)
	self.endpoint = "unlockSubAttribute"
	self.data = nil
	self.params = params
end

function UnlockSubAttributeRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.UnlockSubAttributeSucceed , data ) )
end

function UnlockSubAttributeRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.UnlockSubAttributeFailed , error ) )
end

function UnlockSubAttributeRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = UnlockSubAttributeRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnlockSubAttributeSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnlockSubAttributeFailed, onFailedHandle)--<<<<< 2
	request:start()
end