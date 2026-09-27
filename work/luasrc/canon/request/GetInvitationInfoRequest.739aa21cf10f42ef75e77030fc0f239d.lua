require "canon.request.BaseRequest"

GetInvitationInfoRequest = class(BaseRequest)

--领取邀请好友奖励
function GetInvitationInfoRequest:ctor(params, priority)
	self.endpoint = "getInvitationInfo"
	self.data = nil
	self.params = params
end

function GetInvitationInfoRequest:onSuccess( data )
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetInvitationInfoSucceed , data ) )
end

function GetInvitationInfoRequest:onError(error)
  self:dispatchEvent( Event.new( RequestNotifyEnum.GetInvitationInfoFailed , error ) )
end

function GetInvitationInfoRequest.sendRequest(Data, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = GetInvitationInfoRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GetInvitationInfoSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.GetInvitationInfoFailed, onFailedHandle)--<<<<< 2
	request:start()
end