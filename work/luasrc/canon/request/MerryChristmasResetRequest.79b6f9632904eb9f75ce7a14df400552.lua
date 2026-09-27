-- MerryChristmasResetRequest.lua
-- zhehua.ou

--[[
	策划文档:
		圣诞活动任务
	目的:
		圣诞活动刷新次数请求
--]]
require "canon.request.BaseRequest"

MerryChristmasResetRequest = class(BaseRequest)

function MerryChristmasResetRequest:ctor()
  self.endpoint = "resetChrist"--<<<<< 1. 圣诞刷新次数指令 后端提供
end

function MerryChristmasResetRequest:onSuccess( data )  
  	self:dispatchEvent(Event.new(RequestNotifyEnum.MerryChristmasResetRequestSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function MerryChristmasResetRequest:onError( error )
  	self:dispatchEvent(Event.new(RequestNotifyEnum.MerryChristmasResetRequestFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function MerryChristmasResetRequest.sendRequestDefalut()--<<<<< 3
	MerryChristmasResetRequest.sendRequest(MerryChristmasResetRequest.onSucceedDefault, MerryChristmasResetRequest.onFailedDefault)
end

function MerryChristmasResetRequest.sendRequest(succeedCallback, failedCallback,params)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = MerryChristmasResetRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.MerryChristmasResetRequestSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.MerryChristmasResetRequestFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function MerryChristmasResetRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end
end

--失败默认处理
function MerryChristmasResetRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	CanonMessageBox:showCommUnHandleErrorBox(errorCode)
end