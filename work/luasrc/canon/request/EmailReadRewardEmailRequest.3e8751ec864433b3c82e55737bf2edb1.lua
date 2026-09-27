-- EmailReadRewardEmailRequest.lua
-- 2014-6-17 zheng.che
-- 标记奖励邮件为已读

require "canon.request.BaseRequest"

EmailReadRewardEmailRequest = class(BaseRequest)

function EmailReadRewardEmailRequest:ctor()
  self.endpoint = "readRewardEmail"--<<<<< 1. 修改指令名称 后端提供
end

function EmailReadRewardEmailRequest:onSuccess( data )  
	if SystemManager.debug then
		print("onSuccess! data = " .. tostringRich(data))
	end
	self:dispatchEvent(Event.new(RequestNotifyEnum.EmailReadRewardEmailSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function EmailReadRewardEmailRequest:onError( error )
	if SystemManager.debug then
		print("onError! error = " .. tostringRich(error))
	end
	self:dispatchEvent(Event.new(RequestNotifyEnum.EmailReadRewardEmailFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

--rewardEmailId 奖励邮件id
function EmailReadRewardEmailRequest.sendRequest(rewardEmailId, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = EmailReadRewardEmailRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.EmailReadRewardEmailSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.EmailReadRewardEmailFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function EmailReadRewardEmailRequest.onSucceedDefault(event)--<<<<< 3
end

--失败默认处理
function EmailReadRewardEmailRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	CanonMessageBox:showCommUnHandleErrorBox(errorCode)
--SHARK_EMAILS_IS_NULL(2601, "SharkEmails is null: {0:uid}"),
-- SHARK_REWARD_EMAIL_NOT_EXIST(2610, "Shark reward email not exist: {0:uid}, {1:rewardEmailId}"),
end