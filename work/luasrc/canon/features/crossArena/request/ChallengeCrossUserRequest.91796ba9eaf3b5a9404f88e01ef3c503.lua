require "canon.request.BaseRequest"

ChallengeCrossUserRequest = class(BaseRequest)

--挑战
function ChallengeCrossUserRequest:ctor(params, priority)
	self.endpoint = "challengeCrossUser"
	self.data = nil
	self.params = params
end

function ChallengeCrossUserRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.ChallengeCrossUserSucceed , data ) )
end

function ChallengeCrossUserRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.ChallengeCrossUserFailed , error ) )
end

function ChallengeCrossUserRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		ChallengeCrossUserRequest.onFailedDefault(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = Data--<<<<< 3
	local request = ChallengeCrossUserRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.ChallengeCrossUserSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.ChallengeCrossUserFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--失败默认处理
function ChallengeCrossUserRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end
