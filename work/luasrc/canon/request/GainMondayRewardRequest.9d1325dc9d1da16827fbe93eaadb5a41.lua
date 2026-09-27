require "canon.request.BaseRequest"

GainMondayRewardRequest = class(BaseRequest)

function GainMondayRewardRequest:ctor(params, priority)
	self.endpoint = "gainMondayReward"
	self.data = nil
	self.params = params
end

function GainMondayRewardRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GainMondayRewardSucceed , data ) )
end

function GainMondayRewardRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.GainMondayRewardFailed , error ) )
end

function GainMondayRewardRequest.sendRequest(params , succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = GainMondayRewardRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GainMondayRewardSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.GainMondayRewardFailed, onFailedHandle)--<<<<< 2
	request:start()
end