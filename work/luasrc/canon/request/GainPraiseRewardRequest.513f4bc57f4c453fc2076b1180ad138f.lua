require "canon.request.BaseRequest"

GainPraiseRewardRequest = class(BaseRequest)

--领取点赞礼包奖励
function GainPraiseRewardRequest:ctor(params, priority)
	self.endpoint = "gainPraiseReward"
	self.data = nil
	self.params = params
end

function GainPraiseRewardRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GainPraiseRewardSucceed , data ) )
end

function GainPraiseRewardRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.GainPraiseRewardFailed , error ) )
end

function GainPraiseRewardRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(Data, event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = {praiseId = Data}--<<<<< 3
	local request = GainPraiseRewardRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GainPraiseRewardSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.GainPraiseRewardFailed, onFailedHandle)--<<<<< 2
	request:start()
end