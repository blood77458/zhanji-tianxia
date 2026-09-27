require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.display.Scene"
require "hecore.ui.LayoutBuilder"
require "canon.scene.LoadingScene"
require "canon.customUI/CanonCard"
require "canon.scene.BaseUIScene"

CardStrenthenSelectScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local SUGGESTION_RARE = 3

function CardStrenthenSelectScene:ctor()
	self.title = getTextByKey("cardEnhance_Title")
	self.selectMatterCard = {}
	self.curSelectCardExp = 0
	self.curSelectCardPrice = 0
	self.resultLevel = 0
	self.oldLevel = 0
end

function CardStrenthenSelectScene:create( argv )
  if argv then 
    self.argv = argv 
  else
    self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
  local scene = CardStrenthenSelectScene.new()		
  scene:initScene()
  return scene
end

local CARD_MINRARE = 1
local CARD_MAXRARE = 7

function CardStrenthenSelectScene:onInit()	
	BaseUIScene.initBackGround(self)
	self.builder = LayoutBuilder:createWithContentsOfFile("scene/package_new.json")
	self.builder.useArtLabelTTF = true
	
	self.mainUI = Layer:create();
	
	local matterCardString = HeMemDataHolder:getString("matterCard")
  if matterCardString=="" then 
    matterCardString = {}
  else
    matterCardSelected = table.deserialize(matterCardString)
		for k, v in pairs(matterCardSelected) do
			self.selectMatterCard[v.cardId] = v.metaId
		end
	end
	
	local cardData = DataManager.getCardsData()
	
	if self.argv.params.filterFunc ~= nil then
		cardData = self.argv.params.filterFunc(cardData)
	end
	
	self.strengthenCardData = {}
	local strengthenCardData = {}
	local changeExp = 0
	for i = CARD_MINRARE, CARD_MAXRARE do
		table.insert(strengthenCardData, {rare = i, cardTable = {}, curPage = 1})
	end
	--阵容状态（不可批量卖出）
	local queueList = {}
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
	for key ,data in pairs(cardData) do
		if not data.lock then
			local cardStatus = CommonManager:getBackpackCardPropertiesWithSharkCardWithoutCardProperties( data )
			data.resultExp   = math.floor(cardStatus.resultExp)
			data.price = cardStatus.price
			data.rare = MetaManager.card_meta[data.metaId].rare
			data.cardName = MetaManager.card_meta[data.metaId].name
			data.cardSelect = (self.selectMatterCard[data.cardId] ~= nil)
			if self.selectMatterCard[data.cardId] ~= nil then
				changeExp = changeExp + data.resultExp
			end
			if data.rare and tonumber(data.rare) <= CARD_MAXRARE and tonumber(data.rare) >= CARD_MINRARE 
			and (not queueList[data.cardId])  --add by l1ghtsaber
			then
				table.insert(strengthenCardData[tonumber(data.rare)].cardTable, data)
			end
		end
	end
	
	for key ,data in pairs(strengthenCardData) do
		if table.getn(data.cardTable) > 0 then
			table.insert(self.strengthenCardData, data)
		end
	end
	
	local function cardSortFunc(a, b)
		if a.resultExp == b.resultExp then
			return a.metaId < b.metaId
		else
			return a.resultExp > b.resultExp
		end
	end
	
	for key, data in pairs(self.strengthenCardData) do
		table.sort(data.cardTable, cardSortFunc)
	end
	
	self.tableView = self:createTableView(self.strengthenCardData)
	self.mainUI:addChild(self.tableView)
	
	if self.argv.enterScene == "BackpackScene" then
		self.title = getTextByKey("inventory_sellCardTitle")
		self.infoPanel = self.builder:build("package_package_bottom")
		self.mainUI:addChild(self.infoPanel)
		self.infoPanel:getChildByName("btn_yellow_sure"):getChildByName("txt"):setString(getTextByKey("yes"))
		local sellButton = Button:create(self.infoPanel:getChildByName("btn_yellow_sure"))
		local function onClickSell()
			local idsToSell = {}
			for k,v in pairs(self.selectMatterCard) do
				table.insert(idsToSell, k)
			end
			local function onSellFinish()
				self:replaceScene(BackpackScene, {params={showSellFinish = true}})
			end
			self.targetInfoPanel = ItemSellMessageBoxPanel:create(self, {cardData = idsToSell, bagCategory = BAGCATEGORY.card, onSellFinish = onSellFinish}) 
			self:addChild(self.targetInfoPanel)
			self.targetInfoPanel:scaleIn()   
		end
		sellButton:addEventListener(Events.kStart, onClickSell)
		self:getSellPrice(0)
	else
		self.infoPanel = self.builder:build("package_getall_bottom")
		self.mainUI:addChild(self.infoPanel)
		local mainCardText = ""
		if self.argv.params.mainCardMetaId then
			mainCardText = Localization:getInstance():getText("cardEnhanceSelect_tips1", {cardname = getTextByKey(MetaManager.card_meta[self.argv.params.mainCardMetaId].name)})
		end
		self.infoPanel:getChildByName("skillup_txt_skillname_in"):getChildByName("txt"):setString(mainCardText)
		self.infoPanel:getChildByName("package_getall_bottom_CoinConsume"):getChildByName("txt_equip_CoinConsume"):setString(getTextByKey("cardEnhance_CoinConsume"))
		self.infoPanel:getChildByName("package_getall_btn_yellow_sure"):getChildByName("txt"):setString(getTextByKey("yes"))
		self.infoPanel:getChildByName("package_getall_txt1"):getChildByName("txt"):setString(getTextByKey("cardEnhanceSelect_resultTips1"))
		self.infoPanel:getChildByName("skillup_txt_need_selection"):getChildByName("txt"):setString(getTextByKey("cardEnhanceSelect_selectCardTips"))
		self.infoPanel:getChildByName("package_getall_txt_2"):getChildByName("txt"):setString(getTextByKey("cardEnhanceSelect_resultTips2"))
		self.infoPanel:getChildByName("package_getall_txt_5"):getChildByName("txt"):setString(getTextByKey("cardEnhanceSelect_resultTips5"))
		
		local function onClickEnhance()
			local function replaceScene()
				local matterCard = {}
				for key ,data in pairs(self.selectMatterCard) do
					table.insert(matterCard, {cardId = key, metaId = data})
				end
				local params = {}
				local nextReturnScene = nil;
				if self.argv.params then
					nextReturnScene = self.argv.params.preReturnScene
				end
				local argv = {enterScene="CardStrenthenSelectScene",returnScene=nextReturnScene,params={matterCard=matterCard,cardType="matterCard"}}
				self:replaceScene(CardComposeScene , argv)
			end
			local function continueFunction()
				for k, v in pairs(self.selectMatterCard)
				do
					if MetaManager.card_meta[v].evolutionLevel > 1 then
						self.targetInfoPanel = MessageBoxPanel:create(self, MessageBoxType.kCardComposeRareCardWarning, {setTargetInfoPanelNil = true, continueFunction = replaceScene, warningMessage = getTextByKey("cardEnhanceSelect_evolvedTips")})
						self:addChild(self.targetInfoPanel)
						self.targetInfoPanel:scaleIn()
						return false
					end
				end
				replaceScene()
			end
			
			if tonumber(DataManager.getCurrUser().coins) < tonumber(self.curSelectCardExp * MetaManager.game_meta.gameSettingConfig.cardUpgradeCoinRevise) then
				self.targetInfoPanel = MessageBoxPanel:create(self, MessageBoxType.kCoinLimit, {setTargetInfoPanelNil = true})
				self:addChild(self.targetInfoPanel)
				self.targetInfoPanel:scaleIn()
				return false
			else
				for k, v in pairs(self.selectMatterCard)
				do
					if MetaManager.card_meta[v].rare >= SUGGESTION_RARE then
						self.targetInfoPanel = MessageBoxPanel:create(self, MessageBoxType.kCardComposeRareCardWarning, {setTargetInfoPanelNil = true, continueFunction = continueFunction})
						self:addChild(self.targetInfoPanel)
						self.targetInfoPanel:scaleIn()
						return false
					end
				end
				continueFunction()
			end
		end
		
		self.enhanceButton = Button:create(self.infoPanel:getChildByName("package_getall_btn_yellow_sure"))
		self.enhanceButton:addEventListener(Events.kStart, onClickEnhance)
		
		self:getComposeExp(changeExp)
	end
	
	if table.size(cardData) <= 0 then
		local noCardText = ArtTextField:create(getTextByKey("bag_NoCard"), nil, 30)
		noCardText:setPositionXY(visibleSize.width / 2, visibleSize.height / 2)
		self.mainUI:addChild(noCardText)
	end
	
	self:addChild(self.mainUI)
	BaseUIScene.onInit(self)
end

function CardStrenthenSelectScene:refreshInfoPanel()
	local selectCard = (table.size(self.selectMatterCard) > 0)
	self.infoPanel:getChildByName("skillup_txt_success_rate_font"):setVisible(selectCard)
	self.infoPanel:getChildByName("package_getall_txt_3"):setVisible(selectCard)
	self.infoPanel:getChildByName("package_getall_txt1"):setVisible(selectCard)
	self.infoPanel:getChildByName("package_getall_bottom_CoinConsume"):setVisible(selectCard)
	self.infoPanel:getChildByName("skillup_txt_equip_CoinConsume_num"):setVisible(selectCard)
	self.infoPanel:getChildByName("icon_silverCoin"):setVisible(selectCard)
	self.infoPanel:getChildByName("skillup_txt_need_selection"):setVisible(not selectCard)
	self.infoPanel:getChildByName("skillup_txt_skill_lv"):setVisible(selectCard)
	self.infoPanel:getChildByName("package_getall_txt_2"):setVisible(selectCard)
	self.infoPanel:getChildByName("package_getall_txt_5"):setVisible(selectCard)
	self.infoPanel:getChildByName("package_getall_txt_4"):setVisible(selectCard)
	self.enhanceButton:setEnable(selectCard)
	self.enhanceButton.display:setVisible(selectCard)
	if selectCard then
		local expText = ""
		if self.curSelectCardExp >= 100000000 then
			expText = Localization:getInstance():getText("cardEnhanceSelect_resultTips_yi", {num = tostring(math.floor(self.curSelectCardExp / 100000000))})
		elseif self.curSelectCardExp >= 1000000 then
			expText = Localization:getInstance():getText("cardEnhanceSelect_resultTips_wan", {num = tostring(math.floor(self.curSelectCardExp / 10000))})
		else
			expText = tostring(math.floor(self.curSelectCardExp))
		end
		self.infoPanel:getChildByName("skillup_txt_success_rate_font"):getChildByName("txt"):setString(expText)
		self.infoPanel:getChildByName("skillup_txt_equip_CoinConsume_num"):getChildByName("font"):setString(tostring(math.floor(self.curSelectCardExp * MetaManager.game_meta.gameSettingConfig.cardUpgradeCoinRevise)))
		self.infoPanel:getChildByName("skillup_txt_skill_lv"):getChildByName("txt"):setString(tostring(table.size(self.selectMatterCard)))
		if tonumber(DataManager.getCurrUser().coins) < tonumber(self.curSelectCardExp * MetaManager.game_meta.gameSettingConfig.cardUpgradeCoinRevise) then
			self.infoPanel:getChildByName("skillup_txt_equip_CoinConsume_num"):getChildByName("font"):setColor(ccc3(255, 0, 0))
		else
			self.infoPanel:getChildByName("skillup_txt_equip_CoinConsume_num"):getChildByName("font"):setColor(ccc3(255, 255, 255))
		end
		
		if self.resultLevel <= self.oldLevel then
			self.infoPanel:getChildByName("package_getall_txt_3"):getChildByName("txt"):setString(getTextByKey("cardEnhanceSelect_resultTips3"))
			self.infoPanel:getChildByName("package_getall_txt_4"):setVisible(false)
			self.infoPanel:getChildByName("package_getall_txt_5"):setVisible(false)
		else
			self.infoPanel:getChildByName("package_getall_txt_4"):getChildByName("txt"):setString(tostring(self.resultLevel))
			self.infoPanel:getChildByName("package_getall_txt_3"):getChildByName("txt"):setString(getTextByKey("cardEnhanceSelect_resultTips4"))
		end
	end
end

local TABLEVIEW_CELL_TAG = -1001
local TAG_FIRST_ITEM = 1001
local TAG_LAST_ITEM = 1008
local TAG_FAKE_ITEM = 1009
local TAG_TXT_CARDRARE = 1010
local TAG_TXT_PAGENUM = 1011
local TAG_BTN_NEXTPAGE = 1012
local TAG_BTN_PREVIOUSPAGE = 1013
local TAG_ICON_SELECTED = 1014
local TAG_ICON_WHITE = 1015
local TAG_ICON_GREEN = 1016
local TAG_ICON_BLUE = 1017
local TAG_ICON_PURPLE = 1018
local TAG_ICON_ORANGE = 1019
local TAG_ICON_RED = 1020
local TAG_ICON_GOLD = 1021
local TAG_ICON_CARD_SELECTED = 1022
local TAG_ICON_CARD_NAME = 1023
local TAG_ICON_CARD_FAKE = 1024
local TAG_ICON_CARD_SPRITE = 1025
local TAG_ICON_CARD_LEVEL = 1026

local function inArea(posX, posY, rect)
	if posX >= rect.x and posX <= rect.x + rect.width and posY >= rect.y and posY <= rect.y + rect.height then
		return true
	end
	return false
end

local function setTextByTag( cell, tag, str)
	local txt = cell:getChildByTag(tag):getChildByTag(tag)
	setNodeText(txt, str);
end
	
local function setNodeVisibleByTag(cell, tag, visible)
	cell:getChildByTag(tag):setVisible(visible)
end

local function getMiddlePosition(cell, tag)
	local posX, posY = cell:getChildByTag(tag):getPosition()
	local contentSize = cell:getChildByTag(tag):getContentSize()
	local scaleX,scaleY = cell:getChildByTag(tag):getScaleX(), cell:getChildByTag(tag):getScaleY()
	return ccp(posX + contentSize.width / 2 * scaleX, posY - contentSize.height /2 * scaleY)
end

local function addNodeReplaceWithTag(cell, tag, node, nodeTag)
	if cell:getChildByTag(nodeTag) then
		cell:removeChildByTag(nodeTag, true)
	end
	node:setTag(nodeTag)
	node:setPosition(getMiddlePosition(cell, tag))
	local zOrder = cell:getChildByTag(tag):getZOrder()
	cell:addChild(node, zOrder)
end

function CardStrenthenSelectScene:createTableView(data)
	local CardStrenthenRenderer = class(TableViewRenderer)
	local SELF = self
	function CardStrenthenRenderer:ctor(width, height)
		self.list = data
		local builder = LayoutBuilder:createWithContentsOfFile("scene/package_new.json")
		builder.useArtLabelTTF = true
		self.builder = builder
	end 

	function CardStrenthenRenderer:buildCell(container)
		local cell = self.builder:build("skillup_package_list")
		cell:setTag(TABLEVIEW_CELL_TAG)
		container:addChild(cell)
		
		cell:getChildByName("skillup_item"):setTag(TAG_FAKE_ITEM)
		cell:getChildByName("skillup_item"):setVisible(false)
		cell:getChildByName("txt_lv_skillbook"):setTag(TAG_TXT_CARDRARE)
		cell:getChildByName("txt_lv_skillbook"):getChildByName("txt"):setTag(TAG_TXT_CARDRARE)
		cell:getChildByName("txt_list_page"):setTag(TAG_TXT_PAGENUM)
		cell:getChildByName("txt_list_page"):getChildByName("txt"):setTag(TAG_TXT_PAGENUM)
		cell:getChildByName("btn_pgdown"):setTag(TAG_BTN_NEXTPAGE)
		cell:getChildByName("btn_pgdown"):getChildByName("btn_d_many"):setTag(TAG_BTN_NEXTPAGE)
		cell:getChildByName("btn_pgdown"):getChildByName("txt"):setString(getTextByKey("skill_pageDownBtn"))
		cell:getChildByName("btn_pgup"):setTag(TAG_BTN_PREVIOUSPAGE)
		cell:getChildByName("btn_pgup"):getChildByName("btn_d_many"):setTag(TAG_BTN_PREVIOUSPAGE)
		cell:getChildByName("btn_pgup"):getChildByName("txt"):setString(getTextByKey("skill_pageUpBtn"))
		cell:getChildByName("package_getall_txt_6"):getChildByName("txt"):setString(getTextByKey("cardEnhanceSelect_selectAll"))
		cell:getChildByName("package_icon_checkbox_sb"):setTag(TAG_ICON_SELECTED)
		cell:getChildByName("q_blue9_panel"):setTag(TAG_ICON_BLUE)
		cell:getChildByName("q_green9_panel"):setTag(TAG_ICON_GREEN)
		cell:getChildByName("q_purple9_panel"):setTag(TAG_ICON_PURPLE)
		cell:getChildByName("q_red9_panel"):setTag(TAG_ICON_RED)
		cell:getChildByName("q_white9_panel"):setTag(TAG_ICON_WHITE)
		cell:getChildByName("q_yellow9_panel"):setTag(TAG_ICON_GOLD)
		cell:getChildByName("q_orange9_panel"):setTag(TAG_ICON_ORANGE)
		
		for i = 1, 8 do
			local item = self.builder:build("skillup_item")
			item:setTag(TAG_FIRST_ITEM + i - 1)
			item:setPositionXY(self.width / 2 + 175 * ((i - 1) % 4 - 2), cell:getChildByName("skillup_item"):getPositionY() - 167 * math.floor((i - 1) / 4))
			item:getChildByName("icon_selected"):setTag(TAG_ICON_CARD_SELECTED)
			item:getChildByName("txt_item_name"):setTag(TAG_ICON_CARD_NAME)
			item:getChildByName("txt_item_name"):getChildByName("txt_item_name"):setTag(TAG_ICON_CARD_NAME)
			item:getChildByName("frame_card"):setVisible(false)
			item:getChildByName("normal_card_small"):setVisible(false)
			item:getChildByName("normal_card_small"):setTag(TAG_ICON_CARD_FAKE)
			item:getChildByName("bg_card"):setVisible(false)
			item:getChildByName("lv_txt"):setTag(TAG_ICON_CARD_LEVEL)
			item:getChildByName("lv_txt"):getChildByName("txt"):setTag(TAG_ICON_CARD_LEVEL)
			cell:addChild(item)
		end

	end

	function CardStrenthenRenderer:setData( rawCocosObj, index )
		local cell = self:getChildByTag(rawCocosObj, TABLEVIEW_CELL_TAG)
		local cardInfo = data[index + 1]
		
		setTextByTag(cell, TAG_TXT_CARDRARE, getTextByKey("cardEnhanceSelect_star" .. cardInfo.rare))
		
		for quality = CARD_MINRARE, CARD_MAXRARE do
			setNodeVisibleByTag(cell, TAG_ICON_WHITE + quality - 1, quality == cardInfo.rare)
		end
		
		local allSelect = true		
		for i = 1, 8 do
			local item = cell:getChildByTag(TAG_FIRST_ITEM + i - 1)
			local curCardInfo = cardInfo.cardTable[(cardInfo.curPage - 1) * 8 + i]
			if curCardInfo then
				if (not curCardInfo.cardSelect) and (not curCardInfo.lock) then
					allSelect = false
				end
				item:setVisible(true)
				if item:getChildByTag(TAG_ICON_CARD_SPRITE) then
					item:removeChildByTag(TAG_ICON_CARD_SPRITE, true)
				end
				local perfectType = 0
				local cardMeta = MetaManager.card_meta[curCardInfo.metaId]
				if CommonManager:checkIsCardPerfect(curCardInfo) then
					if cardMeta.evolutionLevel == cardMeta.maxEvolvedLevel then
						perfectType = CardPerfectEnum.goldLeft
					else
						perfectType = CardPerfectEnum.silverLeft
					end
				end
				local cardIcon = getHeadIconCanonCardByMetaId(CommonManager:changeAvatarByCardInfo( curCardInfo ), curCardInfo.lock,perfectType)
				cardIcon:setTag(TAG_ICON_CARD_SPRITE)
				cardIcon:setPositionXY(item:getChildByTag(TAG_ICON_CARD_FAKE):getPositionX(), item:getChildByTag(TAG_ICON_CARD_FAKE):getPositionY())
				item:addChild(cardIcon.refCocosObj, item:getChildByTag(TAG_ICON_CARD_FAKE):getZOrder())	
				cardIcon:dispose()
				
				setTextByTag(item , TAG_ICON_CARD_LEVEL, "LV." .. tostring(curCardInfo.level))
				setTextByTag(item , TAG_ICON_CARD_NAME, getTextByKey(curCardInfo.cardName))
				setNodeVisibleByTag(item ,TAG_ICON_CARD_SELECTED, curCardInfo.cardSelect)
			else
				item:setVisible(false)
			end
			setNodeVisibleByTag(cell, TAG_ICON_SELECTED, allSelect)
			local maxPage = math.floor((table.getn(cardInfo.cardTable) - 1) / 8 + 1)
			setTextByTag(cell, TAG_TXT_PAGENUM, getTextByKey("skill_pageNum") .. tostring(cardInfo.curPage) .. "/" .. tostring(maxPage))
		
			setNodeVisibleByTag(cell:getChildByTag(TAG_BTN_NEXTPAGE), TAG_BTN_NEXTPAGE, cardInfo.curPage < maxPage)
			setNodeVisibleByTag(cell:getChildByTag(TAG_BTN_PREVIOUSPAGE), TAG_BTN_PREVIOUSPAGE, cardInfo.curPage > 1)
		
		end
		
	end
	
	local renderer = CardStrenthenRenderer.new(BAGCONFIG.WIDTH, 460)
	local buttonTag = {}
	table.insert(buttonTag, {TAG_BTN_NEXTPAGE, TAG_BTN_NEXTPAGE})
	table.insert(buttonTag, {TAG_BTN_PREVIOUSPAGE, TAG_BTN_PREVIOUSPAGE})
  local list = TableView:create(renderer, BAGCONFIG.WIDTH, BAGCONFIG.HEIGHT + 50 - 100, TABLEVIEW_CELL_TAG, buttonTag)
	local function onListItemTouch( evt ) 
		local selectedCell = list:cellAtIndex(evt.data):getChildByTag(TABLEVIEW_CELL_TAG)
		local curTabIndex = evt.context
		self._data = data[evt.data + 1]
		
		local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
		
		local itemPosX, itemPosY
		local itemRect = {}
		itemPosX , itemPosY = selectedCell:getChildByTag(TAG_ICON_SELECTED):getPosition()
		itemRect.width = 120
		itemRect.height = 40
		itemRect.x = itemPosX
		itemRect.y = itemPosY - itemRect.height
		
		if inArea(posInCell.x, posInCell.y, itemRect) then --allselect
			local tosetSelect = not selectedCell:getChildByTag(TAG_ICON_SELECTED):isVisible()
			selectedCell:getChildByTag(TAG_ICON_SELECTED):setVisible(tosetSelect)
			local changeExp = 0
			local changePrice = 0
			for i = 1, 8 do
				local cardInfo = self._data.cardTable[(self._data.curPage - 1) * 8 + i]
				if cardInfo and not cardInfo.lock then
					if cardInfo.cardSelect ~= tosetSelect then
						if tosetSelect then
							self.selectMatterCard[cardInfo.cardId] = cardInfo.metaId
							changeExp = changeExp + cardInfo.resultExp
							changePrice = changePrice + cardInfo.price
						else
							self.selectMatterCard[cardInfo.cardId] = nil
							changeExp = changeExp - cardInfo.resultExp
							changePrice = changePrice - cardInfo.price
						end
						cardInfo.cardSelect = tosetSelect
					end
				end
			end
			if self.argv.enterScene == "BackpackScene" then
				self:getSellPrice(changePrice)
			else
				self:getComposeExp(changeExp)
			end
			self.tableView:updateCellAtIndex(evt.data)
		else
			itemRect = {}
			itemPosX , itemPosY = selectedCell:getChildByTag(TAG_BTN_PREVIOUSPAGE):getPosition()
			itemRect.width = 97.7
			itemRect.height = 38.95
			itemRect.x = itemPosX
			itemRect.y = itemPosY - itemRect.height
			if inArea(posInCell.x, posInCell.y, itemRect) then --previousPage
				if selectedCell:getChildByTag(TAG_BTN_PREVIOUSPAGE):getChildByTag(TAG_BTN_PREVIOUSPAGE):isVisible() then
					self._data.curPage = self._data.curPage - 1
					self.tableView:updateCellAtIndex(evt.data)
				end
			else
				itemRect = {}
				itemPosX , itemPosY = selectedCell:getChildByTag(TAG_BTN_NEXTPAGE):getPosition()
				itemRect.width = 97.7
				itemRect.height = 38.95
				itemRect.x = itemPosX
				itemRect.y = itemPosY - itemRect.height
				if inArea(posInCell.x, posInCell.y, itemRect) then --nextPage
					if selectedCell:getChildByTag(TAG_BTN_NEXTPAGE):getChildByTag(TAG_BTN_NEXTPAGE):isVisible() then
						self._data.curPage = self._data.curPage + 1
						self.tableView:updateCellAtIndex(evt.data)
					end
				else
					for i = 1, 8 do
						itemPosX, itemPosY = selectedCell:getChildByTag(TAG_FIRST_ITEM + i - 1):getPosition()
						itemRect = {}
						itemRect.width = 172.2
						itemRect.height = 167.05
						itemRect.x = itemPosX
						itemRect.y = itemPosY - itemRect.height
						
						if inArea(posInCell.x, posInCell.y, itemRect) then
							local cardInfo = self._data.cardTable[(self._data.curPage - 1) * 8 + i]
							if cardInfo then
								if cardInfo.lock then
									SuspensionLabel:showContent(self, Localization:getInstance():getText("card_lockedTips_sell"))
								else
									local tosetSelect = not cardInfo.cardSelect
									local changeExp = 0
									local changePrice = 0
									if tosetSelect then
										self.selectMatterCard[cardInfo.cardId] = cardInfo.metaId
										changeExp = changeExp + cardInfo.resultExp
										changePrice = changePrice + cardInfo.price
									else
										self.selectMatterCard[cardInfo.cardId] = nil
										changeExp = changeExp - cardInfo.resultExp
										changePrice = changePrice - cardInfo.price
									end
									cardInfo.cardSelect = tosetSelect
									if self.argv.enterScene == "BackpackScene" then
										self:getSellPrice(changePrice)
									else
										self:getComposeExp(changeExp)
									end
									self.tableView:updateCellAtIndex(evt.data)
								end
							end
							break;
						end
					end
				end
			end
		end
		
		
	end

  list:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
  list:setPosition(ccp(0, (1280-BAGCONFIG.HEIGHT)/2-85 + 100))
  return list
end

function CardStrenthenSelectScene:dispose()	
	BaseUIScene.dispose(self)
end

function CardStrenthenSelectScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function CardStrenthenSelectScene:preEnterAnimation()
	CanonPlayBackgroundMusic("music/background.mp3", true)
  BaseUIScene.preEnterAnimation(self)
end

function CardStrenthenSelectScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
end

function CardStrenthenSelectScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
end

function CardStrenthenSelectScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function CardStrenthenSelectScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function CardStrenthenSelectScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
      self:nodeAnimationFinished()
  end
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))	
end

function CardStrenthenSelectScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end

function CardStrenthenSelectScene:back()
	local nextReturnScene = nil;
	if self.argv.params then
		nextReturnScene = self.argv.params.preReturnScene
	end
	if self.argv.returnScene == "BackpackScene" then
		self:replaceScene(BackpackScene, {enterScene="CardStrenthenSelectScene", returnScene=nextReturnScene, params={}})
	else
		local argv = {enterScene="CardStrenthenSelectScene",returnScene=nextReturnScene,params={}}
		self:replaceScene(CardComposeScene, argv)
	end
end

function CardStrenthenSelectScene:setTableViewsEnabled( v )
	if (v) then
		self.touchDisableSetTimes = self.touchDisableSetTimes - 1
		if (self.touchDisableSetTimes <= 0) then
			if self.tableView then
				self.tableView:setTouchEnabled(v)
			end
			self.mainUI:setTouchEnabled(v)
		end
	else
		self.touchDisableSetTimes = self.touchDisableSetTimes + 1
		if self.tableView then
			self.tableView:setTouchEnabled(v)
		end
		self.mainUI:setTouchEnabled(v)
	end
end

function CardStrenthenSelectScene:getCardInfoFromInitData(cardId)
  local gameInitData = DataManager.getGameInitData()
  local aCard = {}    
  for _, temp in ipairs(gameInitData.sharkCards.sharkCards) do
    if cardId == temp.cardId then
      aCard = temp
      break
      end
  end
  return aCard
end

function CardStrenthenSelectScene:getComposeExp(changedExp)
	local mainCardId = self.argv.params.mainCardId
	
  local needUpgradeCoin = 0
  local ret = {newLevel=nil,upgradeCoin=nil}
  local aCard = self:getCardInfoFromInitData(mainCardId)
	self.oldLevel = aCard.level
  local aCardLevelConfig = MetaManager.card_level[aCard.level]
  local mainCardExp = aCardLevelConfig.totalExp + aCard.exp
	
	self.curSelectCardExp = self.curSelectCardExp + changedExp
  local resultAllExp = mainCardExp + self.curSelectCardExp
	
	local cardMaxLevel = MetaManager.card_evolve[MetaManager.card_meta[aCard.metaId].evolutionLevel].maxCardLevel
  for index,v in ipairs(MetaManager.card_level) do
    if index==#MetaManager.card_level and resultAllExp>v.totalExp then 
			ret.newLevel = v.level
      break
    end
    if resultAllExp>=v.totalExp and resultAllExp<MetaManager.card_level[index+1].totalExp then 
      ret.newLevel = v.level
      break        
    end
  end     
	if ret.newLevel > cardMaxLevel then
		ret.newLevel = cardMaxLevel
	end
	self.resultLevel = ret.newLevel
	self:refreshInfoPanel();
end

function CardStrenthenSelectScene:getSellPrice(changePrice)
	self.curSelectCardPrice = self.curSelectCardPrice + changePrice
	local count = 0
	for k,v in pairs(self.selectMatterCard) do
		count = count + 1
	end
	self.infoPanel:getChildByName("txt_cardselect"):getChildByName("txt"):setString(getTextByKey("sellItem_cardNum") .. tostring(count))
	self.infoPanel:getChildByName("txt_sell"):getChildByName("txt"):setString(getTextByKey("sellItem_price").. tostring(self.curSelectCardPrice))
	self.infoPanel:getChildByName("btn_yellow_sure"):setVisible(count > 0)
end
