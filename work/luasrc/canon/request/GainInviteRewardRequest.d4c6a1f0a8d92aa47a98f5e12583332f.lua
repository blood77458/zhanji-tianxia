require "canon.request.BaseRequest"

GainInviteRewardRequest = class(BaseRequest)

--领取邀请好友奖励
function GainInviteRewardRequest:ctor(params, priority)
	self.endpoint = "gainInviteReward"
	self.data = nil
	self.params = params
end

function GainInviteRewardRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GainInviteRewardSucceed , data ) )
end

function GainInviteRewardRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.GainInviteRewardFailed , error ) )
end

function GainInviteRewardRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = GainInviteRewardRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GainInviteRewardSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.GainInviteRewardFailed, onFailedHandle)--<<<<< 2
	request:start()
end