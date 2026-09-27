--
-- UpgradeCardByGeneralExpRequest.lua
-- Author: zheng.che
-- Date: 2014-05-05 11:27:17
-- 卡牌经验强化接口
--

require "canon.request.BaseRequest"

UpgradeCardByGeneralExpRequest = class(BaseRequest)

function UpgradeCardByGeneralExpRequest:ctor()
  self.endpoint = "upgradeCardByGeneralExp"--<<<<< 1. 修改指令名称 后端提供
end

function UpgradeCardByGeneralExpRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UpgradeCardByGeneralExpSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UpgradeCardByGeneralExpRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UpgradeCardByGeneralExpFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function UpgradeCardByGeneralExpRequest.sendRequest(cardData, targetLevel, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			event.requestData = {}
			event.requestData.cardData = cardData
			event.requestData.targetLevel = targetLevel
			succeedCallback(event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end

	local params = {masterId = cardData.cardId, targetLevel = targetLevel}--<<<<< 3
	--print("params = " .. table.tostring(params))
	local request = UpgradeCardByGeneralExpRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UpgradeCardByGeneralExpSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UpgradeCardByGeneralExpFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UpgradeCardByGeneralExpRequest.onSucceedDefault(event)--<<<<< 3
	print("onSucceedDefault! event = " .. table.tostring(event))

	g_previousBattleCount = CommonManager:getLocalPlayerStrength()
		
	local mainCardId = HeMemDataHolder:getInteger("CardCompose_MainCardId")
	local cardData = DataManager.getCardsData()
	for k,card in ipairs(cardData)
	do
		if card.cardId == mainCardId then
			cardData[k] = event.data.sharkCard
			--如果是阵列中的卡牌，就清空g_previousBonusTable
			local queueData = {}
			local matrixCardData = CommonManager:getMatrixCardData()
			for k,v in ipairs(matrixCardData) do 
				if not queueData[v] then
					queueData[v] = k + 100
				end
			end
			if queueData[card.cardId] and queueData[card.cardId] > 100 then
				g_previousBonusTable = nil;
			end
		end
	end
	DataManager.setCardsData(cardData)

	--扣钱扣经验
	local rewardTable = {}
	local needUpgradeCoin, needExp = CardComposeScene.getNeedCoinByTargetLevel(event.requestData.cardData, event.requestData.targetLevel)
	table.insert(rewardTable, {itemType = ResourceEnum.COIN, amount = -needUpgradeCoin})
	table.insert(rewardTable, {itemType = ResourceEnum.GENERALEXP, amount = -needExp})
	RewardManager:getReward(rewardTable)
end

--失败默认处理
function UpgradeCardByGeneralExpRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 711063) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.CARD_TARGET_LEVEL_IS_INVALID, nil, nil, nil)
	elseif(errorCode == 716471) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.GENERAL_EXP_NOT_ENOUGH, nil, nil, nil)
	elseif(errorCode == 710512) then
		--银币不足
		local aPanel = MessageBoxPanel:create(Director:mgr():run(), MessageBoxType.kCoinLimit)
		Director:mgr():run():addChild(aPanel)
		aPanel:scaleIn()
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end

-- SHARKCARDS_IS_NULL(1050, "SharkCards is null: {0:uid}"),
-- SHARKCARD_NOT_EXIST(1051, "User does not own card: {0:uid}, {1:cardId}"),
-- CARD_LEVEL_META_NOT_CONFIGED(1010, "CardLevelMeta is not configed in card-level.xml: {0:level}"),
-- USER_NOT_EXIST(70, "User is not exist: {0:uid}"),
-- CARD_META_NOT_CONFIGED(1001, "Card is not configed in card-meta.xml: {0:metaId}"),
-- CARD_EVOLVE_META_NOT_CONFIGED(1030, "CardEvolveMeta is not configed in card-evolve.xml: {0:evolveLevel}"),
-- CARD_TARGET_LEVEL_IS_INVALID(1063, "Card valid target level: {0:uid}, {1:cardId},{2:targetLevel}"),
-- GENERAL_EXP_NOT_ENOUGH(6471, "generalExp is not enough:{0:uid}, {1:currPoints}, {2:needPoints}"),
-- REQUISITE_COIN_NOT_ENOUGH(512, "Coin is not enough: {0:uid}, {1:currCoin}, {2:needCoin}"),
end