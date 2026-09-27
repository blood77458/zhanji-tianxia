require "hecore.display.CocosObject"
SpiritManager = {}

local spiritFreeRefreshTimes = 0

function SpiritManager.getColorByRarity( rarity )
	if rarity == 1 then
		return ccc3(125,125,125)
	elseif rarity == 2 then
		return ccc3(1 , 215 ,21)
	elseif rarity == 3 then
		return ccc3(0,183,236)
	elseif rarity == 4 then
		return ccc3(231 ,0,217)
	elseif rarity == 5 then
		return ccc3(244 ,155,0)
	elseif rarity == 6 then
		return ccc3(234 ,85,4)
	elseif rarity == 7 then
		return ccc3(255 ,222,0)
	else
		return ccc3(255,255,255)
	end
end

function SpiritManager.getTextBySpiritAttrType( attrtype )
	if attrtype == 1 then
		return getTextByKey("attr_Attack")
	elseif attrtype == 2 then
		return getTextByKey("attr_Defense")
	elseif attrtype ==3 then
		return getTextByKey("attr_HP")
	elseif attrtype == 6 then
		return getTextByKey("crtLevel")
	elseif attrtype == 7 then
		return getTextByKey("touLevel")
	elseif attrtype == 8 then
		return getTextByKey("hitLevel")
	elseif attrtype == 9 then
		return getTextByKey("evaLevel")
	elseif attrtype == 10 then
		return getTextByKey("parLevel")
	elseif attrtype == 11 then
		return getTextByKey("prcLevel")
	elseif attrtype == 100 then
		return getTextByKey("spiritExp")
	else
		return nil
	end
end

function SpiritManager.getAllAttributesValue( spirit )
	local attributesTable = {}
	local spiritMetaData = MetaManager.spirit_meta[spirit.metaId]
	local mainAttrValue = spiritMetaData.mainAttributeGrowth * spirit.level
	if spiritMetaData.mainAttributeType == 100 then
		mainAttrValue = spiritMetaData.mainAttributeGrowth
	end
	table.insert(attributesTable , mainAttrValue)
	for k,v in pairs(spirit.sharkSpiritAttributes) do
		local subAttrValue = getFloatNumber(v.attributeGrowing) * spirit.level
		table.insert(attributesTable , subAttrValue)
	end
	for k,v in pairs(attributesTable) do
		attributesTable[k] = math.floor(v)
	end
	return attributesTable
end

function SpiritManager.isExpSpirit( spirit )
	local spiritMetaData = MetaManager.spirit_meta[spirit.metaId]
	if spiritMetaData.mainAttributeType == 100 then
		return true
	else
		return false
	end
end

function SpiritManager.getMainAttributeName( spirit )
	local spiritMetaData = MetaManager.spirit_meta[spirit.metaId]
	return SpiritManager.getTextBySpiritAttrType(spiritMetaData.mainAttributeType)
end

function SpiritManager.getMainAttributeGrow( spirit )
	local spiritMetaData = MetaManager.spirit_meta[spirit.metaId]
	return spiritMetaData.mainAttributeGrowth
end

function SpiritManager.getSpiritName( spirit )
	local spiritMetaData = MetaManager.spirit_meta[spirit.metaId]
	return getTextByKey(spiritMetaData.nameKey)
end

function SpiritManager.getSpiritRare( spirit )
	return MetaManager.spirit_meta[spirit.metaId].rarity
end

function SpiritManager.getSpiritPrice( spirit )
	return MetaManager.spirit_meta[spirit.metaId].price
end

function SpiritManager.calcSpiritTotalGridNum()
  -- bought grid
  local boughtGridNum = 0
  if DataManager.getGameInitData().sharkUserExtend ~= nil then
    boughtGridNum = DataManager.getGameInitData().sharkUserExtend.boughtSpiritPoolNum * DataManager.GameMetaData.spiritSettingConfig.spiritPoolExtraSizePerPurchase
  end

  local initGridNum = DataManager.GameMetaData.spiritSettingConfig.spiritPoolInitSize
  local totalGridNum = boughtGridNum + initGridNum

  return totalGridNum, boughtGridNum, initGridNum
end

function SpiritManager.calcSpiritUsingGridNum()
	local spirit_meta = DataManager.getSpiritsData()
	local usingGridNum = 0
	for k,v in pairs(spirit_meta) do
		if v.cardId == 0 then
			usingGridNum = usingGridNum + 1
		end
	end
	return usingGridNum
end

function SpiritManager.isSpiritPoolFull(  )
	if SpiritManager.calcSpiritUsingGridNum() >= SpiritManager.calcSpiritTotalGridNum() then
		return true
	else
		return false
	end
end

function SpiritManager.getSpiritExp( spirit )
	-- local spiritMetaData = MetaManager.spirit_meta[spirit.metaId]
	local rarity = SpiritManager.getSpiritRare( spirit )
	if SpiritManager.isSpiritFullLevel(spirit) then
		local exp = MetaManager.spirit_level[#MetaManager.spirit_level]["rarity"..rarity.."exp"]
		return exp , exp
	end
	local totalExp = MetaManager.spirit_level[spirit.level + 1]["rarity"..rarity.."exp"]
	return spirit.exp , totalExp
end

function SpiritManager.isVipEnough()
	local minLevel = 999999
	local unlockType = 19
	for k,vsetting in pairs(MetaManager.vip_setting) do
		local unlockList = vsetting.unlockContents:split(",")
		for k,vtype in pairs(unlockList) do
			if(tonumber(vtype) == unlockType) and vsetting.level < minLevel then
				minLevel = vsetting.level
			end
		end
	end
	if DataManager.getGameInitData().sharkUser.vipLevel >= minLevel then
		return true
	else
		return false	
	end
end

function SpiritManager.getRefreshPropNum()
	local propId = DataManager.GameMetaData.spiritSettingConfig.refreshPropId
	return  BagCalcManager.getNumById(propId)
end

function SpiritManager.useRefreshPropNum( num )
	local propId = DataManager.GameMetaData.spiritSettingConfig.refreshPropId
	RewardManager:getReward({{itemType = ResourceEnum.PROP, metaId = propId, amount = -num}})
end

function SpiritManager.setFreeRefreshTimes( times )
	spiritFreeRefreshTimes = times
end

function SpiritManager.getFreeRefreshTimes()
	return spiritFreeRefreshTimes
end

function SpiritManager.getComposeEnabledSpirits(spirit)
	local spirit_data = DataManager.getSpiritsData()
	local ret = {}
	for k,v in pairs(spirit_data) do
		if v.cardId == 0 then
			table.insert(ret , v)
		end
	end
	for k,v in pairs(ret) do
		if v.spiritId == spirit.spiritId then
			table.remove(ret , k)
			break
		end
	end
	--阵容状态（不可吞噬）
	local queueList = {}
	local gameData = DataManager.getGameInitData()
	for BattleArrayId = 1,3 do
		local quedata = gameData.sharkUserBattleArray[BattleArrayId] and gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue or {}
		for k,v in pairs(quedata) do
			if (not v.spirits) then v.spirits = {} end
			for _,value in pairs(v.spirits) do
				queueList[value.spiritId] = true
			end		
		end	
	end
	for i = #ret,1,-1 do
		if queueList[ret[i].spiritId] == true then
			table.remove(ret , i) --移除在阵容中的元神
		end
	end	
	--end by l1ghtsaber
	local function sortFunc(a , b)
		local rarityA = SpiritManager.getSpiritRare( a )
		local rarityB = SpiritManager.getSpiritRare( b )

		if rarityA == rarityB then
			if a.level == b.level then
				return a.metaId < b.metaId
			else
				return a.level < b.level
			end
		else
			return rarityA < rarityB
		end
        
    end
    table.sort(ret,sortFunc)
	return ret
end

function SpiritManager.getSpiritContainedExp( spirit )
	local rarity = SpiritManager.getSpiritRare( spirit )
	local exp = 0 
	for i=1,spirit.level do
		exp = exp + MetaManager.spirit_level[i]["rarity"..rarity.."exp"]
	end
	-- local exp = MetaManager.spirit_level[spirit.level]["rarity"..rarity.."exp"]
	local baseExp = MetaManager.spirit_meta[spirit.metaId].baseExp
	return (exp + spirit.exp + baseExp)
end

function SpiritManager.getLevelupNum( spirit , expCompose )
	local ret = 0
	local rarity = SpiritManager.getSpiritRare( spirit )
	
	local expCur , expTotal = SpiritManager.getSpiritExp( spirit )
	local totalExp = expCompose + expCur
	local expNeed = expTotal - expCur
	if expNeed > expCompose then
		return 0
	end
	local lv = 1
	for i=1,#MetaManager.spirit_level - spirit.level do--这里需要测一下直接升到最高级的情况
		local level = spirit.level + i + 1
		if spirit.level + i + 1 > #MetaManager.spirit_level then
			level = #MetaManager.spirit_level
			return #MetaManager.spirit_level - spirit.level
		end
		local exp = MetaManager.spirit_level[level]["rarity"..rarity.."exp"]
		expNeed = expNeed + exp
		if expNeed > expCompose then
			return lv
		end
		lv = lv + 1
	end
	return 0
end

function SpiritManager.getSpiritRefreshGemCost( spirit )
	return MetaManager.spirit_meta[spirit.metaId].refreshGoldCost
end

function SpiritManager.getSpiritRefreshPropmCost( spirit )
	return MetaManager.spirit_meta[spirit.metaId].refreshItemCost
end

function SpiritManager.getSpiritEquipPos( spirit )
	local cardsData = DataManager.getCardsData()
	if spirit.cardId ~= 0 then
		for _, aCard in pairs(cardsData) do
	      if aCard.cardId == spirit.cardId then
	      	if aCard.cardSpirits == nil then
	      		return 0 
	      	end
	        for pos,spiritTemp in pairs(aCard.cardSpirits) do
				if spiritTemp.spiritId == spirit.spiritId then
					return spiritTemp.index
				end
			end
	      end
	    end
	end
end

function SpiritManager.isSpiritEnable( spirit )
	local cardsData = DataManager.getCardsData()
	local position = 0
	local card
	if spirit.cardId ~= 0 then
		for _, aCard in pairs(cardsData) do
	      if aCard.cardId == spirit.cardId then
	      	card = aCard
	      	if aCard.cardSpirits == nil then
	      		return false 
	      	end
	        for pos,spiritTemp in pairs(aCard.cardSpirits) do
				if spiritTemp.spiritId == spirit.spiritId then
					position = spiritTemp.index
				end
			end
	      end
	    end
	else
		return false
	end
	local rare = MetaManager.card_meta[card.metaId].rare
	local cardSpiritNum = MetaManager.card_rare[rare].spiritNum + MetaManager.card_level[card.level].spiritNum
	if position > cardSpiritNum then
		return false
	else
		return true
	end
end

function SpiritManager.getPlayerAllSpiritOfferedAttribute()
	local attributeTable = {
	hp = 0,
	atk = 0,
	def = 0,
	crt = 0,
	tou = 0,
	hit = 0,
	eva = 0,
	par = 0,
	prc = 0
	}
	local attributeType = {
	[1] = "atk",
	[2] = "def",
	[3] = "hp",
	[6] = "crt",
	[7] = "tou",
	[8] = "hit",
	[9] = "eva",
	[10] = "par",
	[11] = "prc"
}
	local cardsInfo = table.clone(DataManager.getCardsData(), true)
	local queue = table.clone(CommonManager.getQueueData(), true)
	local spiritData = table.clone(DataManager.getSpiritsData(), true)

	for key,value in pairs(queue) do
		queue[key] = CommonManager.getSubTableByKey(
			cardsInfo,
			{name = "cardId", value=value}
		)
	end

	for _, aCard in pairs(queue) do
		local rare = MetaManager.card_meta[aCard.metaId].rare
		local cardSpiritNum = MetaManager.card_rare[rare].spiritNum + MetaManager.card_level[aCard.level].spiritNum
		aCard.cardSpirits = aCard.cardSpirits and aCard.cardSpirits or {}
		
		-- self.spiritData
		--载入元神详情
		aCard.spirits = {}
		for key, aSpiritId in pairs(aCard.cardSpirits) do
			if aSpiritId.index <= cardSpiritNum then
				local spirit = CommonManager.getSubTableByKey(
					spiritData,
					{name = "spiritId", value=aSpiritId.spiritId}
				)
				local mainType = MetaManager.spirit_meta[spirit.metaId].mainAttributeType
				if mainType ~= 100 then
					local mainValue = MetaManager.spirit_meta[spirit.metaId].mainAttributeGrowth * spirit.level
					attributeTable[attributeType[mainType]] = attributeTable[attributeType[mainType]] + mainValue
				end
				for k,v in pairs(spirit.sharkSpiritAttributes) do
					local attrType = v.attributeType
					if attrType~= 100 then
						local value = getFloatNumber(v.attributeGrowing) * spirit.level
						attributeTable[attributeType[attrType]] = attributeTable[attributeType[attrType]] + value
					end
				end
			end
		end

		--ENCHANT_MODIFY 计算附灵的各个二级属性加成
		local equipData = DataManager.getEquipsData()
		if aCard.equipIds then
			for _, aEquipId in ipairs(aCard.equipIds) do
				local aEquip = CommonManager.getSubTableByKey(equipData,{name = "equipId", value = aEquipId})
				if Enchant.isSupportToEnchant(aEquip.metaId) then
					--此装备允许有附灵信息
					local enchantInfo = Enchant.findEnchantInfo(aEquip.metaId, aEquip.enchantLevel)
					for k, attrInfo in pairs(enchantInfo.attrHash) do
						if attributeType[attrInfo.id] then
							attributeTable[attributeType[attrInfo.id]] = attributeTable[attributeType[attrInfo.id]] + attrInfo.num
						end
					end
				end
			end
		end
	end
	for k,v in pairs(attributeTable) do
		attributeTable[k] = math.floor(v)
	end
	return attributeTable
end

function SpiritManager.getSingleAttributeValue( spirit )
	local spiritMetaData = MetaManager.spirit_meta[spirit.metaId]
	local attrValue = spiritMetaData.mainAttributeGrowth 
	if spiritMetaData.mainAttributeType ~= 100 then
		--type100是经验元神，不用乘以等级
		attrValue = attrValue * spirit.level
	end
	return attrValue
end

function SpiritManager.isUserLevelEnough()
	return DataManager.getCurrUser().level >= DataManager.GameMetaData.spiritSettingConfig.unlockLevel
end

function SpiritManager.isSpiritFullLevel( spirit )
	return spirit.level >= #MetaManager.spirit_level
end

function SpiritManager.getCardSpiritOfferedCardStrength( aCard , sharkSpirits)
	local attributeTable = {
	hp = 0,
	atk = 0,
	def = 0,
	crt = 0,
	tou = 0,
	hit = 0,
	eva = 0,
	par = 0,
	prc = 0
	}
	local attributeType = {
	[1] = "atk",
	[2] = "def",
	[3] = "hp",
	[6] = "crt",
	[7] = "tou",
	[8] = "hit",
	[9] = "eva",
	[10] = "par",
	[11] = "prc"
}
	local spiritData
	if not sharkSpirits then
		spiritData = table.clone(DataManager.getSpiritsData(), true)
	else
		spiritData = sharkSpirits
	end
	
	local rare = MetaManager.card_meta[aCard.metaId].rare
	local cardSpiritNum = MetaManager.card_rare[rare].spiritNum + MetaManager.card_level[aCard.level].spiritNum
	aCard.cardSpirits = aCard.cardSpirits and aCard.cardSpirits or {}
	for key, aSpiritId in pairs(aCard.cardSpirits) do
		if aSpiritId.index <= cardSpiritNum then
			local spirit = CommonManager.getSubTableByKey(
				spiritData,
				{name = "spiritId", value=aSpiritId.spiritId}
			)
			if spirit == nil or (MetaManager.spirit_meta[spirit.metaId]) == nil then
				print("哎呀妈呀"..aSpiritId.spiritId)
			end
			local mainType = MetaManager.spirit_meta[spirit.metaId].mainAttributeType
			if mainType ~= 100 then
				local mainValue = MetaManager.spirit_meta[spirit.metaId].mainAttributeGrowth * spirit.level
				attributeTable[attributeType[mainType]] = attributeTable[attributeType[mainType]] + mainValue
			end
			for k,v in pairs(spirit.sharkSpiritAttributes) do
				local attrType = v.attributeType
				if attrType~= 100 then
					local value = getFloatNumber(v.attributeGrowing) * spirit.level
					attributeTable[attributeType[attrType]] = attributeTable[attributeType[attrType]] + value
				end
			end
		end
	end
	for k,v in pairs(attributeTable) do
		attributeTable[k] = math.floor(v)
	end
	return attributeTable
end