-- PhoneChargeSetNumRequest.lua
-- 2014-7-10
-- zheng.che
-- 修改/设定玩家手机号码

require "canon.request.BaseRequest"

PhoneChargeSetNumRequest = class(BaseRequest)

function PhoneChargeSetNumRequest:ctor()
  self.endpoint = "defaultPhoneNum"--<<<<< 1. 修改指令名称 后端提供
end

function PhoneChargeSetNumRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.PhoneChargeSetNumSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function PhoneChargeSetNumRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.PhoneChargeSetNumFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function PhoneChargeSetNumRequest.sendRequestDefalut(phoneNum)--<<<<< 3
	PhoneChargeSetNumRequest.sendRequest(phoneNum, PhoneChargeSetNumRequest.onSucceedDefault, PhoneChargeSetNumRequest.onFailedDefault)
end

function PhoneChargeSetNumRequest.sendRequest(phoneNum, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {phoneNum = phoneNum}--<<<<< 3

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
	local request = PhoneChargeSetNumRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.PhoneChargeSetNumSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.PhoneChargeSetNumFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function PhoneChargeSetNumRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end

	--更改设定的手机号码
	Activity_PhoneChargeLayer.setBindPhoneNumber(event.params.phoneNum)

	--通知更新
	NotificationManager:dispatchEvent(Event.new(Activity_PhoneChargeLayer.PHONE_CHARGE_DATA_UPDATE))

	--提示玩家
	local scene = Director:mgr():run()
	SuspensionLabel:showContent(scene, Localization:getInstance():getText("phoneCharge_bindSuccess_tips"))--成功绑定手机号码
end

--失败默认处理
function PhoneChargeSetNumRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	CanonMessageBox:showCommUnHandleErrorBox(errorCode)
end