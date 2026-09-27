-- EmailGainRewardEmailRewardRequest.lua
-- 2014-6-17 zheng.che
-- 领取邮件奖励

require "canon.request.BaseRequest"

EmailGainRewardEmailRewardRequest = class(BaseRequest)

function EmailGainRewardEmailRewardRequest:ctor()
  self.endpoint = "gainRewardEmailReward"--<<<<< 1. 修改指令名称 后端提供
end

function EmailGainRewardEmailRewardRequest:onSuccess( data )  
	if SystemManager.debug then
		print("onSuccess! data = " .. tostringRich(data))
	end
	self:dispatchEvent(Event.new(RequestNotifyEnum.EmailGainRewardEmailRewardSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function EmailGainRewardEmailRewardRequest:onError( error )
	if SystemManager.debug then
		print("onError! error = " .. tostringRich(error))
	end
	self:dispatchEvent(Event.new(RequestNotifyEnum.EmailGainRewardEmailRewardFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

--rewardEmailId 奖励邮件id
function EmailGainRewardEmailRewardRequest.sendRequest(rewardEmailId, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	
	local params = {rewardEmailId = rewardEmailId}--<<<<<3
	if SystemManager.debug then
		print("params = " .. tostringRich({params}))--<<<<< 3
	end
	local request = EmailGainRewardEmailRewardRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.EmailGainRewardEmailRewardSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.EmailGainRewardEmailRewardFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function EmailGainRewardEmailRewardRequest.onSucceedDefault(event)--<<<<< 3
end

--失败默认处理
function EmailGainRewardEmailRewardRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if errorCode == 710516 then
		NewPackageFullPanel:show()
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
	
-- SHARK_EMAILS_IS_NULL(2601, "SharkEmails is null: {0:uid}"),
-- SHARK_REWARD_EMAIL_NOT_EXIST(2610, "Shark reward email not exist: {0:uid}, {1:rewardEmailId}"),
-- EMAIL_ALREADY_GAINED_REWARD_EMAIL_REWARD(2611, "Already gained reward email reward: {0:uid}, {1:rewardEmailId}"),
end