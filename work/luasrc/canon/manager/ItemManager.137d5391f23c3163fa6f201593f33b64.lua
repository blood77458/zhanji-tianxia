-- ItemManager.lua
-- 2014-8-14
-- zheng.che
-- 物品管理类

ItemManager = {}

------------------------------------------------------------------------------------------------------

--卡牌类型
ItemManager.CARD_TYPE_NORMAL 	= 0--普通卡牌
ItemManager.CARD_TYPE_BRON 		= 1--万能转生卡
ItemManager.CARD_TYPE_MILK 		= 2--奶牛系列

--预设类型 其实就是写死 <cardGroupId, type>
local _typeHash = {}
_typeHash[495] = ItemManager.CARD_TYPE_MILK
_typeHash[496] = ItemManager.CARD_TYPE_MILK
_typeHash[497] = ItemManager.CARD_TYPE_MILK

------------------------------------------------------------------------------------------------------

--查询卡牌类型 通过卡组编号
function ItemManager.getCardTypeByGroupId(cardGroupId)
	cardGroupId = tonumber(cardGroupId)
	--print("cardGroupId = " .. tostringRich(cardGroupId))

	--先检查有没有预设类型
	local checkType = _typeHash[cardGroupId]
	if checkType ~= nil then
		return checkType
	end

	if cardGroupId >= 600 and cardGroupId < 700 then
		--print("ItemManager.CARD_TYPE_BRON!")
		return ItemManager.CARD_TYPE_BRON
	end
	return ItemManager.CARD_TYPE_NORMAL
end

--查询卡牌类型 (只考虑卡牌类型因素)
function ItemManager.getCardTypeByMetaId(metaId)
	local metaData = MetaManager.card_meta[metaId]

	if SystemManager.debug then
		DebugManager.assert(metaData ~= nil, "查无此卡牌! metaId = " .. tostringRich(metaId))
	end
	
	local cardGroupId = metaData.cardGroupId
	return ItemManager.getCardTypeByGroupId(cardGroupId)
end

--查询卡牌是否允许强化 (只考虑卡牌类型因素)
function ItemManager.checkCardTypeCanUpgrade(metaId)
	local cardType = ItemManager.getCardTypeByMetaId(metaId)
	if cardType == ItemManager.CARD_TYPE_BRON then
		--万能转生卡不允许强化
		return false
	end
	return true
end

--查询卡牌是否允许作为强化材料 (只考虑卡牌类型因素)
function ItemManager.checkCardTypeCanUseToUpgrade(metaId)
	local cardType = ItemManager.getCardTypeByMetaId(metaId)
	if cardType == ItemManager.CARD_TYPE_BRON then
		--万能转生卡不允许作为强化材料
		return false
	end
	return true
end

--查询卡牌是否允许作为主卡牌转生 (只考虑卡牌类型因素)
function ItemManager.checkCardTypeCanEvolve(metaId)
	local cardType = ItemManager.getCardTypeByMetaId(metaId)
	if cardType == ItemManager.CARD_TYPE_BRON then
		--万能转生卡不允许转生
		return false
	end
	return true
end

--查询卡牌是否允许培养 (只考虑卡牌类型因素)
function ItemManager.checkCardTypeCanTrain(metaId)
	local cardType = ItemManager.getCardTypeByMetaId(metaId)
	if cardType == ItemManager.CARD_TYPE_BRON then
		--万能转生卡不允许培养
		return false
	end
	if cardType == ItemManager.CARD_TYPE_MILK then
		--奶牛不允许培养
		return false
	end
	return true
end

--查询卡牌是否允许祈祷 (只考虑卡牌类型因素)
function ItemManager.checkCardTypeCanPray(metaId)
	local cardType = ItemManager.getCardTypeByMetaId(metaId)
	if cardType == ItemManager.CARD_TYPE_BRON then
		--万能转生卡不允祈祷
		return false
	end
	return true
end

--查询卡牌是否允许以旧换新消耗 (只考虑卡牌类型因素)
function ItemManager.checkCardTypeCanOldToNew(metaId)
	local cardType = ItemManager.getCardTypeByMetaId(metaId)
	if cardType == ItemManager.CARD_TYPE_BRON then
		--万能转生卡不允许
		return false
	end
	if cardType == ItemManager.CARD_TYPE_MILK then
		--奶牛不允许
		return false
	end
	return true
end

------------------------------------------------------------------------------------------------------

--获得卡牌以旧换新 可选卡牌列表 带排序
-- targetCardMetaId 要兑换的卡牌metaId
function ItemManager.getOldToNewMatterCards(targetCardMetaId , specialCard)
	--print("targetCardMetaId = " .. tostringRich(targetCardMetaId))
	local cardData = DataManager.getCardsData()
	local reslut = {}
	-- local queueData = CommonManager.getQueueData()
	-- for k, v in pairs(CommonManager:getMatrixCardData()) do
	-- 	table.insert(queueData, v)
	-- end
	-- local queueHash = {}
	-- for _,value in pairs(queueData) do
	-- 	queueHash[value] = true
	-- end
	local queueHash = {} --改成多阵容状态
	local gameData = DataManager.getGameInitData()
	for BattleArrayId = 1,3 do
		local quedata = gameData.sharkUserBattleArray[BattleArrayId] and gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue or {}
		local matdata = gameData.sharkUserBattleArray[BattleArrayId] and gameData.sharkUserBattleArray[BattleArrayId].sharkMatrices and 
						gameData.sharkUserBattleArray[BattleArrayId].sharkMatrices.sharkMatrices or {}
		for k,v in pairs(quedata) do
			if v.cardId then queueHash[v.cardId] = true end
		end
		for k,v in pairs(matdata) do
			if not v.sharkMatrixGrids then v.sharkMatrixGrids = {} end
			for _,value in pairs(v.sharkMatrixGrids) do
				if value.cardId then queueHash[value.cardId] = true end
			end		
		end			
	end

	local targetCardGroupId = MetaManager.card_meta[targetCardMetaId].cardGroupId
	local targetCardRare = MetaManager.card_meta[targetCardMetaId].rare

	local specialGroupMeta = MetaManager.getSpecialGroupMeta()

	for k,card in pairs(cardData) do
		local found = false

		--print("card = " .. tostringRich(card))
		--local cardName = CanonGoodIcon.getGoodName(ResourceEnum.CARD, card.metaId, 0, {withoutAmount = true})
		--print("cardName = " .. tostringRich(cardName))

		local slaveCardEvolutionLevel  = MetaManager.card_meta[card.metaId].evolutionLevel
		local slaveCardEvolutionRare  = MetaManager.card_meta[card.metaId].rare
		local slaveCardAstralEssence  = MetaManager.card_meta[card.metaId].astralEssence

		if card.lock then
			--上锁的不能选
			--print("上锁的不能选")
			found = true
		elseif card.metaId == targetCardMetaId then
			--相同meta卡牌 不能选
			--print("相同meta卡牌 不能选")
			found = true
		elseif slaveCardEvolutionLevel > 1 then
			--阶数不满足要求 不能选
			--print("阶数不满足要求 不能选")
			found = true
		elseif slaveCardEvolutionRare ~= targetCardRare then
			--要求星数不匹配 不能选
			--print("要求星数不匹配 不能选")
			found = true
		elseif queueHash[card.cardId] == true then
			--正在使用的卡牌 不能选
			--print("正在使用的卡牌 不能选")
			found = true
		elseif not ItemManager.checkCardTypeCanOldToNew(card.metaId) then
			--卡牌类型不允许选择
			--print("卡牌类型不允许选择")
			found = true
		elseif slaveCardAstralEssence <= 0 then
			--星灵数不满足要求 不能选
			--print("星灵数不满足要求 不能选")
			found = true
		elseif card.level > 1 then
			--升级过 废了 不能选
			--print("升级过 废了 不能选")
			found = true
		end

		if specialCard == true then
			local groups = specialGroupMeta[targetCardGroupId]
			local isFind = false
			for k,v in pairs(groups) do
				if tonumber(v) == tonumber(MetaManager.card_meta[card.metaId].cardGroupId) then
					isFind = true
				end
			end
			if not isFind then
				found = true
			end
		end

		if targetCardRare == 6 then
			--6星卡牌
			if not CommonManager:checkTwoCardsInOneGroup(card.metaId, targetCardMetaId) then
				--不是同名卡牌 不能选
			--print("不是同名卡牌 不能选")
				found = true
			end
		end

		if not found then
			if CommonManager:checkTwoCardsInOneGroup(card.metaId, targetCardMetaId) then
				--缘分卡牌
				card.oldTONew_isFateCard = true
			else
				--不是缘分卡牌
				card.oldTONew_isFateCard = false
			end
			table.insert(reslut, card)
		end
	end

	--排序 返回false表示交换
	local function cardSortFunc(a, b)
		local isSameNameA = a.oldTONew_isFateCard
		local isSameNameB = b.oldTONew_isFateCard

		--同名卡牌排前面
		if isSameNameA ~= isSameNameB then
			return isSameNameA
		end
		return a.metaId < b.metaId
	end
	table.sort(reslut, cardSortFunc)
	return reslut
end