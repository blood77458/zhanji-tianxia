--------------------------------------------------------------------------------
-- CardQueueScene.lua - 卡牌队列界面
-- author: shaomin.shi & fangzhou.long
-- date: 2013-08-12
--------------------------------------------------------------------------------
require "hecore.ui.TableView"

require "canon.scene.BaseUIScene"
require "canon.scene.BackpackScene"
require "canon.scene.SkillEvolveScene"
require "canon.scene.AdjustTeamScene"
require "canon.scene.EquipQuickUpgradeScene"

require "canon.panel.SkillInfoPanel"
require "canon.panel.SkillShowAndUpgradePanel"
require "canon.panel.QueueCardPanel"
require "canon.panel.QueueSpiritPanel"
require "canon.panel.SpiritInfoPanel"
require "canon.scene.FateScene"

require "canon.features.multilineup.request.ChangeBattleArrayRequest"
require "canon.features.multilineup.manager.BitOperManager"


local Table_width = 656
local TableCell_width = Table_width/4
local Table_height = 180  --原版250
local Table_posX = 13.5
local Table_posY = -200  --原版225
local Item_width = 155
local Item_height = 250
local original_scroll_duration = 0.5

local enter_animation_duration = 0.3

g_oldQueueStatus = nil

CardQueueScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local refresh = true

local tableOffsetUpper = 0
local tableOffsetLower = 0
local rollSpeed = 0
local ROLLTIME = 10

local function setCocosObjectColor(obj, color)
	for k,v in pairs(obj.list)
	do
		if type(v.setColor) == "function" then
			v:setColor(color)
		end
		if type(v.list) == "table" then
			setCocosObjectColor(v, color)
		end
	end
end

CardQueueScene.ListTags = {
	ICON_TITLE = -11, --下方文本框
	ICON_TITLE_TEXT = -11, --下方文本框内文字
	ICON_BG = -12, --下方文本框背景
	ICON_FRAME = -13, --卡牌添加的定位点
	ICON_SHADOW = -14, --卡牌选择阴影框
	FRAME_ADD = -15, --卡牌添加加号图片
	ICON_MAIN = -16, --左上角主将标志
	ICON_ADD = -17, --旋转的粒子效果
	CELL = -10,
	LAYER = -1001,
}

function CardQueueScene:onUpdate(dt)
	BaseUIScene.onUpdate(self, dt)
	if self.isCurShowSpiritTableView then
		local offset = self.cardPanelSpirit.tableUI:getContentOffset()
		self.cardPanel.tableUI:setContentOffset(offset)
	else
		local offset = self.cardPanel.tableUI:getContentOffset()
		self.cardPanelSpirit.tableUI:setContentOffset(offset)
	end
	if (rollSpeed==0 and self.rolling) then
		rollSpeed = (tableOffsetUpper - self.tableOffsetUpperTarget)/ROLLTIME
		rollSpeed = math.abs(rollSpeed)
	end
	--滚动函数
	if (self.rolling) then
		self.tableUI:setContentOffset(ccp(tableOffsetUpper, 0))
		
		if (tableOffsetUpper>self.tableOffsetUpperTarget+rollSpeed) then
			tableOffsetUpper = tableOffsetUpper - rollSpeed
		elseif (tableOffsetUpper<self.tableOffsetUpperTarget-rollSpeed) then
			tableOffsetUpper = tableOffsetUpper + rollSpeed
		elseif (tableOffsetUpper~=self.tableOffsetUpperTarget) then
			tableOffsetUpper = self.tableOffsetUpperTarget
		elseif (tableOffsetUpper==self.tableOffsetUpperTarget) then
			self.rolling = false
			rollSpeed = 0
		end
	end
end

function CardQueueScene.cardFilterAndAddFunc(aList)
	local result = {}
	local tempQueue ={}
	--[[
	--old
	for key, value in pairs(CommonManager.getQueueData()) do
		tempQueue[value] = key
	end

	-- 如果是选空格，就走这套逻辑
	if CardQueueScene.srcCardId == nil then
		for k, v in pairs(CommonManager:getMatrixCardData()) do
			tempQueue[v] = k
		end
	end

	for _, v in pairs(aList) do
		if (tempQueue[v.cardId] == nil) then
			table.insert(result, v)
		end
	end
	--]]
	--新的武将互换规则，允许队伍内（阵法内）武将互换
	--new
	-- 如果是选空格，就走这套逻辑
	if CardQueueScene.srcCardId == nil then
		for k, v in pairs(CommonManager:getMatrixCardData()) do
			tempQueue[v] = k
		end
		
		for key, value in pairs(CommonManager.getQueueData()) do
			tempQueue[value] = key
		end
	end
	
	for _, v in pairs(aList) do
		if (v.cardId ~= CardQueueScene.srcCardId ) and (tempQueue[v.cardId] == nil) then
			table.insert(result, v)
		end
	end
	
	return result
end

function CardQueueScene.equipFilterFunc(aList)
	local result = {}
	local equipPos = HeMemDataHolder:getInteger("EquipChange_Position")
	local equipId = HeMemDataHolder:getInteger("EquipChange_NowEquipId")
	for _, v in pairs (aList) do
		local aEquipMeta = MetaManager.equip_meta[v.metaId]
		if (aEquipMeta.position == equipPos and
			v.equipId ~= equipId) then
			table.insert(result, v)
		end
	end
	return result
end

function CardQueueScene.treasureFilterFunc( aList )
	local result = {}
	local cardId = HeMemDataHolder:getInteger("TreasureChange_CardId")
	
	for _, v in pairs (aList) do
		if v.cardId ~= cardId then
			table.insert(result , v)
		end
	end
	return result
end

function CardQueueScene.spiritFilterFunc(aList)
	local result = {}
	local spiritId = HeMemDataHolder:getInteger("SpiritChange_NowSpiritId")
	
	if spiritId == 0 then
		local cardId = HeMemDataHolder:getInteger("SpiritChange_CardId")
		for _, v in pairs (aList) do
			if  v.cardId ~= cardId then
				table.insert(result, v)
			end
		end
		return result
	end
	local cardId = nil
	for k,v in pairs(aList) do
		if v.spiritId == spiritId then
			cardId = v.cardId
		end
	end
	for _, v in pairs (aList) do
		if v.spiritId ~= spiritId and v.cardId ~= cardId then
			table.insert(result, v)
		end
	end
	return result
end

function CardQueueScene:ctor()
    self.mainUI = nil
	self.tableUI = nil
	
	self.cellWidth = TableCell_width

	self.selectedCardNo = 1
	self.tableOffsetUpperTarget = 0
	self.tableOffsetLowerTarget = 0
	self.rolling = false
	
	self.playerTeamData = nil
	
	self.userLevel = 0
	self.userLevel = nil
	self.cardsInfo = nil
	self.equipsData = nil
	self.spiritData = nil
	self.treasureData = nil
	self.queue = {}

	self.isCurShowSpiritTableView = false
	
    self.title = Localization:getInstance():getText("formation_title")
    self.curSceneEnum = SceneEnum.CardQueueScene

    self.isLineupChosen = nil  
end

----------------------------------------
----------------------------------------
function CardQueueScene:loadPlayerData()
	SpiritManager.getPlayerAllSpiritOfferedAttribute()
	if (not self.playerTeamData) then
		self.userLevel = DataManager.getCurrUser().level
		self.cardsInfo = table.clone(DataManager.getCardsData(), true)
		self.equipsData = table.clone(DataManager.getEquipsData(), true)
		self.spiritData = table.clone(DataManager.getSpiritsData(), true)
		self.treasureData = table.clone(DataManager.getTreasuresData(), true)
		self.matrixCardInfo = {}
		for k, v in pairs(CommonManager:getMatrixCardData()) do
			table.insert(self.matrixCardInfo, CommonManager:getCardMetaByCardId(v, self.cardsInfo).id)
		end
			
		--获取队列信息
		self.queue = table.clone(CommonManager.getQueueData(), true)
	else
		self.userLevel = self.playerTeamData.userLevel
		self.cardsInfo = self.playerTeamData.sharkCards
		for k,v in pairs(self.cardsInfo) do
			self.cardsInfo[k].avatarMetaId = 0
		end
		self.equipsData = self.playerTeamData.sharkEquips
		self.spiritData = self.playerTeamData.sharkSpirits
		self.treasureData = self.playerTeamData.sharkTreasures
		if not self.playerTeamData.sharkMatrices then
			self.playerTeamData.sharkMatrices = {}
		end
		if not self.playerTeamData.sharkMatrices.sharkMatrices then
			self.playerTeamData.sharkMatrices.sharkMatrices = {}
		end
		if not self.playerTeamData.sharkBeasts then
			self.playerTeamData.sharkBeasts = {}
		end
		self.matrixCardInfo = {}
		for k, v in pairs(CommonManager:getMatrixCardData(self.playerTeamData.sharkMatrices.sharkMatrices )) do
			table.insert(self.matrixCardInfo, CommonManager:getCardMetaByCardId(v, self.cardsInfo).id)
		end
		--获取队列信息
		self.queue = table.clone(CommonManager.getQueueData( self.playerTeamData.mainCardId , self.playerTeamData.additionalCardIds), true)
	end
	for key,value in pairs(self.queue) do
		self.queue[key] = CommonManager.getSubTableByKey(
			self.cardsInfo,
			{name = "cardId", value=value}
		)
	end
end

----------------------------------------
----------------------------------------
function CardQueueScene:loadQueueData()
	--所有装备及卡牌Meta信息
	local equipsMeta = {}
	
	local equipIdList = {}
	for aKey, aEquip in pairs(self.equipsData) do
		equipsMeta[aEquip.equipId] = tonumber(aEquip.metaId)
		equipIdList[aEquip.equipId] = aKey
	end
		
	for _, aCard in pairs(self.queue) do
		aCard.equipIds = aCard.equipIds and aCard.equipIds or {}
		
		--载入装备详情
		aCard.equips = {}
		for key, aEquipId in pairs(aCard.equipIds) do
			local aMeta = equipsMeta[aEquipId]
			local aEquipInfo = MetaManager.equip_meta[aMeta]
			local aPosition = aEquipInfo.position
			
			aCard.equips[aPosition] = self.equipsData[equipIdList[aEquipId]]
		end
	end
	local equipsPrefixId = {}
	for _, value in pairs(equipsMeta) do
		equipsPrefixId[MetaManager.equip_meta[value]["prefixId"]] = true
	end

	--宝物
	local treasuresMeta = {}
	local treasuresIdList = {}
	for aKey, aTreasure in pairs(self.treasureData) do
		treasuresMeta[aTreasure.treasureId] = tonumber(aTreasure.metaId)
		treasuresIdList[aTreasure.treasureId] = aKey
	end

	for _, aCard in pairs(self.queue) do
		aCard.cardTreasure = aCard.cardTreasure and aCard.cardTreasure or nil		

		aCard.treasure = self.treasureData[treasuresIdList[aCard.treasureId]]
	end

	local treasuresPrefixId = {}
	for _, value in pairs(treasuresMeta) do
		treasuresPrefixId[MetaManager.treasure_meta[value]["prefixID"]] = true
	end
	--宝物end

	local gameInitData = DataManager.getGameInitData()
	--生成背包中卡牌的GroupId表

	local cardsGroupId = {}
	if gameInitData.sharkUserExtend.cardGroupInterworking then
		local specialGroupMeta =  MetaManager.getSpecialGroupMeta()
		for _, value in pairs(self.cardsInfo) do
			if specialGroupMeta[tonumber(MetaManager.card_meta[value.metaId]["cardGroupId"])] ~= nil then
				for k,v in pairs(specialGroupMeta[tonumber(MetaManager.card_meta[value.metaId]["cardGroupId"])]) do
					cardsGroupId[tostring(v)] = MetaManager.card_meta[value.metaId]["cardGroupId"]
				end
			else
				cardsGroupId[tostring(MetaManager.card_meta[value.metaId]["cardGroupId"])] = MetaManager.card_meta[value.metaId]["cardGroupId"]
			end
		end
	else
		for _, value in pairs(self.cardsInfo) do
			cardsGroupId[tostring(MetaManager.card_meta[value.metaId]["cardGroupId"])] = MetaManager.card_meta[value.metaId]["cardGroupId"]
		end
	end
	local skillTipFlag = false
	local cardGroupList = {}
	
	for _, value in pairs(self.matrixCardInfo) do
		if gameInitData.sharkUserExtend.cardGroupInterworking then
	      -- for _, temp in ipairs(aCardGroupList) do
	        local specialGroupMeta =  MetaManager.getSpecialGroupMeta()
	        if specialGroupMeta[MetaManager.card_meta[value]["cardGroupId"]] == nil then
	          cardGroupList[MetaManager.card_meta[value]["cardGroupId"]] = (cardGroupList[cardGroupId] or 0) + 1
	        else
	          local aGroupList = specialGroupMeta[MetaManager.card_meta[value]["cardGroupId"]]
	          -- local aGroupList = group:split("|")
	          for k,v in pairs(aGroupList) do
	            cardGroupList[tonumber(v)] = (cardGroupList[cardGroupId] or 0) + 1
	          end
	        end
	      -- end
	    else
		    cardGroupList[MetaManager.card_meta[value]["cardGroupId"]] = (cardGroupList[cardGroupId] or 0) + 1
	    end
		-- cardGroupList[MetaManager.card_meta[value]["cardGroupId"]] = true
	end
	for _, aCard in pairs(self.queue) do
		aCard.skillStatus = {} --卡牌技能激活属性
		aCard.skillTip = nil
		
		local cardGroupId = MetaManager.card_meta[aCard.metaId].cardGroupId
		if gameInitData.sharkUserExtend.cardGroupInterworking then
	      -- for _, temp in ipairs(aCardGroupList) do
	        local specialGroupMeta =  MetaManager.getSpecialGroupMeta()
	        if specialGroupMeta[cardGroupId] == nil then
	          cardGroupList[cardGroupId] = (cardGroupList[cardGroupId] or 0) + 1
	        else
	          local aGroupList = specialGroupMeta[cardGroupId]
	          -- local aGroupList = group:split("|")
	          for k,v in pairs(aGroupList) do
	            cardGroupList[tonumber(v)] = (cardGroupList[cardGroupId] or 0) + 1
	          end
	        end
	      -- end
	    else
		    cardGroupList[cardGroupId] = (cardGroupList[cardGroupId] or 0) + 1
	    end
		-- cardGroupList[cardGroupId] = true
		
		local equipMetaDic = {} --装备Meta字典
		for _, aEquip in pairs(aCard.equips) do
			equipMetaDic[MetaManager.equip_meta[aEquip.metaId]["prefixId"]] = MetaManager.equip_meta[aEquip.metaId]["position"]
		end
		skillTipFlag = false
		for _, aSuit in pairs(MetaManager.equip_suit) do
			if (aSuit.cardGroupId == cardGroupId) then
				table.insert(
					aCard.cardSkills,{
						skillType = 0,
						equipPrefixId = aSuit.equipId,
						enabled = equipMetaDic[aSuit.equipId],
					}
				)
				if (equipMetaDic[aSuit.equipId]) then
					--标记套装技触发
					aCard.skillStatus[40000000+equipMetaDic[aSuit.equipId]] = aSuit.equipId
				else
					if (equipsPrefixId[aSuit.equipId]) then
						local aEquipMeta = CommonManager.getSubTableByKey(
							MetaManager.equip_meta,
							{name = "prefixId", value=aSuit.equipId}
						)
						local aEquipName = MetaManager.equip_meta[aEquipMeta.id - aEquipMeta.evolveLevel + 1]["name"]
						if (not skillTipFlag) then
							aCard.skillTip = Localization:getInstance():getText(
								"formation_equipSkillTips",
								{itemname = getTextByKey(aEquipName)}
							)
							skillTipFlag = true
						end
					end
				end
			end
		end --套装技查询完毕

		local aTreasureGroupSkill = MetaManager.treasure_suit[cardGroupId]
		if aTreasureGroupSkill then
			for i=1,5 do
				if aTreasureGroupSkill["SkillId"..i] ~= 0 then
					local enable
					if aCard.treasure then
						local tempPrefixID = MetaManager.treasure_meta[aCard.treasure.metaId].prefixID
						enable = CommonManager:checkIsTreasureActive(aCard.treasure.metaId , cardGroupId) and tempPrefixID == aTreasureGroupSkill["prefixID"..i]
					else
						enable = false
					end
					-- local enable = CommonManager:checkIsTreasureActive(aCard.treasure.metaId , cardGroupId)
					table.insert(
							aCard.cardSkills,{
								skillType = 5,
								treasurePrefixId = aTreasureGroupSkill["prefixID"..i],
								enabled = enable,
								skillId = aTreasureGroupSkill["SkillId"..i],
							}
						)
				end
			end
		end--宝物连携技
		
		aCard.groupSkills = {} --合体技字典
		for _, aSkill in pairs(aCard.cardSkills) do
			if (aSkill.skillType == 3 or aSkill.skillType == 4 or aSkill.skillType == 5) then
				local statusIds = MetaManager.skill_meta[aSkill.skillId]["statusIdList"]
				local statusIdList = statusIds:split("|")
				local statusAttr = {}
				for _, aStatusId in pairs(statusIdList) do
					if (aStatusId ~= "0") then
						statusAttr[MetaManager.skill_status[tonumber(aStatusId)]["impactAttr"]] = true
					end
					aCard.groupSkills[aSkill.skillId] = statusAttr
				end
			end
		end
	end
	--先遍历一遍宝物的技能tips
	for _, aCard in pairs(self.queue) do
		skillTipFlag = false
		for _, aSkill in pairs(aCard.cardSkills) do
			if (aSkill.skillType == 5) then			  
		        if aSkill.enabled then
					for aStatusAttr,_ in pairs(aCard.groupSkills[aSkill.skillId]) do
						aCard.skillStatus[aSkill.skillId] = aStatusAttr
					end
				else
					local isTreasureInBackpack = false
					for k,v in pairs(self.treasureData) do
						if MetaManager.treasure_meta[v.metaId].prefixID == aSkill.treasurePrefixId then
							isTreasureInBackpack = true
							break
						end
					end
					
					if not skillTipFlag and isTreasureInBackpack then
						aCard.skillTip = Localization:getInstance():getText(
			              "Treasure_text_43",
			              {name = getTextByKey(MetaManager.treasure_meta[tonumber(aSkill.treasurePrefixId)*10 + 1].name)}
			            )
			            skillTipFlag = true
					end
				end
			    -- end
			end
		end
	end
	local cardCountryNums = CommonManager:getCardCountryNums()
	for _, aCard in pairs(self.queue) do
		skillTipFlag = false
		for _, aSkill in pairs(aCard.cardSkills) do
			if (aSkill.skillType == 3) then
				
		        local flag = true
		        local needNum = 0
		        local aCardName = nil
				for _, aGroupId in pairs(aSkill.cardGroupIds) do
					if (not cardGroupList[aGroupId]) then
						
						if (cardsGroupId[tostring(aGroupId)]) then
							local aCardMeta = CommonManager.getSubTableByKey(
								MetaManager.card_meta,
								{name = "cardGroupId", value=cardsGroupId[tostring(aGroupId)]}
							)
					          needNum = needNum + 1
					          aCardName = MetaManager.card_meta[aCardMeta.id - aCardMeta.evolutionLevel + 1].name
						end
						flag = false
					end
					local cardGroupId = MetaManager.card_meta[aCard.metaId].cardGroupId
					if gameInitData.sharkUserExtend.cardGroupInterworking and CommonManager:checkSpecialGroupCombineSelf( cardGroupId , aSkill.cardGroupIds) then
			          if cardGroupList[cardGroupId] < 2 then
			            flag = false
			          end
			        end
				end
	        
		        if needNum == 1 then
		          if (not skillTipFlag) then
		            aCard.skillTip = Localization:getInstance():getText(
		              "formation_groupSkillTips",
		              {cardname = getTextByKey(aCardName)}
		            )
		            skillTipFlag = true
					end
		        end
				
				if (flag) then --触发合体技时
					for aStatusAttr,_ in pairs(aCard.groupSkills[aSkill.skillId]) do
						aCard.skillStatus[aSkill.skillId] = aStatusAttr
					end
				end
			end
			if (aSkill.skillType == 4) then
				local flag = true
				
				local cardGroupId = MetaManager.card_meta[aCard.metaId].cardGroupId
				local aGroupSkill = MetaManager.special_group_skill[cardGroupId]
				-- if aGroupSkill["groupSkill"..i] ~= 0 then
				local isActive = false
				  if MetaManager.card_meta[aCard.metaId].country == aSkill.countryGroupId then
				    if cardCountryNums[aSkill.countryGroupId] >= aSkill.countryGroupNum + 1 then
				      isActive = true
				    end
				  else
				    if cardCountryNums[aSkill.countryGroupId] >= aSkill.countryGroupNum then
				      isActive = true
				    end
				  end
				  
		        if isActive then
					for aStatusAttr,_ in pairs(aCard.groupSkills[aSkill.skillId]) do
						aCard.skillStatus[aSkill.skillId] = aStatusAttr
					end
				end
			    -- end
			end
		end --合体技触发查询完毕
	end

	--元神
	local spiritsMeta = {}
	local spiritIdList = {}
	for aKey, aSpirit in pairs(self.spiritData) do
		spiritsMeta[aSpirit.spiritId] = tonumber(aSpirit.metaId)
		spiritIdList[aSpirit.spiritId] = aKey
	end

	for _, aCard in pairs(self.queue) do
		aCard.cardSpirits = aCard.cardSpirits and aCard.cardSpirits or {}
		
		-- self.spiritData
		--载入元神详情
		aCard.spirits = {}
		for key, aSpiritId in pairs(aCard.cardSpirits) do
			local aMeta = spiritsMeta[aSpiritId.spiritId]
			local aSpiritInfo = MetaManager.spirit_meta[aMeta]
			local aPosition = aSpiritId.index
			aCard.spirits[aPosition] = self.spiritData[spiritIdList[aSpiritId.spiritId]]
		end
	end

end

local function isMatrixEnable(playerTeamData)
	local unlockLevel = MetaManager.game_meta.gameSettingConfig.matrixUnlockLevel
	if not unlockLevel then
		unlockLevel = 999
	end
	return (unlockLevel <= DataManager.getCurrUser().level) and (not playerTeamData)
end
----------------------------------------
----------------------------------------
function CardQueueScene:createCardListTableView( scaleRate, container )
  local builder = LayoutBuilder:createWithContentsOfFile("scene/formation_new.json")
  
  local aScene = self
  local CardListTableViewRenderer = class(TableViewRenderer)
  local maxQueueCardNum = MetaManager.user_level[self.userLevel].maxQueueCardNum
  self.cardNums = maxQueueCardNum
  local cardNums = maxQueueCardNum
  local isMyTeam = (not self.playerTeamData) and true or false
  if (maxQueueCardNum<MetaManager.user_level[#MetaManager.user_level].maxQueueCardNum and not self.playerTeamData) then
    maxQueueCardNum = maxQueueCardNum + 1
  end

  if not self.playerTeamData then
  	maxQueueCardNum = maxQueueCardNum + 2
  end
  self.maxQueueCardNum = maxQueueCardNum
  
  function CardListTableViewRenderer:ctor(width, height)
    for i=1,maxQueueCardNum do
      self.list[i] = i
    end
  end
  
  --------------------
  -- table每个元素的模版构建
  --------------------
  function CardListTableViewRenderer:buildCell(container)
    local CardLayer = Layer:create()  
    CardLayer:changeWidthAndHeight( Item_width , Item_height )
	
    local aCell = builder:build("layer/formation_entry")
    aCell:setPosition(ccp(-150/2,100))
    CardLayer:addChild(aCell)
    aCell:setTag(CardQueueScene.ListTags.CELL)
	
    aCell:getChildByName("txt_icon_hp"):setTag(CardQueueScene.ListTags.ICON_TITLE)--标记文字
    aCell:getChildByName("txt_icon_hp"):getChildByName("txt_icon_hp"):setTag(CardQueueScene.ListTags.ICON_TITLE_TEXT)
    aCell:getChildByName("red_purple9_panel"):setTag(CardQueueScene.ListTags.ICON_BG)--标记文字背景
	
    local cardFrame = aCell:getChildByName("normal_card_big")
    cardFrame:setTag(CardQueueScene.ListTags.ICON_FRAME)--标记卡牌位置
	
    --标记选择框
    aCell:getChildByName("frame_select"):setTag(CardQueueScene.ListTags.ICON_SHADOW)
    --标记添加按钮
    aCell:getChildByName("formation_add"):setTag(CardQueueScene.ListTags.FRAME_ADD)
    --标记主将图标
    aCell:getChildByName("little_lu_icon"):setTag(CardQueueScene.ListTags.ICON_MAIN)
    
    local anAddIcon = aCell:getChildByName("jia_add")
    anAddIcon:setTag(CardQueueScene.ListTags.ICON_ADD)
    anAddIcon:setAnchorPoint(ccp(0.5,0.5))
    --[[
    anAddIcon:setPositionX(anAddIcon:getPositionX()+25)
    anAddIcon:setPositionY(anAddIcon:getPositionY()-24)--]]
	
    CardLayer:setPosition(ccp(self.width / 2, self.height / 2))
    container:addChild(CardLayer)
    CardLayer:setTag(CardQueueScene.ListTags.LAYER)
  end
  
  --------------------
  -- 设置table每个元素的数据
  --------------------
  function CardListTableViewRenderer:setData( rawCocosObj, index )
    local CardLayer = self:getChildByTag(rawCocosObj, CardQueueScene.ListTags.LAYER)
    local aCell = CardLayer:getChildByTag(CardQueueScene.ListTags.CELL)
    
    local anAddIcon = aCell:getChildByTag(CardQueueScene.ListTags.ICON_ADD)
    anAddIcon:setVisible(false)
	
    local nowCard = aScene.queue[index+1]
    local aTitle = aCell:getChildByTag(CardQueueScene.ListTags.ICON_TITLE)
    local aTitleBackground = aCell:getChildByTag(CardQueueScene.ListTags.ICON_BG)

    if (nowCard) then
      aTitle:setVisible(false)
      setNodeText(aTitle:getChildByTag(CardQueueScene.ListTags.ICON_TITLE_TEXT),getTextByKey(MetaManager.card_meta[nowCard.metaId].name))
      aTitleBackground:setVisible(false)
	elseif ((index+1) == maxQueueCardNum and isMyTeam) then--缘分互通
		aTitle:setVisible(false)
      	aTitleBackground:setVisible(false)
    elseif ((index+1) == maxQueueCardNum - 1 and isMyTeam) then--阵法
    	aTitle:setVisible(false)
      	aTitleBackground:setVisible(false)
    elseif ((index+1)>cardNums) then
      local nextUnlockLevel = 1
      while (MetaManager.user_level[nextUnlockLevel]) do
        if (MetaManager.user_level[nextUnlockLevel].maxQueueCardNum == (cardNums+1)) then
          break
        end
      nextUnlockLevel = nextUnlockLevel + 1
    end
		setNodeText(
			aTitle:getChildByTag(CardQueueScene.ListTags.ICON_TITLE_TEXT),
			Localization:getInstance():getText(
				"formation_levelUnlock",
				{level = nextUnlockLevel}
			)
		)
    else
      aTitle:setVisible(false)
      aTitleBackground:setVisible(false)
    end
	
    local aCard = aCell:getChildByTag(CardQueueScene.ListTags.ICON_FRAME)
    aCard:setVisible(false)
    aCell:getChildByTag(CardQueueScene.ListTags.ICON_SHADOW):setVisible(false)
    aCell:getChildByTag(CardQueueScene.ListTags.FRAME_ADD):setVisible(false)
    if (index == (container.selectedCardNo-1)) then
      aCell:getChildByTag(CardQueueScene.ListTags.ICON_SHADOW):setVisible(true)
    end
    
    local cardFigure = nil
	
    if (nowCard) then
      if index == 1 then
        Set_ShareData( "CardQueue_Show_Icon", 1 ) --传递信号给新手引导：头像
      end
      cardFigure = getHeadIconCanonCardByMetaId(CommonManager:changeAvatarByCardInfo( nowCard ),  nowCard.lock)
	  local item_lv_bg = Sprite:createWithSpriteFrameName("item_lv_bg.png")
	  item_lv_bg:setPosition(ccp(23, 49))
	  card_lv = TextField:create("lv" .. nowCard.level,"Arial", 20)
	  card_lv:setPosition(ccp(42, 10))
	  item_lv_bg:addChild(card_lv)
	  cardFigure:addChild(item_lv_bg)
    elseif ((index+1) == maxQueueCardNum - 1 and isMyTeam) then
    	cardFigure = builder:build("formation_form")
	elseif ((index+1) == maxQueueCardNum and isMyTeam) then
    	cardFigure = builder:build("formation_form2")
    elseif ((index+1)>cardNums) then
      if index == 1 then
        Set_ShareData( "CardQueue_Show_Icon", 2 ) --传递信号给新手引导：锁图标
      end
      cardFigure = builder:build("sb/formation_lock")
    else
      if index == 1 then
        Set_ShareData( "CardQueue_Show_Icon", 3 ) --传递信号给新手引导：加号
      end
      aCell:getChildByTag(CardQueueScene.ListTags.FRAME_ADD):setVisible(true)
      anAddIcon:setVisible(true)
      local array = CCArray:create()
      array:addObject(CCScaleTo:create(0.4, 1.15))
      array:addObject(CCFadeOut:create(0.8))
      array:addObject(CCScaleTo:create(0.01, 1))
      array:addObject(CCFadeIn:create(0.01))
      anAddIcon:runAction(CCRepeatForever:create(CCSequence:create(array)))
      --[[
      particle:setVisible(true)
      particle:setPosition(ccp(6,-6))
      local picMoveTime = 1
      local array = CCArray:create()
      array:addObject(CCMoveBy:create(picMoveTime, ccp(135, 0)))
      array:addObject(CCMoveBy:create(picMoveTime, ccp(0, -135)))
      array:addObject(CCMoveBy:create(picMoveTime, ccp(-135, 0)))
      array:addObject(CCMoveBy:create(picMoveTime, ccp(0, 135)))
      particle:runAction(CCRepeatForever:create(CCSequence:create(array)))]]
    end
    if (cardFigure) then
      cardFigure:setPosition(ccp(aCard:getPositionX(),aCard:getPositionY()))
      aCard:removeFromParentAndCleanup(true)
      cardFigure:setTag(CardQueueScene.ListTags.ICON_FRAME)
      aCell:addChild(cardFigure.refCocosObj)
      cardFigure:dispose()
    end
    if (index == 0) then
      aCell:getChildByTag(CardQueueScene.ListTags.ICON_MAIN):setVisible(true)
    else
      aCell:getChildByTag(CardQueueScene.ListTags.ICON_MAIN):setVisible(false)
    end
  end
  
  --------------------
  -- 设置table每个元素的监听器
  --------------------
  local function onListItemTouch( evt )
    local aIndex = evt.data
    if self.maxQueueCardNum - 1 == (aIndex + 1) and (not self.playerTeamData) then
    	if not isMatrixEnable(self.playerTeamData) then
    		SuspensionLabel:showContent(self, Localization:getInstance():getText("matrix_lock_iremind1"))
    		return
    	end
    	self:replaceScene(MatrixScene)
      	return
    end
    if self.maxQueueCardNum  == (aIndex + 1) and (not self.playerTeamData) then
    	--
    	if __IOS and isInAppleReview() then
	    	local aContent = getTextByKey("shareFate_Prompt",{num = 80})
	      	SuspensionLabel:showContent(self, aContent)
	    else
	    	self:replaceScene(FateScene)
	    end
      	return
    end
    --判断是否锁定
    if (self.cardNums<(aIndex + 1)) then
      return
    end
    --判断是否为加号
    local aCardNo = aIndex + 1
    local aCard = container.queue[aCardNo]
    if not aCard then
      if (not self.playerTeamData) then
        self:cardFrameTouched(aCardNo)
        return
      end
    end
    --设置边框
    if (self.tableUI:cellAtIndex(self.selectedCardNo-1)) then
      self.tableUI:cellAtIndex(self.selectedCardNo-1):getChildByTag(CardQueueScene.ListTags.LAYER):getChildByTag(CardQueueScene.ListTags.CELL):getChildByTag(CardQueueScene.ListTags.ICON_SHADOW):setVisible(false) 
    end
    if self.tableUI:cellAtIndex(aIndex) then
      self.tableUI:cellAtIndex(aIndex):getChildByTag(CardQueueScene.ListTags.LAYER):getChildByTag(CardQueueScene.ListTags.CELL):getChildByTag(CardQueueScene.ListTags.ICON_SHADOW):setVisible(true)
    end

    self.selectedCardNo = aIndex + 1
    refresh = false
    self.cardPanel.tableUI:setContentOffset(ccp(-aIndex*720,0))
    self.cardPanelSpirit.tableUI:setContentOffset(ccp(-aIndex*720,0))
  end
  
  local function setNowIndex(aIndex)
    
  end
  
  local renderer = CardListTableViewRenderer.new(TableCell_width, Item_height)
  local aTableView = TableView:create(renderer, Table_width, Table_height)
  aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  aTableView:setPageEnabled(true)

  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
  
  aTableView:setPosition(ccp( Table_posX, Table_posY))
  return aTableView
end

function CardQueueScene:create( argv )
	self.playerTeamData = nil
	self.curSceneEnum = SceneEnum.CardQueueScene
	if argv then
		self.argv = argv
		self.argv.params = self.argv.params or {}
		if (
			argv.enterScene == SceneEnum.FriendScene
			or argv.enterScene == SceneEnum.NewBabelRankScene
			or argv.enterScene == SceneEnum.ArenaRankScene
		      or argv.enterScene == SceneEnum.MultiplayerBossScene
		      or argv.enterScene == SceneEnum.UnionMemberListScene --来自军团成员列表 unionTag
          or argv.enterScene == SceneEnum.AcrossFightScene 
          or argv.enterScene == SceneEnum.PKScene
          or argv.enterScene == SceneEnum.ActivitySceneToCrossBoss
		) then
			self.playerTeamData = argv.params.playerTeamData
			self.curSceneEnum = SceneEnum.FriendQueueScene
        elseif argv.enterScene == "CrossArena" then
        	--从跨服pvp进入
			self.playerTeamData = argv.params.playerTeamData
		elseif argv.enterScene == "CrossUnionPKBlessingScene" then
        	--从跨服gvg祝福进入
			self.playerTeamData = argv.params.playerTeamData
		elseif argv.enterScene == "CrossUnionPkMemberSelectScene" then
        	--从跨服gvg人员列表进入
			self.playerTeamData = argv.params.playerTeamData
		end
		if (argv.enterScene == "BackpackScene") then
			self.insertCardId = argv.params.insertCardId
		end
	else
		self.argv = { enterScene=nil, returnScene=nil, params={} }
	end
	
    local s = CardQueueScene.new()
    s:initScene()
    return s    
end

----------------------------------------
-- UI初始化
----------------------------------------
function CardQueueScene:initUi()
    BaseUIScene.initBackGround(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/formation_new.json")
	builder.useArtLabelTTF = true
    self.mainUI = builder:build("formation")
	--builder.useArtLabelTTF = false
	
	local function onClickMatrixButton(evt)
		self:replaceScene(MatrixScene)
	end
  
	-- self.mainUI:getChildByName("btn_to_camp"):getChildByName("txt"):setString(getTextByKey("matrix_enter"))
	
	-- local matrixButton = Button:create(self.mainUI:getChildByName("btn_to_camp"))
	-- matrixButton:addEventListener(Events.kStart, onClickMatrixButton)
	
	-- if not isMatrixEnable(self.playerTeamData) then
	-- 	matrixButton:setEnable(false)
	-- 	setCocosObjectColor(matrixButton.display, ccc3(80, 80, 80))
	-- end
	
  local function onAdjustButtonClick(evt)
    self:replaceScene(AdjustTeamScene, argv)
  end

  local function showPlayerAttribute(evt)
  	if self.mainUI:getChildByName("btn_drop_combine"):getChildByName("btn_drop_down"):isVisible() then
  		self.mainUI:getChildByName("btn_drop_combine"):getChildByName("btn_drop_down"):setVisible(false)
  		self.mainUI:getChildByName("btn_drop_combine"):getChildByName("btn_drop_up"):setVisible(true)
  		self.mainUI:getChildByName("formation_other_st"):setVisible(true)
  		self.tableUI:setTouchEnabled(false)
  	else
  		self.mainUI:getChildByName("btn_drop_combine"):getChildByName("btn_drop_down"):setVisible(true)
  		self.mainUI:getChildByName("btn_drop_combine"):getChildByName("btn_drop_up"):setVisible(false)
  		self.mainUI:getChildByName("formation_other_st"):setVisible(false)
  		self.tableUI:setTouchEnabled(true)
  	end
  end

  self.showPlayerAttrBtn = Button:create(self.mainUI:getChildByName("btn_drop_combine"))
  self.mainUI:getChildByName("btn_drop_combine"):getChildByName("btn_drop_up"):setVisible(false)
  self.mainUI:getChildByName("formation_other_st"):setVisible(false)
  self.showPlayerAttrBtn:addEventListener(Events.kStart, showPlayerAttribute, self)

  -- local gameInitData = DataManager.getGameInitData()
  local fateTxt
  if g_previousPlayerFateStatus then
  		fateTxt = getTextByKey("shareFate_state2")
	else
		fateTxt = getTextByKey("shareFate_state1")
	end
	self.mainUI:getChildByName("txt_elesoul8"):getChildByName("txt"):setString(fateTxt)

  if self.playerTeamData then
  	self.mainUI:getChildByName("btn_drop_combine"):setVisible(false)
  	self.mainUI:getChildByName("txt_elesoul8"):setVisible(false)
  end

  local disappearAttributeBtn = Button:create(self.mainUI:getChildByName("formation_other_st"))
  disappearAttributeBtn:addEventListener(Events.kStart, showPlayerAttribute, self)
  disappearAttributeBtn.noTouchEffect = true

  -- -- 队列调整按钮
  -- local adjustButtonDisplay = self.mainUI:getChildByName("btn_change_formation")
  -- adjustButtonDisplay:getChildByName("txt"):setString(getTextByKey("queue_transpositionSet"))
  -- local adjustButton = Button:create(adjustButtonDisplay)
  -- adjustButton:addEventListener(Events.kStart, onAdjustButtonClick, self)
  -- if self.playerTeamData then
  --   adjustButton:setVisible(false)
  -- end
  
  -----------------------我是华丽的分界线-----------------------
  local function showLineupchosen(evt)  --是否显示下拉菜单
  	self.mainUI:getChildByName("dropDown_law"):setVisible(evt) 
  	self.mainUI:getChildByName("btn_change_formation"):getChildByName("btn_drop_down2"):setVisible(evt)
  	self.mainUI:getChildByName("btn_change_formation"):getChildByName("btn_drop_down1"):setVisible(not evt)
	self.tableUI:setTouchEnabled(not evt)
	self.tempLayer:setTouchEnabled(evt)
	self.isLineupChosen = evt
  end

  self.tempLayer = Layer:create()
  self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  local function onTouch(event, x, y)		
	local tmporigin = self.mainUI:getChildByName("btn_change_formation"):getPosition()
	local tmpsize = self.mainUI:getChildByName("btn_change_formation"):getGroupBounds().size
	if x > tmporigin.x and x < tmporigin.x+tmpsize.width and y < tmporigin.y and y > tmporigin.y-tmpsize.height then return end

	tmporigin = self.mainUI:getChildByName("dropDown_law"):getPosition()
	tmpsize = self.mainUI:getChildByName("dropDown_law"):getChildByName("other_solid_gray9_panel"):getContentSize()
	if x > tmporigin.x and x < tmporigin.x+tmpsize.width and y < tmporigin.y and y > tmporigin.y-tmpsize.height then return end
	if event == CCTOUCHBEGAN then
	  if self.isLineupChosen then 
		showLineupchosen(false)
	  end
	  return
	else
	  return
	end
  end
  self.tempLayer:registerScriptTouchHandler(onTouch, false, -66, true)
  self.tempLayer:setTouchEnabled(false)
  self:addChild(self.tempLayer)
  self.mainUI:getChildByName("dropDown_law"):setVisible(false)

  local function onLineupButtonClick(evt)
  	if self.isLineupChosen then 
		showLineupchosen(false)
	else 
		showLineupchosen(true)
	end
  end

  self.lineupButtonDisplay = self.mainUI:getChildByName("btn_change_formation")
  self.lineupButtonDisplay:getChildByName("btn_drop_down2"):setVisible(false)
  local nowId = DataManager.getGameInitData().sharkUserExtendMore.battleArrayId
  self.lineupButtonDisplay:getChildByName("txt"):setString(getTextByKey("Lineup_text" .. nowId))
  local lineupButton = Button:create(self.lineupButtonDisplay)
  lineupButton:addEventListener(Events.kStart, onLineupButtonClick, self)
  if self.playerTeamData then
    lineupButton:setVisible(false)
  end
  if DataManager.getGameInitData().sharkUser.level < (MetaManager.game_meta.gameSettingConfig.lineupUnlockLevel or 43) then 
  	self.lineupButtonDisplay:setVisible(false) 
  end

  local function onLineupChosenClick(evt)	
  	local nowId = evt.context
 	local BattleArrayId = DataManager.getGameInitData().sharkUserExtendMore.battleArrayId
 	if nowId == BattleArrayId then return end

 	local function afterChangeBattleArray()
 	  self:replaceScene(CardQueueScene)
 	end

  	ChangeBattleArrayRequest.sendRequestDefalut(nowId,afterChangeBattleArray)
  end

  local BattleArrayId = DataManager.getGameInitData().sharkUserExtendMore.battleArrayId
  local LineupFirDisplay = self.mainUI:getChildByName("dropDown_law"):getChildByName("btn_1")
  if BattleArrayId ~= 1 then LineupFirDisplay:getChildByName("icon_lamp1"):setVisible(false)  end
  LineupFirDisplay:getChildByName("txt"):getChildByName("txt"):setString(getTextByKey("Lineup_text1"))
  local LineupFirButton = Button:create(LineupFirDisplay)
  LineupFirButton:addEventListener(Events.kStart, onLineupChosenClick, 1)

  local LineupSecDisplay = self.mainUI:getChildByName("dropDown_law"):getChildByName("btn_2")
  if BattleArrayId ~= 2 then LineupSecDisplay:getChildByName("icon_lamp1"):setVisible(false)  end
  LineupSecDisplay:getChildByName("txt"):getChildByName("txt"):setString(getTextByKey("Lineup_text2"))
  local LineupSecButton = Button:create(LineupSecDisplay)
  LineupSecButton:addEventListener(Events.kStart, onLineupChosenClick, 2)

  local LineupThdDisplay = self.mainUI:getChildByName("dropDown_law"):getChildByName("btn_3")
  if BattleArrayId ~= 3 then LineupThdDisplay:getChildByName("icon_lamp1"):setVisible(false)  end
  LineupThdDisplay:getChildByName("txt"):getChildByName("txt"):setString(getTextByKey("Lineup_text3"))
  local LineupThdButton = Button:create(LineupThdDisplay)
  LineupThdButton:addEventListener(Events.kStart, onLineupChosenClick, 3)
  -----------------------我是华丽的分界线-----------------------

	self.mainUI:getChildByName("formation_entry"):setVisible(false)
	self.mainUI:getChildByName("formation_lock"):setVisible(false)
    self.layer = {
        ["left"] = self.mainUI:getChildByName("formation_left"),
        ["card"] = self.mainUI:getChildByName("formation_card"),
        ["right"] = self.mainUI:getChildByName("formation_right"),
		["entry"] = self.mainUI:getChildByName("formation_entry"),
    }

   	-- local totalAttack = 0
    -- local totalDefence = 0
    -- local totalHP = 0
    -- local fightCapacity = 0
    -- if not self.playerTeamData then
    -- 	totalAttack, totalDefence, totalHP = CommonManager:getAttDefHp()
    -- 	fightCapacity = math.floor(CommonManager:getLocalPlayerStrength(totalAttack, totalDefence, totalHP))
    -- else
    -- 	fightCapacity = self.playerTeamData.fightCapacity
    -- end

	--设置文字
	local queueLeadP,totalLeadP = 0,0
	if (self.playerTeamData) then
		queueLeadP,totalLeadP = CalculationManager.calcComplex_getQueueLeaderPoints(self.queue, {["level"] = self.playerTeamData.userLevel,["vipLevel"] = self.playerTeamData.vipLevel})
	else
		queueLeadP,totalLeadP = CalculationManager.calcComplex_getQueueLeaderPoints()
	end

    self.layer.right:getChildByName("txt_formation_leadership"):getChildByName("txt_formation_leadership"):setString(Localization:getInstance():getText("cardInfo_Leadership1")..":")
    self.layer.right:getChildByName("txt_formation_leadership_num"):getChildByName("font"):setString(queueLeadP .. "/" .. totalLeadP)
    -- self.layer.left:getChildByName("txt_formation_strength"):getChildByName("txt_formation_strength"):setString(Localization:getInstance():getText("playerInfo_strength"))
    --local fightCapacity = (self.playerTeamData) and self.playerTeamData.fightCapacity or math.floor(CommonManager:getLocalPlayerStrength())
	-- self.layer.left:getChildByName("txt_formation_strength_num"):getChildByName("font"):setString(fightCapacity)
    
  -- if not self.playerTeamData then
  --   --local totalAttack = 0
  --   --local totalDefence = 0
  --   --local totalHP = 0
  --   --totalAttack, totalDefence, totalHP = CommonManager:getAttDefHp()
  --   self.mainUI:getChildByName("txt_atk_num"):getChildByName("font"):setString(totalAttack)
  --   self.mainUI:getChildByName("txt_def_num"):getChildByName("font"):setString(totalDefence)
  --   self.mainUI:getChildByName("txt_hp_num"):getChildByName("font"):setString(totalHP)
  -- else
  --   self.mainUI:getChildByName("txt_atk_num"):setVisible(false)
  --   self.mainUI:getChildByName("txt_def_num"):setVisible(false)
  --   self.mainUI:getChildByName("txt_hp_num"):setVisible(false)
  --   self.mainUI:getChildByName("icon_atk"):setVisible(false)
  --   self.mainUI:getChildByName("icon_def"):setVisible(false)
  --   self.mainUI:getChildByName("icon_hp"):setVisible(false)
  -- end
  
	self:showPlayerAllAttribute()
	
    --设置TableView
    self.layer.entry:setVisible(false) --隐藏占位卡牌
    
    local scaleRate = 1
    self.tableUI = self:createCardListTableView( scaleRate, self )
    self.layer.card:addChild(self.tableUI)
	--设置下方的TableView
	self.cardPanel = QueueCardPanel:create(self, nil)
	self.cardPanel:setPosition(ccp(16, 140)) -- 16 140 
	self.mainUI:addChild(self.cardPanel)

	self.cardPanelSpirit = QueueSpiritPanel:create(self, nil)
	self.cardPanelSpirit:setPosition(ccp(16, 140)) --16 140 
	self.mainUI:addChild(self.cardPanelSpirit)
	
	if self.argv.params and self.argv.params.backToSpirit then
		self.cardPanel.tableUI:setVisible(false)
		self.cardPanel.tableUI:setTouchEnabled(false)
	else
		self.cardPanelSpirit.tableUI:setVisible(false)
		self.cardPanelSpirit.tableUI:setTouchEnabled(false)
	end
	
	self:addChild(self.mainUI)
    BaseUIScene.onInit(self)
end

function CardQueueScene:showPlayerAllAttribute()
	local totalAttack = 0
    local totalDefence = 0
    local totalHP = 0
    local fightCapacity = 0
    if not self.playerTeamData then
    	totalAttack, totalDefence, totalHP = CommonManager:getAttDefHp()
    	-- fightCapacity = math.floor(CommonManager:getLocalPlayerStrength(totalAttack, totalDefence, totalHP))
    else
    	-- fightCapacity = self.playerTeamData.fightCapacity
    end
    local spiritOfferedAttribute = SpiritManager.getPlayerAllSpiritOfferedAttribute()
    -- totalAttack = totalAttack + spiritOfferedAttribute.atk
    -- totalDefence = totalDefence + spiritOfferedAttribute.def
    -- totalHP = totalHP + spiritOfferedAttribute.hp

    if not self.playerTeamData then
    self.mainUI:getChildByName("txt_atk_num"):getChildByName("font"):setString(totalAttack)
    self.mainUI:getChildByName("txt_def_num"):getChildByName("font"):setString(totalDefence)
    self.mainUI:getChildByName("txt_hp_num"):getChildByName("font"):setString(totalHP)
    self.mainUI:getChildByName("formation_other_st"):getChildByName("txt_atk_num"):getChildByName("font"):setString(totalAttack)
    self.mainUI:getChildByName("formation_other_st"):getChildByName("txt_def_num"):getChildByName("font"):setString(totalDefence)
    self.mainUI:getChildByName("formation_other_st"):getChildByName("txt_hp_num"):getChildByName("font"):setString(totalHP)
    self.mainUI:getChildByName("formation_other_st"):getChildByName("txt_crt_num"):getChildByName("font"):setString(spiritOfferedAttribute.crt)
    self.mainUI:getChildByName("formation_other_st"):getChildByName("txt_avd_num"):getChildByName("font"):setString(spiritOfferedAttribute.eva)
    self.mainUI:getChildByName("formation_other_st"):getChildByName("txt_dog_num"):getChildByName("font"):setString(spiritOfferedAttribute.par)
    self.mainUI:getChildByName("formation_other_st"):getChildByName("txt_ten_num"):getChildByName("font"):setString(spiritOfferedAttribute.tou)
    self.mainUI:getChildByName("formation_other_st"):getChildByName("txt_hit_num"):getChildByName("font"):setString(spiritOfferedAttribute.hit)
    self.mainUI:getChildByName("formation_other_st"):getChildByName("txt_brk_num"):getChildByName("font"):setString(spiritOfferedAttribute.prc)
  else
    self.mainUI:getChildByName("txt_atk_num"):setVisible(false)
    self.mainUI:getChildByName("txt_def_num"):setVisible(false)
    self.mainUI:getChildByName("txt_hp_num"):setVisible(false)
    self.mainUI:getChildByName("icon_atk"):setVisible(false)
    self.mainUI:getChildByName("icon_def"):setVisible(false)
    self.mainUI:getChildByName("icon_hp"):setVisible(false)
  end
end

function CardQueueScene:refreshUI()
	self:loadPlayerData()
	self:loadQueueData()
	local rollto =  HeMemDataHolder:getInteger("CardQueue_RollTo")
		rollto = (rollto>#self.queue) and #self.queue or rollto
    if rollto > 0 then
      self.selectedCardNo = rollto
    end

    local cellNum = (#self.queue >= 10) and 10 or (#self.queue + 1)
	  if self.selectedCardNo + 3  <= cellNum then
	    self.tableOffsetUpperTarget = -(self.selectedCardNo-1)*(TableCell_width)
	  else
	    local offset = (cellNum - 4 >= 0) and (cellNum - 4) or 0
	    self.tableOffsetUpperTarget = -offset*(TableCell_width)
	  end

	self.tableUI:reloadData()
	self.cardPanel.tableUI:reloadData()
	self.cardPanelSpirit.tableUI:reloadData()

	self.cardPanel.tableUI:setContentOffset(ccp(-(self.selectedCardNo-1)*720,0))
	self.cardPanelSpirit.tableUI:setContentOffset(ccp(-(self.selectedCardNo-1)*720,0))
	self.rolling = true

	self:showPlayerAllAttribute()
end

function CardQueueScene:refreshUIForPanelInfo(aCardId)
	self:refreshUI()
end

function CardQueueScene:getPanelInfoData(aCardId)
	local result = self.queue[HeMemDataHolder:getInteger("CardQueue_RollTo")]
	if not result then
		result = CommonManager.getSubTableByKey(
			DataManager.getCardsData(),
			{name = "cardId", value=self.trainShowCardId}
		)
	end
	return result
end

----------------------------------------
----------------------------------------
function CardQueueScene.changeCard( srcCardId , runningScene, preReturnScene)
  g_previousBattleCount = CommonManager:getLocalPlayerStrength()
  
	local cardQueue = table.clone(CommonManager.getQueueData(), true)
	local cardIds = {}
	for aKey, aCardId  in pairs(cardQueue) do
		cardIds[aCardId] = aKey
	end
	local srcPos = 0
	if (srcCardId==0) then
		HeMemDataHolder:setInteger("CardQueue_RollTo",#cardQueue+1)
		srcPos = #cardQueue+1
		CardQueueScene.srcCardId = nil
	else
		HeMemDataHolder:setInteger("CardQueue_RollTo",cardIds[srcCardId])
		srcPos = cardIds[srcCardId]
		CardQueueScene.srcCardId = srcCardId
	end
	local queueIds = {}
	for key, value in pairs(cardQueue) do
		queueIds[key] = value
	end
	local argv = {
		enterScene="CardQueueScene",
		returnScene="CardQueueScene",
		params={
			cardPos = srcPos,
			cardQueue = queueIds,
			filter = BACKPACK_FILTER.CARD,
			filterFunc = CardQueueScene.cardFilterAndAddFunc,
			isCardTrain = false,
			preReturnScene = preReturnScene
		}
	}
	if runningScene then
		runningScene:replaceScene(BackpackScene, argv)
	else
		local scene = BackpackScene:create( argv )
		Director:sharedDirector():replaceScene(scene)
	end
end

----------------------------------------
----------------------------------------
function CardQueueScene:cardFrameTouched( cardNo )
	if (self.queue[cardNo]) then
    HeMemDataHolder:setInteger("CardQueue_RollTo", cardNo)
		self._data = self.queue[cardNo]

		local unsavedCardId = CardTrainingScene.getUnsavedCardId()
		local aPanel
		local showUnsavedPanel
		if unsavedCardId then
			local aCardNo
		  	for key,value in pairs(self.queue) do
				if value.cardId == unsavedCardId then
					aCardNo = key
					break
				end
			end
			if aCardNo then
				HeMemDataHolder:setInteger("CardQueue_RollTo", aCardNo)
				self._data = self.queue[aCardNo]
			else
				HeMemDataHolder:setInteger("CardQueue_RollTo", 0)
				self.trainShowCardId = unsavedCardId
				self._data = CommonManager.getSubTableByKey(
					DataManager.getCardsData(),
					{name = "cardId", value=unsavedCardId}
				)
			end
			
			aPanel = CardInfoNewPanel:create( self, nil, nil, {tabType = tabTypeEnum.cultivate, forceClose = true})
			showUnsavedPanel = function()
				local aScene = Director.sharedDirector():getRunningScene()
				local aPanel = AssistantMessageBoxPanel:create( aScene, AsMessageBoxType.notFinished )
			    aScene:addChild(aPanel)
			    aPanel:scaleIn()
			end
		else
			aPanel = CardInfoNewPanel:create( self)
		end

		self.targetInfoPanel = aPanel
		PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self, nil, showUnsavedPanel) 
	else
		self:setTableViewsEnabledInner(false)
		self.changeCard( 0 , self, self.argv.returnScene)
	end
end

----------------------------------------
----------------------------------------
function CardQueueScene:skillBtnTouched( cardNo, skillType )
	local aCard = self.queue[cardNo]
	if (aCard == nil) then
		return
	end
	local aCardId = aCard.cardId
	local aSkillId = 0
	
	for key, value in pairs(aCard.cardSkills) do
		if (value.skillType == skillType) then
			aSkillId = tonumber(value.skillId)
		end
	end
  
	if ( aSkillId ~= 0 ) then
		local aPanel = SkillShowAndUpgradePanel:create(
			self,
			{	scene = self,
				cardId = aCardId,
        cardLevel = aCard.level,
				skillId = aSkillId
			}
		)
		self:addChild(aPanel)
		aPanel:scaleIn()
	end
end

----------------------------------------
----------------------------------------
function CardQueueScene:equipBtnTouched( cardNo, equipPos )
  g_previousBattleCount = CommonManager:getLocalPlayerStrength()
  
	HeMemDataHolder:setInteger("CardQueue_RollTo", cardNo)
	local aCard = self.queue[cardNo]
	if (aCard == nil) then
		return
	end

	local aEquip = aCard.equips[equipPos]	
	HeMemDataHolder:setInteger("EquipChange_nowCardId", aCard.cardId)
	
	if (aEquip) then
		self._data = aEquip
		self.targetInfoPanel = EquipInfoNewPanel:create(aEquip, {enterScene="CardQueueScene", returnScene="CardQueueScene"})
		PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self) 
	else
		self:setTableViewsEnabledInner(false)
		HeMemDataHolder:setInteger("EquipChange_Position", equipPos)
		HeMemDataHolder:setInteger("EquipChange_NowEquipId", 0)
		local argv = {
			enterScene="CardQueueScene",
			returnScene="CardQueueScene",
			params={
				--cardPos = cardNo,
				cardId = aCard.cardId,
				tabIndex = BAGCATEGORY.equip,
				filter = BACKPACK_FILTER.EQUIP,
				filterFunc = self.equipFilterFunc,
				isCardTrain = false
			}
		}
		self:replaceScene( BackpackScene , argv)
	end
end

function CardQueueScene:treasureBtnTouched( cardNo )
	local aCard = self.queue[cardNo]
	if (aCard == nil) then
		return
	end

	HeMemDataHolder:setInteger("CardQueue_RollTo", cardNo)
	local aTreasure = aCard.treasureId
	if aTreasure == 0 then
		HeMemDataHolder:setInteger("TreasureChange_CardId", aCard.cardId)
		local argv = {
			enterScene="CardQueueScene",
			returnScene="CardQueueScene",
			params={
				--cardPos = cardNo,
				cardId = aCard.cardId,
				filterFunc = self.treasureFilterFunc,
			}
		}
		self:replaceScene( TreasureBackpackScene , argv)
	else
		local event = {
			context = {
				container = self,
				treasureId = aCard.treasureId,
				SelectNum = 1,
				enterAndReturnScene = "CardQueueScene"
			}
		}
		TreasureSystem.PopTreasureInfoPanel( event )

	end
end

function CardQueueScene:upgradeBtnTouched( cardNo)
	
    -- print("~~~~~~~~~~~~~~~~~~~aCard = "..tostringRich(aCard))
	HeMemDataHolder:setInteger("CardQueue_RollTo", cardNo)
    local aCard = self.queue[cardNo]
	if (aCard == nil) then
		return
	end
	
	local argv = {
		enterScene="CardQueueScene",
		returnScene="CardQueueScene",
		params={
			cardPos = cardNo,
			container = self,
		}
	}
	self:replaceScene( EquipQuickUpgradeScene,argv)


end

function CardQueueScene:spriteBtnTouched( cardNo , equipPos )
	g_previousBattleCount = CommonManager:getLocalPlayerStrength()
  
	HeMemDataHolder:setInteger("CardQueue_RollTo", cardNo)
	local aCard = self.queue[cardNo]
	if (aCard == nil) then
		return
	end

	local rare = MetaManager.card_meta[aCard.metaId].rare
	local spriteNum = MetaManager.card_rare[rare].spiritNum + MetaManager.card_level[aCard.level].spiritNum

	local spirtes = aCard.spirits
	local equipSprite = nil 
	for k,v in pairs(spirtes) do
		if equipPos == k then
			equipSprite = v
		end
	end

	if equipPos > spriteNum and equipSprite == nil then
		local levelSpiritNum = equipPos - MetaManager.card_rare[rare].spiritNum
		local str = ""
		if levelSpiritNum > MetaManager.card_level[#MetaManager.card_level].spiritNum then
			str = getTextByKey("spirit_locked_tips")
		else
			for i=1,#MetaManager.card_level do
				if MetaManager.card_level[i].spiritNum == levelSpiritNum then
					str = Localization:getInstance():getText("spirit_lvInsufficient_tips" , {num = i})
					break
				end
			end
		end
		SuspensionLabel:showContent(self, str)
		return
	end

	if equipSprite then
		self._data = equipSprite
		self.targetInfoPanel = SpiritInfoPanel:create( self )
		PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self) 
	else
		self:setTableViewsEnabledInner(false)
		HeMemDataHolder:setInteger("SpiritChange_Position", equipPos)
		HeMemDataHolder:setInteger("SpiritChange_NowSpiritId", 0)
		HeMemDataHolder:setInteger("SpiritChange_CardId", aCard.cardId)
		local argv = {
			enterScene="CardQueueScene",
			returnScene="CardQueueScene",
			params={
				cardId = aCard.cardId,
				filterFunc = self.spiritFilterFunc,
				equipedDown = true,
				backToSpirit = true,
			}
		}
		self:replaceScene( SpiritBackPackScene , argv)
	end
end

function CardQueueScene:toSpritePanelTouched()
	print("toSpritePanelTouched")
	if  not SpiritManager.isUserLevelEnough() and not self.playerTeamData then
		SuspensionLabel:showContent(self, Localization:getInstance():getText("module_needLevel", {num = DataManager.GameMetaData.spiritSettingConfig.unlockLevel}))
		return
	end
			
	self.isCurShowSpiritTableView = true
	self.cardPanelSpirit.tableUI:setVisible(true)
	self.cardPanelSpirit.tableUI:setTouchEnabled(true)
	self.cardPanel.tableUI:setVisible(false)
	self.cardPanel.tableUI:setTouchEnabled(false)
end

function CardQueueScene:toCardPanelTouched()
	print("toCardPanelTouched")
	self.isCurShowSpiritTableView = false
	self.cardPanelSpirit.tableUI:setVisible(false)
	self.cardPanelSpirit.tableUI:setTouchEnabled(false)
	self.cardPanel.tableUI:setVisible(true)
	self.cardPanel.tableUI:setTouchEnabled(true)
end

----------------------------------------
-- 场景初始化
----------------------------------------
function CardQueueScene:onInit()
	--显示Loading界面
	self:loadPlayerData()
	self:loadQueueData()
	
	--刷新镇魂信息
	local curMatrixId = MetaManager.getCurInBattleMatrixId()
	MagicCircleManager.RefreshMagicCircleInfoByMatrixId(curMatrixId)
	
	self:initUi()
	
	if (self.argv.enterScene == "BackpackScene" or
      self.argv.enterScene == "EquipEvolveScene" or
      self.argv.enterScene == "EquipUpgradeScene" or
      self.argv.enterScene == "CardTrainingScene" or
      self.argv.enterScene == "CardComposeScene" or
      self.argv.enterScene == "CardEvolutionScene" or
      self.argv.enterScene == "SpiritBackPackScene" or
      self.argv.enterScene == "TreasureBackpackScene" or
      self.argv.enterScene == "EquipQuickUpgradeScene" or
	  self.argv.params.rollTo) then
		local rollto = self.argv.params.rollTo or HeMemDataHolder:getInteger("CardQueue_RollTo")
		rollto = (rollto>#self.queue) and #self.queue or rollto
    if rollto > 0 then
      self.selectedCardNo = rollto
    end
	end
  	
	self.tableUI:reloadData()
	
	self.cardPanel.tableUI:reloadData()
	
	self.cardPanelSpirit.tableUI:reloadData()

	
  local cellNum = (#self.queue >= 10) and 10 or (#self.queue + 1)
  if self.selectedCardNo + 3  <= cellNum then
    self.tableOffsetUpperTarget = -(self.selectedCardNo-1)*(TableCell_width)
  else
    local offset = (cellNum - 4 >= 0) and (cellNum - 4) or 0
    self.tableOffsetUpperTarget = -offset*(TableCell_width)
  end
	self.cardPanel.tableUI:setContentOffset(ccp(-(self.selectedCardNo-1)*720,0))
	self.cardPanelSpirit.tableUI:setContentOffset(ccp(-(self.selectedCardNo-1)*720,0))
	self.rolling = true
  

	--print("self.argv.enterScene = " .. tostringRich(self.argv.enterScene))
					
	--显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
	DataManager.fightCapacityMaybeUpdated()
  
  if self.argv.params.cardId and self.argv.params.infoPanelTabType then
  	local cardNo
  	for key,value in pairs(self.queue) do
		if value.cardId == self.argv.params.cardId then
			cardNo = key
			break
		end
	end
  	HeMemDataHolder:setInteger("CardQueue_RollTo", cardNo)
	self._data = self.queue[cardNo]
	self.targetInfoPanel = CardInfoNewPanel:create( self, nil, nil, {tabType = self.argv.params.infoPanelTabType} )
	PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
  end
  
  
end

----------------------------------------
-- 覆盖父类setTableViewsEnabled()方法用于关闭触控
----------------------------------------
function CardQueueScene:setTableViewsEnabledInner(v)
  if self.tableUI then
    self.tableUI:setTouchEnabled(v)
  end
  if self.cardPanel.tableUI then
    if self.playerTeamData then
      self.cardPanel.tableUI:setDragEnabled(false)
    else
      self.cardPanel.tableUI:setTouchEnabled(v)
    end
  end
  if self.cardPanelSpirit.tableUI then
    if self.playerTeamData then
      self.cardPanelSpirit.tableUI:setDragEnabled(false)
    else
      self.cardPanelSpirit.tableUI:setTouchEnabled(v)
    end
  end
  -- if self.cardPanel.tableUI:isVisible() then
  --   if self.playerTeamData then
  --     self.cardPanel.tableUI:setTouchEnabled(false)
  --   else
  --     self.cardPanel.tableUI:setTouchEnabled(v)
  --   end
  -- end
  -- if self.cardPanelSpirit.tableUI:isVisible() then
  --   if self.playerTeamData then
  --     self.cardPanel.tableUI:setTouchEnabled(false)
  --   else
  --     self.cardPanel.tableUI:setTouchEnabled(v)
  --   end
  -- end
end

----------------------------------------
-- 返回按钮
----------------------------------------
function CardQueueScene:back()
	if (self.playerTeamData) then
		if (self.argv.returnScene == SceneEnum.FriendScene) then
			self:replaceScene(FriendScene)
		elseif (self.argv.returnScene == SceneEnum.NewBabelRankScene) then
			self:replaceScene(NewBabelRankScene)
		elseif (self.argv.returnScene == SceneEnum.ArenaRankScene) then
			self:replaceToArena()
		elseif (self.argv.returnScene == SceneEnum.UnionMemberListScene) then --返回军团成员列表 unionTag
			self:replaceScene(UnionMemberListScene)
		elseif (self.argv.returnScene == SceneEnum.ActivitySceneToCrossBoss) then
			self:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_CrossBoss"})
	    elseif (self.argv.returnScene == "CrossArena") then 
	    	--返回跨服pvp
	    	CrossArena.gotoCrossPvpScene(self.argv.enterSceneIndex, self.argv.enterPanelIndex)
	    elseif (self.argv.returnScene == "CrossUnionPKBlessingScene") then 
	    	CrossUnionPk.gotoCrossLoginUnionPkScene()
    	elseif (self.argv.returnScene == "CrossUnionPkMemberSelectScene") then 
	    	CrossUnionPk.gotoMemberSelectScene()
    elseif (self.argv.returnScene == SceneEnum.AcrossFightScene) then 
      if AcrossFightManager.isOpen() then
        local function successCallback()
          self:replaceScene(AcrossFightScene)
        end
        AcrossFightScene.enterScene(successCallback)
      end
    elseif (self.argv.returnScene == SceneEnum.PKScene) then 
      self:replaceScene(PKScene)
    elseif (self.argv.returnScene == SceneEnum.MultiplayerBossScene) then
      local function successCallback(data)
        local argv = {enterScene="",returnScene="",params={selectedTag = MultiplayerBossTagEnum.Leaderboard, data = data}}
        self:replaceScene(MultiplayerBossScene, argv)
      end
      
      local function failureCallback(data)
        if data.retCode == 714520 then
          local function closeCanonMessageBox()
            self:replaceScene(MainMenuScene)
          end
          local text = Localization:getInstance():getText("activityNian_timeOver")
          CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        else
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = data.retCode})
          CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        end
      end
      
      MultiplayerBossScene.doPreparationBeforeEnterMultiplayerBossPanel(successCallback, failureCallback)
		else
			self:replaceScene(MainMenuScene)
		end
	else
		if(self.argv.returnScene == "ChapterMapScene") then
			self:replaceScene(ChapterMapScene)
		else
			self:replaceScene(MainMenuScene)
		end
	end
end

----------------------------------------
-- 进入场景动画,被父类onInit()方法调用
----------------------------------------
function CardQueueScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

----------------------------------------
----------------------------------------
function CardQueueScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

----------------------------------------
----------------------------------------
function CardQueueScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
  self.tableUI:setPositionX(self.tableUI:getPositionX() - visibleSize.width)
  self.tableUI:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  
  --如果是换阵容重新进入时战斗力会变
  DataManager.fightCapacityMaybeUpdated()
  --by l1ghtsaber

  --self.arrowLayer:setPositionX(self.arrowLayer:getPositionX() - visibleSize.width)
  --self.arrowLayer:runAction(CCMoveBy:create(0.5, ccp(visibleSize.width, 0)))
end

local skillAttrTexts = {
	getTextByKey("attr_Attack"),
	getTextByKey("attr_Defense"),
	getTextByKey("attr_HP")
}

local function getSkillValueByGroupSkillId( aSkillId )
	local aSkillMeta = MetaManager.skill_meta[aSkillId]
	local aSkillStatus = aSkillMeta.statusIdList:split("|")[1]
	local aStatusMeta = MetaManager.skill_status[tonumber(aSkillStatus)]
	
	if (aStatusMeta.effectValue<1) then
		return (aStatusMeta.effectValue*100) .. "%"
	else
		return aStatusMeta.effectValue
	end
end

local function getSkillByCardAndEquip( aGroupId, aEquipId )
	local aSuitMeta = nil
	for _,aSuit in pairs(MetaManager.equip_suit) do
		if (
			tonumber(aGroupId) == aSuit.cardGroupId and
			tonumber(aEquipId) == aSuit.equipId
		) then
			aSuitMeta = aSuit
			break
		end
	end
	if (aSuitMeta) then
		return ((aSuitMeta.effectValue*100).."%"),skillAttrTexts[aSuitMeta.activeAttr]
	else
		return
	end
end

function CardQueueScene:showSkillEnableInfo()
	CommonManager:checkEnableSkill(self)
	do return end
	local newSkillEffectList = {}
	
	local SkillList = {}
	for _,aCard in pairs(self.queue) do
		SkillList[aCard.cardId] = aCard.skillStatus
	end
	local oldQueueStatus = g_oldQueueStatus
	if (g_oldQueueStatus) then
		for aCardId, aCardStatus in pairs(SkillList) do
			local aCard = CommonManager.getSubTableByKey(
				self.queue,
				{name = "cardId",value = aCardId}
			)
			if (g_oldQueueStatus[aCardId]) then
				for aSkillId,aStatusAttr in pairs(aCardStatus) do
					if (not g_oldQueueStatus[aCardId][aSkillId]) then
						local aCardMeta = MetaManager.card_meta[aCard.metaId]
						local aCardName = getTextByKey(aCardMeta.name)
						local aSkillName = ""
						local aValue = ""
						local aValueType = ""
						if (MetaManager.skill_meta[aSkillId]) then
							aSkillName = getTextByKey(MetaManager.skill_meta[aSkillId].name)
							aValue = getSkillValueByGroupSkillId(aSkillId)
							aValueType = skillAttrTexts[aStatusAttr]
						else
							aSkillName = getTextByKey(MetaManager.equip_meta[aStatusAttr*10+1].name)
							aValue,aValueType = getSkillByCardAndEquip(aCardMeta.cardGroupId, aStatusAttr)
						end
						
						local aDesc = Localization:getInstance():getText(
							"formation_groupSkillInfo",
							{
								cardname = aCardName,
								skillname = aSkillName,
								value = aValue,
								valueType = aValueType,
							}
						)
						table.insert(newSkillEffectList,aDesc)
					end
				end
			else
				for aSkillId,aStatusAttr in pairs(aCardStatus) do
					local aCardName = MetaManager.card_meta[aCard.metaId].name
						local aCardMeta = MetaManager.card_meta[aCard.metaId]
						local aCardName = getTextByKey(aCardMeta.name)
						local aSkillName = ""
						local aValue = ""
						local aValueType = ""
						if (MetaManager.skill_meta[aSkillId]) then
							aSkillName = getTextByKey(MetaManager.skill_meta[aSkillId].name)
							aValue = getSkillValueByGroupSkillId(aSkillId)
							aValueType = skillAttrTexts[aStatusAttr]
						else
							aSkillName = getTextByKey(MetaManager.equip_meta[aStatusAttr*10+1].name)
							aValue,aValueType = getSkillByCardAndEquip(aCardMeta.cardGroupId, aStatusAttr)
						end
						
						local aDesc = Localization:getInstance():getText(
							"formation_groupSkillInfo",
							{
								cardname = aCardName,
								skillname = aSkillName,
								value = aValue,
								valueType = aValueType,
							}
						)
						table.insert(newSkillEffectList,aDesc)
				end
			end
		end
	end
	g_oldQueueStatus = SkillList
	
	if (#newSkillEffectList>0) then
		SuspensionLabel:showContent(self, newSkillEffectList)
	end
	--print(table.tostring(newSkillEffectList))
end

----------------------------------------
----------------------------------------
function CardQueueScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  local canMagicCircleGuideRunning = true
  if (not self.playerTeamData) then
	self:showSkillEnableInfo()
  end
  if IsGuideExecuted(GuideConfig.kCardOn) and not IsGuideExecuted(GuideConfig.kChangeCard) and not self.playerTeamData then --主要新手引导的最后一个执行完后，才执行这个
    canMagicCircleGuideRunning = false
    ExeNewGuide(GuideConfig.kChangeCard)
  end

  if GuideConfig.kMultiLineup == nil then  --多阵容引导
	GuideConfig.kMultiLineup = "Guide_MultiLineup"
  end

  if DataManager.getCurrUser().level >= (MetaManager.game_meta.gameSettingConfig.lineupUnlockLevel or 43) and IsGuideExecuted(GuideConfig.kChangeCard) and not IsGuideExecuted(GuideConfig.kMultiLineup) and not self.playerTeamData then
    canMagicCircleGuideRunning = false
	ExeNewGuide( GuideConfig.kMultiLineup )
  end 

  if GuideConfig.kCardFate == nil then
    GuideConfig.kCardFate = "Guide_CardFate"
  end

  if DataManager.getCurrUser().level >= MetaManager.game_meta.gameSettingConfig.specialGroupUnlockLevel and IsGuideExecuted(GuideConfig.kMultiLineup) and not IsGuideExecuted(GuideConfig.kCardFate) and not self.playerTeamData then
  	if not IsGuideExecuted(GuideConfig.kCardFate) then
  		self.tableUI:setContentOffset(ccp(-(self.maxQueueCardNum - 4) * TableCell_width,0))
  		self.tableUI:setDragEnabled(false)
  		self.cardPanel.tableUI:setDragEnabled(false)
		self.cardPanelSpirit.tableUI:setDragEnabled(false)
  	end
  	canMagicCircleGuideRunning = false
  	ExeNewGuide( GuideConfig.kCardFate )
  end
  
  --弹出阵魂灯引导 by dangchao 2015/4/14
	--begin
	if GuideConfig.kMagicCircle == nil then  
		GuideConfig.kMagicCircle = "Guide_MagicCircle"
	end
	if not IsGuideExecuted(GuideConfig.kMagicCircle) and MagicCircleManager.IsCurMagicCircleOpen() and canMagicCircleGuideRunning  then
		local newBox = UserUnlockContentBox:create("MagicCircle",nil)
		PopoutManager:sharedManager():popout(newBox, kPopoutDir.kScale, true, false)
		local gameData = DataManager.getGameInitData()
		table.insert(gameData.sharkUserExtend.tutorialSteps,{funcName = "Guide_MagicCircle",step = 1})
		DataManager.setGameInitData(gameData)
		local params = {funcName = "Guide_MagicCircle",step = 1}
		local request = RecordTutorialStepRequest.new( params, rpc.SendingPriority.kHigh )
		request:start()
	end
	--end
end

----------------------------------------
-- 场景切换时，被父类的replaceScene调用
----------------------------------------
function CardQueueScene:doExitAnimation()
   self:preExitAnimation()
   self:startExitAnimation()
   self.tableUI:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0))) 
   --self.arrowLayer:runAction(CCMoveBy:create(0.5, ccp(-visibleSize.width, 0))) 
end

----------------------------------------
----------------------------------------
function CardQueueScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

----------------------------------------
----------------------------------------
function CardQueueScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width-100, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
end

----------------------------------------
----------------------------------------
function CardQueueScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function CardQueueScene:dispose()
  CardQueueScene.super.dispose(self)
end
