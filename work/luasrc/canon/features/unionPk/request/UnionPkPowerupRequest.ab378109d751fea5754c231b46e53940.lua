-- UnionPkPowerupRequest.lua
-- 2014-9-1
-- zheng.che
-- 战前鼓舞接口(3种)

-- 鼓舞接口中BuffId
-- 1：金币鼓舞
-- 2：银币鼓舞
-- 3：奋力一击

require "canon.request.BaseRequest"

UnionPkPowerupRequest = class(BaseRequest)

function UnionPkPowerupRequest:ctor()
  self.endpoint = "inspireUnionBattle"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function UnionPkPowerupRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function UnionPkPowerupRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function UnionPkPowerupRequest.sendRequestDefalut(unionCityId, buffId, afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		UnionPkPowerupRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	UnionPkPowerupRequest.sendRequest(unionCityId, buffId, onSucceed, UnionPkPowerupRequest.onFailedDefault)
end

--发送请求
--unionCityId 目标城池id
--buffId 鼓舞类型
function UnionPkPowerupRequest.sendRequest(unionCityId, buffId, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {unionCityId = unionCityId, buffId = buffId}--<<<<< 3

	local function onSucceedHandle(event)
		if succeedCallback then
			event.params = params
			succeedCallback(event)
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
	local request = UnionPkPowerupRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)
	request:addEventListener(request.failedEventName, onFailedHandle)
	request:start()
end

--成功的默认处理
function UnionPkPowerupRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end

	--增加攻防数 同时扣钱 提示
	local buffId = event.params.buffId
	if buffId == UnionPkConsts.POWERUP_SILVER then
		--银币鼓舞
		UnionManager.setCoinInspireNum(UnionManager.getCoinInspireNum() + 1)
		RewardManager:getReward({{itemType = ResourceEnum.COIN, amount = (-UnionPkConfig.silverBuffCost() or 0)}})

		local scene = Director:mgr():run()
		SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_battle_success1"))--成功使用银币鼓舞
	elseif buffId == UnionPkConsts.POWERUP_GOLD then
		--金币鼓舞
		UnionManager.setGemInspireNum(UnionManager.getGemInspireNum() + 1)
		RewardManager:getReward({{itemType = ResourceEnum.GEMS, amount = (-UnionPkConfig.goldBuffCost() or 0)}})

		local scene = Director:mgr():run()
		SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_battle_success2"))--成功使用金币鼓舞
	else
		--奋力一击
		UnionManager.setStriveInspireNum(UnionManager.getStriveInspireNum() + 1)
		RewardManager:getReward({{itemType = ResourceEnum.GEMS, amount = (-UnionPkConfig.striveCost() or 0)}})
		
		local scene = Director:mgr():run()
		SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_battle_success3"))--成功使用奋力一击
	end
end

--失败默认处理
function UnionPkPowerupRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end