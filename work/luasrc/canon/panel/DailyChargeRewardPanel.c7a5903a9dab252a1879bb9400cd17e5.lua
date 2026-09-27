require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local CELL_HEIGHT = 200
local CELL_WIDTH = 560
local LIST_HEIGHT = 200
local LIST_WIDTH = 660
local LIST_POS_Y = 1230
local COLS_NUM = 3

----------------------------------
-- TAG常量
----------------------------------
local TAG_PIC_REWARD = 100
local TAG_REWARD_NAME = 101
local TAG_REWARD_NUM = 102
local TAG_NORMAL_CARD_SMALL = 103
local TAG_PIC_REWARD_BG = 104	    
local TAG_FRAME_CARD = 105
local TAG_START = 1000

--
-- DailyChargeRewardPanel
--

DailyChargeRewardPanel = class(Layer)

function DailyChargeRewardPanel:ctor()
    self.container = nil
    self.args = nil
end

function DailyChargeRewardPanel:create( container, args )
    local s = DailyChargeRewardPanel.new()
    s:initLayer(container, args)
    return s
end

function DailyChargeRewardPanel:initLayer(container, args)
    DailyChargeRewardPanel.super.initLayer(self)
    
    self.container = container
    self.args = args
    self.args.rewardList = self.args.rewardList or {}
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
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_daily_first_blunt_01") 
    self.tempLayer:addChild(self.panelUI)
    
    local function closeBtnAction(evt)
      self:dismissSelf()
    end
    
    local sureBtnDisplay = self.panelUI:getChildByName("btn")
    sureBtnDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("yes"))
    local sureBtn = Button:create(sureBtnDisplay)
    sureBtn:addEventListener( Events.kStart, closeBtnAction, self )
    
    self.panelUI:getChildByName("txt_normal_rewerd_2"):getChildByName("txt"):setString(getTextByKey("reward_rewardClaimed"))
    
    self.panelUI:getChildByName("normal_card"):setVisible(false)
    
    self.tableView = self:createTableView(self.args.rewardList) 
    self.panelUI:addChild(self.tableView)
    
    self.tempLayer:setScale(0.1)
end

function DailyChargeRewardPanel:createTableView(data, argv)
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
    for cols = 1, COLS_NUM do
      local builder = LayoutBuilder:createWithContentsOfFile("scene/reward_new.json")
      local layer = builder:build("reward_item")
      if layer:getChildByName("txt_level") then
        layer:getChildByName("txt_level"):setVisible(false)
      end
      if layer:getChildByName("bg_small_number") then
        layer:getChildByName("bg_small_number"):setVisible(false)
      end
      layer:getChildByName("normal_card_small"):setTag(TAG_NORMAL_CARD_SMALL)
      layer:getChildByName("bg_card"):setTag(TAG_PIC_REWARD_BG)
      layer:getChildByName("txt_item_name"):setTag(TAG_REWARD_NAME)
      layer:getChildByName("txt_item_quantity"):setTag(TAG_REWARD_NUM)
      layer:getChildByName("txt_item_name"):getChildByName("txt_item_name"):setTag(TAG_REWARD_NAME)
      layer:getChildByName("txt_item_quantity"):getChildByName("txt_item_quantity"):setTag(TAG_REWARD_NUM)
      layer:getChildByName("frame_card"):setTag(TAG_FRAME_CARD)
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
			
      local rewardId = index * COLS_NUM + cols
			if rewardId <= #data then
        -- 根据Tag设置文本
        local function setTextByTag(tag, str)
          local txt = cellLayer:getChildByTag(tag):getChildByTag(tag)
          ViewControlUtil.setLableText(txt, str)
		    end
        
        -- 根据Tag设置是否可见
		    local function setNodeVisibleByTag(tag, visible)
			    cellLayer:getChildByTag(tag):setVisible(visible)
		    end
			    
        -- 获取UI信息
        local picPosX, picPosY = cellLayer:getChildByTag(TAG_NORMAL_CARD_SMALL):getPosition()
		    local picZOrder = cellLayer:getChildByTag(TAG_PIC_REWARD_BG):getZOrder()
			  cellLayer:setVisible(true)
        cellLayer:removeChildByTag(TAG_PIC_REWARD, true)
		        
        -- 获取奖励信息
			  local rewardInfo = data[rewardId]
			  local rewardNum = "x" .. rewardInfo.amount
			  local rewardName = rewardInfo.itemType .. ":" .. rewardInfo.metaId
			  
        if rewardInfo.itemType == ResourceEnum.COIN then
          cellLayer:getChildByTag(TAG_FRAME_CARD):setVisible(true)
          local coinIcon = CCSprite:create("common/CoinIcon.png")
          coinIcon:setTag(TAG_PIC_REWARD)
          coinIcon:setPosition(ccp(picPosX, picPosY))
          cellLayer:addChild(coinIcon, picZOrder)
          rewardName = getTextByKey("resource_silverCoin")
          
        elseif rewardInfo.itemType == ResourceEnum.GEMS then	
          cellLayer:getChildByTag(TAG_FRAME_CARD):setVisible(true)
          local gemIcon = CCSprite:create("common/GemIcon.png")
          gemIcon:setTag(TAG_PIC_REWARD)
          gemIcon:setPosition(ccp(picPosX, picPosY))
          cellLayer:addChild(gemIcon, picZOrder)
          rewardName = getTextByKey("resource_goldCoin")
          
        elseif rewardInfo.itemType == ResourceEnum.CARD then
          cellLayer:getChildByTag(TAG_FRAME_CARD):setVisible(false)
          local headCard = getHeadIconCanonCardByMetaId(rewardInfo.metaId)
          headCard:setPosition(ccp(picPosX, picPosY))
          headCard:setTag(TAG_PIC_REWARD)
          cellLayer:addChild(headCard.refCocosObj, picZOrder)
          headCard:dispose()
          local cardMeta = MetaManager.card_meta[rewardInfo.metaId]
			    if cardMeta == nil then
            rewardName = "Card" .. rewardInfo.metaId
          else
            rewardName = getTextByKey(cardMeta.name)
			    end 
				
        elseif rewardInfo.itemType == ResourceEnum.EQUIP then
          cellLayer:getChildByTag(TAG_FRAME_CARD):setVisible(false)
          local canonItem = CanonItem:create()
          local itemMeta = MetaManager.equip_meta[rewardInfo.metaId]
          canonItem:loadByMetaId(rewardInfo.metaId)
          canonItem:setScale(0.9)
          canonItem:setPosition(ccp(picPosX, picPosY))
          canonItem:setTag(TAG_PIC_REWARD)
          cellLayer:addChild(canonItem.refCocosObj, picZOrder)
          canonItem:dispose()
          if itemMeta == nil then
            rewardName = "Equip" .. rewardInfo.metaId
          else
            rewardName = getTextByKey(itemMeta.name)
          end
            
        elseif rewardInfo.itemType == ResourceEnum.PROP then
          cellLayer:getChildByTag(TAG_FRAME_CARD):setVisible(false)
          local canonItem = CanonItem:create()
          local itemMeta = MetaManager.prop_meta[rewardInfo.metaId]
          canonItem:loadByMetaId(rewardInfo.metaId)
          canonItem:setScale(0.9)
          canonItem:setPosition(ccp(picPosX, picPosY))
          canonItem:setTag(TAG_PIC_REWARD)
          cellLayer:addChild(canonItem.refCocosObj, picZOrder)
          canonItem:dispose()
          if itemMeta == nil then
            rewardName = "Prop" .. rewardInfo.metaId
          else
            rewardName = getTextByKey(itemMeta.name)
          end 
                
        elseif rewardInfo.itemType == ResourceEnum.FRIENDPOINT then
          cellLayer:getChildByTag(TAG_FRAME_CARD):setVisible(true)
          local friendpointIcon = CCSprite:create("common/FriendpointIcon.png")
          friendpointIcon:setTag(TAG_PIC_REWARD)
          friendpointIcon:setPosition(ccp(picPosX, picPosY))
          cellLayer:addChild(friendpointIcon, picZOrder)
          rewardName = getTextByKey("resource_friendshipPoint")
		
		elseif rewardInfo.itemType == ResourceEnum.GACHA_POINT then
		  cellLayer:getChildByTag(TAG_FRAME_CARD):setVisible(true)
          local gachaPointsIcon = CCSprite:createWithSpriteFrameName("Prop_chaojijingyanqiu0.png")
          gachaPointsIcon:setTag(TAG_PIC_REWARD)
          gachaPointsIcon:setPosition(ccp(picPosX, picPosY))
          cellLayer:addChild(gachaPointsIcon, picZOrder)
          rewardName = getTextByKey("resource_gachaPoints")
        elseif rewardInfo.itemType == ResourceEnum.RP_VALUE then
          cellLayer:getChildByTag(TAG_FRAME_CARD):setVisible(true)
          local coinIcon = CCSprite:create("common/icon_luck.png")
          coinIcon:setTag(TAG_PIC_REWARD)
          coinIcon:setPosition(ccp(picPosX, picPosY))
          cellLayer:addChild(coinIcon, picZOrder)
          rewardName = getTextByKey("gacha_rpNum")
        else
          cellLayer:getChildByTag(TAG_FRAME_CARD):setVisible(false)
          local icon = CanonGoodIcon.createGoodIcon(rewardInfo.itemType , rewardInfo.metaId , 0 , nil)
          icon:setTag(TAG_PIC_REWARD)
          icon:setPosition(ccp(picPosX,picPosY))
          cellLayer:addChild(icon.refCocosObj,picZOrder)
          local params = {withoutAmount = true}
          rewardName = CanonGoodIcon.getGoodName(rewardInfo.itemType , rewardInfo.metaId , rewardInfo.amount , params)
		end	
        
        setTextByTag(TAG_REWARD_NAME, rewardName)
        setTextByTag(TAG_REWARD_NUM, rewardNum)
			end
		end
  end
  
  -- 生成TableView
  local renderer = RewardCellRenderer.new(CELL_WIDTH, CELL_HEIGHT)
  local tableView = TableView:create(renderer, LIST_WIDTH, LIST_HEIGHT)
  tableView:setPosition(ccp(-10, (LIST_POS_Y - LIST_HEIGHT) / 2))
  return tableView
end


function DailyChargeRewardPanel:scaleIn()
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

  --添加到二级堆栈
  UiStackManager.push(self)
end

function DailyChargeRewardPanel:dismissSelf()
  UiStackManager.remove(self)
  if (self.container.setTableViewsEnabled) then --有些弹窗可能发生在未继承BaseUI的场景中
      self.container:setTableViewsEnabled(true)
    end
  self.container.targetInfoPanel = self.pre_container_targetInfoPanel
  self:removeFromParentAndCleanup(true)
  if self.args.callback then
    self.args:callback()
  end
end