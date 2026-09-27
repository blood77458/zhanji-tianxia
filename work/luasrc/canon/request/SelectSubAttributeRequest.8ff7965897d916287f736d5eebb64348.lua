require "canon.request.BaseRequest"

SelectSubAttributeRequest = class(BaseRequest)

--卖出元神
function SelectSubAttributeRequest:ctor(params, priority)
	self.endpoint = "selectSubAttribute"
	self.data = nil
	self.params = params
end

function SelectSubAttributeRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.SelectSubAttributeSucceed , data ) )
end

function SelectSubAttributeRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.SelectSubAttributeFailed , error ) )
end

function SelectSubAttributeRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = SelectSubAttributeRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.SelectSubAttributeSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.SelectSubAttributeFailed, onFailedHandle)--<<<<< 2
	request:start()
end