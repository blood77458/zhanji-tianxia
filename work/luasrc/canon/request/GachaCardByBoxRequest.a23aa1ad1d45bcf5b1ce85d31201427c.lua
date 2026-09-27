require "canon.request.BaseRequest"

GachaCardByBoxRequest = class(BaseRequest)

--领取邀请好友奖励
function GachaCardByBoxRequest:ctor(params, priority)
	self.endpoint = "gachaCardByBox"
	self.data = nil
	self.params = params
end

function GachaCardByBoxRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GachaCardByBoxSucceed , data ) )
end

function GachaCardByBoxRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.GachaCardByBoxFailed , error ) )
end

function GachaCardByBoxRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = GachaCardByBoxRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GachaCardByBoxSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.GachaCardByBoxFailed, onFailedHandle)--<<<<< 2
	request:start()
end