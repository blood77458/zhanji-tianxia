require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local CELL_HEIGHT = 200
local CELL_WIDTH = 685.2
local LIST_HEIGHT = 355
local LIST_WIDTH = 660
local LIST_POS_Y = 1070
local COLS_NUM = 4

----------------------------------
-- TAG常量
----------------------------------
local TABLEVIEW_CELL_TAG = -1000
local TAG_PIC_REWARD = 100
local TAG_REWARD_NAME = 101
local TAG_REWARD_NUM = 102
local TAG_NORMAL_CARD_SMALL = 103
local TAG_PIC_REWARD_BG = 104	    
local TAG_FRAME_CARD = 105
local TAG_GREY_LAYER = 106
local TAG_START = 1000

local TAG_NORMAL_ICON_ALL = 10000
local TAG_TXT_NAME = 1002
local TAG_NORMAL_ICON = 1003

--
-- ShowGachaBoxCardsPanel
--

ShowGachaBoxCardsPanel = class(Layer)

function ShowGachaBoxCardsPanel:ctor()
    self.container = nil
    self.args = nil
end

function ShowGachaBoxCardsPanel:create( container, args )
    local s = ShowGachaBoxCardsPanel.new()
    s:initLayer(container, args)
    return s
end

function ShowGachaBoxCardsPanel:initLayer(container, args)
    ShowGachaBoxCardsPanel.super.initLayer(self)

    local rewardTable = {}
    for i=1,#args.rewardList do
      table.insert(rewardTable , args.rewardList[#args.rewardList - i + 1])
    end

    self.container = container
    self.args = args
    self.args.rewardList = rewardTable or {}
    self.pre_container_targetInfoPanel = self.container.targetInfoPanel
    self.container.targetInfoPanel = self
    
    if (self.container.setTableViewsEnabled) then --有些弹窗可能发生在未继承BaseUI的场景中
      self.container:setTableViewsEnabled(false)
    end
    
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)
    
    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/gacha_new.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_high_and_mid") 
    self.tempLayer:addChild(self.panelUI)
    
    local function closeBtnAction(evt)
      self:dismissSelf()
    end
    local closeBtnDisplay = self.panelUI:getChildByName("common_btn_close")
    local closeBtn = Button:create(closeBtnDisplay)
    closeBtn:addEventListener( Events.kStart, closeBtnAction, self )

    local closeBtn2 = Button:create(self.panelUI:getChildByName("btn_down"))
    closeBtn2:addEventListener( Events.kStart, closeBtnAction, self )
    self.panelUI:getChildByName("btn_down"):getChildByName("txt"):setString(getTextByKey("close"))
    
    self.tableView = self:createTableView(self.args.rewardList) 
    self.panelUI:addChild(self.tableView)
    
    self.tempLayer:setScale(0.1)
end

function ShowGachaBoxCardsPanel:createTableView(data, argv)
  local RewardCellRenderer = class(TableViewRenderer)
  
  -- 构造函数中计算cell个数
  function RewardCellRenderer:ctor(width, height)
		local rows = 0
    if #data % COLS_NUM == 0 then
      rows = #data / COLS_NUM
    else
      rows = #data / COLS_NUM + 1
    end
    for i = 1, rows do
      self.list[i] = i
    end
    if rows == 0 then
      self.list = {}
    end
	end
  
  -- 构建Cell
  function RewardCellRenderer:buildCell(container)
    
    local function getGreyLayer()
      local backLayer = LayerColor:create()
      backLayer:setColor(ccc3( 0, 0, 0 ))
      backLayer.refCocosObj:setOpacity( 170 )
      backLayer:setContentSize(CCSizeMake( 130, 130 ))
      backLayer:setPosition(ccp(-65, -65))
      local recievedSpr = Sprite:create("pic/signInIcon_obtain.png")
      recievedSpr:setPosition(ccp(65,65 ))
      recievedSpr:setScale(0.75)
      backLayer:addChild(recievedSpr)
      return backLayer
    end

    for cols = 1, COLS_NUM do
      local builder = LayoutBuilder:createWithContentsOfFile("scene/gacha_new.json")
      local layer = builder:build("sb/reward_item")
      layer:getChildByName("normal_card_small"):setTag(TAG_NORMAL_CARD_SMALL)
      -- layer:getChildByName("bg_card"):setTag(TAG_PIC_REWARD_BG)
      layer:getChildByName("txt_item_name"):setTag(TAG_REWARD_NAME)
      -- layer:getChildByName("txt_item_quantity"):setTag(TAG_REWARD_NUM)
      layer:getChildByName("txt_item_name"):getChildByName("txt"):setTag(TAG_REWARD_NAME)
      -- layer:getChildByName("txt_item_quantity"):getChildByName("txt_item_quantity"):setTag(TAG_REWARD_NUM)
      -- layer:getChildByName("frame_card"):setTag(TAG_FRAME_CARD)
      local width = 693.85
      local layerPosX = cols * (width / COLS_NUM) - (width / (COLS_NUM * 2))
      layer:setPosition(ccp(layerPosX, self.height * 0.9 - 65)) 
      layer:setVisible(false)
      layer:getChildByName("normal_card_small"):setVisible(false)
      container:addChild(layer)
      local greyLayer = getGreyLayer()
      greyLayer:setTag(TAG_GREY_LAYER)
      layer:addChildAt(greyLayer , 10000)
      layer:setTag(TAG_START + cols)
    end
  end
  
  -- 设置数据
  function RewardCellRenderer:setData(rawCocosObj, index)
    for cols = 1, COLS_NUM do 
      local cellLayer = self:getChildByTag(rawCocosObj, TAG_START + cols)
		  cellLayer:setVisible(false)
			
      local rewardId = index * COLS_NUM + cols
			if rewardId <= #data then
        -- 根据Tag设置文本
        local function setTextByTag(tag, str)
          local txt = cellLayer:getChildByTag(tag):getChildByTag(tag)
          ViewControlUtil.setLableText(txt, str)
          txt:setColor(ccc3(255,255,255))
		    end
        
        -- 根据Tag设置是否可见
		    local function setNodeVisibleByTag(tag, visible)
			    cellLayer:getChildByTag(tag):setVisible(visible)
		    end
			    
        -- 获取UI信息
        local picPosX, picPosY = cellLayer:getChildByTag(TAG_NORMAL_CARD_SMALL):getPosition()
		    -- local picZOrder = cellLayer:getChildByTag(TAG_PIC_REWARD_BG):getZOrder()
			  cellLayer:setVisible(true)
        cellLayer:removeChildByTag(TAG_PIC_REWARD, true)
		        
        -- 获取奖励信息
			  local rewardInfo = data[rewardId]

          local headCard = getHeadIconCanonCardByMetaId(rewardInfo.cardId)
          headCard:setPosition(ccp(picPosX, picPosY))
          headCard:setTag(TAG_PIC_REWARD)
          cellLayer:addChild(headCard.refCocosObj, 1000)
          headCard:dispose()
          local cardMeta = MetaManager.card_meta[rewardInfo.cardId]

            rewardName = getTextByKey(cardMeta.name)

        setTextByTag(TAG_REWARD_NAME, rewardName)

        if rewardInfo.cardStatus then
          setNodeVisibleByTag(TAG_GREY_LAYER , true)
        else
          setNodeVisibleByTag(TAG_GREY_LAYER , false)
        end
			end
		end
  end
  
  -- 生成TableView
  local renderer = RewardCellRenderer.new(CELL_WIDTH, CELL_HEIGHT)
  local tableView = TableView:create(renderer, 693.85, 813.85)
  tableView:setPosition(ccp(12, 270))
  return tableView
end


function ShowGachaBoxCardsPanel:scaleIn()
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

function ShowGachaBoxCardsPanel:dismissSelf()
  if (self.container.setTableViewsEnabled) then --有些弹窗可能发生在未继承BaseUI的场景中
      self.container:setTableViewsEnabled(true)
    end
  self.container.targetInfoPanel = self.pre_container_targetInfoPanel
  self:removeFromParentAndCleanup(true)
  if self.args.callback then
    self.args:callback()
  end
end