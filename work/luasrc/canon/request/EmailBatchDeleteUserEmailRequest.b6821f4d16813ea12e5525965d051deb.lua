-- EmailBatchDeleteUserEmailRequest.lua
-- 2014-6-17 zheng.che
-- 批量删除用户邮件

require "canon.request.BaseRequest"

EmailBatchDeleteUserEmailRequest = class(BaseRequest)

function EmailBatchDeleteUserEmailRequest:ctor()
  self.endpoint = "batchDeleteUserEmail"--<<<<< 1. 修改指令名称 后端提供
end

function EmailBatchDeleteUserEmailRequest:onSuccess( data )  
	if SystemManager.debug then
		print("onSuccess! data = " .. tostringRich(data))
	end
	self:dispatchEvent(Event.new(RequestNotifyEnum.EmailBatchDeleteUserEmailSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function EmailBatchDeleteUserEmailRequest:onError( error )
	if SystemManager.debug then
		print("onError! error = " .. tostringRich(error))
	end
	self:dispatchEvent(Event.new(RequestNotifyEnum.EmailBatchDeleteUserEmailFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

--emailIds 删除列表
function EmailBatchDeleteUserEmailRequest.sendRequest(emailIds, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(emailIds, event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	
	local params = {userEmailIds = emailIds}--<<<<<3
	if SystemManager.debug then
		print("params = " .. tostringRich({params}))--<<<<< 3
	end
	local request = EmailBatchDeleteUserEmailRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.EmailBatchDeleteUserEmailSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.EmailBatchDeleteUserEmailFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function EmailBatchDeleteUserEmailRequest.onSucceedDefault(emailIds, event)--<<<<< 3
end

--失败默认处理
function EmailBatchDeleteUserEmailRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	CanonMessageBox:showCommUnHandleErrorBox(errorCode)
--SHARK_EMAILS_IS_NULL(2601, "SharkEmails is null: {0:uid}"),
end