require "canon.request.BaseRequest"

GetTaskInfoRequest = class(BaseRequest)

function GetTaskInfoRequest:ctor(params, priority)
	self.endpoint = "getTaskInfo"
	self.data = nil
	self.params = params
end

function GetTaskInfoRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetTaskInfoSucceed , data ) )
end

function GetTaskInfoRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetTaskInfoFailed , error ) )
end

function GetTaskInfoRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = GetTaskInfoRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GetTaskInfoSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.GetTaskInfoFailed, onFailedHandle)--<<<<< 2
	request:start()
end