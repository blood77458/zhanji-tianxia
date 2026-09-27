require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.Button"
require "hecore.display.Sprite"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "hecore.ui.TableView"
require "canon.models.CountryManager"
require "canon.scene.CitySelectScene"
require "canon.scene.ChapterMapScene"
require "canon.canonUtils"
require "canon.request.BuyMissionCompleteCountRequest"
require "canon.request.GainChapterFinishRewardRequest"
require "canon.manager.BagCalcManager"
require "canon.panel.MapLoadingPanel"
require "canon.panel.MissionUnlockContentPanel"
require "canon.panel.StageSweepPanel"
require "canon.panel.SweepResultPanel"
require "canon.scene.StoryReviewScene"

--
-- CityMainScene
--

local chapterTable_width = 720
local chapterTable_height = 380
local chapterTable_posX = 0
local chapterTable_posY = 660
local chapterItem_width = 720
local chapterItem_height = 380
local bg_start_posY = 169

local chapterNameTable_width = 990
local chapterNameTable_height = 121
local chapterNameTable_posX = -135
local chapterNameTable_posY = 650
local chapterNameItem_width = 330
local chapterNameItem_height = 121

local missionTable_width = 702--684
local missionTable_height = 536
local missionItem_height = 126
local missionTable_posX = 18
local missionTable_posY = 120
local missionItem_actualHeight = 122

local enter_animation_duration = 0.3
local original_scroll_duration = enter_animation_duration
local enter_animation_cell_duration = 0.15
local reset_chapter_offset_duration = 0.1

local visibleSize = CCDirector:sharedDirector():getVisibleSize()


CityMainScene = class(BaseUIScene)

function CityMainScene:ctor()
	self.curSceneEnum = SceneEnum.CityMainScene
end

function CityMainScene:create(argv)
  local s = CityMainScene.new()
  if argv then 
      self.argv = argv 
  else
      self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
  self.notResetCurrentSelectedItem = self.argv.params.notReset
  self.nomccomplete = self.argv.params.nomccomplete
  self.newMissionId = self.argv.params.newMissionId
  self.showAllFinishedPanel = self.argv.params.showAllFinishedPanel
  s:initScene()
  return s
end

function indexOfObject(aList, aObject)
  for i = 1, #aList do
    if aList[i] == aObject then
      return i
    end
  end
  return 0
end

local function cityButtonSelected(evt)
  BaseUIScene.replaceScene(evt.context, CitySelectScene)
end

--[[
local function leftArrowBtnSelected(evt)
  local aCityMainScene = evt.context
  
  local aIndex = indexOfObject(aCityMainScene.chapterList, aCityMainScene.currentChapterID)
  aIndex = aIndex - 1
  if aIndex > 0 then
    print("leftArrowBtnSelected")
    aCityMainScene:removeArrowListener()
    aCityMainScene.chapterTableView:setContentOffsetInDuration(ccp(-chapterTable_width * (aIndex - 1), 0), 0.3)
  end
end

local function rightArrowBtnSelected(evt)
  local aCityMainScene = evt.context
  
  local aIndex = indexOfObject(aCityMainScene.chapterList, aCityMainScene.currentChapterID)
  aIndex = aIndex + 1
  if aIndex <= #aCityMainScene.chapterList then
    print("rightArrowBtnSelected")
    aCityMainScene:removeArrowListener()
    aCityMainScene.chapterTableView:setContentOffsetInDuration(ccp(-chapterTable_width * (aIndex - 1), 0), 0.3)
  end
end
]]
function CityMainScene:onInit()
	BaseUIScene.initBackGround(self)
  
  CountryManager:sharedManager():checkMissionComplete()
  
  if not self.notResetCurrentSelectedItem then
    CountryManager:sharedManager():resetCurrentSelectedItem()
  end
  self.currentCountryID = CountryManager:sharedManager().selectedCountryID
  self.chapterList = self:getCurrentValidChapterIDList()
  self.currentChapterID = CountryManager:sharedManager().selectedChapterID
  self.missionIDs = self:getCurrentValidMissionIDList()
  self.currentMissionID = CountryManager:sharedManager().selectedMissionID
  self.nextNewMissionID = CountryManager:sharedManager():getNewMissionID()
  --print(self.currentChapterID)
  --print(table.tostring(self.missionIDs))
  self.title = CountryManager:sharedManager():getCountryName(self.currentCountryID)
  --print(self.currentCountryID .. "_" .. self.currentChapterID .. "_" .. self.currentMissionID)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/chapterSelect_new.json")
  local ui = builder:build("chapterSelect")
  self:addChild(ui)
  self.cityMainUI = ui
  
  self.uiGroup1 = ui:getChildByName("chapterSelect_bg_chapterSelect_map")
  self.uiGroup2 = ui:getChildByName("chapterSelect_btn_chapterSelect_cityName")
  self.uiGroup3 = ui:getChildByName("chapterSelect_pattern_equipEnhance_bottom")
  self.uiGroup4 = ui:getChildByName("btn_chapterSelect_review_plot")
  self.uiGroup5 = ui:getChildByName("bg_genera1")
  
  local aBattleChapterConfig = MetaManager.battle_chapter[self.currentChapterID]
  local aTempList = aBattleChapterConfig.missionIdList:split("|")
  self.bossMissionID = tonumber(aTempList[#aTempList], 10)
  --[[
  local stageNameLabel = self.uiGroup7:getChildByName("txt_levelName") 
  changeLabelToBMFont(stageNameLabel, Localization:getInstance():getText(aBattleChapterConfig.chapterNameKey), "common/stage_name.fnt")
]]
  
  local aCityPic = self.uiGroup1:getChildByName("bg_chapterSelect")
  local aBattleCountryConfig = MetaManager.battle_country[self.currentCountryID]
  local aCityTexture = CCTextureCache:sharedTextureCache():addImage("map/others/" .. aBattleCountryConfig.cityBGID .. ".png")
  aCityPic:setDisplayFrame(CCSpriteFrame:createWithTexture(aCityTexture, CCRect(0, bg_start_posY, aCityTexture:getContentSize().width, chapterTable_height / 1.4648)))
  aCityPic:setScale(1.4648)
  local aCityLabel = self.uiGroup2:getChildByName("font")
  aCityLabel:setString(Localization:getInstance():getText("changeCity"))
  local citySelectButton = Button:create(self.uiGroup2)
  citySelectButton:addEventListener(Events.kStart, cityButtonSelected, self)
  self.uiGroup4:getChildByName("txt"):setString(Localization:getInstance():getText("storyReview_title"))

  local function onReviewStroy( evt )
    self:replaceScene(StoryReviewScene)
  end

  local citySelectButton = Button:create(self.uiGroup4, true)
  citySelectButton:addEventListener(Events.kStart, onReviewStroy, self)


  if CityMainScene.CheckStoryReviewBtnEnable() then
    citySelectButton:setEnable(true)
  else
    citySelectButton:setEnable(false)
  end

  
  self:addChapterTableView(ui)
  
  self:addMissionTableView(ui)
  
  self.cellScriptList = {}
  self.chapterNameList = {}
  table.insert(self.chapterNameList, 0)
  for _, v in ipairs(self.chapterList) do
    table.insert(self.chapterNameList, v)
  end
  table.insert(self.chapterNameList, 0)
  self:addChapterNameTableView(ui)
  
  local function checkCellPos()
    for i = 1, #self.chapterNameList - 2 do
      local aCell = self.chapteNamerTableView:cellAtIndex(i)
      if aCell then
        local lua_cell = aCell:getChildByTag(1024)
        local world_pos = aCell:getParent():convertToWorldSpace(ccp(aCell:getPositionX() + chapterNameItem_width / 2.0, aCell:getPositionY() + chapterNameItem_height / 2.0))
        local active_display = lua_cell:getChildByTag(-10)
        local inactive_display = lua_cell:getChildByTag(-11)
        local bitmapLabel = lua_cell:getChildByTag(-20)
        tolua.cast(active_display, "CCSprite")
        if (world_pos.x > visibleSize.width / 2.0 - chapterNameItem_width) and (world_pos.x < visibleSize.width / 2.0 + chapterNameItem_width) then
          --print(1)
          active_display:setScale(0.7 + (chapterNameItem_width - math.abs(world_pos.x - visibleSize.width / 2.0)) / chapterNameItem_width * 0.3)
          active_display:setOpacity(255 * (chapterNameItem_width - math.abs(world_pos.x - visibleSize.width / 2.0)) / chapterNameItem_width)
          inactive_display:setScale(0.7 + (chapterNameItem_width - math.abs(world_pos.x - visibleSize.width / 2.0)) / chapterNameItem_width * 0.3)
          bitmapLabel:setScale(0.8 * (0.7 + (chapterNameItem_width - math.abs(world_pos.x - visibleSize.width / 2.0)) / chapterNameItem_width * 0.3))
          bitmapLabel:setPosition(ccp(chapterNameItem_width / 2.0, chapterNameItem_height / 2.0 - 14 * (math.abs(world_pos.x - visibleSize.width / 2.0)) / chapterNameItem_width))
        else
          --print(2)
          active_display:setScale(0.7)
          active_display:setOpacity(0)
          inactive_display:setScale(0.7)
          bitmapLabel:setScale(0.8 * 0.7)
          bitmapLabel:setPosition(ccp(chapterNameItem_width / 2.0, chapterNameItem_height / 2.0 - 14))
        end
      end
    end
  end
  self.cell_script_handler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(checkCellPos,0,false)
  
  if self.argv.enterScene == "BattleScene" and (not self.nomccomplete) and self.newMissionId then
    local fspt = FlashSprite:create("map/others/flashPack/mcomplete")
    fspt:changeAnimation(0)
    fspt:setLoop(false)
    local fspt_co = CocosObject.new(fspt)
    self:addChild(fspt_co)
  end
  
	BaseUIScene.onInit(self)
  
end

function CityMainScene:onExit()
  if self.cell_script_handler then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.cell_script_handler)
    self.cell_script_handler = nil
  end
end

function CityMainScene:getCurrentValidMissionIDList()
  local result = {}
  local aCountryManager = CountryManager:sharedManager()
  local aList = aCountryManager:getAllMissionIDsWithChapterID(self.currentChapterID)
  assert(self.currentChapterID <= aCountryManager:getLastOpenedChapterID(), "CityMainScene:getCurrentValidChapterIDList assert failed")
  if self.currentChapterID < aCountryManager:getLastOpenedChapterID() then
    result = aList
  else
    for _, aValue in ipairs(aList) do
      if aValue <= aCountryManager:getLastOpenedMissionID() then
        table.insert(result, aValue)
      else
        break
      end
    end
    if #result == 0 then
      table.insert(result, aList[1])
    end
  end
  
  local aCompleteInfo = aCountryManager:getChapterCompleteInfo(self.currentChapterID)
  if not (aCompleteInfo.finish and aCompleteInfo.finishReward) then
    aCompleteInfo.cellType = "reward"
    table.insert(result, 1, aCompleteInfo)
  end
  
  return result
end

function CityMainScene:getCurrentValidChapterIDList()
  local aList = CountryManager:sharedManager():getAllChapterIDsWithCountryID(self.currentCountryID)
  assert(self.currentCountryID <= CountryManager:sharedManager():getLastOpenedCountryID(), "CityMainScene:getCurrentValidChapterIDList assert failed")
  if self.currentCountryID < CountryManager:sharedManager():getLastOpenedCountryID() then
    return aList
  end
  local anotherList = {}
  for _, aValue in ipairs(aList) do
    if aValue <= CountryManager:sharedManager():getLastOpenedChapterID() then
      table.insert(anotherList, aValue)
    else
      break
    end
  end
  return anotherList
end

function CityMainScene:addChapterTableView(ui)
  self.chapterTableView = self:createChapterTableView()
  ui:addChildAt(self.chapterTableView, 10)
  self.chapterTableView:reloadData()
  local aIndex = indexOfObject(self.chapterList, self.currentChapterID)
  self.chapterTableView:setContentOffsetInDuration(ccp(-chapterTable_width * (aIndex - 1), 0), original_scroll_duration)
  self.chapterTableView:setTouchEnabled(false)
end

function CityMainScene:addChapterNameTableView(ui)
  self.chapteNamerTableView = self:createChapterNameTableView()
  ui:addChildAt(self.chapteNamerTableView, 11)
  self.chapteNamerTableView:reloadData()
  local aIndex = indexOfObject(self.chapterNameList, self.currentChapterID)
  self.chapteNamerTableView:setContentOffsetInDuration(ccp(-chapterNameItem_width * (aIndex - 1 - 1), 0), original_scroll_duration)
end

function CityMainScene:addMissionTableView(ui)
  self.missionTableView = self:createMissionTableView()
  ui:addChild(self.missionTableView)
  self.missionTableView:reloadData()
  self:resetMisstionTableViewOffset()
end

function CityMainScene:resetMisstionTableViewOffset()
  local originalOffset = self.missionTableView:getContentOffset()
  local aIndex = indexOfObject(self.missionIDs, self.currentMissionID)
  if (type(self.missionIDs[1]) == "table") and (self.missionIDs[1].cellType == "reward") and self.missionIDs[1].finish then
    aIndex = 1
  end
  local newOffsetY = originalOffset.y + missionItem_height * (aIndex - 1)
  local maxOffsetY = originalOffset.y + missionItem_height * #self.missionIDs - missionTable_height
  if newOffsetY > maxOffsetY then
    newOffsetY = maxOffsetY
  end
  if newOffsetY < originalOffset.y then
    newOffsetY = originalOffset.y
  end
  self.missionTableView:setContentOffset(ccp(0, newOffsetY), false)
  self.originalOffsetY = originalOffset.y
  self.newOffsetY = newOffsetY
  self.animatedCells = nil
end

function CityMainScene:resetWithChapterIndex(aChapterIndex)
  self.chapterTableView:setContentOffsetInDuration(ccp(-chapterTable_width * (aChapterIndex + 1 - 1), 0), original_scroll_duration - 0.1)
  
  if self.chapterList[aChapterIndex + 1] == self.currentChapterID then
    return
  end
  
  CountryManager:sharedManager():selectChapterID(self.chapterList[aChapterIndex + 1])
  self.currentChapterID = CountryManager:sharedManager().selectedChapterID
  self.currentMissionID = CountryManager:sharedManager().selectedMissionID
  local aBattleChapterConfig = MetaManager.battle_chapter[self.currentChapterID]
  local aTempList = aBattleChapterConfig.missionIdList:split("|")
  self.bossMissionID = tonumber(aTempList[#aTempList], 10)
  
  local function enterFinished()
    
  end
  
  local function exitFinished()
    self.missionTableView:removeFromParentAndCleanup(true)
    self.missionIDs = self:getCurrentValidMissionIDList()
    self:addMissionTableView(self.cityMainUI)
    self:generateAnimatedCells()
    local aDuration
    if #self.animatedCells == 1 then
      aDuration = enter_animation_duration - enter_animation_cell_duration
    else
      aDuration = (enter_animation_duration - enter_animation_cell_duration) / (#self.animatedCells - 1)
    end
    for aIndex, aCell in ipairs(self.animatedCells) do
      aCell:setPositionX(aCell:getPositionX() - visibleSize.width)
      local arr = CCArray:create()
      arr:addObject(CCDelayTime:create(aDuration * (aIndex - 1)))
      arr:addObject(CCMoveBy:create(enter_animation_cell_duration, ccp(visibleSize.width, 0)))
      if aIndex == #self.animatedCells then
        arr:addObject(CCCallFunc:create(enterFinished))
      end
      aCell:runAction(CCSequence:create(arr))
    end
  end
  
  self.newOffsetY = self.missionTableView:getContentOffset().y
  self:generateAnimatedCells()
  local aDuration
    if #self.animatedCells == 1 then
      aDuration = enter_animation_duration - enter_animation_cell_duration
    else
      aDuration = (enter_animation_duration - enter_animation_cell_duration) / (#self.animatedCells - 1)
    end
  for aIndex, aCell in ipairs(self.animatedCells) do
    local arr = CCArray:create()
    arr:addObject(CCDelayTime:create(aDuration * (aIndex - 1)))
    arr:addObject(CCMoveBy:create(enter_animation_cell_duration, ccp(-visibleSize.width, 0)))
    if aIndex == #self.animatedCells then
      arr:addObject(CCCallFunc:create(exitFinished))
    end
    aCell:runAction(CCSequence:create(arr))
  end
  
end

function CityMainScene:createChapterTableView()
  local aCityMainScene = self
  local ChapterTableViewRenderer = class(TableViewRenderer)
  function ChapterTableViewRenderer:ctor(width, height)
    self.list = aCityMainScene.chapterList
  end
  function ChapterTableViewRenderer:buildCell(container)
    
  end
  function ChapterTableViewRenderer:setData( rawCocosObj, index )
    local originalCard3_co = rawCocosObj:getChildByTag(-20)
    if originalCard3_co then
      originalCard3_co:removeFromParentAndCleanup(true)
    end
    
    local allMissionIDs = CountryManager:getAllMissionIDsWithChapterID(self.list[index + 1])
    local aLastMissionID = allMissionIDs[#allMissionIDs]
    local aBattleMonsterGroupConfig
    for _, aConfig in pairs(MetaManager.battle_monster_group) do
      if (math.modf(aConfig.id / 100) == aLastMissionID) and (aConfig.id % 10 == 2) then
        aBattleMonsterGroupConfig = aConfig
        break
      end
    end
    local aCardID = MetaManager.battle_monster[tonumber(aBattleMonsterGroupConfig.monsterIdList:split("|")[1], 10)].cardId
    local card3_co = Sprite:createWithSpriteFrame( getHalfWideCardSpriteFrame(aCardID ) )
    card3_co:setPosition( ccp(chapterItem_width/2, chapterItem_height/2))
    rawCocosObj:addChild(card3_co.refCocosObj)
    card3_co:setTag(-20)
    card3_co:dispose()
  end
  local renderer = ChapterTableViewRenderer.new(chapterTable_width, chapterItem_height)
  local aTableView = TableView:create(renderer, chapterTable_width, chapterTable_height)
  aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  --aTableView:setPageEnabled(true)
  --aTableView:addEventListener(DisplayEvents.kSelectItem, onSelectItem , self)
  aTableView:setPosition(ccp(chapterTable_posX, chapterTable_posY))
  return aTableView
end

function CityMainScene:createChapterNameTableView()
  local cellTag = 1024
  local buttonTag = {}
  local function onSelectItem( evt )
    local aIndex = evt.globalPosition
    if aIndex >= (#self.chapterNameList - 3) then
      aIndex = #self.chapterNameList - 3
    end
    self:resetWithChapterIndex(aIndex)
  end
  local aCityMainScene = self
  local ChapterNameTableViewRenderer = class(TableViewRenderer)
  function ChapterNameTableViewRenderer:ctor(width, height)
    self.list = aCityMainScene.chapterNameList
  end
  function ChapterNameTableViewRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile("scene/chapterSelect_new.json")
    local aCell = builder:build("icon_chapterSelect")
    container:addChild(aCell)
    aCell:setTag(cellTag)
    
    local active_display = aCell:getChildByName("btn_select_chapter_active")
    active_display:setTag(-10)
    local original_x = active_display:getPositionX()
    local original_y = active_display:getPositionY()
    active_display:setAnchorPoint(ccp(0.5, 0.1))
    active_display:setPosition(ccp(original_x + active_display:getContentSize().width / 2.0, original_y - active_display:getContentSize().height * (1 - 0.1)))
    local inactive_display = aCell:getChildByName("btn_select_chapter_inactive")
    inactive_display:setTag(-11)
    original_x = inactive_display:getPositionX()
    original_y = inactive_display:getPositionY()
    inactive_display:setAnchorPoint(ccp(0.5, 0.1))
    inactive_display:setPosition(ccp(original_x + inactive_display:getContentSize().width / 2.0, original_y - inactive_display:getContentSize().height * (1 - 0.1)))
    local name_label = aCell:getChildByName("txt_active")
    name_label:setVisible(false)
    
    local bitmapLabel = BitmapText:create("", "common/stage_name.fnt")
    bitmapLabel:setPosition(ccp(chapterNameItem_width / 2.0, chapterNameItem_height / 2.0))
    bitmapLabel:setScale(0.8)
    aCell:addChildAt(bitmapLabel, 10)
    bitmapLabel:setTag(-20)
  end
  function ChapterNameTableViewRenderer:setData( rawCocosObj, index )
    local aCell = self:getChildByTag(rawCocosObj, cellTag)
    local bitmapLabel = aCell:getChildByTag(-20)
    tolua.cast(bitmapLabel, "CCLabelBMFont")
    local active_display = aCell:getChildByTag(-10)
    local inactive_display = aCell:getChildByTag(-11)
    if (index == 0) or (index == (#self.list - 1)) then
      active_display:setVisible(false)
      inactive_display:setVisible(false)
      bitmapLabel:setVisible(false)
    else
      active_display:setVisible(true)
      inactive_display:setVisible(true)
      bitmapLabel:setVisible(true)
      local aBattleChapterConfig = MetaManager.battle_chapter[(self.list[index + 1])]
      bitmapLabel:setString(Localization:getInstance():getText(aBattleChapterConfig.chapterNameKey))--[[
      bitmapLabel = CCLabelBMFont:create(Localization:getInstance():getText(aBattleChapterConfig.chapterNameKey), "common/stage_name.fnt")
      bitmapLabel:setPosition(ccp(chapterNameItem_width / 2.0, chapterNameItem_height / 2.0))
      bitmapLabel:setScale(0.8)
      aCell:addChild(bitmapLabel, 10)
      bitmapLabel:setTag(-20)]]
    end
  end
  local renderer = ChapterNameTableViewRenderer.new(chapterNameItem_width, chapterNameItem_height)
  local aTableView = TableView:create(renderer, chapterNameTable_width, chapterNameTable_height)
  aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  aTableView:setPageEnabled(true)
  aTableView:addEventListener(DisplayEvents.kSelectItem, onSelectItem , self)
  aTableView:setPosition(ccp(chapterNameTable_posX, chapterNameTable_posY))
  return aTableView
end

function CityMainScene:generateAnimatedCells()
  self.animatedCells = {}
  for i = 1, #self.missionIDs do
    if (self.newOffsetY - self.originalOffsetY) < i * missionItem_height and (self.newOffsetY - self.originalOffsetY + missionTable_height + missionItem_height) > i * missionItem_height then
      table.insert(self.animatedCells, self.missionTableView:cellAtIndex(i - 1))
    end
  end
end

function CityMainScene:createMissionTableView()
  local cellTag = 1024
  local buttonTag = {{-10, -12},{-11, -15},{-12, -15}}
  local aCityMainScene = self
  local MissionTableViewRenderer = class(TableViewRenderer)
  function MissionTableViewRenderer:ctor(width, height)
    self.list = aCityMainScene.missionIDs
  end
  function MissionTableViewRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile("scene/chapterSelect_new.json")
    local aCell = builder:build("chapterSelect_selectLevelItem")
    container:addChild(aCell)
    aCell:setTag(cellTag)
    
    local aRewardList = aCell:getChildByName("chapterSelect_rewardList")
    local aStageList = aCell:getChildByName("chapterSelect_stageList")
    local aStageBossList = aCell:getChildByName("chapterSelect_stageList_boss")
    
    aRewardList:setTag(-10)
    local aCardDisplay = aRewardList:getChildByName("chapterSelect_normal_card_small_sb")
    aCardDisplay:setVisible(false)
    aCardDisplay:setTag(-10)
    local aRewardDes = aRewardList:getChildByName("chapterSelect_selectLevel_reword_txt")
    aRewardDes:setTag(-11)
    aRewardDes:setVisible(false)
    local aTempNamePos = aRewardDes:getPosition()
    aRewardDes = aRewardDes:getChildByName("txt_chapterSelect_progress_txt")
    local aFontSize = aRewardDes:getFontSize()
    local aFontName = aRewardDes:getFontName()
    local aNewTempNameLabel = TextField:create(Localization:getInstance():getText("chapterPresent"), aFontName, aFontSize, nil, kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
    aNewTempNameLabel:setAnchorPoint(ccp(0, 1.0))
    aNewTempNameLabel:setPosition(ccp(aTempNamePos.x, aTempNamePos.y))
    aNewTempNameLabel:setColor(ccc3(0,0,0))
    aRewardList:addChild(aNewTempNameLabel)
    aNewTempNameLabel:setTag(-20)
    aRewardDes = aRewardList:getChildByName("chapterSelect_selectLevel_reword2_txt")
    aRewardDes:setTag(-13)
    aRewardDes:setVisible(false)
    local aCardNamePosX = aNewTempNameLabel:getPosition().x + aNewTempNameLabel:getTexture():getContentSize().width
    aRewardDes = aRewardDes:getChildByName("txt_chapterSelect_progress2_txt")
    local aCardFontSize = aRewardDes:getFontSize()
    local aCardFontName = aRewardDes:getFontName()
    local aNewCardNameLabel = TextField:create("example", aCardFontName, aCardFontSize, nil, kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
    aNewCardNameLabel:setAnchorPoint(ccp(0, 1.0))
    aNewCardNameLabel:setPosition(ccp(aCardNamePosX, aTempNamePos.y - (aNewTempNameLabel:getTexture():getContentSize().height - aNewCardNameLabel:getTexture():getContentSize().height) / 2.0))
    aRewardList:addChild(aNewCardNameLabel)
    aNewCardNameLabel:setTag(-21)
    local aButtonDisplay = aRewardList:getChildByName("chapterSelect_BtnSelectLevelReword")
    aButtonDisplay:setTag(-12)
    local aButtonLabel = aButtonDisplay:getChildByName("font")
    aButtonLabel:setTag(-10)
    aButtonLabel:setString(Localization:getInstance():getText("getChapterPresent"))
    local aButtonPic = aButtonDisplay:getChildByName("btn")
    aButtonPic:setTag(-11)
    aButtonPic = aButtonDisplay:getChildByName("btn_inactive")
    aButtonPic:setTag(-12)
    
    aStageList:setTag(-11)
    aCardDisplay = aStageList:getChildByName("chapterSelect_selectLevelCard_sb")
    aCardDisplay:setVisible(false)
    aCardDisplay:setTag(-10)
    aStageList:getChildByName("chapterSelect_bg_card"):setVisible(false)
    local aMissionName = aStageList:getChildByName("chapterSelect_txt_stageList_eventList_desc")
    aMissionName:setTag(-11)
    aMissionName = aMissionName:getChildByName("txt_stageList_eventList_desc")
    aMissionName:setTag(-10)
    local aTempName = aStageList:getChildByName("chapterSelect_txt_stageList_eventList_name")
    aTempName:setTag(-12)
    aTempName:setVisible(false)
    local aTempNamePos = aTempName:getPosition()
    aTempName = aTempName:getChildByName("txt_stageList_eventList_name")
    local aFontSize = aTempName:getFontSize()
    local aFontName = aTempName:getFontName()
    local aNewTempNameLabel = TextField:create(Localization:getInstance():getText("possibleGet"), aFontName, aFontSize, nil, kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
    aNewTempNameLabel:setAnchorPoint(ccp(0, 1.0))
    aNewTempNameLabel:setPosition(ccp(aTempNamePos.x, aTempNamePos.y))
    aNewTempNameLabel:setColor(ccc3(0,0,0))
    aStageList:addChild(aNewTempNameLabel)
    aNewTempNameLabel:setTag(-20)
    --[[
    aTempName = aTempName:getChildByName("txt_stageList_eventList_name")
    aTempName:setTag(-10)
    aTempName:setDimensions(CCSizeMake(0, aTempName:getDimensions().height))
    aTempName:setString(Localization:getInstance():getText("possibleGet"))]]
    local aCardName = aStageList:getChildByName("chapterSelect_selectLevel_reword_name_txt")
    aCardName:setTag(-13)
    aCardName:setVisible(false)
    local aCardNamePosX = aNewTempNameLabel:getPosition().x + aNewTempNameLabel:getTexture():getContentSize().width
    aCardName = aCardName:getChildByName("txt_chapterSelect_progress_txt")
    local aCardFontSize = aCardName:getFontSize()
    local aCardFontName = aCardName:getFontName()
    local aNewCardNameLabel = TextField:create("example", aCardFontName, aCardFontSize, nil, kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
    aNewCardNameLabel:setAnchorPoint(ccp(0, 1.0))
    aNewCardNameLabel:setPosition(ccp(aCardNamePosX, aTempNamePos.y - (aNewTempNameLabel:getTexture():getContentSize().height - aNewCardNameLabel:getTexture():getContentSize().height) / 2.0))
    aStageList:addChild(aNewCardNameLabel)
    aNewCardNameLabel:setTag(-21)
    --[[
    aCardName = aCardName:getChildByName("txt_chapterSelect_progress_txt")
    aCardName:setTag(-10)
    aCardName:setDimensions(CCSizeMake(0, aCardName:getDimensions().height))]]
    local aNewTag = aStageList:getChildByName("chapterSelect_icon_stageList_new_sb")
    aNewTag:setTag(-14)
    aButtonDisplay = aStageList:getChildByName("chapterSelect_btn_stageList")
    aButtonDisplay:setTag(-15)
    aButtonPic = aButtonDisplay:getChildByName("btn")
    aButtonPic:setTag(-10)
    local aCoinPic = aButtonDisplay:getChildByName("coin")
    aCoinPic:setTag(-11)
    local aShine = aButtonDisplay:getChildByName("btn_light_upyellow")
    aShine:setTag(-12)
    local challangeLabel = aButtonDisplay:getChildByName("font")
    challangeLabel:setTag(-13)
    --challangeLabel:setString(Localization:getInstance():getText("challenge"))
    local aChallengeNumsLabel = aStageList:getChildByName("chapterSelect_selectLevel_fightNumber_txt")
    aChallengeNumsLabel:setTag(-16)
    aChallengeNumsLabel = aChallengeNumsLabel:getChildByName("txt_chapterSelect_progress_txt")
    aChallengeNumsLabel:setTag(-10)
    
    aStageBossList:setTag(-12)
    aCardDisplay = aStageBossList:getChildByName("chapterSelect_selectLevelCard_sb")
    aCardDisplay:setVisible(false)
    aCardDisplay:setTag(-10)
    aStageBossList:getChildByName("chapterSelect_bg_card"):setVisible(false)
    local aMissionName = aStageBossList:getChildByName("chapterSelect_txt_stageList_eventList_desc")
    aMissionName:setTag(-11)
    aMissionName = aMissionName:getChildByName("txt_stageList_eventList_desc")
    aMissionName:setTag(-10)
    local aTempName = aStageBossList:getChildByName("chapterSelect_txt_stageList_eventList_name")
    aTempName:setTag(-12)
    aTempName:setVisible(false)
    local aTempNamePos = aTempName:getPosition()
    aTempName = aTempName:getChildByName("txt_stageList_eventList_name")
    local aFontSize = aTempName:getFontSize()
    local aFontName = aTempName:getFontName()
    local aNewTempNameLabel = TextField:create(Localization:getInstance():getText("possibleGet"), aFontName, aFontSize, nil, kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
    aNewTempNameLabel:setAnchorPoint(ccp(0, 1.0))
    aNewTempNameLabel:setPosition(ccp(aTempNamePos.x, aTempNamePos.y))
    --aNewTempNameLabel:setColor(ccc3(255,255,255))
    aStageBossList:addChild(aNewTempNameLabel)
    aNewTempNameLabel:setTag(-20)
    --[[
    aTempName = aTempName:getChildByName("txt_stageList_eventList_name")
    aTempName:setTag(-10)
    aTempName:setDimensions(CCSizeMake(0, aTempName:getDimensions().height))
    aTempName:setString(Localization:getInstance():getText("possibleGet"))]]
    local aCardName = aStageBossList:getChildByName("chapterSelect_selectLevel_reword_name_txt")
    aCardName:setTag(-13)
    aCardName:setVisible(false)
    local aCardNamePosX = aNewTempNameLabel:getPosition().x + aNewTempNameLabel:getTexture():getContentSize().width
    aCardName = aCardName:getChildByName("txt_chapterSelect_progress_txt")
    local aCardFontSize = aCardName:getFontSize()
    local aCardFontName = aCardName:getFontName()
    local aNewCardNameLabel = TextField:create("example", aCardFontName, aCardFontSize, nil, kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
    aNewCardNameLabel:setAnchorPoint(ccp(0, 1.0))
    aNewCardNameLabel:setPosition(ccp(aCardNamePosX, aTempNamePos.y - (aNewTempNameLabel:getTexture():getContentSize().height - aNewCardNameLabel:getTexture():getContentSize().height) / 2.0))
    aStageBossList:addChild(aNewCardNameLabel)
    aNewCardNameLabel:setTag(-21)
    --[[
    aCardName = aCardName:getChildByName("txt_chapterSelect_progress_txt")
    aCardName:setTag(-10)
    aCardName:setDimensions(CCSizeMake(0, aCardName:getDimensions().height))]]
    local aNewTag = aStageBossList:getChildByName("chapterSelect_icon_stageList_new_sb")
    aNewTag:setTag(-14)
    aButtonDisplay = aStageBossList:getChildByName("chapterSelect_btn_stageList")
    aButtonDisplay:setTag(-15)
    aButtonPic = aButtonDisplay:getChildByName("btn")
    aButtonPic:setTag(-10)
    local aCoinPic = aButtonDisplay:getChildByName("coin")
    aCoinPic:setTag(-11)
    local aShine = aButtonDisplay:getChildByName("btn_light_upyellow")
    aShine:setTag(-12)
    local challangeLabel = aButtonDisplay:getChildByName("font")
    challangeLabel:setTag(-13)
    --challangeLabel:setString(Localization:getInstance():getText("challenge"))
    local aChallengeNumsLabel = aStageBossList:getChildByName("chapterSelect_selectLevel_fightNumber_txt")
    aChallengeNumsLabel:setTag(-16)
    aChallengeNumsLabel = aChallengeNumsLabel:getChildByName("txt_chapterSelect_progress_txt")
    aChallengeNumsLabel:setTag(-10)
    
  end
  function MissionTableViewRenderer:setData( rawCocosObj, index )
    local aCell = self:getChildByTag(rawCocosObj, cellTag)
    local aRewardList = aCell:getChildByTag(-10)
    local aStageList = aCell:getChildByTag(-11)
    local aStageBossList = aCell:getChildByTag(-12)
    local aBorder = aCell:getChildByTag(-21)
    if aBorder then
      aBorder:removeFromParentAndCleanup(true)
    end
    local icon = aCell:getChildByTag(-20)
    if icon then
      icon:removeFromParentAndCleanup(true)
    end
    if type(self.list[index + 1]) == "table" and self.list[index + 1].cellType then
      
      aRewardList:setVisible(true)
      aStageList:setVisible(false)
      aStageBossList:setVisible(false)
      
      local aRewardName = aRewardList:getChildByTag(-21)
      
      local aRare
      local aRewardNameString
      
      local aCardDisplay = aRewardList:getChildByTag(-10)
      if not self.list[index + 1].finish then
        aRewardList:getChildByTag(-12).ignoreTouch = true
        aRewardList:getChildByTag(-12):getChildByTag(-11):setVisible(false)
        aRewardList:getChildByTag(-12):getChildByTag(-12):setVisible(true)
      else
        aRewardList:getChildByTag(-12).ignoreTouch = false
        aRewardList:getChildByTag(-12):getChildByTag(-11):setVisible(true)
        aRewardList:getChildByTag(-12):getChildByTag(-12):setVisible(false)
      end
      
      local aBattleChapterConfig = MetaManager.battle_chapter[aCityMainScene.currentChapterID]
      if aBattleChapterConfig.rewardType == 5 then
        icon = getHeadIconCanonCardByMetaId(aBattleChapterConfig.rewardID)
        icon:setScale(0.7)
        aRare = tonumber(MetaManager.card_meta[aBattleChapterConfig.rewardID].rare, 10)
        aRewardNameString = Localization:getInstance():getText(MetaManager.card_meta[aBattleChapterConfig.rewardID].name) .. "x" .. aBattleChapterConfig.rewardNum
      elseif (aBattleChapterConfig.rewardType == 6) or (aBattleChapterConfig.rewardType == 7) then
        icon = CanonItem:create()
        icon:loadByMetaId(aBattleChapterConfig.rewardID)
        icon:setScale(0.6)
        if aBattleChapterConfig.rewardType == 6 then
          aRare = tonumber(MetaManager.equip_meta[aBattleChapterConfig.rewardID].quality, 10)
          aRewardNameString = Localization:getInstance():getText(MetaManager.equip_meta[aBattleChapterConfig.rewardID].name) .. "x" .. aBattleChapterConfig.rewardNum
        else
          aRare = tonumber(MetaManager.prop_meta[aBattleChapterConfig.rewardID].quality, 10)
          aRewardNameString = Localization:getInstance():getText(MetaManager.prop_meta[aBattleChapterConfig.rewardID].name) .. "x" .. aBattleChapterConfig.rewardNum
        end
      elseif aBattleChapterConfig.rewardType == 1 then
        icon = Sprite:create("common/CoinIcon_Mission.png")
        icon:setScale(0.75)
        aBorder = Sprite:create("Item/border/equipBorder1.png")
        aBorder:setScale(0.7)
        aRare = 0
        aRewardNameString = Localization:getInstance():getText("resource_silverCoin") .. "x" .. aBattleChapterConfig.rewardNum
      elseif aBattleChapterConfig.rewardType == 2 then
        icon = Sprite:create("common/GemIcon_Mission.png")
        icon:setScale(0.75)
        aBorder = Sprite:create("Item/border/equipBorder1.png")
        aBorder:setScale(0.7)
        aRare = 0
        aRewardNameString = Localization:getInstance():getText("resource_goldCoin") .. "x" .. aBattleChapterConfig.rewardNum
      else
        -- print("aBattleChapterConfig.rewardType = " .. aBattleChapterConfig.rewardType)
        -- print("aBattleChapterConfig.rewardID = " .. aBattleChapterConfig.rewardID)
        -- print("aBattleChapterConfig.rewardNum = " .. aBattleChapterConfig.rewardNum)
        --碎片等
        local params = {}
        params.sourceDisplay = aCardDisplay
        --params.sourceSizes = {80,80}
        params.isShowStar = false--显示稀有度星星
        icon = CanonGoodIcon.createGoodIcon(aBattleChapterConfig.rewardType, aBattleChapterConfig.rewardID, aBattleChapterConfig.rewardNum, params)
        aRewardNameString = CanonGoodIcon.getGoodName(aBattleChapterConfig.rewardType, aBattleChapterConfig.rewardID, aBattleChapterConfig.rewardNum, params)
        aRare = CanonGoodIcon.getGoodRare(aBattleChapterConfig.rewardType, aBattleChapterConfig.rewardID)
      end
      if icon then
        icon:setPosition( ccp(aCardDisplay:getPositionX(), aCardDisplay:getPositionY()) )
        aCell:addChild(icon.refCocosObj, 10)
        icon:setTag(-20)
        icon:dispose()
      end
      if aBorder then
        aBorder:setPosition( ccp(aCardDisplay:getPositionX(), aCardDisplay:getPositionY()) )
        aCell:addChild(aBorder.refCocosObj, 10)
        aBorder:setTag(-21)
        aBorder:dispose()
      end
      
      local aColor
      if aRare == 1 then
        aColor = ccc3(51,51,51)
      elseif aRare == 2 then
        aColor = ccc3(0,153,0)
      elseif aRare == 3 then
        aColor = ccc3(0,153,255)
      elseif aRare == 4 then
        aColor = ccc3(153,51,204)
      elseif aRare == 5 then
        aColor = ccc3(252,126,3)
      elseif aRare == 6 then
        aColor = ccc3(204,51,51)
      elseif aRare == 7 then
        aColor = ccc3(250,191,7)
      elseif aRare == 0 then
        aColor = ccc3(0,0,0)
      end
      if aColor then
        setNodeColor(aRewardName, aColor)
      end
      setNodeText(aRewardName, aRewardNameString)
    else
      if aCityMainScene.bossMissionID == self.list[index + 1] then
        aRewardList:setVisible(false)
        aStageList:setVisible(false)
        aStageBossList:setVisible(true)
        aStageList = aStageBossList
      else
        aRewardList:setVisible(false)
        aStageList:setVisible(true)
        aStageBossList:setVisible(false)
      end
      
      local aCardDisplay = aStageList:getChildByTag(-10)
      local aBattleId
      local aMonsterGroupId = tonumber(self.list[index + 1] .. "02")
      for _, aMonsterGroupConfig in pairs(MetaManager.battle_monster_group) do
        if aMonsterGroupId == tonumber(aMonsterGroupConfig.id) then
          aBattleId = tonumber(aMonsterGroupConfig.monsterIdList:split("|")[1], 10)
          break
        end
      end
      local aBattleMonsterConfig = MetaManager.battle_monster[aBattleId]
      local aCardMetaConfig = MetaManager.card_meta[tonumber(aBattleMonsterConfig.cardId, 10)]
      icon = getHeadIconCanonCardByMetaId(tonumber(aBattleMonsterConfig.cardId, 10))
      icon:setPosition( ccp(aCardDisplay:getPositionX(), aCardDisplay:getPositionY()) )
      icon:setScale(0.7)
      aCell:addChild(icon.refCocosObj, 10)
      icon:setTag(-20)
      icon:dispose()
      local aMissionName = aStageList:getChildByTag(-11):getChildByTag(-10)
      setNodeText(aMissionName, CountryManager:sharedManager():getMissionName(self.list[index + 1]))
      
      local possibleGet = false
      for _, aBattleEventBattleConfig in pairs(MetaManager.battle_event_battle) do
        if (tonumber(aBattleEventBattleConfig.missionId, 10) == self.list[index + 1]) and (tonumber(aBattleEventBattleConfig.missionType, 10) == 2) then
          if tonumber(aBattleEventBattleConfig.leaderDropCardProb, 10) > 0 then
            possibleGet = true
          end
          break
        end
      end
      local aTempName = aStageList:getChildByTag(-20)
      local aCardName = aStageList:getChildByTag(-21)
      if possibleGet then
        aTempName:setVisible(true)
        aCardName:setVisible(true)
        if aCardMetaConfig.evolutionLevel == 1 then
          setNodeText(aCardName, Localization:getInstance():getText(aCardMetaConfig.name))
        else
          local tailNum = math.mod(aCardMetaConfig.id, 10)
          local aNewCardId = aCardMetaConfig.id - tailNum + 1
          setNodeText(aCardName, Localization:getInstance():getText(MetaManager.card_meta[aNewCardId].name))
        end
        local aColor
        if aCardMetaConfig.rare == 1 then
          aColor = ccc3(51,51,51)
        elseif aCardMetaConfig.rare == 2 then
          aColor = ccc3(0,153,0)
        elseif aCardMetaConfig.rare == 3 then
          aColor = ccc3(0,153,255)
        elseif aCardMetaConfig.rare == 4 then
          aColor = ccc3(153,51,204)
        elseif aCardMetaConfig.rare == 5 then
          aColor = ccc3(252,126,3)
        elseif aCardMetaConfig.rare == 6 then
          aColor = ccc3(204,51,51)
        elseif aCardMetaConfig.rare == 7 then
          aColor = ccc3(250,191,7)
        end
        setNodeColor(aCardName, aColor)
      else
        aTempName:setVisible(false)
        aCardName:setVisible(false)
      end
      local aChallengeNumsLabel = aStageList:getChildByTag(-16):getChildByTag(-10)
      local aCurrentTime = CountryManager:sharedManager():getMissionCurrentBattleTime(self.list[index + 1])
      local aLimitTime = CountryManager:sharedManager():getMissionBattleLimit(self.list[index + 1])
      setNodeText(aChallengeNumsLabel, string.format("(%d/%d)", aCurrentTime, aLimitTime))
      local aNewTag = aStageList:getChildByTag(-14)
      local aButtonDisplay = aStageList:getChildByTag(-15)
      local aCoinPic = aButtonDisplay:getChildByTag(-11)
      local aShine = aButtonDisplay:getChildByTag(-12)
      local challangeLabel = aButtonDisplay:getChildByTag(-13)
      if self.list[index + 1] == aCityMainScene.nextNewMissionID then
        setNodeText(challangeLabel, Localization:getInstance():getText("challenge"))
        aNewTag:setVisible(true)
        aShine:setVisible(true)
        local array = CCArray:create()
        array:addObject(CCFadeOut:create(0.5))
        array:addObject(CCFadeIn:create(0.5))
        aShine:runAction(CCRepeatForever:create(CCSequence:create(array)))
      else
        setNodeText(challangeLabel, Localization:getInstance():getText("stage_stageClear"))
        aNewTag:setVisible(false)
        aShine:setVisible(false)
        aShine:stopAllActions()
      end
      
      if (aCurrentTime < aLimitTime) or (CountryManager:sharedManager().missionIDInChallenge == self.list[index + 1]) then
        aButtonDisplay.timeLimit = false
        aCoinPic:setVisible(false)
      else
        aButtonDisplay.timeLimit = true
        aCoinPic:setVisible(true)
      end
    end
  end
  local function onListItemTouch( evt )
    if not self.missionTableView.refCocosObj then
	return
    end
    local aIndex = evt.data + 1
    local newCell = self.missionTableView:cellAtIndex(aIndex - 1)
    local cellType
    local buttonDisplay
    local buttonBg
    if type(self.missionIDs[aIndex]) == "table" and self.missionIDs[aIndex].cellType then
      cellType = "reward"
      local aRewardList = newCell:getChildByTag(cellTag):getChildByTag(-10)
      buttonDisplay = aRewardList:getChildByTag(-12)
      buttonBg = buttonDisplay:getChildByTag(-11)
      if not buttonBg:isVisible() then
        return
      end
    else
      cellType = "mission"
      local aStageList = newCell:getChildByTag(cellTag):getChildByTag(-11)
      buttonDisplay = aStageList:getChildByTag(-15)
      buttonBg = buttonDisplay:getChildByTag(-10)
    end
    
    --print(buttonDisplay:getPositionX(), buttonDisplay:getPositionY())
    local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
    --print(posInCell.x, posInCell.y)
    if posInCell.x > buttonDisplay:getPositionX() and
      posInCell.x < (buttonDisplay:getPositionX() + buttonBg:getContentSize().width) and
      posInCell.y > (buttonDisplay:getPositionY() - buttonBg:getContentSize().height) and
      posInCell.y < buttonDisplay:getPositionY() then
      if cellType == "mission" then
        self:challengeButtonTapped(self.missionIDs[aIndex])
      else
        if self.missionIDs[aIndex].finish then
          self:gainChapterFinishReward()
        else
          
        end
      end
    end
  end
  local renderer = MissionTableViewRenderer.new(missionTable_width, missionItem_height)
  local aTableView = TableView:create(renderer, missionTable_width, missionTable_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , aTableView)
  aTableView:setPosition(ccp(missionTable_posX, missionTable_posY))
  return aTableView
end

function CityMainScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function CityMainScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  --
  
  CanonPlayBackgroundMusic("music/background.mp3", true)
end

function CityMainScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self:generateAnimatedCells()
  local aDuration
  if #self.animatedCells == 1 then
    aDuration = enter_animation_duration - enter_animation_cell_duration
  else
    aDuration = (enter_animation_duration - enter_animation_cell_duration) / (#self.animatedCells - 1)
  end
  for aIndex, aCell in ipairs(self.animatedCells) do
    aCell:setPositionX(aCell:getPositionX() - visibleSize.width)
    local arr = CCArray:create()
    arr:addObject(CCDelayTime:create(aDuration * (aIndex - 1)))
    arr:addObject(CCMoveBy:create(enter_animation_cell_duration, ccp(visibleSize.width, 0)))
    aCell:runAction(CCSequence:create(arr))
  end
  
  self.uiGroup1:setPositionX(self.uiGroup1:getPositionX() - visibleSize.width)
  self.uiGroup1:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  self.chapterTableView:setPositionX(self.chapterTableView:getPositionX() - visibleSize.width)
  self.chapterTableView:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  self.chapteNamerTableView:setPositionX(self.chapteNamerTableView:getPositionX() - 990)
  self.chapteNamerTableView:runAction(CCMoveBy:create(enter_animation_duration, ccp(990, 0)))
  self.uiGroup2:setPositionX(self.uiGroup2:getPositionX() + visibleSize.width)
  self.uiGroup2:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  self.uiGroup3:setPositionX(self.uiGroup3:getPositionX() - visibleSize.width)
  self.uiGroup4:setPositionX(self.uiGroup4:getPositionX() - visibleSize.width)
  self.uiGroup4:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  self.uiGroup5:setPositionX(self.uiGroup5:getPositionX() - visibleSize.width)
  self.uiGroup5:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.uiGroup3:runAction(CCSequence:create(arr))
end

function CityMainScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  --
  
  if self.newMissionId == 100110 then
--	ExeNewGuide(GuideConfig.kRisk3) --Not Run Here
  end
  
  if self.showAllFinishedPanel then
    self:showAllFinishPanel()
  else
    self:checkUnlockContent()
  end
end

function CityMainScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function CityMainScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function CityMainScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.newOffsetY = self.missionTableView:getContentOffset().y
  self:generateAnimatedCells()
  local aDuration
  if #self.animatedCells == 1 then
    aDuration = enter_animation_duration - enter_animation_cell_duration
  else
    aDuration = (enter_animation_duration - enter_animation_cell_duration) / (#self.animatedCells - 1)
  end
  for aIndex, aCell in ipairs(self.animatedCells) do
    local arr = CCArray:create()
    arr:addObject(CCDelayTime:create(aDuration * (aIndex - 1)))
    arr:addObject(CCMoveBy:create(enter_animation_cell_duration, ccp(-visibleSize.width, 0)))
    aCell:runAction(CCSequence:create(arr))
  end
  
  self.uiGroup1:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  self.chapterTableView:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  self.chapteNamerTableView:runAction(CCMoveBy:create(enter_animation_duration, ccp(-990, 0)))
  self.uiGroup2:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  self.uiGroup4:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  self.uiGroup5:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.uiGroup3:runAction(CCSequence:create(arr))
end

function CityMainScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function CityMainScene:back()
  if self.argv.enterScene == "ChapterMapScene" then
    self:replaceScene(ChapterMapScene)
  else
    self:replaceScene(MainMenuScene)
  end
end

function CityMainScene:enableUserInterface()
  self.chapteNamerTableView:setTouchEnabled(true)
  self.missionTableView:setTouchEnabled(true)
end

function CityMainScene:disableUserInterface()
  self.chapteNamerTableView:setTouchEnabled(false)
  self.missionTableView:setTouchEnabled(false)
end

function CityMainScene:panelDismiss()
  self:enableUserInterface()
end

function CityMainScene:setTableViewsEnabledInner(aEnabled)
  self.chapteNamerTableView:setTouchEnabled(aEnabled)
  self.missionTableView:setTouchEnabled(aEnabled)
end

function CityMainScene:showLevelLimitPanel(aLevelLimit)
  self:disableUserInterface()
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kMapChallengeLevelLimit, {levelLimit = aLevelLimit})
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function CityMainScene:showCannotBuyMissionCountPanel()
  self:disableUserInterface()
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kCannotBuyMissionCount, {})
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function CityMainScene:showTimeLimitPanel(aMissionId, aGoldNum, extraArgs)
  self:disableUserInterface()
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kMapChallengeTimeLimit, {missionId = aMissionId, glodNum = aGoldNum, extraArgs = extraArgs})
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function CityMainScene:challengeButtonTapped(aMissionId)
  local GameInitData = DataManager.getGameInitData()
  local aBattleMissionConfig = MetaManager.battle_mission[aMissionId]
  if tonumber(aBattleMissionConfig.levelMin, 10) > GameInitData.sharkUser.level then
    self:showLevelLimitPanel(tonumber(aBattleMissionConfig.levelMin, 10))
    return
  end
  
  if CountryManager:sharedManager():getMaxFinishedMissionID() < aMissionId then
    self:checkStageChallenge(aMissionId)
  else
    self:checkStageSweep(aMissionId)
  end
end

function CityMainScene:checkStageSweep(aMissionId)
  local aCurrentTime = CountryManager:sharedManager():getMissionCurrentBattleTime(aMissionId)
  local aLimitTime = CountryManager:sharedManager():getMissionBattleLimit(aMissionId)
  if (aCurrentTime >= aLimitTime) and (CountryManager:sharedManager().missionIDInChallenge ~= aMissionId) then
    self:challangeLimitForMissionId(aMissionId, {sweep = true})
  else
    self:showStageSweepPanel(aMissionId)
  end
end

function CityMainScene:checkStageChallenge(aMissionId)
  if aMissionId == CountryManager:sharedManager().selectedMissionID then
    self:replaceScene(ChapterMapScene)
  else
    local aCurrentTime = CountryManager:sharedManager():getMissionCurrentBattleTime(aMissionId)
    local aLimitTime = CountryManager:sharedManager():getMissionBattleLimit(aMissionId)
    if (aCurrentTime >= aLimitTime) and (CountryManager:sharedManager().missionIDInChallenge ~= aMissionId) then
      self:challangeLimitForMissionId(aMissionId)
    else
      self:checkBagFullForChallenge(aMissionId)
    end
  end
end

function CityMainScene:challangeLimitForMissionId(aMissionId, extraArgs)
  local maxResetNum = MetaManager.vip_setting[DataManager.getCurrUser().vipLevel].extraMissionPerDay
  if DailyDataManager.getResetMissionNum() >= maxResetNum then
    self:showCannotBuyMissionCountPanel()
  else
    local aBattleMissionConfig = MetaManager.battle_mission[aMissionId]
    self:showTimeLimitPanel(aMissionId, aBattleMissionConfig.battleWinPrice, extraArgs)
  end
end

function CityMainScene:energyLimitForMissionId(aMissionId, extraArgs)
  local hasEnergyProp, energyPropList = BagCalcManager.getEnergyPropList()
  if hasEnergyProp then
    self:showUseEnergyProptPanel(energyPropList)
  else
    self:showEnergyLimitPanel()
  end
end

function CityMainScene:showResetSweepTimePanel(extraArgs)
  local coolDownLeftTime = DataManager.GameMetaData.battleSettingConfig.clearMissionConfig.coolDownTime - (TimeUtil.getServerTimeSeconds() - CountryManager:sharedManager().countryData.lastClearTime)
  if coolDownLeftTime < 0.01 then
    self:sweepStage(extraArgs)
  else
    self:disableUserInterface()
    local gemNeeded = math.modf(coolDownLeftTime / 300)
    if math.mod(coolDownLeftTime, 300) > 0.01 then
      gemNeeded = gemNeeded +  1
    end
    gemNeeded =  gemNeeded * DataManager.GameMetaData.battleSettingConfig.clearMissionConfig.resetCoolDownFiveMinsCost
    extraArgs.gemNeeded = gemNeeded
    local aPanel = MessageBoxPanel:create(self, MessageBoxType.kResetCoolDownUseGem, {extraArgs = extraArgs})
    self:addChild(aPanel)
    aPanel:scaleIn()
  end
end

function CityMainScene:readyToResetCoolDownUseGem(extraArgs)
  if CalculationManager.calcComplex_getGemsNow() >= extraArgs.gemNeeded then
    local function resetClearTimeSucceed(event)
      local gemCount = 0
      if event.data.gemRequisite and event.data.gemRequisite.amount then
        gemCount = event.data.gemRequisite.amount
      end
      RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -gemCount})
      CountryManager:sharedManager().countryData.lastClearTime = 0
      self:sweepStage(extraArgs)
    end
    local function resetClearTimeFailed(event)
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
      self.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    end
    
    local params = {}
    local request = ResetClearTimeRequest.new(params, rpc.SendingPriority.kHigh)
    request:addEventListener(RequestNotifyEnum.ResetClearTimeSucceed, resetClearTimeSucceed)
    request:addEventListener(RequestNotifyEnum.ResetClearTimeFailed, resetClearTimeFailed)
    request:start()
  else
    self:disableUserInterface()
    local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
    self:addChild(aPanel)
    aPanel:scaleIn()
    --[[
    local aPanel = MessageBoxPanel:create(self, MessageBoxType.kGemLimit)
    self:addChild(aPanel)
    aPanel:scaleIn()
    ]]
  end
end

function CityMainScene:sweepStage(extraArgs)
  local function clearMissionSucceed(event)
    CountryManager:sharedManager().countryData.lastClearTime = TimeUtil.getServerTimeSeconds()
    CountryManager:sharedManager():consumeMissionChallengeCount(extraArgs.missionId, extraArgs.clearRounds)
    local currentOffset = self.missionTableView:getContentOffset().y
    self.missionTableView:reloadData()
    self.missionTableView:setContentOffset(ccp(0, currentOffset), false)
    RewardManager:getReward({{itemType = ResourceEnum.ENERGY, amount = -extraArgs.clearRounds * DataManager.GameMetaData.battleSettingConfig.clearMissionConfig.roundConsumeEnergy}})
    for _, aClearMissionReward in ipairs(event.data.clearMissionRewards) do
      RewardManager:getReward(aClearMissionReward.rewards)
    end
    local mergedMissionRewards = {}
    for _, aClearMissionReward in ipairs(event.data.clearMissionRewards) do
      local aMergedMissionReward = {}
      aMergedMissionReward.round = aClearMissionReward.round
      aMergedMissionReward.rewards = {}
      local aRewardType
      local aRewardMetaId
      local aReward
      for _, aTempReward in ipairs(aClearMissionReward.rewards) do
        if (aRewardType == aTempReward.itemType) and (aRewardMetaId == aTempReward.metaId) then
          aReward.amount = aReward.amount + 1
        else
          aRewardType = aTempReward.itemType
          aRewardMetaId = aTempReward.metaId
          aReward = aTempReward
          table.insert(aMergedMissionReward.rewards, aReward)
        end
        
      end
      table.insert(mergedMissionRewards, aMergedMissionReward)
    end
    self:disableUserInterface()
    local aPanel = SweepResultPanel:create(self, mergedMissionRewards)
    self:addChild(aPanel)
    aPanel:scaleIn()
  end
  local function clearMissionFailed(event)
    if event.data.retCode == 710461 then
      self:showSweepInCoolDownPanel()
    elseif event.data.retCode == 710463 then
      self:showSweepRoundLimitPanel()
    elseif event.data.retCode == 710514 then
      self:energyLimitForMissionId()
    else
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
      self.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    end
  end
  --print(extraArgs.missionId .. "__" .. extraArgs.routeId .. "__" .. extraArgs.clearRounds)
  local params = {missionId = extraArgs.missionId, routeId = extraArgs.routeId, clearRounds = extraArgs.clearRounds}
  local request = ClearMissionRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.ClearMissionSucceed, clearMissionSucceed)
  request:addEventListener(RequestNotifyEnum.ClearMissionFailed, clearMissionFailed)
  request:start()
end

function CityMainScene:showSweepInCoolDownPanel()
  self:disableUserInterface()
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kSweepInCoolDown)
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function CityMainScene:showSweepRoundLimitPanel()
  self:disableUserInterface()
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kSweepRoundLimit)
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function CityMainScene:showUseEnergyProptPanel(energyPropList)
  local function callback(aEnergyPropId)
    self:recoveryEnergy(aEnergyPropId)
  end
  local aPanel = EEPSupplyPanel:create(self, energyPropList, callback, true)
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function CityMainScene:recoveryEnergy(aEnergyPropId)
  local function usePropSucceed(event)
    local aReward = {
      {	itemType = ResourceEnum.PROP, metaId = aEnergyPropId, amount = -1
      },
      {	itemType = ResourceEnum.ENERGY,
        amount = event.data.rewards[1].amount,
      }
    }
    RewardManager:getReward(aReward)
    CanonPlayEffect("music/sfx_engly_lvup.wav")
    SuspensionLabel:showContent(self, getTextByKey("propInfo_energyReplenished"))
  end
  
  local function usePropFailed(event)
    if event.data.retCode == 712308 then
      CanonMessageBox:Show( getTextByKey("propInfo_energyFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
    elseif event.data.retCode == 712301 then
      local aPropMetaConfig = MetaManager.prop_meta[aEnergyPropId]
      CanonMessageBox:Show( getTextByKey("popup_noProp", {propname = Localization:getInstance():getText(aPropMetaConfig.name)}), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
    end
  end
  
  local request = UsePropRequest.new( {propId = aEnergyPropId, amount = 1}, rpc.SendingPriority.kHigh )
	request:addEventListener( RequestNotifyEnum.UsePropSucceed, usePropSucceed )
	request:addEventListener( RequestNotifyEnum.UsePropFailed, usePropFailed )
	request:start()
  
end

function CityMainScene:showEnergyLimitPanel()
  local function callback()
  end
  local aPanel = EENPSupplyPanel:create(self, {supplyType = EESupplyTypeEnum.Energy, callback = callback})
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function CityMainScene:showMainActorPanel()
  self.targetInfoPanel = MainActorPanel:create( self )
  PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
end

function CityMainScene:checkBagFullForChallenge(aMissionId)
  if BagCalcManager.isFull() then
    local aContent = Localization:getInstance():getText("bagFull_challenge")
    -- SuspensionLabel:showContent(self, aContent)
    NewPackageFullPanel:show()
  else
    self:challengeMap(aMissionId)
  end
end

function CityMainScene:challengeMap(aMissionId)
  if CountryManager:sharedManager().missionIDInChallenge ~= aMissionId then
    CountryManager:sharedManager():challangeMissionID(aMissionId)
  end
  self:replaceScene(ChapterMapScene)
end

function CityMainScene:gainChapterFinishReward()
  local function gainChapterFinishRewardSucceed(event)
    RewardManager:getReward(event.data.reward)
    CountryManager:sharedManager():receiveChapterFinishReward(self.currentChapterID)
    table.remove(self.missionIDs, 1)
    self.missionTableView:reloadData()
    self.originalOffsetY = self.originalOffsetY + missionItem_height
    local aReward = event.data.reward[1]
    local aName = ""
    local aAmount = aReward.amount
    if aReward.itemType == ResourceEnum.CARD then
      aName = Localization:getInstance():getText(MetaManager.card_meta[aReward.metaId].name)
    elseif aReward.itemType == ResourceEnum.EQUIP then
      aName = Localization:getInstance():getText(MetaManager.equip_meta[aReward.metaId].name)
    elseif aReward.itemType == ResourceEnum.PROP then
      aName = Localization:getInstance():getText(MetaManager.prop_meta[aReward.metaId].name)
    elseif aReward.itemType == ResourceEnum.COIN then
      aName = Localization:getInstance():getText("resource_silverCoin")
    elseif aReward.itemType == ResourceEnum.GEMS then
      aName = Localization:getInstance():getText("resource_goldCoin")
    else
      local params = {withoutAmount = true}--数量在后面统一加
      aName = CanonGoodIcon.getGoodName(aReward.itemType, aReward.metaId, aReward.amount, params)
    end
    self:showGainChapterRewardSucceedPanel(aName, aAmount)
  end
  
  local function gainChapterFinishRewardFailed(event)
    if event.data.retCode == 710407 then
      self:showCannotGainChapterRewardPanel()
    elseif event.data.retCode == 710408 then
      self:showAlreadyGainChapterRewardPanel()
    end
  end
  
  local params = {chapterId = self.currentChapterID}
  local request = GainChapterFinishRewardRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.GainChapterFinishRewardSucceed, gainChapterFinishRewardSucceed)
  request:addEventListener(RequestNotifyEnum.GainChapterFinishRewardFailed, gainChapterFinishRewardFailed)
  request:start()
end

function CityMainScene:readyToResetMissionCompleteCount(aMissionId, extraArgs)
  local aBattleMissionConfig = MetaManager.battle_mission[aMissionId]
  if tonumber(aBattleMissionConfig.battleWinPrice, 10) > CalculationManager.calcComplex_getGemsNow() then
    self:showGemLimitPanel()
    return
  end
  
  local function buyMissionCompleteCountSucceed(event)
    DailyDataManager.setResetMissionNum(DailyDataManager.getResetMissionNum() + 1)
    local aGem = CalculationManager.calcComplex_getGemsNow() - event.data.gems
    RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -aGem})
    CountryManager:sharedManager():resetMissionCompleteInfo(aMissionId)
    local currentOffset = self.missionTableView:getContentOffset().y
    self.missionTableView:reloadData()
    self.missionTableView:setContentOffset(ccp(0, currentOffset), false)
    if extraArgs and extraArgs.sweep then
      self:showStageSweepPanel(aMissionId)
    else
      self:checkBagFullForChallenge(aMissionId)
    end
  end
  local function buyMissionCompleteCountFailed(event)
    if event.data.retCode == 710513 then
      self:showGemLimitPanel()
    end
  end
  
  local params = {missionId = aMissionId}
  local request = BuyMissionCompleteCountRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.BuyMissionCompleteCountSucceed, buyMissionCompleteCountSucceed)
  request:addEventListener(RequestNotifyEnum.BuyMissionCompleteCountFailed, buyMissionCompleteCountFailed)
  request:start()
end

function CityMainScene:moveToIAPShop()
  self:replaceScene(ShopScene, {params = {tabIndex = TABLEVIEW_TAB_INDEX.CHARGE}})
end

function CityMainScene:showGainChapterRewardSucceedPanel(aName, aAmount)
  self:disableUserInterface()
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kGainChapterRewardSucceed, {itemName = aName, itemNum = aAmount})
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function CityMainScene:showCannotGainChapterRewardPanel()
  self:disableUserInterface()
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kCannotGainChapterReward)
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function CityMainScene:showAlreadyGainChapterRewardPanel()
  self:disableUserInterface()
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kAlreadyGainChapterReward)
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function CityMainScene:moveToElite()
  local argv = {enterScene = "CityMainScene", returnScene = CityMainScene, params = {}}
  self:replaceScene(EliteMissionScene, argv)
end

function CityMainScene:showGemLimitPanel()
  self:disableUserInterface()
  local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function CityMainScene:showAllFinishPanel()
  self:disableUserInterface()
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kMapAllFinish)
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function CityMainScene:showMissionUnlockContentPanel()
  local function unlockCallback(aSceneType)
    if aSceneType == UnlockReturnSceneEnum.kEliteScene then
      self:moveToElite()
    end
  end
  
  self:disableUserInterface()
  local aPanel = MissionUnlockContentPanel:create(self, unlockCallback, self.newMissionId)
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function CityMainScene:checkUnlockContent()
  if self.newMissionId and existInMissionUnlockConfig(self.newMissionId) then
    self:showMissionUnlockContentPanel()
  end
end

function CityMainScene:showStageSweepPanel(aMissionId)
  self:disableUserInterface()
  local args = {}
  args.missionId = aMissionId
  args.currentTime = CountryManager:sharedManager():getMissionCurrentBattleTime(aMissionId)
  args.limitTime = CountryManager:sharedManager():getMissionBattleLimit(aMissionId)
  local aPanel = StageSweepPanel:create(self, args)
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function CityMainScene:checkUserLevelUp()
  local function add_Exp_callback()
    local function checkUserLevelUpCallback()
    end
    UserLevelManager.checkUserLevelUp(checkUserLevelUpCallback)
  end
  local levelLabel = g_BaseUISceneObject:getChildByName("home_menu_title"):getChildByName("txt_home_lv"):getChildByName("font")
  local expLabel = g_BaseUISceneObject:getChildByName("home_menu_title"):getChildByName("txt_icon_playerExp_num"):getChildByName("font")
  local expBar = g_BaseUISceneExpBar[0]
  doUIActionForAddedExp(levelLabel, expLabel, expBar, add_Exp_callback)
end


-- 剧情回顾按钮是否可点
function CityMainScene.CheckStoryReviewBtnEnable()
  local btnEnable = false
  if CityMainScene.CheckMainStoryReviewBtnEnable() or CityMainScene.CheckActivityStoryReviewBtnEnable() then
    btnEnable = true
  end

  return btnEnable
end

-- 主线剧情按钮是否可点
function CityMainScene.CheckMainStoryReviewBtnEnable()
  local btnEnable = true
  local newMissionID = CountryManager:sharedManager():getNewMissionID()
  newMissionID = string.sub(newMissionID , 1 , 4)
  if tonumber(newMissionID) == 1001 then
    btnEnable = false
  end

  return btnEnable
end

-- 主线剧情按钮是否可点
function CityMainScene.CheckActivityStoryReviewBtnEnable()
  local btnEnable = false

  local GameInitData = DataManager.getGameInitData()
  if GameInitData and GameInitData.sharkSceneProcess and GameInitData.sharkSceneProcess.activitySceneChapterList then
    local activitySceneChapterList = GameInitData.sharkSceneProcess.activitySceneChapterList
    for i,v in ipairs(activitySceneChapterList) do
      if v.passAll then
        btnEnable = true
        break
      end
    end
  end

  return btnEnable
end