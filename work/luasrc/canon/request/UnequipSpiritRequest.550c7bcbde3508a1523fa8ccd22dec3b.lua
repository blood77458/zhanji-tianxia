require "canon.request.BaseRequest"

UnequipSpiritRequest = class(BaseRequest)

--卸下元神
function UnequipSpiritRequest:ctor(params, priority)
	self.endpoint = "unequipSpirit"
	self.data = nil
	self.params = params
end

function UnequipSpiritRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.UnequipSpiritSucceed , data ) )
end

function UnequipSpiritRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.UnequipSpiritFailed , error ) )
end

function UnequipSpiritRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = UnequipSpiritRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnequipSpiritSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnequipSpiritFailed, onFailedHandle)--<<<<< 2
	request:start()
end