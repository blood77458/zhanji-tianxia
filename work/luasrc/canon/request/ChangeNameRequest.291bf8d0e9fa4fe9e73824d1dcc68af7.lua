require "canon.request.BaseRequest"

ChangeNameRequest = class(BaseRequest)

--卖出元神
function ChangeNameRequest:ctor(params, priority)
	self.endpoint = "rename"
	self.data = nil
	self.params = params
end

function ChangeNameRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.ChangeNameSucceed , data ) )
end

function ChangeNameRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.ChangeNameFailed , error ) )
end

function ChangeNameRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = ChangeNameRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.ChangeNameSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.ChangeNameFailed, onFailedHandle)--<<<<< 2
	request:start()
end