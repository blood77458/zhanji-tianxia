require "canon.request.BaseRequest"

RefreshMatchRequest = class(BaseRequest)

--刷新对手
function RefreshMatchRequest:ctor(params, priority)
	self.endpoint = "refreshMatch"
	self.data = nil
	self.params = params
end

function RefreshMatchRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.RefreshMatchSucceed , data ) )
end

function RefreshMatchRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.RefreshMatchFailed , error ) )
end

function RefreshMatchRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = RefreshMatchRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.RefreshMatchSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.RefreshMatchFailed, RefreshMatchRequest.onFailedDefault)--<<<<< 2
	request:start()
end

--失败默认处理
function RefreshMatchRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end
