require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- ContendRewardInfoPanel
--

local function tabButtonClicked(evt)
  for aIndex, aValue in ipairs(evt.context.tabButtonList) do
    if aValue == evt.target then
      evt.context.selectedTab = aIndex
      break
    end
  end
  evt.context:updateForTabChange()
end

ContendRewardInfoPanel = class(Layer)

function ContendRewardInfoPanel:ctor()
    self.container = nil
end

function ContendRewardInfoPanel:create( container, params )
    local s = ContendRewardInfoPanel.new()
    s:initLayer(container, params)
    return s
end

function ContendRewardInfoPanel:initLayer(container, params)
    ContendRewardInfoPanel.super.initLayer(self)
    
    self.container = container
    self.params = params or {}
    
    self.pre_container_targetInfoPanel = self.container.targetInfoPanel
    self.container.targetInfoPanel = self
    
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)
    
    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/fight_for_soul.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_watchloot") 
    self.tempLayer:addChild(self.panelUI)
    
    local function onCloseButtonClicked(evt)
      self:dismissSelf()
    end
    local closeButtonDisplay = self.panelUI:getChildByName("common_btn_close")
    local closeButton = Button:create(closeButtonDisplay)
    closeButton:addEventListener( Events.kStart, onCloseButtonClicked, self )
    
    self.panelUI:getChildByName("txt_fight_for_soul2"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_contend_droptxt"))
    
    self.panelUI:getChildByName("reward_item"):setVisible(false)
    self.tableData = {}
    self.tableCellList = {}
    
    --self.selectCornerList = {}
    --table.insert(self.selectCornerList, self.panelUI:getChildByName("icon_tr_white1"))
    --table.insert(self.selectCornerList, self.panelUI:getChildByName("icon_tr_white2"))
    --table.insert(self.selectCornerList, self.panelUI:getChildByName("icon_tr_white3"))
    --table.insert(self.selectCornerList, self.panelUI:getChildByName("icon_tr_white4"))
    
    self.tabButtonList = {}
    self.selectedTab = 1
    
    local tabButton = Button:create(self.panelUI:getChildByName("wei_s"))
    tabButton:addEventListener( Events.kStart, tabButtonClicked, self )
    table.insert(self.tabButtonList, tabButton)
    tabButton = Button:create(self.panelUI:getChildByName("shu_s"))
    tabButton:addEventListener( Events.kStart, tabButtonClicked, self )
    table.insert(self.tabButtonList, tabButton)
    tabButton = Button:create(self.panelUI:getChildByName("wu_s"))
    tabButton:addEventListener( Events.kStart, tabButtonClicked, self )
    table.insert(self.tabButtonList, tabButton)
    tabButton = Button:create(self.panelUI:getChildByName("qun_s"))
    tabButton:addEventListener( Events.kStart, tabButtonClicked, self )
    table.insert(self.tabButtonList, tabButton)
    self:updateForTabChange()

    self.tempLayer:setScale(0.1)
end

function ContendRewardInfoPanel:dispose()
  ContendRewardInfoPanel.super.dispose(self)
end

function ContendRewardInfoPanel:scaleIn()
  self.tempLayer.touchEnabled = false
  self.tempLayer.touchChildren = false
  local function scaleInFinished()
    self.tempLayer.touchEnabled = true
    self.tempLayer.touchChildren = true
  end
  local arr = CCArray:create()
  arr:addObject(CCEaseSineOut:create(CCScaleTo:create(0.3, 1.0)))
  arr:addObject(CCCallFunc:create(scaleInFinished))
  self.tempLayer:runAction(CCSequence:create(arr))
end

function ContendRewardInfoPanel:dismissSelf()
  self.container.targetInfoPanel = self.pre_container_targetInfoPanel
  self:removeFromParentAndCleanup(true)
  if self.params.callback then
    self.params.callback()
  end
end

local CELL_HEIGHT = 180
local CELL_WIDTH = 560
local LIST_HEIGHT = 400
local LIST_WIDTH = 660
local LIST_POS_Y = 362
local COLS_NUM = 3

local TAG_PIC_REWARD = 100
local TAG_REWARD_NAME = 101
local TAG_REWARD_NUM = 102
local TAG_NORMAL_CARD_SMALL = 103
local TAG_PIC_REWARD_BG = 104	    
local TAG_FRAME_CARD = 105
local TAG_START = 1000

function ContendRewardInfoPanel:getRewardList(aId)
  if not self.tableData[aId] then
    for _, aContentFratmentConfig in ipairs(MetaManager.activity_contend_fragment) do
      if not self.tableData[aContentFratmentConfig.id] then
        self.tableData[aContentFratmentConfig.id] = {}
      end
      table.insert(self.tableData[aContentFratmentConfig.id], aContentFratmentConfig.fragmentId)
    end
  end
  local tempData1 = self.tableData[aId]
  local rows = 0
  if #tempData1 % COLS_NUM == 0 then
    rows = #tempData1 / COLS_NUM
  else
    rows = #tempData1 / COLS_NUM + 1
  end
  local tempData2 = {}
  for i = 1, rows do
    tempData2[i] = i
  end
  if rows == 0 then
    tempData2 = {}
  end
  return tempData2
end

function ContendRewardInfoPanel:createTableView()
  local aPanel = self
  
  local RewardCellRenderer = class(TableViewRenderer)
  function RewardCellRenderer:ctor(width, height)
		self.list = aPanel.tableCellList
	end
  
  -- 构建Cell
  function RewardCellRenderer:buildCell(container)
    for cols = 1, COLS_NUM do
      local builder = LayoutBuilder:createWithContentsOfFile("scene/fight_for_soul.json")
      local layer = builder:build("sb/reward_item")
      layer:getChildByName("normal_card_small"):setTag(TAG_NORMAL_CARD_SMALL)
      layer:getChildByName("txt_item_name"):setTag(TAG_REWARD_NAME)
      layer:getChildByName("txt_item_name"):getChildByName("txt_item_name"):setTag(TAG_REWARD_NAME)
      local layerPosX = cols * (self.width / COLS_NUM) - (self.width / (COLS_NUM * 2))
      layer:setPosition(ccp(layerPosX, self.height * 0.9)) 
      layer:setVisible(false)
      layer:getChildByName("normal_card_small"):setVisible(false)
      container:addChild(layer)
      layer:setTag(TAG_START + cols)
    end
  end
  
  -- 设置数据
  function RewardCellRenderer:setData(rawCocosObj, index)
    for cols = 1, COLS_NUM do 
      local cellLayer = self:getChildByTag(rawCocosObj, TAG_START + cols)
		  cellLayer:setVisible(false)
			local data = aPanel.tableData[aPanel.selectedTab]
      local rewardId = index * COLS_NUM + cols
			if rewardId <= #data then
        -- 根据Tag设置文本
        local function setTextByTag(tag, str)
          local txt = cellLayer:getChildByTag(tag):getChildByTag(tag)
          ViewControlUtil.setLableText(txt, str)
		    end
			    
        -- 获取UI信息
        local picPosX, picPosY = cellLayer:getChildByTag(TAG_NORMAL_CARD_SMALL):getPosition()
			  cellLayer:setVisible(true)
        cellLayer:removeChildByTag(TAG_PIC_REWARD, true)
		        
        -- 获取奖励信息
			  local fragmentId = data[rewardId]
        local cardMetaId = MetaManager.card_fragment_meta[fragmentId].cardId
        local headCard = getHeadIconCanonCardByMetaId(cardMetaId)
        local aSmallIcon = Sprite:create("Item/Picture/Prop_soul.png")
        aSmallIcon:setPosition( ccp(45, 42) )
        headCard:addChild(aSmallIcon)
        headCard:setPosition(ccp(picPosX, picPosY))
        headCard:setTag(TAG_PIC_REWARD)
        cellLayer:addChild(headCard.refCocosObj, 1)
        headCard:dispose()
        local rewardName = Localization:getInstance():getText(MetaManager.card_meta[cardMetaId].name) .. Localization:getInstance():getText("fragment_cardTab")
        
        setTextByTag(TAG_REWARD_NAME, rewardName)
			end
		end
  end
  
  -- 生成TableView
  local renderer = RewardCellRenderer.new(CELL_WIDTH, CELL_HEIGHT)
  local tableView = TableView:create(renderer, LIST_WIDTH, LIST_HEIGHT)
  tableView:setPosition(ccp(-10, LIST_POS_Y))
  return tableView
end

function ContendRewardInfoPanel:updateForTabChange()
  for aIndex, aValue in ipairs(self.tabButtonList) do
    if aIndex == self.selectedTab then
      aValue:setEnable(false)
      --self.selectCornerList[aIndex]:setVisible(true)
      aValue.display:getChildByName("icon_selected"):setVisible(true)
      aValue.display:getChildByName("icon"):setVisible(false)
    else
      aValue:setEnable(true)
      --self.selectCornerList[aIndex]:setVisible(false)
      aValue.display:getChildByName("icon_selected"):setVisible(false)
      aValue.display:getChildByName("icon"):setVisible(true)
    end
  end
  if self.tableView then
    self.tableView:removeFromParentAndCleanup(true)
  end
  self.tableCellList = self:getRewardList(self.selectedTab)
  self.tableView = self:createTableView() 
  self.panelUI:addChildAt(self.tableView, 10)
  self.tableView:reloadData()
  --self.tableView:setContentOffset(ccp(0, 0), false)
end

