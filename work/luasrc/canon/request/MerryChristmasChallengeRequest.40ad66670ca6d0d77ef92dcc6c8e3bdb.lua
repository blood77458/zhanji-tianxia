-- MerryChristmasChallengeRequest.lua
-- luoyang.yi

--[[
	策划文档:
		圣诞活动任务
	目的:
		圣诞活动挑战请求
--]]
require "canon.request.BaseRequest"

MerryChristmasChallengeRequest = class(BaseRequest)

function MerryChristmasChallengeRequest:ctor()
  self.endpoint = "challengeChrist"--<<<<< 1. 圣诞挑战指令 后端提供
end

function MerryChristmasChallengeRequest:onSuccess( data )  
  	self:dispatchEvent(Event.new(RequestNotifyEnum.MerryChristmasChallengeRequestSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function MerryChristmasChallengeRequest:onError( error )
  	self:dispatchEvent(Event.new(RequestNotifyEnum.MerryChristmasChallengeRequestFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function MerryChristmasChallengeRequest.sendRequestDefalut()--<<<<< 3
	MerryChristmasChallengeRequest.sendRequest(MerryChristmasChallengeRequest.onSucceedDefault, MerryChristmasChallengeRequest.onFailedDefault)
end

function MerryChristmasChallengeRequest.sendRequest(succeedCallback, failedCallback,params)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	--local params = {}--<<<<< 3

	local function onSucceedHandle(event)
		if succeedCallback then
			event.params = params
			succeedCallback(event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			event.params = params
			failedCallback(event)
		end
	end
	if SystemManager.debug then
		print("params = " .. table.tostring(params))
	end
	local request = MerryChristmasChallengeRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.MerryChristmasChallengeRequestSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.MerryChristmasChallengeRequestFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function MerryChristmasChallengeRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end
end

--失败默认处理
function MerryChristmasChallengeRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	CanonMessageBox:showCommUnHandleErrorBox(errorCode)
end
