require "canon.request.BaseRequest"

GainInvitedRewardRequest = class(BaseRequest)

--领取邀请好友奖励
function GainInvitedRewardRequest:ctor(params, priority)
	self.endpoint = "gainInvitedReward"
	self.data = nil
	self.params = params
end

function GainInvitedRewardRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GainInvitedRewardSucceed , data ) )
end

function GainInvitedRewardRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.GainInvitedRewardFailed , error ) )
end

function GainInvitedRewardRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = GainInvitedRewardRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GainInvitedRewardSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.GainInvitedRewardFailed, onFailedHandle)--<<<<< 2
	request:start()
end