require "canon.request.BaseRequest"

GetChargeFeedbackRewardRequest = class(BaseRequest)

function GetChargeFeedbackRewardRequest:ctor(params, priority)
	self.endpoint = "getChargeFeedbackReward"
	self.data = nil
	self.params = params
end

function GetChargeFeedbackRewardRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetChargeFeedbackRewardSucceed , data ) )
end

function GetChargeFeedbackRewardRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetChargeFeedbackRewardFailed , error ) )
end

function GetChargeFeedbackRewardRequest.sendRequest(params , succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = GetChargeFeedbackRewardRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GetChargeFeedbackRewardSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.GetChargeFeedbackRewardFailed, onFailedHandle)--<<<<< 2
	request:start()
end