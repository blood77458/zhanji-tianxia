require "canon.request.BaseRequest"

GetSharkGachaBoxInfoRequest = class(BaseRequest)

--领取邀请好友奖励
function GetSharkGachaBoxInfoRequest:ctor(params, priority)
	self.endpoint = "getSharkGachaBoxInfo"
	self.data = nil
	self.params = params
end

function GetSharkGachaBoxInfoRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetSharkGachaBoxInfoSucceed , data ) )
end

function GetSharkGachaBoxInfoRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetSharkGachaBoxInfoFailed , error ) )
end

function GetSharkGachaBoxInfoRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = GetSharkGachaBoxInfoRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GetSharkGachaBoxInfoSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.GetSharkGachaBoxInfoFailed, onFailedHandle)--<<<<< 2
	request:start()
end