require "canon.request.BaseRequest"

GetCrossBossInfoRequest = class(BaseRequest)

--获取世界boss信息
function GetCrossBossInfoRequest:ctor(params, priority)
	self.endpoint = "getCrossBossInfo"
	self.data = nil
	self.params = params
end

function GetCrossBossInfoRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetCrossBossInfoSucceed , data ) )
end

function GetCrossBossInfoRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetCrossBossInfoFailed , error ) )
end

function GetCrossBossInfoRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = GetCrossBossInfoRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GetCrossBossInfoSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.GetCrossBossInfoFailed, onFailedHandle)--<<<<< 2
	request:start()
end