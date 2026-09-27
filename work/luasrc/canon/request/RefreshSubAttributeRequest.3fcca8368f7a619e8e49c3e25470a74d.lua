require "canon.request.BaseRequest"

RefreshSubAttributeRequest = class(BaseRequest)

--刷新元神副属性
function RefreshSubAttributeRequest:ctor(params, priority)
	self.endpoint = "refreshSubAttribute"
	self.data = nil
	self.params = params
end

function RefreshSubAttributeRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.RefreshSubAttributeSucceed , data ) )
end

function RefreshSubAttributeRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.RefreshSubAttributeFailed , error ) )
end

function RefreshSubAttributeRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(Data , event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = Data--<<<<< 3
	local request = RefreshSubAttributeRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.RefreshSubAttributeSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.RefreshSubAttributeFailed, onFailedHandle)--<<<<< 2
	request:start()
end