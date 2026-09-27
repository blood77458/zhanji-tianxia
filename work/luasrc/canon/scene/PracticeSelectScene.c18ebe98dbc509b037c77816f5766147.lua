

--
-- PracticeSelectScene
--

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local function getRecordTableLen(recordTable, maxLen)
	local result = 0
	for i = 1, maxLen do
		if recordTable[i] then
			result = result + 1
		end
	end
	return result
end

PracticeSelectScene = class(BaseUIScene)

function PracticeSelectScene:ctor()
	self.title = getTextByKey("home_sacrificeBtn")
	self.tabPicActive = {}
	self.tabPicInActive = {}
	self.tabButton = {}
	self.selectedIndex = 1
	self.practiceDataList = {}
	self.selectedType = nil
	self.currentDataList = nil
	self.selectedDataList = {}
end

function PracticeSelectScene:create(argv)
	local scene = PracticeSelectScene.new()
	scene.argv = argv
	if scene.argv.practiceData and (getRecordTableLen(scene.argv.practiceData.data, 5) > 0) then
		scene.fixedType = scene.argv.practiceData.dataType
		scene.originalData = {dataType = scene.argv.practiceData.dataType, data = {}}
		for i, aData in pairs(scene.argv.practiceData.data) do
			scene.originalData.data[i] = aData
		end
	else
		scene.fixedType = nil
		scene.argv.practiceData = {dataType = "card", data = {}}
		scene.originalData = nil
	end
	if tonumber(Get_ShareData( "Sacrifice_Guide_Running")) == 1 then
		scene.fixedType = "equip"
		scene.argv.practiceData = {dataType = "equip", data = {}}
		scene.originalData = nil
	end
	scene:initScene()
	return scene
end

function PracticeSelectScene:onInit()
	BaseUIScene.initBackGround(self)

	self:generatePracticeDataList()

	self.uiBuilder = LayoutBuilder:createWithContentsOfFile("scene/the_practice.json")
	self.uiBuilder.useArtLabelTTF = true
	self.topMenu = self.uiBuilder:build("bg_background")
	self:addChild(self.topMenu)
	-- self.topMenu:getChildByName("btn_rebirth2"):setVisible(false)
	local tabButton = {"btn_thepractice", "btn_rebirth", "btn_rebirth2"}
	local tabTextChildName = {"txt_thepractice", "txt_thepractice" ,"txt"}
	local tabTextKey = {"bag_CardTag", "bag_EquipmentTag", "Treasure_titel_4"}
	self.tapNum = 3
	if not TreasureManager.isUserLevelEnough() then
		self.tapNum = 2
		self.topMenu:getChildByName(tabButton[3]):setVisible(false)
	end
	if not self.fixedType then
		for i = 1, self.tapNum do
			local tab = self.topMenu:getChildByName(tabButton[i])
			tab:getChildByName(tabTextChildName[i]):setString(getTextByKey(tabTextKey[i]))
			self.tabPicActive[i] = tab:getChildByName("btn")
			self.tabPicInActive[i] = tab:getChildByName("disable")
			self.tabButton[i] = Button:create(tab)
			local function resetTabState(aIndex, aSelectedIndex)
				self.tabButton[aIndex]:setEnable(aIndex ~= aSelectedIndex)
				self.tabPicActive[aIndex]:setVisible(aIndex == aSelectedIndex)
				self.tabPicInActive[aIndex]:setVisible(aIndex ~= aSelectedIndex)
			end
			local function onClick(e)
				local aSelectedIndex = e.context
				for j = 1, self.tapNum do
					resetTabState(j, aSelectedIndex)
				end
				self:showTab(aSelectedIndex, true)
			end
			self.tabButton[i]:addEventListener(Events.kStart, onClick, i)
			resetTabState(i, 1)
		end
	elseif self.fixedType == "card" then
		self.topMenu:getChildByName(tabButton[1]):setVisible(true)
		self.topMenu:getChildByName(tabButton[1]):getChildByName("btn"):setVisible(true)
		self.topMenu:getChildByName(tabButton[1]):getChildByName("disable"):setVisible(false)
		self.topMenu:getChildByName(tabButton[1]):getChildByName(tabTextChildName[1]):setString(getTextByKey(tabTextKey[1]))
		self.topMenu:getChildByName(tabButton[2]):setVisible(false)
		self.topMenu:getChildByName(tabButton[3]):setVisible(false)
	elseif self.fixedType == "equip" then
		self.topMenu:getChildByName(tabButton[1]):setVisible(true)
		self.topMenu:getChildByName(tabButton[1]):getChildByName("btn"):setVisible(true)
		self.topMenu:getChildByName(tabButton[1]):getChildByName("disable"):setVisible(false)
		self.topMenu:getChildByName(tabButton[1]):getChildByName(tabTextChildName[1]):setString(getTextByKey(tabTextKey[2]))
		self.topMenu:getChildByName(tabButton[2]):setVisible(false)
		self.topMenu:getChildByName(tabButton[3]):setVisible(false)
	elseif self.fixedType == "treasure" then
		self.topMenu:getChildByName(tabButton[1]):setVisible(true)
		self.topMenu:getChildByName(tabButton[1]):getChildByName("btn"):setVisible(true)
		self.topMenu:getChildByName(tabButton[1]):getChildByName("disable"):setVisible(false)
		self.topMenu:getChildByName(tabButton[1]):getChildByName(tabTextChildName[1]):setString(getTextByKey(tabTextKey[3]))
		self.topMenu:getChildByName(tabButton[2]):setVisible(false)
		self.topMenu:getChildByName(tabButton[3]):setVisible(false)
	end
	self.uiView = self.uiBuilder:build("rebirth_list_choose")
	self:addChild(self.uiView)
	self.uiView:getChildByName("txt_thepractice4"):getChildByName("txt"):setString(getRecordTableLen(self.argv.practiceData.data, 5) .. "/5")
	local confirmBtnDisplay = self.uiView:getChildByName("btn3_Blowing Balloons")
	confirmBtnDisplay:getChildByName("txt"):setString(getTextByKey("sacrifice_title4"))
	local function onClickConfirm()
		local argv = self.argv.practiceData
		if getRecordTableLen(argv.data, 5) == 0 then
			argv = nil
		end
		self:replaceScene(CardRebirthScene , {params = argv, enterScene = "PracticeSelectScene"})
	end
	local btnConfirm = Button:create(confirmBtnDisplay)
	btnConfirm:addEventListener(Events.kStart, onClickConfirm)
	self.uiView:getChildByName("txt_thepractice3"):getChildByName("txt"):setString("")
	local table_temp_view = self.uiView:getChildByName("table_thePractice_inventory_list")
	table_temp_view:setVisible(false)
	self.table_meta_info = getTableViewSizes(table_temp_view)
	self.tableView = nil

	BaseUIScene.onInit(self)
end

function PracticeSelectScene.getPracticeTreasureData()
	local treasureData = DataManager.getTreasuresData()
	local result = {}
  	if(treasureData) then
    	for _, aConfig in ipairs( treasureData ) do
      		if ((not aConfig.cardId) or (aConfig.cardId == 0)) and aConfig.level <= 1 and not aConfig.lock then  --没有被card穿戴并且没有锁住
        		table.insert(result, aConfig)
      		end
    	end
  	end

	--宝物阵容状态
	local queueList = {}
	local gameData = DataManager.getGameInitData()
	for BattleArrayId = 1,3 do
		local quedata = gameData.sharkUserBattleArray[BattleArrayId] and gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue or {}
		for k,v in pairs(quedata) do
			queueList[v.treasureId] = true
		end	
	end
	for i = #result,1,-1 do
		if queueList[result[i].treasureId] == true then
			table.remove(result , i)
		end
	end	

  	local function sortFunc(a, b)
    	local rareA = MetaManager.treasure_meta[a.metaId].rare
		local rareB = MetaManager.treasure_meta[b.metaId].rare
		if rareA ~= rareB then
			return (rareA < rareB)
		elseif a.level ~= b.level then
			return (a.level < b.level)
		else
			return (a.metaId < b.metaId)
		end
  	end
  	table.sort(result, sortFunc)
  	return result
end

function PracticeSelectScene.getParcticeCardData()
	local queueList = {}
	for k,v in pairs(CommonManager.getQueueData()) do
		queueList[v] = true
	end
	for k,v in pairs(CommonManager:getMatrixCardData()) do
		queueList[v] = true
	end
	--阵容状态（不可祭炼）
	local gameData = DataManager.getGameInitData()
	for BattleArrayId = 1,3 do	
		local quedata = gameData.sharkUserBattleArray[BattleArrayId] and gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue or {}
		local matdata = gameData.sharkUserBattleArray[BattleArrayId] and gameData.sharkUserBattleArray[BattleArrayId].sharkMatrices and 
						gameData.sharkUserBattleArray[BattleArrayId].sharkMatrices.sharkMatrices or {}
		for k,v in pairs(quedata) do
			if v.cardId then queueList[v.cardId] = true end
		end
		for k,v in pairs(matdata) do
			if not v.sharkMatrixGrids then v.sharkMatrixGrids = {} end
			for _,value in pairs(v.sharkMatrixGrids) do
				if value.cardId then queueList[value.cardId] = true end
			end		
		end			
	end
	--end by l1ghtsaber
	local result = {}
	local cardList = DataManager.getCardsData()
	for k,card in pairs(cardList) do
		if (not card.lock) and (not queueList[card.cardId]) then
			if MetaManager.card_meta[card.metaId].astralEssence > 0 then
				local origin = true
				if card.level > 1 or card.exp > 0 or card.usedPotential > 0 then
					origin = false
				elseif card.cardSkills then
					for i,v in ipairs(card.cardSkills) do
						if v.skillId and MetaManager.skill_meta[v.skillId] and MetaManager.skill_meta[v.skillId].level > 1 then
							origin = false
							break
						end
					end
				end
				if origin then
					table.insert(result, card)
				end
			end
		end
	end
	local function sortFunc(a, b)
    	local rareA = MetaManager.card_meta[a.metaId].rare
		local rareB = MetaManager.card_meta[b.metaId].rare
		if rareA ~= rareB then
			return (rareA < rareB)
		elseif a.level ~= b.level then
			return (a.level < b.level)
		else
			return (a.metaId < b.metaId)
		end
  	end
  	table.sort(result, sortFunc)
	return result
end

function PracticeSelectScene.getPracticeEquipData()
	local result = {}
	if tonumber(Get_ShareData( "Sacrifice_Guide_Running")) == 1 then
    	table.insert(result, {equipId = 0, metaId = 235001, level = 1, cardId = 0, enchantLevel = 0, enchantNum = 0})
    	return result
    end
	local equipData = DataManager.getEquipsData()
  	if(equipData) then
    	for _, aConfig in ipairs( equipData ) do
      		if ((not aConfig.cardId) or (aConfig.cardId == 0)) and (MetaManager.equip_meta[aConfig.metaId].quality > 2) then  --没有被card穿戴
        		table.insert(result, aConfig)
      		end
    	end
  	end
	--阵容状态（不可祭炼）
	local queueList = {}
	local gameData = DataManager.getGameInitData()
	for BattleArrayId = 1,3 do
		local quedata = gameData.sharkUserBattleArray[BattleArrayId] and gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue or {}
		for k,v in pairs(quedata) do
			if (not v.equips) then v.equips = {} end
			for _,value in pairs(v.equips) do
				queueList[value] = true
			end		
		end	
	end
	for i = #result,1,-1 do
		if queueList[result[i].equipId] == true then
			table.remove(result , i)
		end
	end	
	--end by l1ghtsaber
  	local function sortFunc(a, b)
    	local rareA = MetaManager.equip_meta[a.metaId].quality
		local rareB = MetaManager.equip_meta[b.metaId].quality
		if rareA ~= rareB then
			return (rareA < rareB)
		elseif a.level ~= b.level then
			return (a.level < b.level)
		else
			return (a.metaId < b.metaId)
		end
  	end
  	table.sort(result, sortFunc)
  	return result
end

function PracticeSelectScene:generatePracticeDataList()
	if not self.fixedType then
		self.practiceDataList[1] = PracticeSelectScene.getParcticeCardData()
		self.practiceDataList[2] = PracticeSelectScene.getPracticeEquipData()
		self.practiceDataList[3] = PracticeSelectScene.getPracticeTreasureData()
	elseif self.fixedType == "card" then
		self.practiceDataList[1] = PracticeSelectScene.getParcticeCardData()
	elseif self.fixedType == "equip" then
		self.practiceDataList[1] = PracticeSelectScene.getPracticeEquipData()
	elseif self.fixedType == "treasure" then
		self.practiceDataList[1] = PracticeSelectScene.getPracticeTreasureData()
	end
end

function PracticeSelectScene:showTab(aIndex, whetherClearData)
	if not self.fixedType then
		if aIndex == 1 then
			self.selectedType = "card"
		elseif aIndex == 2 then
			self.selectedType = "equip"
		elseif aIndex == 3 then
			self.selectedType = "treasure"
		end
	else
		self.selectedType = self.fixedType
	end
	self.currentDataList = self.practiceDataList[aIndex]
	if whetherClearData then
		self.argv.practiceData = {dataType = self.selectedType, data = {}}
	end

  	local tempLayer
  	local originalTargetInfoPanel = self.targetInfoPanel
  	local function beforeTransition()
  		tempLayer = Layer:create()
		tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
	    self.targetInfoPanel = tempLayer
		self:addChild(tempLayer)
  	end
  	local function afterTransition()
  		tempLayer:removeFromParentAndCleanup(true)
  		self.targetInfoPanel = originalTargetInfoPanel
  	end
  	local function showNewContent()
  		local aContentKey
  		if self.selectedType == "card" then
  			aContentKey = "sacrifice_text4"
  		elseif self.selectedType == "equip" then
  			aContentKey = "sacrifice_text1"
		elseif self.selectedType == "treasure" then
  			aContentKey = "Treasure_text_5"
  		end
  		self.uiView:getChildByName("txt_thepractice3"):getChildByName("txt"):setString(getTextByKey(aContentKey))
  		self.uiView:getChildByName("txt_thepractice4"):getChildByName("txt"):setString(getRecordTableLen(self.argv.practiceData.data, 5) .. "/5")
  		self.tableView = self:createTableView(self.currentDataList, self.table_meta_info)
		self.uiView:addChild(self.tableView)
  		self.tableView:reloadData()
  		ViewControlUtil.showTableViewAction(self.tableView, visibleSize, afterTransition)
  	end
  	local function disappearActionFinished()
  		self.tableView:removeFromParentAndCleanup(true)
  		self.tableView = nil
  		showNewContent()
  	end
  	beforeTransition()
	if not self.tableView then
		showNewContent()
	else
		ViewControlUtil.disappearTableViewAction(self.tableView, visibleSize, showNewContent)
	end
	
	
end

local colorLabelList = {"q_white9_panel", "q_green9_panel", "q_blue9_panel", "q_purple9_panel", "q_orange9_panel", 
"q_red9_panel", "q_yellow9_panel"}
local colorLabelTagList = {-11, -12, -13, -14, -15, -16, -17}

function PracticeSelectScene:createTableView(data, metaInfo)
	local cellTag = 1024
	local TableRenderer = class(TableViewRenderer)
	local SELF = self
	function TableRenderer:ctor(width, height)
		self.list = data
	end 

	function TableRenderer:buildCell(container)
		local cell = SELF.uiBuilder:build("thePractice_inventory_list1")
		cell:setTag(cellTag)
		container:addChild(cell)
		
		cell:getChildByName("zhuangbeizhong"):setVisible(false)
		cell:getChildByName("normal_card_small_sb"):setTag(-10)
		cell:getChildByName("normal_card_small_sb"):setVisible(false)
		for i = 1, 7 do
			cell:getChildByName(colorLabelList[i]):setTag(colorLabelTagList[i])
		end
		cell:getChildByName("txt_4"):setTag(-18)
		cell:getChildByName("txt_4"):getChildByName("txt_inventory_card_name"):setTag(-10)
		for i = 1, 7 do
			cell:getChildByName("icon_star_" .. i):setTag(-18 - i)
		end
		cell:getChildByName("txt_2"):setTag(-26)
		cell:getChildByName("txt_2"):getChildByName("font"):setTag(-10)
		cell:getChildByName("txt_1"):setTag(-27)
		cell:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("enchant_1"))--附灵
		cell:getChildByName("txt_3"):setTag(-28)
		cell:getChildByName("txt_3"):getChildByName("txt"):setTag(-10)
		for i = 1, 3 do
			local attributeView = cell:getChildByName("attribute_0" .. i)
			attributeView:setTag(-28 - i)
			attributeView:getChildByName("icon_atk"):setTag(-11)
			attributeView:getChildByName("icon_hp"):setTag(-12)
			attributeView:getChildByName("icon_def"):setTag(-13)
			attributeView:getChildByName("txt_03"):setTag(-14)
			attributeView:getChildByName("txt_03"):getChildByName("txt"):setTag(-11)
			attributeView:getChildByName("txt_02"):setTag(-15)
			attributeView:getChildByName("txt_02"):getChildByName("txt"):setTag(-11)
		end
		cell:getChildByName("btn_selected_all"):setTag(-32)
		cell:getChildByName("btn_selected_all"):getChildByName("email_checked"):setTag(-10)
		cell:getChildByName("btn_not_selected_all"):setTag(-33)
		cell:getChildByName("icon_spirit"):setTag(-35)
		cell:getChildByName("icon_soulValue"):setTag(-34)
		cell:getChildByName("icon_snl"):setTag(-40)
		cell:getChildByName("txt_5"):setTag(-36)
		cell:getChildByName("txt_5"):getChildByName("txt"):setTag(-10)

		cell:getChildByName("lbl_you"):setTag(-41)
		cell:getChildByName("lbl_you"):getChildByName("txt"):setTag(-10)
	end

	function TableRenderer:setData( rawCocosObj, index )
		local cell = self:getChildByTag(rawCocosObj, cellTag)
		local cardInfo = data[index + 1]
		
		local resourceType
		local aStarNum
		local propertyId
		local aTempList = {{-10, "att"}, {-12, "def"}, {-11, "hp"}}
		if SELF.selectedType == "card" then
			propertyId = "cardId"
			resourceType = ResourceEnum.CARD
			aStarNum = MetaManager.card_meta[cardInfo.metaId].rare
			cell:getChildByTag(-27):setVisible(false)
			cell:getChildByTag(-28):setVisible(false)
			cell:getChildByTag(-34):setVisible(false)
			cell:getChildByTag(-40):setVisible(false)
			cell:getChildByTag(-30):setVisible(true)
			cell:getChildByTag(-31):setVisible(true)
			cell:getChildByTag(-41):setVisible(false)
			
			local astralEssenceNum = MetaManager.card_meta[cardInfo.metaId].astralEssence
			if astralEssenceNum > 0 then
				cell:getChildByTag(-36):setVisible(true)
				setNodeText(cell:getChildByTag(-36):getChildByTag(-10), tostring(astralEssenceNum))
			else
				cell:getChildByTag(-36):setVisible(false)
			end
			if aStarNum >= 4 then
				cell:getChildByTag(-35):setVisible(true)
			else
				cell:getChildByTag(-35):setVisible(false)
			end
			local aValueList = CommonManager:getBackpackCardPropertiesWithSharkCard(cardInfo)
			local aTempList = {{-11, "att"}, {-13, "def"}, {-12, "hp"}}
			for i = 1, 3 do
				local attributeView = cell:getChildByTag(-28 - i)
				for j = 1, 3 do
					if j == i then
						attributeView:getChildByTag(aTempList[j][1]):setVisible(true)
						setNodeText(attributeView:getChildByTag(-14):getChildByTag(-11), tostring(aValueList[aTempList[j][2]]))
						setNodeColor(attributeView:getChildByTag(-14):getChildByTag(-11), ccc3(70, 40, 255))
					else
						attributeView:getChildByTag(aTempList[j][1]):setVisible(false)
					end
				end
			end
		elseif SELF.selectedType == "equip" then
			cell:getChildByTag(-35):setVisible(false)
			cell:getChildByTag(-40):setVisible(false)
			cell:getChildByTag(-41):setVisible(false)
			propertyId = "equipId"
			resourceType = ResourceEnum.EQUIP
			aStarNum = MetaManager.equip_meta[cardInfo.metaId].quality
			--[[
			local attrInfo = EquipUtils.findAttrAddInfo(cardInfo.metaId, cardInfo.level)
			for i = 1, 3 do
				if attrInfo.type == i then
					cell:getChildByTag(-29):getChildByTag(aTempList[i][1]):setVisible(true)
				else
					cell:getChildByTag(-29):getChildByTag(aTempList[i][1]):setVisible(false)
				end
			end
			setNodeText(cell:getChildByTag(-29):getChildByTag(-13):getChildByTag(-10), tostring(math.floor(attrInfo.num) or 0))
			]]
			local function getSpiritNum(cardInfo)
				local baseSpiritNum = 0
				for _, aEquipSpiritValueConfig in pairs(MetaManager.equip_spirit_value) do
					if (aEquipSpiritValueConfig.equipRolex == MetaManager.equip_meta[cardInfo.metaId].quality) and (MetaManager.equip_meta[cardInfo.metaId].position == aEquipSpiritValueConfig.itemPosition) then
						baseSpiritNum = aEquipSpiritValueConfig.spiritValue
						break
					end
				end
				local gameSettingConfig = MetaManager.game_meta.gameSettingConfig
				local aSpiritNum = baseSpiritNum + math.floor(cardInfo.enchantNum * gameSettingConfig.equipSpiritValue / 1000)
				return aSpiritNum
			end
			local aSpiritNum = getSpiritNum(cardInfo)
			if aSpiritNum > 0 then
				cell:getChildByTag(-34):setVisible(true)
				setNodeText(cell:getChildByTag(-36):getChildByTag(-10), tostring(aSpiritNum))
			else
				cell:getChildByTag(-34):setVisible(false)
				cell:getChildByTag(-36):setVisible(false)
			end
			local attrInfos = EquipUtils.findFirstAttrs(cardInfo.metaId, cardInfo.level, cardInfo.enchantLevel)
			for i = 1, (ConstManager.HEAD_ATTR_COUNT) do
				local enchantDisplay = cell:getChildByTag(-29 - (i-1))
				if enchantDisplay then
					local attrInfo = attrInfos[i]
					if attrInfo then
						--有附加属性
						enchantDisplay:setVisible(true)
						if i == 1 then
							--普通属性
							EnchantUtils.setAttrShowAsTag(enchantDisplay, attrInfo.id, math.floor(attrInfo.num), 1)
						else
							EnchantUtils.setAttrShowAsTag(enchantDisplay, attrInfo.id, math.floor(attrInfo.num), 2)
						end
					else
						--无附加属性
						enchantDisplay:setVisible(false)
					end
				end
			end
			if cardInfo.enchantLevel > 0 then
				cell:getChildByTag(-27):setVisible(true)
				cell:getChildByTag(-28):setVisible(true)
				setNodeText(cell:getChildByTag(-28):getChildByTag(-10), EnchantUtils.getEnchantLevelStr(cardInfo.enchantLevel))
				--[[
				local enchantAttrIds = {}
				local enchantInfo = Enchant.findEnchantInfo(cardInfo.metaId, cardInfo.enchantLevel)
				for i, attrId in ipairs(ConstManager.HEAD_ATTRS) do
					if attrId ~= attrInfo.type then
						--不是固有属性
						if enchantInfo.attrHash[attrId] then
							table.insert(enchantAttrIds, attrId)
						end
					end
				end
				for i = 1, 2 do
					local attributeView = cell:getChildByTag(-29 - i)
					local attrId = enchantAttrIds[i]
					if attrId then
						attributeView:setVisible(true)
						for j = 1, 3 do
							if attrId == j then
								attributeView:getChildByTag(aTempList[j][1]):setVisible(true)
								setNodeText(attributeView:getChildByTag(-13):getChildByTag(-10), tostring(math.floor(enchantInfo.attrHash[attrId].num) or 0))
								setNodeColor(attributeView:getChildByTag(-13):getChildByTag(-10), ccc3(0, 204, 0))
							else
								attributeView:getChildByTag(aTempList[j][1]):setVisible(false)
							end
						end
					else
						attributeView:setVisible(false)
					end
				end
				]]
			else
				cell:getChildByTag(-27):setVisible(false)
				cell:getChildByTag(-28):setVisible(false)
				--[[
				cell:getChildByTag(-30):setVisible(false)
				cell:getChildByTag(-31):setVisible(false)
				]]
			end
		elseif SELF.selectedType == "treasure" then
			cell:getChildByTag(-35):setVisible(false)
			cell:getChildByTag(-27):setVisible(false)
			cell:getChildByTag(-28):setVisible(false)
			cell:getChildByTag(-34):setVisible(false)
			cell:getChildByTag(-41):setVisible(true)

			-- print(table.tostring(cardInfo) .. "####".. TreasureManager.getTreasureQua( TreasureSystemUtils.CheckPotentialRank(cardInfo) ))
			local aTreasure = CommonManager.getSubTableByKey(
						DataManager.getTreasuresData(),
						{name = "treasureId", value = cardInfo.treasureId}
				)
			setNodeText(cell:getChildByTag(-41):getChildByTag(-10), TreasureManager.getTreasureQua( TreasureSystemUtils.CheckPotentialRank(aTreasure) ))
			setNodeColor(cell:getChildByTag(-41):getChildByTag(-10),TreasureManager.getColorByRarity(TreasureSystemUtils.CheckPotentialRank(aTreasure) + 1))


			propertyId = "treasureId"
			resourceType = ResourceEnum.TREASURE
			aStarNum = MetaManager.treasure_meta[cardInfo.metaId].rare

			local astralEssenceNum = MetaManager.treasure_meta[cardInfo.metaId].astralEssence
			if astralEssenceNum > 0 then
				cell:getChildByTag(-36):setVisible(true)
				setNodeText(cell:getChildByTag(-36):getChildByTag(-10), tostring(astralEssenceNum))
			else
				cell:getChildByTag(-36):setVisible(false)
			end

			local aValueList = {}
			aValueList.hp , aValueList.def, aValueList.att = TreasureSystemUtils.CountAttandDefandHp(cardInfo)
			local aTempList = {{-11, "att"}, {-13, "def"}, {-12, "hp"}}
			for i = 1, 3 do
				local attributeView = cell:getChildByTag(-28 - i)
				for j = 1, 3 do
					if j == i then
						attributeView:getChildByTag(aTempList[j][1]):setVisible(true)
						setNodeText(attributeView:getChildByTag(-14):getChildByTag(-11), tostring(aValueList[aTempList[j][2]]))
						setNodeColor(attributeView:getChildByTag(-14):getChildByTag(-11), ccc3(70, 40, 255))
					else
						attributeView:getChildByTag(aTempList[j][1]):setVisible(false)
					end
				end
			end
		end
		local aIcon = cell:getChildByTag(-10)
	    local params = {}
	    params.notShowCardStar = true --不显示头像星星
	    params.sourceDisplay = aIcon
	    params.container = cell
	    --params.showInCenter = true
	    params.zindex = 10
	    aCard = CanonGoodIcon.createGoodIcon(resourceType, cardInfo.metaId, 0, params)
	    if aCard then
	    	aCard:setTag(-50)
	        aCard:dispose()
	    end
	    local aName = CanonGoodIcon.getGoodName(resourceType, cardInfo.metaId, 0, {withoutAmount = true})
	    setNodeText(cell:getChildByTag(-18):getChildByTag(-10), aName)
	    for i = 1, 7 do
	    	local aStarSprite = cell:getChildByTag(-18 - i)
	    	if i <= aStarNum then
	    		aStarSprite:setVisible(true)
	    	else
	    		aStarSprite:setVisible(false)
	    	end
	    	local aColorSprite = cell:getChildByTag(colorLabelTagList[i])
	    	if i == aStarNum then
	    		aColorSprite:setVisible(true)
	    	else
	    		aColorSprite:setVisible(false)
	    	end
	    end
	    setNodeText(cell:getChildByTag(-26):getChildByTag(-10), tostring(cardInfo.level))
	    local existed = false
		for _, aCardData in pairs(SELF.argv.practiceData.data) do
			if aCardData[propertyId] == cardInfo[propertyId] then
				existed = true
				break
			end
		end
		if existed then
			cell:getChildByTag(-32):setVisible(true)
			cell:getChildByTag(-33):setVisible(false)
		elseif getRecordTableLen(SELF.argv.practiceData.data, 5) == 5 then
			cell:getChildByTag(-32):setVisible(false)
			cell:getChildByTag(-33):setVisible(false)
		else
			cell:getChildByTag(-32):setVisible(false)
			cell:getChildByTag(-33):setVisible(true)
		end
	end

	local function inArea(posX, posY, rect)
	    if posX >= rect.x and posX <= rect.x + rect.width and posY >= rect.y and posY <= rect.y + rect.height then
	      	return true
	    end
	    return false
	end 
	
	local function onListItemTouch( evt ) 
		local selectedCell = self.tableView:cellAtIndex(evt.data):getChildByTag(cellTag)
		local curTabIndex = evt.context
		local aData = data[evt.data + 1]
		local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
		local btnDisplay = selectedCell:getChildByTag(-32)
		local aPosition = btnDisplay:getPosition()
		local aSize = btnDisplay:getChildByTag(-10):getContentSize()
		local itemRect = {x = btnDisplay:getPositionX() - 20, y = btnDisplay:getPositionY() - aSize.height - 25, width = aSize.width + 45, height = aSize.height + 45}
		if tonumber(Get_ShareData( "Sacrifice_Guide_Running")) == 1 then
			self:selectCellData(aData)
		elseif inArea(posInCell.x, posInCell.y, itemRect) then --allselect
			self:selectCellData(aData)
		end
	end

	local renderer = TableRenderer.new(metaInfo.item_width, metaInfo.item_height)
	local buttonTag = {}
    local list = TableView:create(renderer, metaInfo.table_width, metaInfo.table_height, cellTag, buttonTag)
    list:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
    list:setPosition(ccp(metaInfo.table_posX, metaInfo.table_posY))
    return list
end

function PracticeSelectScene:selectCellData(aData)
	local propertyId
	if self.selectedType == "card" then
		propertyId = "cardId"
	elseif self.selectedType == "equip" then
		propertyId = "equipId"
	elseif self.selectedType == "treasure" then
		propertyId = "treasureId"
	end
	local existed = false
	for aIndex, aCardData in pairs(self.argv.practiceData.data) do
		if aCardData[propertyId] == aData[propertyId] then
			existed = true
			self.argv.practiceData.data[aIndex] = nil
			break
		end
	end
	if not existed then
		if getRecordTableLen(self.argv.practiceData.data, 5) == 5 then
			return
		end
		for i = 1, 5 do
			if not self.argv.practiceData.data[i] then
				self.argv.practiceData.data[i] = aData
				break
			end
		end
	end
	ViewControlUtil.refreshTableView(self.tableView, true)
	self.uiView:getChildByName("txt_thepractice4"):getChildByName("txt"):setString(getRecordTableLen(self.argv.practiceData.data, 5) .. "/5")
end

function PracticeSelectScene:back()
	self:replaceScene(CardRebirthScene , {params = self.originalData, enterScene = "PracticeSelectScene"})
end

function PracticeSelectScene:doEnterAnimation()
	self:preEnterAnimation()
	self:startEnterAnimation()
end

function PracticeSelectScene:doExitAnimation()
	self:preExitAnimation()
	self:startExitAnimation()
end

function PracticeSelectScene:startEnterAnimation()
	BaseUIScene.startEnterAnimation(self)

	local function nodeActionFinished()
		self:nodeAnimationFinished()
	end

	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(nodeActionFinished))
	self.topMenu:setPositionX(self.topMenu:getPositionX() - visibleSize.width)
	self.topMenu:runAction(CCSequence:create(arr))
	self.uiView:setPositionX(self.uiView:getPositionX() - visibleSize.width)
	arr = CCArray:create()
	arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
	self.uiView:runAction(CCSequence:create(arr))
	
	self:showTab(1)
end

function PracticeSelectScene:startExitAnimation()
	BaseUIScene.startExitAnimation(self)

	local function nodeActionFinished()
		self:nodeAnimationFinished()
	end

	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(nodeActionFinished))
	self.topMenu:runAction(CCSequence:create(arr))
	arr = CCArray:create()
	arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
	self.uiView:runAction(CCSequence:create(arr))
	ViewControlUtil.disappearTableViewAction(self.tableView, visibleSize)
end