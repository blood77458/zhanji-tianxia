--------------------------------------------------------------------------------
-- CardDescPanel.lua - 卡牌描述信息面板
-- author: fanzhou.long
-- updated: 2013-09-29
--------------------------------------------------------------------------------

require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.data.MetaManager"
require "canon.models.CommonManager"
require "canon.customUI.CanonItem"

local defaultSpacing = 0
local defaultColor = ccc3(0,0,0)
local defaultTextSize = 23

CardDescPanel = class(Layer)

function CardDescPanel:ctor()
    self.scrollView = nil
	self.desc = nil
	self.content = nil
	self.cardGroupList = {}
end

function CardDescPanel:setScrollViewTouchEnable(isEnable)
	if self.scrollView ~= nil then
		self.scrollView:setTouchEnabled(isEnable)
	end 
end 

--[[
--size包含两个值：width & height
--metaId：卡牌/装备的metaId
--color：颜色
--cardId：卡牌的Id / 装备对应的卡牌Id
-- adjudedetail : 是不是卡牌详情
]]
function CardDescPanel:create( metaId, size, color, cardId, fixedHeight ,adjudedetail)
	self.metaId = metaId
	self.size = size
	self.color = color
	self.cardId = cardId
	self.adjudedetail = adjudedetail
	local s = CardDescPanel.new()
	s.fixedHeight = fixedHeight
    s:initLayer()
    return s
end

--通过传入一个x,y坐标值来设置其位置
function CardDescPanel:setViewPosition( viewX, viewY )
	self.scrollView:setPosition(ccp(viewX, viewY-self.size.height))
end

function CardDescPanel:loadData( metaId )
	local skillTexts = {}
	local gameInitData = DataManager.getGameInitData()
	local allCardsData = DataManager.getCardsData()
	if (MetaManager.card_meta[metaId]) then
		self.equipMetaDic = {}
		local cardQueue = CommonManager:getEffectCardQueue()
		local cardInQueue = false
		local cardCountryNums = CommonManager:getCardCountryNums()

		if (self.cardId) then
			for _, aCardId in pairs(cardQueue) do
				local aMetaId = CommonManager.getSubTableByKey(
					allCardsData,
					{name = "cardId", value = aCardId}
				).metaId
				if (aCardId == self.cardId) then
					cardInQueue = true
				end
			end
		end
		if (cardInQueue) then
			self.card = CommonManager.getSubTableByKey(
				allCardsData,
				{name = "cardId", value = self.cardId}
			)
			
			for _, aCardId in pairs(cardQueue) do
				local aMetaId = CommonManager.getSubTableByKey(
					allCardsData,
					{name = "cardId", value = aCardId}
				).metaId
				local cardGroupId = MetaManager.card_meta[aMetaId].cardGroupId
				if g_previousPlayerFateStatus then
			      -- for _, temp in ipairs(aCardGroupList) do
			        local specialGroupMeta =  MetaManager.getSpecialGroupMeta()
			        if specialGroupMeta[cardGroupId] == nil then
			          self.cardGroupList[cardGroupId] = (self.cardGroupList[cardGroupId] or 0) + 1
			        else
			          local aGroupList = specialGroupMeta[cardGroupId]
			          -- local aGroupList = group:split("|")
			          for k,v in pairs(aGroupList) do
			            self.cardGroupList[tonumber(v)] = (self.cardGroupList[cardGroupId] or 0) + 1
			          end
			        end
			      -- end
			    else
			      self.cardGroupList[cardGroupId] = (self.cardGroupList[cardGroupId] or 0) + 1
			    end
				-- self.cardGroupList[cardGroupId] = true
			end
			
			local cardEquips = {}
			if (self.card.equipIds) then
				local equipsData = DataManager.getEquipsData()
				local equipsMeta = {}
				local equipIdList = {}
				for aKey, aEquip in pairs(equipsData) do
					equipsMeta[aEquip.equipId] = tonumber(aEquip.metaId)
					equipIdList[aEquip.equipId] = aKey
				end
				for key, aEquipId in pairs(self.card.equipIds) do
					local aMeta = equipsMeta[aEquipId]
					local aEquipInfo = MetaManager.equip_meta[aMeta]
					local aPosition = aEquipInfo.position
					cardEquips[aPosition] = equipsData[equipIdList[aEquipId]]
				end
			end
			
			for _, aEquip in pairs(cardEquips) do
				--将套装技位置标记入装备Meta字典
				self.equipMetaDic[MetaManager.equip_meta[aEquip.metaId]["prefixId"]] = MetaManager.equip_meta[aEquip.metaId]["position"]
			end
		end
		local cardMeta = MetaManager.card_meta[metaId]
        if not self.adjudedetail then
			self.desc = Localization:getInstance():getText(cardMeta.desc)
		end 

		--计算合体技
		for i=1,5 do
			local aSkill = MetaManager.skill_meta[cardMeta["groupSkill"..i]]
			if (aSkill) then
				aSkill.cardGroupIds = cardMeta["group"..i]:split("|")
				local descText = {}
				for i=1,5 do
					if (aSkill.cardGroupIds[i]) then
						local aCardMeta = CommonManager.getSubTableByKey(
							MetaManager.card_meta,
							{name = "cardGroupId", value = aSkill.cardGroupIds[i]}
						)
						local aCardNameKey 
						if g_previousPlayerFateStatus then
							aCardNameKey = CommonManager:getSpecialGroupFirstCardName(aCardMeta)
						else
							aCardNameKey = MetaManager.card_meta[aCardMeta.id - aCardMeta.evolutionLevel + 1].name
						end
						-- local aCardNameKey = MetaManager.card_meta[aCardMeta.id - aCardMeta.evolutionLevel + 1].name
						if (aSkill.cardGroupIds[i+1]) then
							descText["name"..i] = getTextByKey(aCardNameKey)..getTextByKey("comma")
						else
							descText["name"..i] = getTextByKey(aCardNameKey)
						end
					else
						descText["name"..i] = ""
					end
				end
				local skillStatus = aSkill.statusIdList:split("|")
				for i=1,#skillStatus do
					if (skillStatus[i]~="0") then
						local aSkillStatus = MetaManager.skill_status[tonumber(skillStatus[i])]
						descText["num1"] = (aSkillStatus.valueType==2) and aSkillStatus.effectValue or (aSkillStatus.effectValue*100 .. "%")
						if (aSkillStatus.impactAttr==1) then
							descText["type"] = getTextByKey("attr_Attack")
						elseif (aSkillStatus.impactAttr==2) then
							descText["type"] = getTextByKey("attr_Defense")
						else
							descText["type"] = getTextByKey("attr_HP")
						end
						break
					end
				end
				local desc 
				if g_previousPlayerFateStatus then
					desc = aSkill.desc.."_fate"
				else
					desc = aSkill.desc
				end
				local aText = Localization:getInstance():getText(
							desc,
							descText
				)
				local flag = false
				if (self.cardId) then
					flag = true
					for _, aGroupId in pairs(aSkill.cardGroupIds) do
						if (not self.cardGroupList[tonumber(aGroupId)]) then
							flag = false
							break
						end
					end

					local aMetaId = CommonManager.getSubTableByKey(
					allCardsData,
					{name = "cardId", value = self.cardId}
				).metaId
					local cardGroupId = MetaManager.card_meta[aMetaId].cardGroupId
					if g_previousPlayerFateStatus and CommonManager:checkSpecialGroupCombineSelf( cardGroupId , aSkill.cardGroupIds) then
			          if self.cardGroupList[tonumber(cardGroupId)] and self.cardGroupList[tonumber(cardGroupId)] < 2 then
			            flag = false
			          end
			        end
				end
				if (flag) then
					local color
					if g_previousPlayerFateStatus then
						color = ccc3(43,186,233)
					else
						color = ccc3(128,255,96)
					end
					table.insert(skillTexts,{text = getTextByKey(aSkill.name) .. ":" .. aText, color = color})
				else
					table.insert(skillTexts,{text = getTextByKey(aSkill.name) .. ":" .. aText})
				end
			end
		end
		--计算特殊合体技
		local aGroupSkill = MetaManager.special_group_skill[cardMeta.cardGroupId]
		if aGroupSkill then
			for i=1,4 do
				if aGroupSkill["groupSkill"..i] ~= 0 then
					local descText = {}
					local aSkill = MetaManager.skill_meta[aGroupSkill["groupSkill"..i]]

					descText["num"] = aGroupSkill["groupNum"..i]
					local skillStatus = aSkill.statusIdList:split("|")
					for i=1,#skillStatus do
						if (skillStatus[i]~="0") then
							local aSkillStatus = MetaManager.skill_status[tonumber(skillStatus[i])]
							descText["num1"] = (aSkillStatus.valueType==2) and aSkillStatus.effectValue or (aSkillStatus.effectValue*100 .. "%")
							if (aSkillStatus.impactAttr==1) then
								descText["type"] = getTextByKey("attr_Attack")
							elseif (aSkillStatus.impactAttr==2) then
								descText["type"] = getTextByKey("attr_Defense")
							else
								descText["type"] = getTextByKey("attr_HP")
							end
							break
						end
					end
					local aText = Localization:getInstance():getText(
						aSkill.desc,
						descText
					)
					local isActive = CommonManager:checkSpecialGroupIsActive(cardMeta.country , aGroupSkill , i)
					if isActive and cardInQueue then
						local color
						if g_previousPlayerFateStatus then
							color = ccc3(43,186,233)
						else
							color = ccc3(51,255,0)
						end
						table.insert(skillTexts,{text = getTextByKey(aSkill.name) .. ":" .. aText, color = color})
					else
						table.insert(skillTexts,{text = getTextByKey(aSkill.name) .. ":" .. aText})
					end
				end
			end
		end
		--计算套装技
		for _, aSuit in pairs(MetaManager.equip_suit) do
			if (aSuit["cardGroupId"] == cardMeta["cardGroupId"]) then
				local descText = {}
				local aEquip = CommonManager.getSubTableByKey(
						MetaManager.equip_meta,
						{name = "prefixId", value = aSuit.equipId}
				)
				aEquip = MetaManager.equip_meta[aEquip.id - aEquip.evolveLevel + 1]
				descText["equip_name1"] = getTextByKey(aEquip.name)
				descText["num1"] = (aSuit.valueType==2) and aSuit.effectValue or (aSuit.effectValue*100 .. "%")
				if (aSuit.activeAttr==1) then
					descText["type"] = getTextByKey("attr_Attack")
				elseif (aSuit.activeAttr==2) then
					descText["type"] = getTextByKey("attr_Defense")
				else
					descText["type"] = getTextByKey("attr_HP")
				end
				
				local aText = Localization:getInstance():getText(
							"Skill_suit_equip_desc",
							descText
				)
				local flag = false
				if (self.equipMetaDic[aSuit.equipId]) then
					flag = true
				end
				if (flag) then
					table.insert(skillTexts,{text = getTextByKey(aEquip.name) .. ":" .. aText, color = ccc3(51,255,0)})
				else
					table.insert(skillTexts,{text = getTextByKey(aEquip.name) .. ":" .. aText})
				end
			end
		end
		--计算宝物技能！
		local aTreasureSkill = MetaManager.treasure_suit[cardMeta.cardGroupId]
		if aTreasureSkill then
			for i=1,5 do
				if aTreasureSkill["SkillId"..i] ~= 0 then
					local descText = {}
					local aSkill = MetaManager.skill_meta[aTreasureSkill["SkillId"..i]]

					aEquip = MetaManager.treasure_meta[aTreasureSkill["prefixID"..i] * 10 + 1]
					descText["equip_name1"] = getTextByKey(aEquip.name)..""
					local skillStatus = aSkill.statusIdList:split("|")
					for i=1,#skillStatus do
						if (skillStatus[i]~="0") then
							local aSkillStatus = MetaManager.skill_status[tonumber(skillStatus[i])]
							descText["num1"] = (aSkillStatus.valueType==2) and aSkillStatus.effectValue or (aSkillStatus.effectValue*100 .. "%")
							if (aSkillStatus.impactAttr==1) then
								descText["type"] = getTextByKey("attr_Attack")
							elseif (aSkillStatus.impactAttr==2) then
								descText["type"] = getTextByKey("attr_Defense")
							else
								descText["type"] = getTextByKey("attr_HP")
							end
							break
						end
					end
					local aText = Localization:getInstance():getText(
						"treasureSkill_1",
						descText
					)
					local isActive = false
					if self.card and self.card.treasureId ~= 0 then
						local aTreasure = CommonManager.getSubTableByKey(
							DataManager.getTreasuresData(),
							{name = "treasureId", value = self.card.treasureId}
					)
						local tempPrefixID = MetaManager.treasure_meta[aTreasure.metaId].prefixID
						isActive = CommonManager:checkIsTreasureActive( aTreasure.metaId , cardMeta.cardGroupId) and tempPrefixID == aTreasureSkill["prefixID"..i]
					end
					
					if isActive and cardInQueue then
						local color
						if g_previousPlayerFateStatus then
							color = ccc3(43,186,233)
						else
							color = ccc3(51,255,0)
						end
						table.insert(skillTexts,{text = getTextByKey(aSkill.name) .. ":" .. aText, color = color})
					else
						table.insert(skillTexts,{text = getTextByKey(aSkill.name) .. ":" .. aText})
					end
				end
			end
		end
	elseif (MetaManager.equip_meta[metaId]) then
		local equipMeta = MetaManager.equip_meta[metaId]
		self.desc = Localization:getInstance():getText(equipMeta.desc)
		if (self.cardId) then
			self.card = CommonManager.getSubTableByKey(
				allCardsData,
				{name = "cardId", value = self.cardId}
			)
		end
		local cardGroupId = (self.card) and MetaManager.card_meta[self.card.metaId]["cardGroupId"] or 0
		for _, aSuit in pairs(MetaManager.equip_suit) do
			if (aSuit["equipId"] == equipMeta["prefixId"]) then
				local aCardMeta = CommonManager.getSubTableByKey(
					MetaManager.card_meta,
					{name = "cardGroupId", value = aSuit["cardGroupId"]}
				)
				aCardMeta = MetaManager.card_meta[aCardMeta.id - aCardMeta.evolutionLevel + 1]
				--增加过滤条件: 当前区域允许卡牌出现 modified by zheng.che @ 2015-1-12
				if SystemManager.isMyLocation(aCardMeta.areaSwitch) then
					local descText = {}
					descText["card_name"] = getTextByKey(aCardMeta.name)
					descText["num1"] = (aSuit.valueType==2) and aSuit.effectValue or (aSuit.effectValue*100 .. "%")
					if (aSuit.activeAttr==1) then
						descText["type"] = getTextByKey("attr_Attack")
					elseif (aSuit.activeAttr==2) then
						descText["type"] = getTextByKey("attr_Defense")
					else
						descText["type"] = getTextByKey("attr_HP")
					end
					
					local aText = Localization:getInstance():getText(
								"Skill_suit_card_desc",
								descText
					)
					
					if (cardGroupId == aSuit["cardGroupId"]) then
						table.insert(skillTexts,{text = aText, color = ccc3(51,255,0)})
					else
						table.insert(skillTexts,{text = aText})
					end
				end
			end
		end
	elseif (MetaManager.treasure_meta[metaId]) then
		
		local treasureMeta = MetaManager.treasure_meta[metaId]
		self.desc = Localization:getInstance():getText(treasureMeta.describe)
		if (self.cardId) then
			self.card = CommonManager.getSubTableByKey(
				allCardsData,
				{name = "cardId", value = self.cardId}
			)
		end
	
        local cardGroupIdnew = (self.card) and MetaManager.card_meta[self.card.metaId]["cardGroupId"] or 0
       
		for i = 1,5 do
			
			local cardGroupId = treasureMeta["group"..i]

            if tonumber(cardGroupId) ~= 0 then
            	    
				    local aCardMeta = CommonManager.getSubTableByKey(
						MetaManager.card_meta,
						{name = "cardGroupId", value = cardGroupId}
					)
					
					aCardMeta = MetaManager.card_meta[aCardMeta.id - aCardMeta.evolutionLevel + 1]
					
					--增加过滤条件: 当前区域允许卡牌出现 modified by zheng.che @ 2015-1-12
					if SystemManager.isMyLocation(aCardMeta.areaSwitch) then
					
						local descText = {}
						
							if treasureMeta["groupSkill"..i] ~= 0 then
								
								local descText = {}
								local aSkill = MetaManager.skill_meta[treasureMeta["groupSkill"..i]]
			                    descText["card_name"] = getTextByKey(aCardMeta.name)
								
								local skillStatus = aSkill.statusIdList:split("|")

								for i=1,#skillStatus do
                                    
									if (skillStatus[i]~="0") then
										
										local aSkillStatus = MetaManager.skill_status[tonumber(skillStatus[i])]
										descText["num1"] = (aSkillStatus.valueType==2) and aSkillStatus.effectValue or (aSkillStatus.effectValue*100 .. "%")
						                if (aSkillStatus.impactAttr==1) then
											descText["type"] = getTextByKey("attr_Attack")
										elseif (aSkillStatus.impactAttr==2) then
											descText["type"] = getTextByKey("attr_Defense")
										else
											descText["type"] = getTextByKey("attr_HP")
										end
										
										local aText = Localization:getInstance():getText(
													"treasureSkill_2",
													descText
										)

										-- local isActive = CommonManager:checkIsTreasureActive( metaId , aCardMeta.cardGroupId)
                                        
										if aCardMeta.cardGroupId == cardGroupIdnew then
											local color = ccc3(51,255,0)
											
											table.insert(skillTexts,{text = getTextByKey(aSkill.name) .. ":" .. aText, color = color})
										else
											table.insert(skillTexts,{text = getTextByKey(aSkill.name) .. ":" .. aText})
										end
									end
								end
							end
						end   
					end
				end
			end
	self.content = skillTexts
end

local function buildText(str, width, color, textSize, fixedHeight)
	local textSpt = TextField:create( str )
	textSpt:setDimensions(CCSizeMake(width, fixedHeight and 62 or 0))
	textSpt:setColor( color )
	textSpt:setFontSize( textSize )
	return textSpt,textSpt:getContentSize().height
end

function CardDescPanel:initLayer()
	self:loadData(self.metaId)
	CardDescPanel.super.initLayer(self)
	
	local aScrollView = ScrollView:create(self.size.width, self.size.height)
	aScrollView:setDirection(kCCScrollViewDirectionVertical)
	self.scrollView = aScrollView
	
	local totalHeight = 0
	local texts = {}
	local heights = {}
	
	--初始化所有元素
	local mainTextSpt,textHeight = buildText(
		self.desc,
		self.size.width,
		self.color,
		defaultTextSize,
		self.fixedHeight
	)
	totalHeight = totalHeight + textHeight + (self.fixedHeight and 0 or 10)
	
	local lineSpt = Sprite:create("pic/Line1.png")
	--lineSpt:setScaleX(0.65)lineSpt:setScaleX(self.size.width/3)
	lineSpt:setScaleY(0.5)
	totalHeight = totalHeight + 22
	
	for aKey,aContent in pairs(self.content) do
		local textSpt,textHeight = buildText(
			aContent.text,
			self.size.width,
			( aContent.color or self.color ),
			( aContent.textSize or defaultTextSize )
		)
		table.insert(texts, aKey, textSpt)
		table.insert(heights, aKey, textHeight)
		totalHeight = totalHeight + textHeight + (aContent.spacing or defaultSpacing)
	end
	aScrollView:setContentSize(CCSizeMake(self.size.width, totalHeight))
	
	--设置位置并添加
	local textPosition = totalHeight
	textPosition = textPosition - textHeight - (self.fixedHeight and 0 or 10)
	mainTextSpt:setPositionY( textPosition )
	aScrollView:addChild(mainTextSpt)
	
	textPosition = textPosition - 12
	lineSpt:setPositionY( textPosition - 5)
	lineSpt:setPositionX(-lineSpt:getContentSize().width*0.15)
	if not self.adjudedetail then
		aScrollView:addChild(lineSpt)
	end
	textPosition = textPosition - 10
	
	for aKey,aTextSpt in pairs(texts) do
		textPosition = textPosition - heights[aKey] - (self.content[aKey].spacing or defaultSpacing)
		aTextSpt:setPositionY( textPosition )
		aScrollView:addChild(aTextSpt)
	end
	
	aScrollView:setContentOffset(ccp(0, self.size.height-totalHeight), false)
	--aScrollView:setTouchEnabled(false)
	self:addChild(aScrollView)
end