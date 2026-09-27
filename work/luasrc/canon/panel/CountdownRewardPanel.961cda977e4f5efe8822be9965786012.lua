--------------------------------------------------------------------------------
-- CountdownRewardPanel.lua -- 新手礼包界面
-- author: Jiang Yize
-- date: 2013-11-06
--------------------------------------------------------------------------------
require "canon.data.MetaManager"
require "canon.utils.ViewControlUtil"

----------------------------------
-- UI常量
----------------------------------
local CELL_HEIGHT = 200
local CELL_WIDTH = 560
local LIST_HEIGHT = 355
local LIST_WIDTH = 660
local LIST_POS_Y = 1070
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

CountdownRewardPanel = class(Layer)

CountdownType = {
  ViewReward = 1,
  GetReward = 2,
}

function CountdownRewardPanel:ctor()
  self.container = nil
end

-----------------------------------------------------
-- 生成新手礼包Panel
-- container：容器
-- timeCoolDown：冷却时间
-- finish：是否完成新手礼包
-- panelType：面板类型(领取&查看,见CountdownType)
-- closeCallBackFunc：关闭面板的回调函数
-----------------------------------------------------
function CountdownRewardPanel:create(container, timeCoolDown, rewardId, finish, panelType, closeCallBackFunc)
  self.container = container
  self.timeCoolDown = timeCoolDown
  self.rewardId = rewardId
  self.finish = finish
  self.panelType = panelType
  self.closeCallBackFunc = closeCallBackFunc
  
  local panel = CountdownRewardPanel.new()
  panel:initLayer()
  
  return panel
end

-- 生成TableView
function CountdownRewardPanel:createTableView(data, argv)
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

function CountdownRewardPanel:initLayer()
  CountdownRewardPanel.super.initLayer(self)
  self.container:setTableViewsEnabled(false)
  
  -- 设置Layer
  local winSize = CCDirector:sharedDirector():getWinSize()
  self:setContentSize(CCSizeMake(winSize.width, winSize.height))
  
  -- 获取公告UI
  local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
  local ui = builder:build("common_countdown_reward_upbox")
  self:addChild(ui)
  
  -- 设置页面标题
  local titleLabel = ui:getChildByName("common_txt_reward_title"):getChildByName("txt_reward_title")
  titleLabel:setString(getTextByKey("countdownReward_title"))
  
  -- 关闭Panel事件
  local function onClosePanel(evt)
    PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
    self.container:setTableViewsEnabled(true)
    self.container.targetInfoPanel = nil
    if self.container.btnGetReward then
      self.container.btnGetReward:setEnable(true)
    end
    if self.colseCallBackFunc and type(self.colseCallBackFunc) == "function" then
      self.colseCallBackFunc()
    end
  end
  
  -- 关闭按钮
  local closeButtonDisplay = ui:getChildByName("common_btn_close")
  local closeButton = Button:create(closeButtonDisplay)
  closeButton:addEventListener(Events.kStart, onClosePanel, self)
  local confirmButtonDisplay = ui:getChildByName("common_button_long_blue")
  confirmButtonDisplay:getChildByName("txt_sure"):setString(getTextByKey("yes"))
  local confirmButton = Button:create(confirmButtonDisplay)
  confirmButton:addEventListener(Events.kStart, onClosePanel, self)
  
  -- 生成文本信息
  local function geneTextField(labelUI, childName, txtString)
    local txtField = labelUI:getChildByName(childName):getChildByName("txt")
    txtField:setString(txtString)
  end
  
  -- 文本信息
  local hintLabel = ui:getChildByName("common_txt_reward_com"):getChildByName("txt_reward_com")
  local txtHour, txtMin, txtSec = TimeUtil.getHourMinSec(self.timeCoolDown)
  if self.panelType == CountdownType.ViewReward then
    hintLabel:setString(getTextByKey("countdownReward_display_text"))
    ui:getChildByName("common_lbl_countdown2"):setVisible(false)
    
    if not self.finish then -- 新手礼包未完成
      local timeLabels = ui:getChildByName("common_lbl_countdown")
      geneTextField(timeLabels, "common_txt_normal", getTextByKey("countdownReward_text1"))
      geneTextField(timeLabels, "common_txt_hour", txtHour)
      geneTextField(timeLabels, "common_txt_hour_normal", getTextByKey("countdownReward_text_hour"))
      geneTextField(timeLabels, "common_txt_min", txtMin)
      geneTextField(timeLabels, "common_txt_min_normal", getTextByKey("countdownReward_text_min"))
      geneTextField(timeLabels, "common_txt_sec", txtSec)
      geneTextField(timeLabels, "common_txt_sec_normal", getTextByKey("countdownReward_text2")) 
    else
      ui:getChildByName("common_lbl_countdown"):setVisible(false)
    end
  else
    hintLabel:setString(getTextByKey("countdownReward_open_text"))
    ui:getChildByName("common_lbl_countdown"):setVisible(false)
    
    if not self.finish then -- 新手礼包未完成
      local timeLabels = ui:getChildByName("common_lbl_countdown2")
      geneTextField(timeLabels, "common_txt_hour", txtHour)
      geneTextField(timeLabels, "common_txt_hour_normal", getTextByKey("countdownReward_text_hour"))
      geneTextField(timeLabels, "common_txt_min", txtMin)
      geneTextField(timeLabels, "common_txt_min_normal", getTextByKey("countdownReward_text_min"))
      geneTextField(timeLabels, "common_txt_sec", txtSec)
      geneTextField(timeLabels, "common_txt_sec_normal", getTextByKey("countdownReward_text3"))
    else
      ui:getChildByName("common_lbl_countdown2"):setVisible(false)
    end
  end
  
  -- 隐藏美术的奖励信息
  ui:getChildByName("common_reward_item"):setVisible(false)
  
  -- 获取奖励信息列表
  local packageId = MetaManager.countdown_reward[self.rewardId].rewardPackage
  rewardList = MetaManager.getRewardInfoByID(packageId)
  --[[
  for k, v in pairs(rewardList) do
    print(table.serialize(v))
  end
  ]]
  
  -- 奖励信息
  self.tableView = self:createTableView(rewardList) 
	self:addChild(self.tableView)
end
