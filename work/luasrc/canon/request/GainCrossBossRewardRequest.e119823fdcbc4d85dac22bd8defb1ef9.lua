require "canon.request.BaseRequest"

GainCrossBossRewardRequest = class(BaseRequest)

--领取奖励
function GainCrossBossRewardRequest:ctor(params, priority)
	self.endpoint = "gainCrossBossReward"
	self.data = nil
	self.params = params
end

function GainCrossBossRewardRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GainCrossBossRewardSucceed , data ) )
end

function GainCrossBossRewardRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.GainCrossBossRewardFailed , error ) )
end

function GainCrossBossRewardRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = GainCrossBossRewardRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GainCrossBossRewardSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.GainCrossBossRewardFailed, onFailedHandle)--<<<<< 2
	request:start()
end