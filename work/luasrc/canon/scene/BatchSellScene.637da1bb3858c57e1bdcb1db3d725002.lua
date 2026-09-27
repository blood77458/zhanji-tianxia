-- BatchSellScene.lua
-- 2014-7-3
-- zheng.che
-- 批量卖出物品场景

require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.display.Scene"
require "hecore.ui.LayoutBuilder"
require "canon.scene.LoadingScene"
require "canon.customUI/CanonCard"
require "canon.scene.BaseUIScene"

BatchSellScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local SUGGESTION_RARE = 3

function BatchSellScene:ctor()
	self.title = getTextByKey("inventory_sellEquipTitle")
	self.selectHash = {}
	self.curSelectCardExp = 0
	self.curSelectCardPrice = 0
	self.resultLevel = 0
	self.oldLevel = 0
end

function BatchSellScene:create( argv )
  if argv then 
    self.argv = argv 
  else
    self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
  local scene = BatchSellScene.new()		
  scene:initScene()
  return scene
end

local CARD_MINRARE = 1
local CARD_MAXRARE = 7

function BatchSellScene:onInit()	
	BaseUIScene.initBackGround(self)
	self.builder = LayoutBuilder:createWithContentsOfFile("scene/package_new.json")
	self.builder.useArtLabelTTF = true
	
	self.mainUI = Layer:create();

	--默认情况 卖出装备
	if self.argv.params.sellType == nil then
		self.argv.params.sellType = ResourceEnum.EQUIP
	end
	
	selectHash = {}
	
	--获得物品总表
	local goodDataTotalList = {}
	if self.argv.params.sellType == ResourceEnum.EQUIP then
		goodDataTotalList = DataManager.getEquipsData()
	end
	--print("goodDataTotalList = " .. tostringRich(goodDataTotalList))
	local goodDataList = {}

	--阵容状态（不可卖出）
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
	--end by l1ghtsaber

	for k,v in ipairs(goodDataTotalList) do
		if not CanonGoodIcon.getGoodIsInUseByData(self.argv.params.sellType, v)
			and (not queueList[v.equipId]) -- add by l1ghtsaber
		then
			table.insert(goodDataList, v)
		end
	end
	
	if self.argv.params.filterFunc ~= nil then
		goodDataList = self.argv.params.filterFunc(goodDataList)
	end
	
	self.goodList = {}
	local tempGoodList = {}
	local changeExp = 0--del
	for i = CARD_MINRARE, CARD_MAXRARE do
		table.insert(tempGoodList, {rare = i, goodTable = {}, curPage = 1})
	end
	for key ,goodData in pairs(goodDataList) do
		local data = {}
		data.goodData = goodData
		data.goodType = self.argv.params.sellType
		data.goodId = CanonGoodIcon.getGoodIdByData(self.argv.params.sellType, data.goodData)
		data.metaId = CanonGoodIcon.getGoodMetaIdByData(self.argv.params.sellType, data.goodData)
		data.price = CanonGoodIcon.getGoodSellPrice(self.argv.params.sellType, data.goodData)
		data.rare = CanonGoodIcon.getGoodRare(self.argv.params.sellType, data.metaId)
		data.name = CanonGoodIcon.getGoodNameWithoutNum(self.argv.params.sellType, data.metaId)
		data.level = data.goodData.level
		data.selected = false--初始默认不选中
		if data.rare and tonumber(data.rare) <= CARD_MAXRARE and tonumber(data.rare) >= CARD_MINRARE then
			table.insert(tempGoodList[tonumber(data.rare)].goodTable, data)
		end
	end
	
	--生成有效数组(去掉空内容的rare列)
	for key ,data in pairs(tempGoodList) do
		if table.getn(data.goodTable) > 0 then
			table.insert(self.goodList, data)
		end
	end
	
	--排了个序
	local function cardSortFunc(a, b)
		return a.metaId < b.metaId
	end
	for key, data in pairs(self.goodList) do
		table.sort(data.goodTable, cardSortFunc)
	end
	
	self.tableView = self:createTableView(self.goodList)
	self.mainUI:addChild(self.tableView)
	
	--初始化点击卖出按钮事件
	if self.argv.params.sellType == ResourceEnum.EQUIP then
		self.title = getTextByKey("inventory_sellEquipTitle")
		self.infoPanel = self.builder:build("package_package_bottom")
		self.mainUI:addChild(self.infoPanel)
		self.infoPanel:getChildByName("btn_yellow_sure"):getChildByName("txt"):setString(getTextByKey("yes"))
		local sellButton = Button:create(self.infoPanel:getChildByName("btn_yellow_sure"))
		local function onClickSell()
			local idsToSell = {}
			for k,v in pairs(self.selectHash) do
				table.insert(idsToSell, k)
			end
			local function onSellFinish()
				self:replaceScene(BackpackScene, {params={showSellFinish = true, tabIndex = BAGCATEGORY.equip}})
			end
			self.targetInfoPanel = ItemSellMessageBoxPanel:create(self, {equipData = idsToSell, bagCategory = BAGCATEGORY.equip, onSellFinish = onSellFinish}) 
			self:addChild(self.targetInfoPanel)
			self.targetInfoPanel:scaleIn()   
		end
		sellButton:addEventListener(Events.kStart, onClickSell)
		self:getSellPrice(0)
	end
	
	--没有物品的情况
	if table.size(goodDataList) <= 0 then
		local noCardText = ArtTextField:create(getTextByKey("bag_NoEquip"), nil, 30)
		noCardText:setPositionXY(visibleSize.width / 2, visibleSize.height / 2)
		self.mainUI:addChild(noCardText)
	end
	
	self:addChild(self.mainUI)
	BaseUIScene.onInit(self)
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

function BatchSellScene:createTableView(data)
	local TableRenderer = class(TableViewRenderer)
	local SELF = self
	function TableRenderer:ctor(width, height)
		self.list = data
		local builder = LayoutBuilder:createWithContentsOfFile("scene/package_new.json")
		builder.useArtLabelTTF = true
		self.builder = builder
	end 

	function TableRenderer:buildCell(container)
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

	function TableRenderer:setData( rawCocosObj, index )
		local cell = self:getChildByTag(rawCocosObj, TABLEVIEW_CELL_TAG)
		local goodInfo = data[index + 1]
		
		setTextByTag(cell, TAG_TXT_CARDRARE, getTextByKey("activity-sworn-equip" .. goodInfo.rare))
		
		for quality = CARD_MINRARE, CARD_MAXRARE do
			setNodeVisibleByTag(cell, TAG_ICON_WHITE + quality - 1, quality == goodInfo.rare)
		end
		
		local allSelect = true		
		for i = 1, 8 do
			local item = cell:getChildByTag(TAG_FIRST_ITEM + i - 1)
			local curGoodInfo = goodInfo.goodTable[(goodInfo.curPage - 1) * 8 + i]
			if curGoodInfo then
				if not curGoodInfo.selected then
					allSelect = false
				end
				item:setVisible(true)
				if item:getChildByTag(TAG_ICON_CARD_SPRITE) then
					item:removeChildByTag(TAG_ICON_CARD_SPRITE, true)
				end

				local params = {}
				params.sourceSizes = {135, 135}
				local goodIcon = CanonGoodIcon.createGoodIcon(curGoodInfo.goodType, curGoodInfo.metaId, 1, params)
				goodIcon:setTag(TAG_ICON_CARD_SPRITE)
				goodIcon:setPositionXY(item:getChildByTag(TAG_ICON_CARD_FAKE):getPositionX(), item:getChildByTag(TAG_ICON_CARD_FAKE):getPositionY())
				item:addChild(goodIcon.refCocosObj, item:getChildByTag(TAG_ICON_CARD_FAKE):getZOrder())	
				goodIcon:dispose()
				
				setTextByTag(item , TAG_ICON_CARD_LEVEL, "LV." .. tostring(curGoodInfo.level))
				setTextByTag(item , TAG_ICON_CARD_NAME, curGoodInfo.name)
				setNodeVisibleByTag(item ,TAG_ICON_CARD_SELECTED, curGoodInfo.selected)
			else
				item:setVisible(false)
			end
			setNodeVisibleByTag(cell, TAG_ICON_SELECTED, allSelect)
			local maxPage = math.floor((table.getn(goodInfo.goodTable) - 1) / 8 + 1)
			setTextByTag(cell, TAG_TXT_PAGENUM, getTextByKey("skill_pageNum") .. tostring(goodInfo.curPage) .. "/" .. tostring(maxPage))
		
			setNodeVisibleByTag(cell:getChildByTag(TAG_BTN_NEXTPAGE), TAG_BTN_NEXTPAGE, goodInfo.curPage < maxPage)
			setNodeVisibleByTag(cell:getChildByTag(TAG_BTN_PREVIOUSPAGE), TAG_BTN_PREVIOUSPAGE, goodInfo.curPage > 1)
		
		end
		
	end
	
	local renderer = TableRenderer.new(BAGCONFIG.WIDTH, 460)
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
				local goodInfo = self._data.goodTable[(self._data.curPage - 1) * 8 + i]
				if goodInfo and goodInfo.selected ~= tosetSelect then
					if tosetSelect then
						self.selectHash[goodInfo.goodId] = goodInfo.metaId
						changePrice = changePrice + goodInfo.price
					else
						self.selectHash[goodInfo.goodId] = nil
						changePrice = changePrice - goodInfo.price
					end
					goodInfo.selected = tosetSelect
				end
			end
			self:getSellPrice(changePrice)
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
							local goodInfo = self._data.goodTable[(self._data.curPage - 1) * 8 + i]
							if goodInfo then
								local tosetSelect = not goodInfo.selected
								local changeExp = 0
								local changePrice = 0
								if tosetSelect then
									self.selectHash[goodInfo.goodId] = goodInfo.metaId
									changePrice = changePrice + goodInfo.price
								else
									self.selectHash[goodInfo.goodId] = nil
									changePrice = changePrice - goodInfo.price
								end
								goodInfo.selected = tosetSelect
								self:getSellPrice(changePrice)
								self.tableView:updateCellAtIndex(evt.data)
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

function BatchSellScene:dispose()	
	BaseUIScene.dispose(self)
end

function BatchSellScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function BatchSellScene:preEnterAnimation()
	CanonPlayBackgroundMusic("music/background.mp3", true)
  BaseUIScene.preEnterAnimation(self)
end

function BatchSellScene:startEnterAnimation()
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

function BatchSellScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
end

function BatchSellScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function BatchSellScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function BatchSellScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
      self:nodeAnimationFinished()
  end
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))	
end

function BatchSellScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end

function BatchSellScene:back()
	local nextReturnScene = nil;
	if self.argv.params then
		nextReturnScene = self.argv.params.preReturnScene
	end
	self:replaceScene(BackpackScene, {enterScene="BatchSellScene", returnScene=nextReturnScene, params={tabIndex = BAGCATEGORY.equip}})
end

function BatchSellScene:setTableViewsEnabled( v )
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

function BatchSellScene:getSellPrice(changePrice)
	self.curSelectCardPrice = self.curSelectCardPrice + changePrice
	local count = 0
	for k,v in pairs(self.selectHash) do
		count = count + 1
	end
	self.infoPanel:getChildByName("txt_cardselect"):getChildByName("txt"):setString(getTextByKey("sellItem_equipNum") .. tostring(count))
	self.infoPanel:getChildByName("txt_sell"):getChildByName("txt"):setString(getTextByKey("sellItem_price").. tostring(math.floor(self.curSelectCardPrice)))
	self.infoPanel:getChildByName("btn_yellow_sure"):setVisible(count > 0)
end
