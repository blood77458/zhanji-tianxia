-- PhoneChargeGetInfoRequest.lua
-- 2014-7-16
-- zheng.che
-- 获得充值活动最新状态接口

require "canon.request.BaseRequest"

PhoneChargeGetInfoRequest = class(BaseRequest)

function PhoneChargeGetInfoRequest:ctor()
  self.endpoint = "getDailyRecharge"--<<<<< 1. 修改指令名称 后端提供
end

function PhoneChargeGetInfoRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.PhoneChargeGetInfoSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function PhoneChargeGetInfoRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.PhoneChargeGetInfoFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function PhoneChargeGetInfoRequest.sendRequestDefalut()--<<<<< 3
	PhoneChargeGetInfoRequest.sendRequest(PhoneChargeGetInfoRequest.onSucceedDefault, PhoneChargeGetInfoRequest.onFailedDefault)
end

function PhoneChargeGetInfoRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {}--<<<<< 3

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
	local request = PhoneChargeGetInfoRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.PhoneChargeGetInfoSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.PhoneChargeGetInfoFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function PhoneChargeGetInfoRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end

	--设置为今日是否充值状态
	Activity_PhoneChargeLayer.setTodayRechargedState(event.data.dailyRecharge)
end

--失败默认处理
function PhoneChargeGetInfoRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	CanonMessageBox:showCommUnHandleErrorBox(errorCode)
end