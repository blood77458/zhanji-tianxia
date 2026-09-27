require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.data.MetaManager"
require "canon.models.CommonManager"
require "canon.customUI.CanonItem"
require "canon.request.AdjustCardAvatarRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize();
local enter_animation_duration = 0.3
local original_scroll_duration = enter_animation_duration
local exchangeTable_width = visibleSize.width
local exchangeTable_height = 550
local exchangeItem_width = visibleSize.width
local exchangeItem_height = 550
local exchangeTable_posX = 0
local exchangeTable_posY = 367

CardSelectPanel = class(Layer)

function CardSelectPanel:ctor()
    self.container = nil
end

function CardSelectPanel:create( container , cardNewPanel, ownedCard , argv)
    self.container = container
    self.dataList = ownedCard
    self.cardNewPanel = cardNewPanel
    self.argv = argv
    local s = CardSelectPanel.new()
    s:initLayer()
    return s
end

--左按钮点击
local function onLeftBtnClick(evt)
  --print("onLeftBtnClick")
  local self = evt.context
  self:gotoIndex(self.currentSelectedIndex - 1, false)
end

--右按钮点击
local function onRightBtnClick(evt)
  --print("onLeftBtnClick")
  local self = evt.context
  self:gotoIndex(self.currentSelectedIndex + 1, false)
end

--移动到某一位置
function CardSelectPanel:gotoIndex(aIndex, forceMove)
  --延时结束
  local function actionFinished()
    self.moving = false
  end

  if not self.moving then
    --print("-exchangeTable_width * (aIndex - 1) = " .. (-exchangeTable_width * (aIndex - 1)))
    self:setCurrentSelectIndex(aIndex)
    if forceMove then
      --直接移动 没有缓动 没有延时处理 
      self.listTableView:setContentOffset(ccp(-exchangeTable_width * (aIndex - 1), self.listTableView:getContentOffset().y))
    else
      self.listTableView:setContentOffsetInDuration(ccp(-exchangeTable_width * (aIndex - 1), self.listTableView:getContentOffset().y), original_scroll_duration)
      self.moving = true

      --延时处理
      local arr2 = CCArray:create()
      arr2:addObject(CCDelayTime:create(original_scroll_duration))
      arr2:addObject(CCCallFunc:create(actionFinished))
      self:runAction(CCSequence:create(arr2))
    end
  end
end


--设置当前选择的数据
function CardSelectPanel:setCurrentSelectIndex(aIndex)
  local tempCombineData = self.dataList[aIndex]
  if tempCombineData then
    self.currentSelectedIndex = aIndex

    if self.currentSelectedIndex <= 1 then
      self.leftBtn.display:setVisible(false)
      self.leftBtn:setEnable(false)
    else
      self.leftBtn.display:setVisible(true)
      self.leftBtn:setEnable(true)
    end

    if self.currentSelectedIndex >= #self.dataList then
      self.rightBtn.display:setVisible(false)
      self.rightBtn:setEnable(false)
    else
      self.rightBtn.display:setVisible(true)
      self.rightBtn:setEnable(true)
    end

  end
end


function CardSelectPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	if self.cardNewPanel.currentTabView.setTableViewTouchEnable and type(self.cardNewPanel.currentTabView.setTableViewTouchEnable) == "function" then
		self.cardNewPanel.currentTabView:setTableViewTouchEnable(false)
	end
	local cardMeta = MetaManager.card_meta[self.metaId]
    CardSelectPanel.super.initLayer(self)
		
	local builder = LayoutBuilder:createWithContentsOfFile("scene/details_card.json")
    self.panelUI = builder:build("popup_choose_picture_2")

    --关闭
	local function onClosePanel(evt)
		if self.cardNewPanel.currentTabView.setTableViewTouchEnable and type(self.cardNewPanel.currentTabView.setTableViewTouchEnable) == "function" then
			self.cardNewPanel.currentTabView:setTableViewTouchEnable(true)
		end
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end
	
	local bt_panel_close = Button:create(self.panelUI:getChildByName("btn_return"))
	bt_panel_close:addEventListener(Events.kStart, onClosePanel)
    
	self:addChild(self.panelUI)

		--初始化各种组件
	self.leftBtn = Button:create(self.panelUI:getChildByName("icon_sliding_l"))
	self.leftBtn:addEventListener(Events.kStart, onLeftBtnClick, self)

	self.rightBtn = Button:create(self.panelUI:getChildByName("icon_sliding_r"))
	self.rightBtn:addEventListener(Events.kStart, onRightBtnClick, self)

  self.TipTxt  = self.panelUI:getChildByName("txt")
  self.TipTxt:getChildByName("txt"):setString(getTextByKey("cardSet_tip"))

	--初始化列表
  	self.listTableView = self:createListTableView()
  	self.panelUI:addChild(self.listTableView)

  	  --改按钮层级
  	self.panelUI:removeChild(self.leftBtn.display, false)
  	self.panelUI:addChild(self.leftBtn.display)
  	self.panelUI:removeChild(self.rightBtn.display, false)
  	self.panelUI:addChild(self.rightBtn.display)
    self.panelUI:removeChild(self.TipTxt, false)
    self.panelUI:addChild(self.TipTxt)

  	self.listTableView:reloadData()
  	self:gotoIndex(1, true)
    self.panelUI:getChildByName("btn_return"):setZOrder(10000)
end

-------------------------------------------------------------------------------------
-- 生成列表
-------------------------------------------------------------------------------------
function CardSelectPanel:createListTableView()
  local cellTag = 1024
  local picTag = 1001
  local buttonTag = 1002
  local nameTag = 1003
  local aExchangeScene = self
  local CardSelectTableViewRender = class(TableViewRenderer)

  --文件初始化
  function CardSelectTableViewRender:ctor(width, height)
    self.list = aExchangeScene.dataList
    print(table.tostring(aExchangeScene.dataList))
  end

  --创建单元
  function CardSelectTableViewRender:buildCell(container)
    --print("buildCell")
    local builder = LayoutBuilder:createWithContentsOfFile("scene/details_card.json")
    local cell = builder:build("popup_choose_picture")
    container:addChild(cell)
    cell:setTag(cellTag)
    cell:getChildByName("full"):setTag(picTag)
    cell:getChildByName("btn_choose_picture"):setTag(buttonTag)
    cell:getChildByName("btn_choose_picture"):getChildByName("txt"):setTag(buttonTag)
    cell:getChildByName("txt_1"):setTag(nameTag)
    cell:getChildByName("txt_1"):getChildByName("txt"):setTag(nameTag)
  end

  local function setTextByTag( cell, tag, str)
    local txt = cell:getChildByTag(tag):getChildByTag(tag)
    setNodeText(txt, str);
  end

  --获得数据
  function CardSelectTableViewRender:setData( rawCocosObj, index )
    local cell = self:getChildByTag(rawCocosObj, cellTag)
    local metaId = self.list[index+1]

    local oldPic = cell:getChildByTag(picTag)
    oldPic:setVisible(false)
    local card_frame = CocosObject.new(oldPic)
	local frame_position = card_frame:getPosition()
	card_frame:removeFromParentAndCleanup(true)

	local bigCardSpriteFrame = getFullCardSpriteFrame(metaId)
	local cardSprite = CCSprite:createWithSpriteFrame(bigCardSpriteFrame)
	local cardDisplay = CocosObject.new(cardSprite)

	cardDisplay:setPosition(ccp(37.95 + cardDisplay:getContentSize().width / 2
		,563.4 - cardDisplay:getContentSize().height / 2 ))
-- cardDisplay:setPosition(ccp(37.95 + 325 , 563.4 - 250))
	-- cardDisplay:setAnchorPoint(ccp(0.5,0.5))
	cardDisplay:setTag(picTag)
	-- cardDisplay:setScale(0.3)
	-- cardDisplay:setZOrder(-1001)
	cell:addChild(cardDisplay.refCocosObj)
	oldPic:removeFromParentAndCleanup(true)
	card_frame:dispose()
	cardDisplay:dispose()

	local cardName = getTextByKey("cardSet_title") .. (index + 1)
	setTextByTag(cell , nameTag , cardName)
	setTextByTag(cell , buttonTag , getTextByKey("cardSet_button"))
  end

  	local function inArea(posX, posY, rect)
		if posX >= rect.x and posX <= rect.x + rect.width and posY >= rect.y and posY <= rect.y + rect.height then
			return true
		end
		return false
	end

  local function onListItemTouch( evt )
    local aIndex = evt.data + 1
    local metaId = self.dataList[aIndex]

    local selectedCell = self.listTableView:cellAtIndex(aIndex - 1):getChildByTag(cellTag)

    local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
    local itemPosX, itemPosY = selectedCell:getChildByTag(buttonTag):getPosition()
    local itemRect = {}
    itemRect.x = itemPosX
    itemRect.y = itemPosY - 74.9
    itemRect.width = 235.9
    itemRect.height = 74.9
    if inArea(posInCell.x, posInCell.y, itemRect) then
    	local function AdjustCardAvatarSuccess( e )
    		local cardData = DataManager.getCardsData()
    		for i=1,#cardData do
    			if cardData[i].cardId == self.cardNewPanel.cardId then
    				cardData[i].avatarMetaId = metaId
    				break
    			end
    		end
    		DataManager.setCardsData(cardData)

    		if self.container.curSceneEnum == SceneEnum.BackpackScene then
    			self.container:refreshUIForPanelInfo(self.cardNewPanel.cardId)
    		elseif self.container.curSceneEnum == SceneEnum.CardQueueScene then
    			self.container:refreshUI()
			elseif self.container.curSceneEnum == SceneEnum.MatrixScene then
				self.container:refreshUIForPanelInfo(self.cardNewPanel.cardId)
    		end

    		self.cardNewPanel.metaId = metaId
    		self.cardNewPanel:refreshCardOriginalInfo()

        SuspensionLabel:showContent(self.container, getTextByKey("cardSet_success"))
    	end
    	local function AdjustCardAvatarFail( e )
        local errorCode = tonumber(e.data)
    		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
    	end
      if self.cardNewPanel.metaId == metaId then
        SuspensionLabel:showContent(self.container, getTextByKey("cardSet_warning"))
        return 
      end
    	local param = {}
	    param.cardId = self.cardNewPanel.cardId
	    param.avatarMetaId = metaId
	    AdjustCardAvatarRequest.sendRequest(param , AdjustCardAvatarSuccess , AdjustCardAvatarFail)
    end
  end

  --开始
  local renderer = CardSelectTableViewRender.new(exchangeItem_width, exchangeItem_height)
  local aTableView = TableView:create(renderer, exchangeTable_width, exchangeTable_height, cellTag , buttonTag)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , aTableView)
  --aTableView:addEventListener(DisplayEvents.kSelectItem, onSelectItem , self)
  aTableView:setPosition(ccp(exchangeTable_posX, exchangeTable_posY))
  aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  --aTableView:setPageEnabled(true)--自动对齐位置
  aTableView:setDragEnabled(false)--不能拖拽
  return aTableView
end
