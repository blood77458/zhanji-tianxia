-- PhoneChargeGainRequest.lua
-- 2014-7-10
-- zheng.che
-- 送话费活动 获取话费

require "canon.request.BaseRequest"

PhoneChargeGainRequest = class(BaseRequest)

function PhoneChargeGainRequest:ctor()
  self.endpoint = "rechargeCalls"--<<<<< 1. 修改指令名称 后端提供
end

function PhoneChargeGainRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.PhoneChargeGainSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function PhoneChargeGainRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.PhoneChargeGainFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function PhoneChargeGainRequest.sendRequestDefalut(phoneNum, callsType)--<<<<< 3
	PhoneChargeGainRequest.sendRequest(phoneNum, callsType, PhoneChargeGainRequest.onSucceedDefault, PhoneChargeGainRequest.onFailedDefault)
end

-- <request>
-- 		<property code="phoneNum" type="String" desc="电话号码" />
-- 		<property code="callsType" type="int" desc="0-单次充值,1-余额充值" />
-- 	</request>
function PhoneChargeGainRequest.sendRequest(phoneNum, callsType, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {phoneNum = phoneNum, callsType = callsType}--<<<<< 3

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
	local request = PhoneChargeGainRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.PhoneChargeGainSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.PhoneChargeGainFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function PhoneChargeGainRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end

	--话费清零
	Activity_PhoneChargeLayer.setPhoneMoneyLeft(0)
	--更新设定的手机号码
	Activity_PhoneChargeLayer.setBindPhoneNumber(event.params.phoneNum)

	--通知更新
	NotificationManager:dispatchEvent(Event.new(Activity_PhoneChargeLayer.PHONE_CHARGE_DATA_UPDATE))

	--提示玩家
	local scene = Director:mgr():run()
	SuspensionLabel:showContent(scene, Localization:getInstance():getText("phoneCharge_chargeSuccess_tips", {num = Activity_PhoneChargeLayer.getBindPhoneNumber()}))--您的话费将会被充入{num}，请注意查收
end

--失败默认处理
function PhoneChargeGainRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local scene = Director:mgr():run()
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 714643) then -- 活动关闭
		local function closeCanonMessageBox()
		end
		local text = Localization:getInstance():getText("activity_error_expired")
		CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	elseif(errorCode == 714644) then --余额不足
		local function closeCanonMessageBox()
		end
		local text = Localization:getInstance():getText("phoneCharge_error_noBalance")--您现在没有可以充入的话费
		CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	elseif(errorCode == 714642) then -- api错误
		local function closeCanonMessageBox()
		end
		local text = Localization:getInstance():getText("phoneCharge_error_apiError")--在充入话费过程中遇到了错误。请联系客服解决。
		CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	elseif(errorCode == 714645) then -- 手机号码不正确
		local function closeCanonMessageBox()
		end
		local text = Localization:getInstance():getText("phoneCharge_error_wrongNumber")--此手机号码不存在，无法充入话费
		CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
-- ACTIVITY_RECHARGE_CALLS_EXCLUSIVE_PLATFORM(4640, "Activities within the exclusive platform:{0:uid}"),
-- 	ACTIVITY_RECHARGE_CALLS_INFO_NOT_EXISTS(4641, "rechargeCallsInfo does not exist:{0:uid}"),
-- 	ACTIVITY_RECHARGE_CALLS_ERROR(4642, "recharge calls error"),
-- ACTIVITY_RECHARGE_CALLS_CLOSED(4643, "recharge calls is closed:{0:uid},(1:featureName)"),
-- 	ACTIVITY_RECHARGE_CALLS_BALANCE_NOT_ENOUGH(4644, "Balance is not enough"),
-- ACTIVITY_RECHARGE_CALLS_PHONE_NUM_ERROR(4645, "phoneNum is wrong:{0:uid},{1:phoneNum}"),

end