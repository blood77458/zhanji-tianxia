require "canon.request.BaseRequest"

RefreshCrossBossBattlePhaseRequest = class(BaseRequest)

--获取世界boss信息
function RefreshCrossBossBattlePhaseRequest:ctor(params, priority)
	self.endpoint = "refreshCrossBossBattlePhase"
	self.data = nil
	self.params = params
end

function RefreshCrossBossBattlePhaseRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.RefreshCrossBossBattlePhaseSucceed , data ) )
end

function RefreshCrossBossBattlePhaseRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.RefreshCrossBossBattlePhaseFailed , error ) )
end

function RefreshCrossBossBattlePhaseRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = RefreshCrossBossBattlePhaseRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.RefreshCrossBossBattlePhaseSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.RefreshCrossBossBattlePhaseFailed, onFailedHandle)--<<<<< 2
	request:start()
end