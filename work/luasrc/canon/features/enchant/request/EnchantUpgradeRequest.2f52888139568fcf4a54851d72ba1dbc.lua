-- EnchantUpgradeRequest.lua
-- 2014-12-17
-- zheng.che
-- 附灵接口

-- <protocol desc="装备附灵">
-- 	<request>
-- 		<property code="equipId" type="int" desc="被附灵装备ID"/>
-- 	</request>
-- 	<response>
-- 		<property code="sharkEquip" ref="SharkEquip" desc="装备信息" />
-- 	</response>
-- </protocol>

require "canon.request.BaseRequest"

EnchantUpgradeRequest = class(BaseRequest)

function EnchantUpgradeRequest:ctor()
  self.endpoint = "equipEnchant"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function EnchantUpgradeRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function EnchantUpgradeRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function EnchantUpgradeRequest.sendRequestDefalut(equipData, afterSucceedCallback)--<<<<< 3
	local function onSucceed(evt)
		EnchantUpgradeRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	EnchantUpgradeRequest.sendRequest(equipData, onSucceed, EnchantUpgradeRequest.onFailedDefault)
end

--发送请求
--equipData 装备数据
function EnchantUpgradeRequest.sendRequest(equipData, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local params = {equipId = equipData.equipId}--<<<<< 3

	local function onSucceedHandle(event)
		if succeedCallback then
			event.params = params
			event.equipData = equipData
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
	local request = EnchantUpgradeRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(request.succeedEventName, onSucceedHandle)
	request:addEventListener(request.failedEventName, onFailedHandle)
	request:start()
end

--成功的默认处理
function EnchantUpgradeRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. table.tostring(event))
	end

	local equipData = event.equipData
	local enchantInfo = EnchantUtils.findEnchantInfo(equipData.metaId, equipData.enchantLevel)

	--扣灵值
	EnchantData.setEnchantPoint(EnchantData.getEnchantPoint() - enchantInfo.cost)

	--加附灵等级
	equipData.enchantLevel = event.data.sharkEquip.enchantLevel
	--增加累计消耗
	equipData.enchantNum = event.data.sharkEquip.enchantNum

	--背包里的装备换成新的
	local gameData = DataManager.getGameInitData()
	for i, v in ipairs(gameData.sharkEquips.sharkEquips) do
		if v.equipId == equipData.equipId then
			v.enchantLevel = equipData.enchantLevel
			gameData.sharkEquips.sharkEquips[i] = event.data.sharkEquip
		end
	end
	DataManager.setGameInitData(gameData)

	--卡牌属性下次需要重新计算
	CommonManager:setCardNeedUpdate({event.data.sharkEquip.cardId})

	--给提示
	local scene = Director:mgr():run()
	SuspensionLabel:showContent(scene, Localization:getInstance():getText("enchant_10"))--附灵成功！

	--必定显示战力变更动画
	DataManager.fightCapacityMaybeUpdated()
end

--失败默认处理
function EnchantUpgradeRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end