require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.panel.RankRewardReviewPanel"

local enter_animation_duration = 0.3
local enter_animation_cell_duration = 0.15
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
--AcrossScheduleTablePanel
--

AcrossScheduleTablePanel = class(Layer)

function AcrossScheduleTablePanel:ctor()
	self.container = nil
end

function AcrossScheduleTablePanel:create(container)
	local s = AcrossScheduleTablePanel.new()
	s:initLayer(container)
	return s
end

function AcrossScheduleTablePanel:initLayer(container)
	AcrossScheduleTablePanel.super.initLayer(self)
	self.container = container

	local builder = LayoutBuilder:createWithContentsOfFile("scene/across_fight.json")
  builder.useArtLabelTTF = true
  self.uiView = builder:build("event_form_combination")
  self:addChild(self.uiView)
  
  local rewardTime = AcrossFightManager.getRewardTime()
  
  local function infoButtonSelected(evt)
    self.container:setTableViewsEnabled(false)
    local timeTable = AcrossFightManager.getCurrentOrNextCrossPkTimeTable()
    local aInfoPanel = ActivityInfoPanel:create(self.container, Localization:getInstance():getText("cross_explain_text", {num1 = timeTable[1].month, num2 = timeTable[1].day, num3 = timeTable[1].hour, num4 = timeTable[2].month, num5 = timeTable[2].day, num6 = timeTable[2].hour, num7 = timeTable[3].month, num8 = timeTable[3].day, num9 = timeTable[3].hour, num10 = timeTable[4].month, num11 = timeTable[4].day, num12 = timeTable[4].hour, num13 = timeTable[5].month, num14 = timeTable[5].day, num15 = timeTable[5].hour, num16 = timeTable[6].month, num17 = timeTable[6].day, num18 = timeTable[6].hour, num19 = timeTable[7].month, num20 = timeTable[7].day, num21 = timeTable[7].hour, num22 = timeTable[8].month, num23 = timeTable[8].day, num24 = timeTable[8].hour, num25 = timeTable[9].month, num26 = timeTable[9].day, num27 = timeTable[9].hour, num28 = timeTable[10].month, num29 = timeTable[10].day, num30 = timeTable[10].hour, num31 = timeTable[11].month, num32 = timeTable[11].day, num33 = timeTable[11].hour, num34 = timeTable[12].month, num35 = timeTable[12].day, num36 = timeTable[12].hour, num37 = timeTable[13].month, num38 = timeTable[13].day, num39 = timeTable[13].hour, num40 = timeTable[14].month, num41 = timeTable[14].day, num42 = timeTable[14].hour, num43 = timeTable[15].month, num44 = timeTable[15].day, num45 = timeTable[15].hour}))
    self.container:addChild(aInfoPanel)
    aInfoPanel:scaleIn()
  end
  local aInfoDisplay = self.uiView:getChildByName("sky_btn_qa")
  local aInfoButton = Button:create(aInfoDisplay)
  aInfoButton:addEventListener(Events.kStart, infoButtonSelected, self)
  
  local function rewardReviewButtonSelected(evt)
    local params = {}
    params.subTitle = getTextByKey("cross_reward_text", {num1 = rewardTime[1].month, num2 = rewardTime[1].day, num3 = rewardTime[1].hour, num4 = rewardTime[2].month, num5 = rewardTime[2].day, num6 = rewardTime[2].hour})
    params.rewardList = {}
    for _, aReward in ipairs(DataManager.GameMetaData.crossServerRewardConfig.items) do
      local temp = {}
      if aReward.crossServerRank < 8 then
        temp.rankText = getTextByKey("cross_list_rank", {num1 = aReward.crossServerRank})
      else
        temp.rankText = getTextByKey("cross_list_rank1", {num1 = aReward.crossServerRank})
      end
      temp.rewardPackage = aReward.rewardPackageId
      table.insert(params.rewardList, temp)
    end
    local panel = RankRewardReviewPanel:create(self.container, params)
    PopoutManager:sharedManager():popout(panel, kPopoutDir.kScale, true, false, self.container)
  end
  local aReviewDisplay = self.uiView:getChildByName("icon_reward_tab")
  local aReviewButton = Button:create(aReviewDisplay)
  aReviewButton:addEventListener(Events.kStart, rewardReviewButtonSelected, self)
  
  local currentTimeEnum = AcrossFightManager.getCurrentTimeEnum()
  self.scrollData = AcrossFightManager.getScheduleTableData(currentTimeEnum)
  self.scrollView = self:createScheduleScrollView()
  self.uiView:addChild(self.scrollView)
end

function AcrossScheduleTablePanel:dispose()
  AcrossScheduleTablePanel.super.dispose(self)
end

local scroll_width = 713
local scroll_height = 746
local scroll_posX = 3
local scroll_posY = 124
local scroll_startPosY = 740
local overlap_height = 8
local top4_view_posX = 15

function AcrossScheduleTablePanel:createScheduleScrollView()
	local aScrollContentList = {}
  local aScrollView = ScrollView:create(scroll_width, scroll_height)
  aScrollView:setPosition(ccp(scroll_posX, scroll_posY))
  aScrollView:setDirection(kCCScrollViewDirectionVertical)
  
  local builder = LayoutBuilder:createWithContentsOfFile("scene/across_fight.json")
  local aStartPosY = scroll_startPosY
  if self.scrollData[5] then
    local aTop4View = builder:build("event_form_thelistfour")
    aTop4View:setPosition(ccp(top4_view_posX, aStartPosY))
    aScrollView:addChild(aTop4View)
    table.insert(aScrollContentList, aTop4View)
    aStartPosY = aStartPosY - aTop4View:getGroupBounds().size.height - overlap_height
    
    for i = 1, 7 do
      local aNameLabel = aTop4View:getChildByName("txt_across_fight_13_" .. (8+i))
      aNameLabel = aNameLabel:getChildByName("txt")
      if self.scrollData[5][i] and self.scrollData[5][i].nickName then
        aNameLabel:setString(self.scrollData[5][i].nickName)
      else
        aNameLabel:setString("")
      end
    end
  end
  local aArray = {'a', 'b', 'c', 'd'}
  for i = 1, 4 do
    local aView = builder:build("table_event_form_list")
    aView:setPosition(ccp(0, aStartPosY))
    aScrollView:addChild(aView)
    table.insert(aScrollContentList, aView)
    aStartPosY = aStartPosY - aView:getGroupBounds().size.height - overlap_height
    
    for _, aNameSuffix in ipairs(aArray) do
      aView:getChildByName("lbl_" .. aNameSuffix):setVisible(false)
    end
    aView:getChildByName("lbl_" .. aArray[i]):setVisible(true)
    local aNameGroup = aView:getChildByName("list_begin")
    for j = 1, 15 do
      local aNameLabel = aNameGroup:getChildByName("txt_across_fight_13_" .. j)
      aNameLabel = aNameLabel:getChildByName("txt")
      if self.scrollData[i][j] and self.scrollData[i][j].nickName then
        aNameLabel:setString(self.scrollData[i][j].nickName)
      else
        aNameLabel:setString("")
      end
    end
  end
  aScrollView:setContentSize(CCSizeMake(scroll_width, (aStartPosY < 0) and (scroll_height - aStartPosY) or scroll_height))
  if aStartPosY < 0 then
    for _, aGroup in ipairs(aScrollContentList) do
      aGroup:setPositionY(aGroup:getPositionY() - aStartPosY)
    end
    aScrollView:setContentOffset(ccp(0, aStartPosY), false)
  end
  
  return aScrollView
end

function AcrossScheduleTablePanel:setTableViewTouched(enabled)
  self.scrollView:setTouchEnabled(enabled)
end

function AcrossScheduleTablePanel:panelEnter(callback)
  local function enterActionFinished()
    if callback then
      callback()
    end
  end
  self.uiView:setPositionX(self.uiView:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.uiView:runAction(CCSequence:create(arr))
  --[[
  self.tableView:setPositionX(self.tableView:getPositionX() - visibleSize.width)
  self.tableView:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))]]
end

function AcrossScheduleTablePanel:panelExit(callback)
  local function exitActionFinished()
    if callback then
      callback()
    end
  end
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(exitActionFinished))
  self.uiView:runAction(CCSequence:create(arr))
  --[[
  self.tableView:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))]]
end