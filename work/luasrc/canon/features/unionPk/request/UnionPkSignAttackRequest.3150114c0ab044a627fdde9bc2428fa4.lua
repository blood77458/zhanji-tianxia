-- UnionPkSignAttackRequest.lua
-- 2014-8-12
-- zheng.che
-- 军团战 报名攻打城池

require "canon.request.BaseRequest"

UnionPkSignAttackRequest = class(BaseRequest)

function UnionPkSignAttackRequest:ctor()
  self.endpoint = "applyUnionCity"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function UnionPkSignAttackRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function UnionPkSignAttackRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function UnionPkSignAttackRequest.sendRequestDefalut(unionCityId, afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		UnionPkSignAttackRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	UnionPkSignAttackRequest.sendRequest(unionCityId, onSucceed, UnionPkSignAttackRequest.onFailedDefault)
end

--发送请求
function UnionPkSignAttackRequest.sendRequest(unionCityId, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {unionCityId = unionCityId}--<<<<< 3

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
	local request = UnionPkSignAttackRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)
	request:addEventListener(request.failedEventName, onFailedHandle)
	request:start()
end

--成功的默认处理
function UnionPkSignAttackRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end

	--标记为已报名此城池
	UnionPkData.addSignedCity(event.params.unionCityId)
end

--失败默认处理
function UnionPkSignAttackRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)

	if errorCode == 716641 then
		--军团等级不足 提示告知所需等级
		local cityTypeId = UnionPkUtils.getCityTypeById(event.params.unionCityId)
		local singLimitUnionLevel = UnionPkConfig.getSignUnionLevelByCityId(cityTypeId)
		CanonMessageBox.showTextBox(getTextByKey("UnionWar_optimize_supply", {num1 = singLimitUnionLevel}))--主公，您的军团等级需要大于{num1}级才能报名本城池。
		return
	end

	if errorCode == 716642 then
		--军团战力不足 提示告知所需战力
		local cityTypeId = UnionPkUtils.getCityTypeById(event.params.unionCityId)
		local singLimitFightCapacity = UnionPkConfig.getSignFightCapacityByCityId(cityTypeId)
		CanonMessageBox.showTextBox(getTextByKey("UnionWar_optimize_supply1", {num1 = singLimitFightCapacity}))--主公，您的军团所有成员战力总和大于{num1}才能进行报名。
		return
	end
	
	local function onErrorConfirm(errorCode)
		if errorCode == 716428 then
			--权限不够 刷新权限相关的数据
			local function onGetDataComplete(getDataEvent)
				UnionGetMyDataRequest.onSucceedDefault(getDataEvent)

				--通知更新
				UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionPkConsts.UNIONPK_USERDATA_UPDATE))
			end
			UnionGetMyDataRequest.sendRequest(onGetDataComplete, UnionGetMyDataRequest.onFailedDefault)
			return
		end

		if errorCode == 716606 then
			--报名的军团数量达到上限 标记城池为人满
			UnionPkData.setCityErrorTag(event.params.unionCityId, UnionPkConsts.CITY_ERROR_TAG_SIGN_FULL)--记录该城池id 防止再次请求
			return
		end
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end