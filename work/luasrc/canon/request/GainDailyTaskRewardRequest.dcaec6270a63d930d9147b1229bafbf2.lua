require "canon.request.BaseRequest"

GainDailyTaskRewardRequest = class(BaseRequest)

function GainDailyTaskRewardRequest:ctor(params, priority)
	self.endpoint = "gainDailyTaskReward"
	self.data = nil
	self.params = params
end

function GainDailyTaskRewardRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GainDailyTaskRewardSucceed , data ) )
end

function GainDailyTaskRewardRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.GainDailyTaskRewardFailed , error ) )
end

function GainDailyTaskRewardRequest.sendRequest(params , succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = GainDailyTaskRewardRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GainDailyTaskRewardSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.GainDailyTaskRewardFailed, onFailedHandle)--<<<<< 2
	request:start()
end