--------------------------------------------------------------------------------
-- StoryReviewMainPanel.lua

-- 原:
-- StoryReviewScene.lua - 精英关卡界面: 动态显示所有精英关卡状态，购买挑战次数，发起挑战
-- author: xiaojie.bai
-- date: 2013-09-26 10:40
--------------------------------------------------------------------------------

require "canon.models.EliteManager"
require "canon.models.CalculationManager"
require "canon.models.RewardManager"
require "canon.canonUtils"
require "canon.utils.ViewControlUtil"
require "canon.utils.IdUtil"

require "canon.panel.CanonMessageBox"
require "canon.panel.AssistantMessageBoxPanel"
require "canon.manager.BagCalcManager"
require "canon.manager.DailyDataManager"

require "canon.data.MetaManager"

StoryReviewMainPanel = class(Layer)
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

function StoryReviewMainPanel:ctor()
  self.mainUI = nil
  self.contentLayer = nil
  
  self.missionTableView = nil
  self.cityTableView = nil
end

function StoryReviewMainPanel:create(contianer)
  local layer = StoryReviewMainPanel.new()
  
  layer.contianer = contianer
  
  layer.maxMissionId = 0 --最大普通关卡id
  layer.selectedCityId = nil --当前选择的城市id
  layer.selectedCityTableIdx = nil --城市菜单选中
  layer.selectedMissionId = nil --当前选择的关卡id
  
  layer.cityTableView = nil
  layer.missionTableView = nil
  
  layer:initLayer()
  return layer
end


function StoryReviewMainPanel:setTableViewsEnabledInner(v)
  if(self.cityTableView) then
    self.cityTableView:setTouchEnabled(v)
  end
  if(self.missionTableView) then
    self.missionTableView:setTouchEnabled(v)
  end
end

--------------------
-- 创建城池标签
--------------------
local function isPassFirstChapter()
  local lastOpenCity = CountryManager:sharedManager():getLastOpenedCountryID()
  local isPassFirstChapter = false
  local chapterIds = CountryManager:sharedManager():getAllChapterIDsWithCountryID(lastOpenCity)
  local newMissionID =  CountryManager:sharedManager():getNewMissionID()
  newMissionID = string.sub(newMissionID , 1 , 4)
  if tonumber(newMissionID) > chapterIds[1] or tonumber(newMissionID) == 1000 then
    isPassFirstChapter = true
  end
  return isPassFirstChapter
end 

function StoryReviewMainPanel:createCityTableView()
  local builder = LayoutBuilder:createWithContentsOfFile(EliteManager.DICT.RESOURCE_FILE)
  builder.useArtLabelTTF = true

  local selectedCityId = self.selectedCityId
  local citysInfo = {}
  for k,v in pairs(MetaManager.battle_country) do
    local cityInfo = {cityId = v.id , selected = false}
    table.insert(citysInfo , cityInfo)
  end

  local function cityIdSort(a, b)
    if a.cityId < b.cityId then
      return true
    else
      return false
    end
  end
  table.sort(citysInfo, cityIdSort)

  for k,v in pairs(citysInfo) do
    if(v.cityId == selectedCityId) then
      v.selected = true
      self.selectedCityTableIdx = k
    end
  end

  local selectedCity = CountryManager:sharedManager():getLastOpenedCountryID()
  
  local CityTableViewRenderer = class(TableViewRenderer)
  function CityTableViewRenderer:ctor(width, height)
    self.list = citysInfo
  end
  
  function CityTableViewRenderer:buildCell(container)
    local aCell = builder:build("btn/elite_btn_title_city")
    container:addChild(aCell)
    aCell:setTag(-1001)
    
    local font = aCell:getChildByName("font")
    font:setTag(-10)
    local btn = aCell:getChildByName("btn")
    btn:setTag(-11)
    local disable = aCell:getChildByName("disable")
    disable:setTag(-12)
    local inactive = aCell:getChildByName("inactive")
    inactive:setTag(-13)
  end
  
  function CityTableViewRenderer:setData(rawCocosObj, index)
    local aCell = self:getChildByTag(rawCocosObj, -1001)
    
    local cityInfo = self.list[index + 1]
    local font = aCell:getChildByTag(-10)
    local cityNameKey = CountryManager:sharedManager():getCountryName(cityInfo.cityId)
    ViewControlUtil.setLableText(font, getTextByKey(cityNameKey))

    local lastOpenCity = CountryManager:sharedManager():getLastOpenedCountryID()
    
    
    if(cityInfo.selected) then
      aCell:getChildByTag(-11):setVisible(true)
      aCell:getChildByTag(-12):setVisible(false)
      aCell:getChildByTag(-13):setVisible(false)
    elseif(cityInfo.cityId <= lastOpenCity) then
      aCell:getChildByTag(-11):setVisible(false)
      aCell:getChildByTag(-12):setVisible(true)
      aCell:getChildByTag(-13):setVisible(false)
    else
      local newMissionID =  CountryManager:sharedManager():getNewMissionID()
      if newMissionID == 1000000 then
        aCell:getChildByTag(-11):setVisible(false)
        aCell:getChildByTag(-12):setVisible(true)
        aCell:getChildByTag(-13):setVisible(false)
      else
        aCell:getChildByTag(-11):setVisible(false)
        aCell:getChildByTag(-12):setVisible(false)
        aCell:getChildByTag(-13):setVisible(true)
      end
    end

    if cityInfo.cityId == lastOpenCity and not isPassFirstChapter() then
      aCell:getChildByTag(-11):setVisible(false)
      aCell:getChildByTag(-12):setVisible(false)
      aCell:getChildByTag(-13):setVisible(true)
    end
  end
  
  local function onListItemTouch(evt)
    local index = evt.data + 1
    if(index == self.selectedCityTableIdx) then
      return nil
    end
    
    local aCell = self.cityTableView:cellAtIndex(index - 1)
    local posInCell = aCell:convertToNodeSpace(evt.globalPosition)
    local btnCity = aCell:getChildByTag(-1001)
    local picBtnCity = btnCity:getChildByTag(-11)
    if (posInCell.x < btnCity:getPositionX() or posInCell.x > (btnCity:getPositionX() + picBtnCity:getContentSize().width)) then
      return nil
    end
    
    local lastOpenCity = CountryManager:sharedManager():getLastOpenedCountryID()
    local selectingCityInfo = citysInfo[index].cityId
    if(selectingCityInfo > lastOpenCity) then
      return nil
    end

    if (selectingCityInfo == lastOpenCity) and not isPassFirstChapter() then
      return nil
    end
    
    for _, cityInfo in ipairs(citysInfo) do
      cityInfo.selected = false
      if(_ == index) then
        cityInfo.selected = true
        self.selectedCityId = cityInfo.cityId
      end
    end
    
    self.selectedCityTableIdx = index
    selectedCity = index
    local needRefresh = true
    if needRefresh then --TODO
      ViewControlUtil.refreshAndLocateTableView(self.cityTableView, index)
    end
    
    --切换城市动画
    local function missionTableExitFinished()
      self.contentLayer:removeChild(self.missionTableView)
      self.missionTableView = self:createMissionTableView(self.selectedCityId)
      self.contentLayer:addChild(self.missionTableView)
      ViewControlUtil.showTableViewAction(self.missionTableView, visibleSize)
    end
    ViewControlUtil.disappearTableViewAction(self.missionTableView, visibleSize, missionTableExitFinished)
  end
  
  local renderer = CityTableViewRenderer.new(EliteManager.DICT.ITEM_CITY_WIDTH, EliteManager.DICT.ITEM_CITY_HEIGHT)
  local aTableView = TableView:create(renderer, EliteManager.DICT.TB_CITY_WIDTH, EliteManager.DICT.TB_CITY_HEIGHT)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
  aTableView:setPosition(ccp(EliteManager.DICT.TB_CITY_POSX, EliteManager.DICT.TB_CITY_POSY))
  aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  
  local selectedIdx = 0
  for k,v in pairs(citysInfo) do
    selectedIdx = k
    if(self.selectedCityId == v.cityId) then
      break
    end
  end
  
  ViewControlUtil.refreshAndLocateTableView(aTableView, selectedIdx)
  
  return aTableView
end

--------------------
-- 创建关卡表格
--------------------
function StoryReviewMainPanel:createMissionTableView(cityId, seletedMissionId)
  local missionIds = CountryManager:sharedManager():getAllChapterIDsWithCountryID(cityId)
  
  local MissionTableViewRenderer = class(TableViewRenderer)
  local builder = LayoutBuilder:createWithContentsOfFile(EliteManager.DICT.RESOURCE_FILE)
  builder.useArtLabelTTF = true
  
  function MissionTableViewRenderer:ctor(width, height)
    self.list = missionIds
  end
  
  local cellTag = -1001
  local buttonTag = {18}
  function MissionTableViewRenderer:buildCell(container)
    local aCell = builder:build("review_plot_list")
    container:addChild(aCell)
    aCell:setTag(-1001)
    
    local cityNameTxt = aCell:getChildByName("txt_01")
    cityNameTxt:setTag(10)
    cityNameTxt:getChildByName("txt"):setTag(10)

    cityNameTxt:getChildByName("txt"):setColor(ccc3(0, 0, 0))
    cityNameTxt:getChildByName("txt"):setAroundColor(ccc3(189, 255, 255))
    
    local missionNameTxt = aCell:getChildByName("txt_02")
    missionNameTxt:setTag(11)
    missionNameTxt:getChildByName("txt"):setTag(10)

    missionNameTxt:getChildByName("txt"):setColor(ccc3(0, 0, 0))
    missionNameTxt:getChildByName("txt"):setAroundColor(ccc3(189, 255, 255))

    local ChapterName = aCell:getChildByName("lbl_encouraging_the_end")
    ChapterName:setTag(12)
    ChapterName:setVisible(false)
    
    local btnReview = aCell:getChildByName("btn")
    btnReview:setTag(18)
    btnReview:getChildByName("txt_guild_66"):getChildByName("txt"):setTag(10)
    btnReview:getChildByName("txt_guild_66"):getChildByName("txt"):setString(getTextByKey("storyReview_title"))
    btnReview:getChildByName("txt_guild_66"):getChildByName("txt"):setColor(ccc3(255, 255, 255))
    btnReview:getChildByName("txt_guild_66"):getChildByName("txt"):setAroundColor(ccc3(181, 89, 0))
    local btnReviewPic = btnReview:getChildByName("normal")
    btnReviewPic:setTag(13)
    -- btnReviewPic:setVisible(false)

    local bitmapLabel = BitmapText:create("", "common/stage_name.fnt")
    bitmapLabel:setPosition(ccp(ChapterName:getPositionX(), ChapterName:getPositionY()))
    bitmapLabel:setScale(0.8)
    bitmapLabel:setAnchorPoint( ccp(0.0, 0.5) )
    aCell:addChildAt(bitmapLabel, 10)
    bitmapLabel:setTag(-20)
    
  end
  
  function MissionTableViewRenderer:setData(rawCocosObj, index)
    local aCell = self:getChildByTag(rawCocosObj, -1001)

    local bitmapLabel = aCell:getChildByTag(-20)
    tolua.cast(bitmapLabel, "CCLabelBMFont")
    local aBattleChapterConfig = MetaManager.battle_chapter[(self.list[index + 1])]
    bitmapLabel:setString(Localization:getInstance():getText(aBattleChapterConfig.chapterNameKey))
    
    local chapterInfo = self.list[index + 1]
    local chapterNumStr
    local sectionNumStr
    if index + 1 < 10 then
      sectionNumStr = "0"..tostring(index + 1)
    else
      sectionNumStr = tostring(index + 1)
    end
    if cityId - 9 < 10 then
      chapterNumStr = "0"..tostring(cityId - 9)
    else
      chapterNumStr = tostring(cityId - 9)
    end
    setNodeText(aCell:getChildByTag(10):getChildByTag(10), getTextByKey("storyReview_chapter"..chapterNumStr))

    local txtSection = Localization:getInstance():getText("storyReview_section" , {num = sectionNumStr})
    setNodeText(aCell:getChildByTag(11):getChildByTag(10), txtSection)

    local newMissionID =  CountryManager:sharedManager():getNewMissionID()
    newMissionID = string.sub(newMissionID , 1 , 4)
    if tonumber(newMissionID) <= (self.list[index + 1]) and tonumber(newMissionID) ~= 1000 then
      aCell:getChildByTag(18):setVisible(false)
    else
      aCell:getChildByTag(18):setVisible(true)
    end
    
  end
  
  local function onListItemTouch(evt)
    local aIndex = evt.data + 1
    local aCell = self.missionTableView:cellAtIndex(aIndex - 1)
    local posInCell = aCell:convertToNodeSpace(evt.globalPosition)
    local btnReview = aCell:getChildByTag(-1001):getChildByTag(18)
    local picBtnReview = btnReview:getChildByTag(13)
    if ViewControlUtil.isInAreaPic(posInCell, btnReview, picBtnReview) and btnReview:isVisible() then
      self:reviewStory(missionIds[aIndex])
    end
  end
  
  local renderer = MissionTableViewRenderer.new(720, 154)
  local aTableView = TableView:create(renderer, 
      EliteManager.DICT.TB_MISSION_WIDTH + 14, 
      EliteManager.DICT.TB_MISSION_HEIGHT,
      cellTag,
      buttonTag,
      CCScale9Sprite:create("pic/scroll.png"), 
      CCScale9Sprite:create("pic/scroll.png"),
      missionIds
    )
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
  aTableView:setPosition(ccp(EliteManager.DICT.TB_MISSION_POSX - 12, EliteManager.DICT.TB_MISSION_POSY))
  
  return aTableView
end

function StoryReviewMainPanel:disableUserInterface()
  if not self.tempLayer then
    self.tempLayer = LayerColor:create()
    self.tempLayer:changeWidthAndHeight(visibleSize.width, visibleSize.height)
    self.tempLayer:setOpacity(255)
    self.targetInfoPanel = self.tempLayer
    self:addChild(self.tempLayer)
    if self.cityTableView then
      self.cityTableView:setTouchEnabled(false)
    end
    if self.missionTableView then
      self.missionTableView:setTouchEnabled(false)
    end
  end
end

function StoryReviewMainPanel:enableUserInterface()
  if self.tempLayer then
    self.tempLayer:removeFromParentAndCleanup(true)
    self.tempLayer = nil
    self.targetInfoPanel = nil
    if self.cityTableView then
      self.cityTableView:setTouchEnabled(true)
    end
    if self.missionTableView then
      self.missionTableView:setTouchEnabled(true)
    end
  end
end

function StoryReviewMainPanel:reviewStory(aChapterId)
  self:disableUserInterface()

  local storyList = {}
  local previousDialogId
  local previoudDialogOpportunity
  for _, aConfig in ipairs(MetaManager.event_conversation) do
    if tonumber(string.sub(tostring(aConfig.dialogId), 1, string.len(tostring(aChapterId)))) == aChapterId then
      if (not previousDialogId) or (previousDialogId ~= aConfig.dialogId) or (not previoudDialogOpportunity) or (previoudDialogOpportunity ~= aConfig.activeOpportunity) then
        previousDialogId = aConfig.dialogId
        previoudDialogOpportunity = aConfig.activeOpportunity
        local temp = {}
        temp.dialogId = previousDialogId
        temp.dialogOpportunity = previoudDialogOpportunity
        table.insert(storyList, temp)
      end
    end
  end

  local storyIndex = 0
  local reviewOneStory
  local originalGuideCallback = getGuideFinishCallback()
  local function storyReviewFinished()
    local function fadeFinished()
      RegisterOnGuideFinishCallback(originalGuideCallback)
      self:enableUserInterface()
    end
    local arr = CCArray:create()
    arr:addObject(CCFadeOut:create(0.3))
    arr:addObject(CCCallFunc:create(fadeFinished))
    self.tempLayer:runAction(CCSequence:create(arr))
    CanonPlayBackgroundMusic("music/background.mp3", true)
  end
  local function addTransitionTip()
    if Get_ShareData("Skip_Story") == 1 then
      Set_ShareData("Skip_Story", 0)
      storyReviewFinished()
      return
    end
    local loadingSprite = FlashSprite:create("EVO2/Loading_lvbu")
    math.randomseed(os.time())
    local rand = math.random(3) - 1
    loadingSprite:changeAnimation(rand)
    local loadingSprite_co = CocosObject.new(loadingSprite)
    self:addChild(loadingSprite_co)
    local delayEntry
    local function delayCallback( dt )
      loadingSprite_co:removeFromParentAndCleanup(true)
      CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(delayEntry)
      delayEntry = nil
      reviewOneStory()
    end
    delayEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(delayCallback, 0.3, false)
  end
  reviewOneStory = function()
    storyIndex = storyIndex + 1
    local aStory = storyList[storyIndex]
    if not aStory then
      storyReviewFinished()
      return
    end
    RegisterOnGuideFinishCallback(addTransitionTip)
    Run_Script_Using_Dialog_Index(aStory.dialogId, aStory.dialogOpportunity)
  end
  local arr = CCArray:create()
  arr:addObject(CCFadeIn:create(0.3))
  arr:addObject(CCCallFunc:create(reviewOneStory))
  self.tempLayer:runAction(CCSequence:create(arr))
end

function StoryReviewMainPanel:initLayer()
  StoryReviewMainPanel.super.initLayer(self)

	local builder = LayoutBuilder:createWithContentsOfFile(EliteManager.DICT.RESOURCE_FILE)
  self.mainUI = builder:build("elite_page_elite_list")
  self:addChild(self.mainUI)
  
  -- content layer
  self.contentLayer = Layer:create()
  self.contentLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(self.contentLayer)
  
  self.maxMissionId = EliteManager.getMaxMissionId()
  self.maxFinishedEliteId = EliteManager.getMaxFinishedEliteId()
  self.selectedCityId = CountryManager:sharedManager():getLastOpenedCountryID()
  if not isPassFirstChapter() then
    self.selectedCityId = self.selectedCityId - 1
  end

  self.cityTableView = self:createCityTableView()
  self.contentLayer:addChild(self.cityTableView)
  self.missionTableView = self:createMissionTableView(self.selectedCityId)
  self.contentLayer:addChild(self.missionTableView)
  
end

function StoryReviewMainPanel:dispose()
  StoryReviewMainPanel.super.dispose(self)
end

function StoryReviewMainPanel:doEnterAnimation()
  local RunningScene = Director:sharedDirector():getRunningScene()
  RunningScene:setTouchEnabled(false)

  self:startEnterAnimation()
end


function StoryReviewMainPanel:startEnterAnimation()
  local function enterActionFinished()
    self.aniCount = self.aniCount - 1
    if self.aniCount == 0 then
      local RunningScene = Director:sharedDirector():getRunningScene()
      RunningScene:setTouchEnabled(true)
    end
  end
  
  local function getCCSequence()
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
    arr:addObject(CCCallFunc:create(enterActionFinished))
    
    return CCSequence:create(arr)
  end
  
  self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
  self.contentLayer:setPositionX(self.contentLayer:getPositionX() - visibleSize.width)

  self.aniCount = 2
  self.mainUI:runAction(getCCSequence())
  self.contentLayer:runAction(getCCSequence())
end

function StoryReviewMainPanel:doExitAnimation(callBackFunc)
  local RunningScene = Director:sharedDirector():getRunningScene()
  RunningScene:setTouchEnabled(false)

  self:startExitAnimation(callBackFunc)
end


function StoryReviewMainPanel:startExitAnimation(callBackFunc)  
  local function exitActionFinished()
    self.aniCount = self.aniCount - 1
    if self.aniCount == 0 then
      local RunningScene = Director:sharedDirector():getRunningScene()
      RunningScene:setTouchEnabled(true)

      if callBackFunc then
        callBackFunc()
      end
    end
  end
  
  local function getCCSequence()
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
    arr:addObject(CCCallFunc:create(exitActionFinished))
    
    return CCSequence:create(arr)
  end
  self.aniCount = 2
  self.mainUI:runAction(getCCSequence())
  self.contentLayer:runAction(getCCSequence())
end
