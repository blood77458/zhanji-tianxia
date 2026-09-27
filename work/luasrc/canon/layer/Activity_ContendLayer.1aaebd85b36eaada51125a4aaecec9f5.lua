require "canon.manager.MaintenanceManager"
require "canon.manager.BagCalcManager"
require "canon.panel.ContendRewardInfoPanel"
require "canon.request.ChallengeContendRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local table_width = 720
local table_height = 583
local table_posX = 0
local table_posY = 169
local item_width = 720
local item_height = 160
local enter_animation_duration = 0.3
local enter_animation_cell_duration = 0.15

--
--Activity_ContendLayer
--

Activity_ContendLayer = class(Layer)
function Activity_ContendLayer:ctor()
    self.container = nil
end

function Activity_ContendLayer:create( container )
    local s = Activity_ContendLayer.new()
    self.container = container
    s:initLayer()
    return s
end

function Activity_ContendLayer:initLayer()
    Activity_ContendLayer.super.initLayer(self)
    
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/fight_for_soul.json")
    self.builder.useArtLabelTTF = true
    self.mainUI = self.builder:build("fight_for_soul_title")
    self:addChild(self.mainUI)
    
    local function infoButtonSelected(evt)
      self.container:setTableViewsEnabled(false)
      self.scrollView:setTouchEnabled(false)
      local function closeCallback()
        self.container:setTableViewsEnabled(true)
        self.scrollView:setTouchEnabled(true)
      end
      local aRewardInfoPanel = ContendRewardInfoPanel:create(self.container, {callback = closeCallback})
      self.container:addChild(aRewardInfoPanel)
      aRewardInfoPanel:scaleIn()
    end
    local infoButton = Button:create(self.mainUI:getChildByName("icon_watchloot"))
    infoButton:addEventListener(Events.kStart, infoButtonSelected, self)
    
    self.tableData, self.leftNum = Activity_ContendLayer.getTableData()
    self.scrollView = self:createContendScrollView()
    self.mainUI:addChildAt(self.scrollView, 2)
    
    if Activity_ContendLayer.whetherActivityOpen() then
      self.mainUI:getChildByName("txt_fight_for_soul3"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_contend_remain"))
      self.mainUI:getChildByName("txt_fight_for_soul1"):getChildByName("txt"):setString(tostring(self.leftNum))
    else
      self.mainUI:getChildByName("txt_fight_for_soul3"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_contend_close"))
      self.mainUI:getChildByName("txt_fight_for_soul1"):setVisible(false)
    end
    
    
    self.mainUI:getChildByName("txt_fight_for_soul_info"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_contend_txt"))
end

function Activity_ContendLayer.getTableData(activityOpen)
  activityOpen = activityOpen or Activity_ContendLayer.whetherActivityOpen()
  
  local result = {}
  local aTotalChallengeNum = 0
  local sharkUserContendConstant = DataManager.GameMetaData.activityContendConfig
  local sharkUserContend = DailyDataManager.getSharkUserContend()
  for i = 1, 4 do
    local temp = {}
    temp.id = i
    local aContentInfo
    for _, aValue in pairs(sharkUserContend.contendInfo) do
      if aValue.contendId == i then
        aContentInfo = aValue
        break
      end
    end
    temp.totalChallengeNum = sharkUserContendConstant.challengedNum
    if aContentInfo then
      temp.challengeNum = aContentInfo.challengeNums
    else
      temp.challengeNum = 0
    end
    if not activityOpen then
      temp.totalChallengeNum = 0
      temp.challengeNum = 0
    end
    table.insert(result, temp)
    aTotalChallengeNum = aTotalChallengeNum + temp.challengeNum
  end
  local dayLeftNum = sharkUserContendConstant.dayDareNum - aTotalChallengeNum
  if not activityOpen then
    dayLeftNum = 0
  end
  return result, dayLeftNum
end

function Activity_ContendLayer:createContendScrollView()
  local cellTag = 1024
  local buttonTag = {-15}
  local aContendLayer = self
  local ContendTableViewRenderer = class(TableViewRenderer)
  function ContendTableViewRenderer:ctor(width, height)
    self.list = aContendLayer.tableData or {}
  end
  function ContendTableViewRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile("scene/fight_for_soul.json")
    local aCell = builder:build("list_fight_for_soul")
    --aCell:setAnchorPoint(ccp(0,1))
    container:addChild(aCell)
    aCell:setTag(cellTag)
    
    local weiBg = aCell:getChildByName("ad_1")
    weiBg:setTag(-10)
    
    local shuBg = aCell:getChildByName("ad_2")
    shuBg:setTag(-11)
    
    local wuBg = aCell:getChildByName("ad_3")
    wuBg:setTag(-12)
    
    local qunBg = aCell:getChildByName("ad_4")
    qunBg:setTag(-13)
    
    local aNumLabel = aCell:getChildByName("txt_fight_for_soul")
    aNumLabel:setTag(-14)
    aNumLabel = aNumLabel:getChildByName("txt")
    aNumLabel:setTag(-10)
    
    local aButtonDisplay = aCell:getChildByName("btn_ch")
    aButtonDisplay:setTag(-15)
    local challangeLabel = aButtonDisplay:getChildByName("lbl_chl")
    challangeLabel:setTag(-10)
    local challangBg = aButtonDisplay:getChildByName("btn_go")
    challangBg:setTag(-11)
    challangeLabel = aButtonDisplay:getChildByName("lbl_chl_inactive")
    challangeLabel:setTag(-12)
    challangBg = aButtonDisplay:getChildByName("btn_go_inactive")
    challangBg:setTag(-13)
  end
  function ContendTableViewRenderer:setData( rawCocosObj, index )
    local aCell = self:getChildByTag(rawCocosObj, cellTag)
    
    for i = 1, 4 do
      if self.list[index + 1].id == i then
        aCell:getChildByTag(-10 + 1 - i):setVisible(true)
      else
        aCell:getChildByTag(-10 + 1 - i):setVisible(false)
      end
    end
    
    local aNumLabel = aCell:getChildByTag(-14):getChildByTag(-10)
    setNodeText(aNumLabel, string.format("%d/%d", self.list[index + 1].challengeNum, self.list[index + 1].totalChallengeNum))

    local aButtonDisplay = aCell:getChildByTag(-15)
    if (aContendLayer.leftNum > 0) and (self.list[index + 1].challengeNum < self.list[index + 1].totalChallengeNum) then
      aButtonDisplay.ignoreTouch = false
      aButtonDisplay:getChildByTag(-10):setVisible(true)
      aButtonDisplay:getChildByTag(-11):setVisible(true)
      aButtonDisplay:getChildByTag(-12):setVisible(false)
      aButtonDisplay:getChildByTag(-13):setVisible(false)
    else
      aButtonDisplay.ignoreTouch = true
      aButtonDisplay:getChildByTag(-10):setVisible(false)
      aButtonDisplay:getChildByTag(-11):setVisible(false)
      aButtonDisplay:getChildByTag(-12):setVisible(true)
      aButtonDisplay:getChildByTag(-13):setVisible(true)
    end
    
  end
  local function onListItemTouch( evt )
    local aIndex = evt.data + 1
    local newCell = self.scrollView:cellAtIndex(aIndex - 1)
    local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
    local buttonDisplay = newCell:getChildByTag(cellTag):getChildByTag(-15)
    local challengeDisplay = buttonDisplay:getChildByTag(-11)
    if posInCell.x > buttonDisplay:getPositionX() and
      posInCell.x < (buttonDisplay:getPositionX() + challengeDisplay:getContentSize().width) and
      posInCell.y > (buttonDisplay:getPositionY() - challengeDisplay:getContentSize().height) and
      posInCell.y < buttonDisplay:getPositionY() then
      if (self.leftNum > 0) and (self.tableData[aIndex].challengeNum < self.tableData[aIndex].totalChallengeNum) then
        self:challengeContendId(self.tableData[aIndex].id)
      end
    end
  end
  local renderer = ContendTableViewRenderer.new(item_width, item_height)
  local aTableView = TableView:create(renderer, table_width, table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
  --aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
  aTableView:setPosition(ccp(table_posX, table_posY))
  return aTableView
end

function Activity_ContendLayer:challengeContendId(aContendId)
  if DataManager.getCurrUser().level < DataManager.GameMetaData.activityContendConfig.levelLimit then
    local aContent = Localization:getInstance():getText("stageLevelLimite", {stageLevelLimite = DataManager.GameMetaData.activityContendConfig.levelLimit})
    SuspensionLabel:showContent(self.container, aContent)
    return
  end
  
  local function showBagFullTip()
    -- local aContent = Localization:getInstance():getText("shop_inventoryFull")
    -- SuspensionLabel:showContent(self.container, aContent)
    NewPackageFullPanel:show()
  end
  
  if BagCalcManager.isFull() then
    showBagFullTip()
    return
  end
  
  local function onSucceed(requestEvent)
		ChallengeContendRequest.onSucceedDefault(requestEvent)
    
    local sharkUserContend = DailyDataManager.getSharkUserContend()
    local existed = false
    for _, aContendInfo in ipairs(sharkUserContend.contendInfo) do
      if aContendInfo.contendId == aContendId then
        aContendInfo.challengeNums = aContendInfo.challengeNums + 1
        break
      end
    end
    if not existed then
      local temp = {}
      temp.contendId = aContendId
      temp.challengeNums = 1
      table.insert(sharkUserContend.contendInfo, temp)
    end
    DailyDataManager.setSharkUserContend(sharkUserContend)
   
    Director:sharedDirector():replaceScene(BattleScene:create(requestEvent.data, BattleBackType.kActivityContend, BattleEnterEnum.kActivityContend))
	end
  local params = {contendId = aContendId}
  ChallengeContendRequest.sendRequest(onSucceed, ChallengeContendRequest.onFailedDefault, params)
end

function Activity_ContendLayer:enable()
  if not DataManager.GameMetaData.activityContendConfig then
    return false
  end
  --[[
  if DataManager.getCurrUser().level < DataManager.GameMetaData.activityContendConfig.levelLimit then
    return false
  end
  ]]
  local isEnable = MaintenanceManager.isActivityOpen(DataManager.GameMetaData.activityContendConfig.panelFeatureName)
  return isEnable
end 

function Activity_ContendLayer:dispose()
  Activity_ContendLayer.super.dispose(self)
end

function Activity_ContendLayer.whetherActivityOpen()
  local activityOpen = false
  for _, aFeatureName in pairs(DataManager.GameMetaData.activityContendConfig.featureNameList) do
    if MaintenanceManager.isActivityOpen(aFeatureName) then
      activityOpen = true
      break
    end
  end
  return activityOpen
end

function Activity_ContendLayer.getTipNum()
  if not DataManager.GameMetaData.activityContendConfig then
    return 0
  end
  
  if not Activity_ContendLayer.enable() then
    return 0
  end
  
  if DataManager.getCurrUser().level < DataManager.GameMetaData.activityContendConfig.levelLimit then
    return 0
  end
  
  local activityOpen = Activity_ContendLayer.whetherActivityOpen()
  if not activityOpen then
    return 0
  end
  
  local aTipNum = 0
  _, aTipNum = Activity_ContendLayer.getTableData(activityOpen)
  return aTipNum
end
