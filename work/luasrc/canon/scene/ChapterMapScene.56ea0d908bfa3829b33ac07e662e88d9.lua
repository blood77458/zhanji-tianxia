require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.display.Sprite"
require "hecore.ui.Button"
require "canon.models.CountryManager"
require "canon.customUI.TMXTiledMap"
require "canon.request.TriggerCoinEventRequest"
require "canon.request.TriggerExpEventRequest"
require "canon.request.TriggerBattleRequest"
require "canon.request.TriggerCardEventRequest"
require "canon.request.TriggerEmptyEventRequest"
require "canon.request.TriggerRandomEventRequest"
require "canon.models.RewardManager"
require "canon.scene.BattleScene"
require "canon.models.BattleManager"
require "canon.manager.BagCalcManager"
require "canon.script_and_guide.Script_And_Dialog"
require "canon.customUI.MapEventLabel"
require "canon.customUI.MapBossNameLabel"
require "canon.customUI.MapBossStarLabel"
require "canon.panel.EEPSupplyPanel"
require "canon.panel.EENPSupplyPanel"

LeadRoleDirection = {
	kUp = "up",
	kDown = "down",
	kLeft = "left",
	kRight = "right"
}

local map_radian = math.atan(0.5)
local duration_per_tile = 0.15
local step_per_event = 4
local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local card_original_width = 320
local card_original_height = 450
local card_scale_factor = 0.6
local box_scale_factor = 1.5
local lead_role_up_duration = 1.0
local lead_role_up_distance = 20
local map_offset_y = 50

local select_dir_animate_duration = 0.8
local select_dir_move_height = 10

local mission_des_stay_duration = 5.0
local mission_des_move_duration = 0.5
local progress_sprite_width = 442
local progress_duration = 0.3
local selectdir_z_order = 102
local leadrole_z_order = 103
local map_element_z_order = 101
local mark_move_distance = 30
local mark_move_duration = 0.8

local function kMapTouchBegin(evt)
  --print("____kMapTouchBegin")
  local aChapterScene = evt.context
  
  aChapterScene:moveCommandReceived()
end

local function kMapTouchMove(evt)
  
end

local function onMapTouchEnd(evt)
  
end

local function missionButtonSelected(evt)
  local aChapterScene = evt.context
  aChapterScene:disableUserInterface()
  
  aChapterScene:moveToCityMain()
end

local function moveButtonSelected(evt)
  local aChapterScene = evt.context
  
  aChapterScene:moveCommandReceived()
end

--
-- ChapterMapScene
--

ChapterMapScene = class(BaseUIScene)

function ChapterMapScene:ctor()
	self.curSceneEnum = SceneEnum.ChapterMapScene
end

function ChapterMapScene:create(argv)
  local s = ChapterMapScene.new()
  if argv then 
      self.argv = argv 
  else
      self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
  self.ignoreAction = self.argv.params.ignoreAction
  self.finishedType = self.argv.params.finishedType
  self.newMissionId = self.argv.params.newMissionId
  self.multiBossInfo = self.argv.params.multiBossInfo
  s:initScene()
  return s
end

local function dirButtonSelected(evt)
  local aChapterMapScene = evt.context
  local aButton = evt.target
  
  aChapterScene:moveCommandReceived(aButton.dirFlag)
end


function ChapterMapScene:onInit(  )
  BaseUIScene.initBackGround(self)
  self.exit_animation_duration = 0.2
  
  self.title = Localization:getInstance():getText(MetaManager.battle_chapter[CountryManager:sharedManager().selectedChapterID].chapterShow)
  --CCTexture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_RGBA4444)
  --SpriteUtil:addSpriteFramesWithFile("map/others/box.plist", "map/others/box.png")
  
  self.currentMissionId = CountryManager:sharedManager().selectedMissionID
  if self.currentMissionId == CountryManager:sharedManager().missionContext.missionId then
    self.currentRouteId = CountryManager:sharedManager().missionContext.routeId
    self.currentFinishedStep = CountryManager:sharedManager().missionContext.finishedStep
  else
    self.currentRouteId = 1
    self.currentFinishedStep = CountryManager:sharedManager():getStartStepWithMissionID(self.currentMissionId) - 1
  end
  
  self.markList = {}
  self.progress = nil
  self.progressHead = nil
  self.totalStepsOfCurrentMission = 0
  self.startStepsOfCurrentMission = 0
  self.userInterfaceEnabled = -1
  self.moveDirections = {}
  self.selectDir = nil
  self.moving = false
  self.dirSelectedIndex = 1
  self.passedTileNum = 0
  self.lastTouchLocation = nil
	self.currentPos = ccp(0, 0)		--主角当前的地图坐标
  local GameInitData = DataManager.getGameInitData()
  local aMainCardId = GameInitData.sharkUser.mainCardId
  local aSharkCards = GameInitData.sharkCards.sharkCards
  local aMainCardMetaId
  local oldName
  for _, aValue in pairs(aSharkCards) do
    if aValue.cardId == aMainCardId then
      aMainCardMetaId = CommonManager:changeAvatarByCardInfo( aValue )
      oldName = getTextByKey(MetaManager.card_meta[aValue.metaId].name)
      break
    end
  end
  self.leadRole = getBigCanonCardNoInfoByMetaId(aMainCardMetaId)
  self.leadRole:setContentSize(CCSizeMake(card_original_width, card_original_height))
  self.leadRole:setName(oldName)
  
  local circle = FlashSprite:create("EVO2/FZZZZ2")
  circle:changeAnimation(1)
  circle:setLoop(true)
  local circle_co = CocosObject.new(circle)
  circle_co:setPositionY(-circle_co:getGroupBounds().size.height)
  self.leadRole:addChildAt(circle_co, -1)
  
  self.leadRole:setAnchorPoint(ccp(0, 0.9))
  self.leadRole:setScale(card_scale_factor)
  self.tiledMap = TMXTiledMap:create(string.format("map/%d.tmx", CountryManager:sharedManager().selectedChapterID))
  self:updateEventIcons()
  
  local builder = LayoutBuilder:createWithContentsOfFile("scene/map_new.json")
  builder.useArtLabelTTF = true
  self.selectDirUI = builder:build("map_arrow_combine")
  self.tiledMap:addChildAt(self.selectDirUI, selectdir_z_order)
  --self.tiledMap:addChild(self.selectDirUI)
  local aDirButtonDisplay = self.selectDirUI:getChildByName("arrow_lu")
  self.luOriginalPosX = aDirButtonDisplay:getPositionX()
  self.luOriginalPosY = aDirButtonDisplay:getPositionY()
  local aButton = Button:create(aDirButtonDisplay)
  aButton.dirFlag = 1
  aButton:addEventListener(Events.kStart, dirButtonSelected, self)
  aDirButtonDisplay = self.selectDirUI:getChildByName("arrow_ru")
  self.ruOriginalPosX = aDirButtonDisplay:getPositionX()
  self.ruOriginalPosY = aDirButtonDisplay:getPositionY()
  aButton = Button:create(aDirButtonDisplay)
  aButton.dirFlag = 2
  aButton:addEventListener(Events.kStart, dirButtonSelected, self)
  aDirButtonDisplay = self.selectDirUI:getChildByName("arrow_rd")
  self.rdOriginalPosX = aDirButtonDisplay:getPositionX()
  self.rdOriginalPosY = aDirButtonDisplay:getPositionY()
  aButton = Button:create(aDirButtonDisplay)
  aButton.dirFlag = 3
  aButton:addEventListener(Events.kStart, dirButtonSelected, self)
  aDirButtonDisplay = self.selectDirUI:getChildByName("arrow_ld")
  self.ldOriginalPosX = aDirButtonDisplay:getPositionX()
  self.ldOriginalPosY = aDirButtonDisplay:getPositionY()
  aButton = Button:create(aDirButtonDisplay)
  aButton.dirFlag = 4
  aButton:addEventListener(Events.kStart, dirButtonSelected, self)
  self:hideSelectDirUI()
  
  self.tiledMap:addChildAt(self.leadRole, leadrole_z_order)
	self:setLeadRoleAndMapPosition()
  
  local aPos2 = self:convertFromCoorToMapOrthogonalSpace(self.currentPos)
  --local aLRPos2World = self.tiledMap:convertToWorldSpace(aPos2)
  self.selectDirUI:setPosition(aPos2)
  self.selectDirUI:setZOrder(self:getZorderFromMapPosition(self.currentPos))
  self.leadRole:setZOrder(self:getZorderFromMapPosition(self.currentPos))
	
  --self.tiledMap:addChild(self.leadRole)
  
  self.mapTouchLayer = Layer:create()
  self.mapTouchLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(self.mapTouchLayer)
	self:addChild(self.tiledMap)
  local anchorX = self.leadRole:getPositionX() / self.tiledMap:getContentSize().width
  local anchorY = self.leadRole:getPositionY() / self.tiledMap:getContentSize().height
  self.originalMapPosX = self.tiledMap:getPositionX()
  self.originalMapPosY = self.tiledMap:getPositionY()
  self.tiledMap:setAnchorPoint(ccp(anchorX, anchorY))
  self.tiledMap:setPosition(ccp(self.originalMapPosX + self.leadRole:getPositionX(), self.originalMapPosY + self.leadRole:getPositionY()))
  
  self:addClouds()
  
  local aDirectionLayer = self.tiledMap:layerNamed("direction")
  aDirectionLayer:setVisible(false)
  self.currentDirection = self:defaultDirectionWithCoordinate(self.currentPos)
  
  --CCTexture2D:setDefaultAlphaPixelFormat(kCCTexture2DPixelFormat_Default)
  
  self.mapUI = builder:build("map_panel")

  self:addChild(self.mapUI)
  
  local mission_des_bg = self.mapUI:getChildByName("story_bg")
  local mission_des = self.mapUI:getChildByName("txt_story")
  mission_des_bg:removeFromParentAndCleanup(true)
  mission_des:removeFromParentAndCleanup(true)
  --[[mission_des:getChildByName("txt"):setString(CountryManager:sharedManager():getChapterInfo(CountryManager:sharedManager().selectedChapterID))
  local function dismissMissionDes( dt )
    if self.dismissMissionDesScriptEntry then
      CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.dismissMissionDesScriptEntry)
      self.dismissMissionDesScriptEntry = nil
    end
    local function dismiss_mission_bg()
      mission_des_bg:setVisible(false)
    end
    local function dismiss_mission_des()
      mission_des:setVisible(false)
    end
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(mission_des_move_duration, ccp(0, mission_des_bg:getGroupBounds().size.height)))
    arr:addObject(CCCallFunc:create(dismiss_mission_bg))
    mission_des_bg:runAction(CCSequence:create(arr))
    arr = CCArray:create()
    arr:addObject(CCMoveBy:create(mission_des_move_duration, ccp(0, mission_des_bg:getGroupBounds().size.height)))
    arr:addObject(CCCallFunc:create(dismiss_mission_des))
    mission_des:runAction(CCSequence:create(arr))
	end
  self.dismissMissionDesScriptEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(dismissMissionDes, mission_des_stay_duration, false)]]
  
  local stageNameTempLabel = self.mapUI:getChildByName("txt_stage_name")
  local stageNameLabel = stageNameTempLabel:getChildByName("txt")
  if self.finishedType == ChapterEventFinishedType.kMissionFinished then
    local aBeforeMissionID = CountryManager:sharedManager():missionIDBeforeMissionID(self.currentMissionId)
    stageNameLabel:setString(CountryManager:sharedManager():getMissionName(aBeforeMissionID))
    local aPosX = stageNameLabel:getPositionX()
    local aPosY = stageNameLabel:getPositionY()
    local aWidth = stageNameLabel:getDimensions().width
    local aHeight = stageNameLabel:getDimensions().height
    local aFontName = stageNameLabel:getFontName()
    local aFontSize = stageNameLabel:getFontSize()
    local aFontColor = stageNameLabel:getColor()
    local aReplaceLabel = TextField:create(CountryManager:sharedManager():getMissionName(self.currentMissionId), aFontName, aFontSize, CCSizeMake(aWidth, aHeight), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
    aReplaceLabel:setAnchorPoint(ccp(0, 1))
    aReplaceLabel:setPosition(ccp(aPosX, aPosY - aHeight))
    aReplaceLabel:setColor(aFontColor)
    stageNameTempLabel:addChild(aReplaceLabel)
    aReplaceLabel:setOpacity(0)
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(1.0, ccp(0, aHeight)))
    arr:addObject(CCFadeIn:create(1.0))
    aReplaceLabel:runAction(CCSpawn:create(arr))
    
    arr = CCArray:create()
    arr:addObject(CCMoveBy:create(1.0, ccp(0, aHeight)))
    arr:addObject(CCFadeOut:create(1.0))
    stageNameLabel:runAction(CCSpawn:create(arr))
  else
    stageNameLabel:setString(CountryManager:sharedManager():getMissionName(self.currentMissionId))
  end
  
  
  self.mapUI:getChildByName("txt_stage_progress"):getChildByName("txt"):setString(Localization:getInstance():getText("levelProgress"))
  
  
  local aRate = (self.currentFinishedStep - self.startStepsOfCurrentMission + 1) / self.totalStepsOfCurrentMission
  local progress_string = string.format("%d%%", math.modf(aRate * 100))
  self.mapUI:getChildByName("font_stage_progress"):getChildByName("font"):setString(Localization:getInstance():getText(progress_string))
  
  local progress_sprite = self.mapUI:getChildByName("progress_bar")
  self.progress = ProgressBar:create(progress_sprite) 
  self.progress:setPercentage(aRate * 100)
  self.progressHead = self.mapUI:getChildByName("icon_map_player")
  self.progressHead:setPositionX(self.progressHead:getPositionX() + aRate * progress_sprite_width)
  
  local mission_select_display = self.mapUI:getChildByName("btn_change_stage")
  mission_select_display:getChildByName("txt"):setString(Localization:getInstance():getText("selectLevel"))
  self.mapUI:getChildByName("btn_change_stage"):getChildByName("txt"):setAroundColor(ccc3(0, 0, 0))
  local mission_select_button = Button:create(mission_select_display)
  mission_select_button:addEventListener(Events.kStart, missionButtonSelected, self)
  
  local move_display = self.mapUI:getChildByName("btn_go")
  local move_button = Button:create(move_display)
  move_button:addEventListener(Events.kStart, moveButtonSelected, self)
  
  local yellow_guide_panel = self.mapUI:getChildByName("q_yellow9_panel")
  yellow_guide_panel:setVisible(false)
  local red_guide_panel = self.mapUI:getChildByName("q_red9_panel")
  red_guide_panel:setVisible(false)
  
  local function checkAddParticle()
    if CountryManager:sharedManager():getMaxFinishedMissionID() < 100110 and self.currentFinishedStep >= 8 then
      yellow_guide_panel:setVisible(true)
      red_guide_panel:setVisible(true)
      local y_array = CCArray:create()
      y_array:addObject(CCFadeOut:create(0.75))
      y_array:addObject(CCFadeIn:create(0.75))
      yellow_guide_panel:runAction(CCRepeatForever:create(CCSequence:create(y_array)))
      local r_array = CCArray:create()
      r_array:addObject(CCDelayTime:create(11/24))
      r_array:addObject(CCFadeOut:create(7/24))
      r_array:addObject(CCDelayTime:create(11/24))
      r_array:addObject(CCFadeIn:create(7/24))
      red_guide_panel:runAction(CCRepeatForever:create(CCSequence:create(r_array)))
    end
  end
  
  checkAddParticle()
  
  local mainMenuBuilder = LayoutBuilder:createWithContentsOfFile("scene/mainmenu_scene_new.json")
  --local mainMenuBuilder = LayoutBuilder:createWithContentsOfFile("scene/mainmenu_scene.json")
  local rewardUI = mainMenuBuilder:build("mainmenu_scene_home_countdown_reward")
  local countdown_bg = rewardUI:getChildByName("bg_countdown_reward")--[[
  local original_posX = countdown_bg:getPositionX()
  local original_posY = countdown_bg:getPositionY()
  countdown_bg:setAnchorPoint(ccp(0.5, 0.5))
  countdown_bg:setPositionX(original_posX + countdown_bg:getContentSize().width / 2.0)
  countdown_bg:setPositionY(original_posY + countdown_bg:getContentSize().height / 2.0)]]
  countdown_bg.refCocosObj:setFlipX(true)
  local reward_box = rewardUI:getChildByName("icon_countdown_reward")
  local box_original_posX = reward_box:getPositionX()
  reward_box:setPositionX(countdown_bg:getContentSize().width - reward_box:getPositionX() - (0.5 - reward_box:getAnchorPoint().x) * 2 * reward_box:getContentSize().width)
  local reward_des = rewardUI:getChildByName("icon_txt_getreward")
  reward_des:setPositionX(reward_des:getPositionX() + 60)
  local reward_numLabel = rewardUI:getChildByName("txt_countdown")
  reward_numLabel:setPositionX(reward_numLabel:getPositionX() + 60)
  rewardUI:setPositionY(440)
  self:addChild(rewardUI)
  self:setupCountdownRewardUI(rewardUI, 15)
  --[[
  local reward_particle = rewardUI.refCocosObj:getChildByTag(-555)
  if reward_particle then
    reward_particle:setPositionX(reward_particle:getPositionX() + reward_box:getPositionX() - box_original_posX)
  end
  ]]
  BaseUIScene.onInit(self)
  
  self.BaseUi:getChildByName("home_menu_title"):getChildByName("bg_home_menu_title_for_jet"):setVisible(true)
  -- self.BaseUi:getChildByName("home_menu_title"):getChildByName("bg_home_menu_title"):setVisible(false)
  
  if self.argv.enterScene == "BattleScene" then
    Set_ShareData( "Battle_Result_Finished", 1 )
  end
  
  if (self.argv.enterScene == "BattleScene") and self.newMissionId then
    local fspt = FlashSprite:create("map/others/flashPack/Bossbreak")
    fspt:changeAnimation(0)
    fspt:setLoop(false)
    local fspt_co = CocosObject.new(fspt)
    local function bossbreakAnimationEnd(anim)
      fspt:unregisterEndAnimationScriptHandler()
      self:removeChild(fspt_co)
    end
    fspt:registerEndAnimationScriptHandler(bossbreakAnimationEnd)
    self:addChild(fspt_co)
    --[[
    local bloodScriptEntry
    local function startBloodAnimation(dt)
      CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(bloodScriptEntry)
      local fspt2 = FlashSprite:create("battle/Cardbattle_blood")
      fspt2:changeAnimation(0)
      fspt2:setLoop(false)
      local fspt_co2 = CocosObject.new(fspt2)
      local function bloodAnimationEnd(anim)
        fspt2:unregisterEndAnimationScriptHandler()
        self:removeChild(fspt_co2)
      end
      fspt2:registerEndAnimationScriptHandler(bloodAnimationEnd)
      self:addChild(fspt_co2)
    end
    bloodScriptEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(startBloodAnimation, 1/6, false)]]
  end

  self.mapUI:getChildByName("txt_newon"):getChildByName("txt"):setString(getTextByKey("stageNewCardOnRemind"))
  self.btnAddCard = Button:create(self.mapUI:getChildByName("jiaren"))
  local function onClickAddCard()
    self:replaceScene(CardQueueScene, {enterScene="ChapterMapScene",returnScene="ChapterMapScene",params={rollTo = #CommonManager.getQueueData()}})
  end
  self.btnAddCard:addEventListener(Events.kStart, onClickAddCard)
  self:refreshAddCardButton()
end

function ChapterMapScene:getZorderFromMapPosition(aMapPos)
  return (aMapPos.x + self.tiledMap.mapSize.height - 1 - aMapPos.y)
end

function ChapterMapScene:resetProgress()
  local aRate = (self.currentFinishedStep + 1 - self.startStepsOfCurrentMission + 1) / self.totalStepsOfCurrentMission
  local progress_string = string.format("%d%%", math.modf(aRate * 100))
  self.mapUI:getChildByName("font_stage_progress"):getChildByName("font"):setString(Localization:getInstance():getText(progress_string))
  --self.progress:progressTo(aRate * 100, progress_duration)
  
  local start_progress = self.progress.progress
  local addition_progress = aRate * 100 - start_progress
  local start_head_pos_x = self.progressHead:getPositionX()
  local addition_pos_x = addition_progress / 100 * progress_sprite_width
  local dt_accumulated = 0
  local function progressMove( dt )
    dt_accumulated = dt_accumulated + dt
    if dt_accumulated >= progress_duration then
      CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.progressScriptEntry)
      self.progressScriptEntry = nil
      dt_accumulated = progress_duration
    end
    self.progress:setPercentage(start_progress + addition_progress * dt_accumulated / progress_duration)
    self.progressHead:setPositionX(start_head_pos_x +  addition_pos_x * dt_accumulated / progress_duration)
	end
  if self.progressScriptEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.progressScriptEntry)
    self.progressScriptEntry = nil
  end
  self.progressScriptEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(progressMove, 0, false)
end

function ChapterMapScene:onExit()
  if self.updateMapPosScriptEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.updateMapPosScriptEntry)
  end
  --[[if self.dismissMissionDesScriptEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.dismissMissionDesScriptEntry)
  end]]
  if self.progressScriptEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.progressScriptEntry)
  end
end

function ChapterMapScene:addMapEventListener()
  self.mapTouchLayer:addEventListener(DisplayEvents.kTouchBegin, kMapTouchBegin, self)
  self.mapTouchLayer:addEventListener(DisplayEvents.kTouchMove, kMapTouchMove, self)
  self.mapTouchLayer:addEventListener(DisplayEvents.kTouchEnd, onMapTouchEnd, self)
end

function ChapterMapScene:removeMapEventListener()
  self.mapTouchLayer:removeEventListener(DisplayEvents.kTouchBegin, kMapTouchBegin)
  self.mapTouchLayer:removeEventListener(DisplayEvents.kTouchMove, kMapTouchMove)
  self.mapTouchLayer:removeEventListener(DisplayEvents.kTouchEnd, onMapTouchEnd)
end

function ChapterMapScene:startScheduleUpdateMapPos()
  local function updateMapPos( dt )
    if self.moving then
      local aWinSize = CCDirector:sharedDirector():getWinSize()
      local aPos2 = self.leadRole:getPosition()
      self:correctMapPosition(ccp(-(aPos2.x - aWinSize.width / 2), -(aPos2.y - aWinSize.height / 2) - map_offset_y))
    end
	end
  
  self.tiledMap:setAnchorPoint(ccp(0, 0))
  self.tiledMap:setPosition(ccp(self.originalMapPosX, self.originalMapPosY))
  self:addMapEventListener()
  self.updateMapPosScriptEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(updateMapPos, 0, false)
end

function ChapterMapScene:addClouds()
  --[[local aCloud1 = Sprite:create("map/Map_Cloud1.png")
  aCloud1:setPosition(ccp(360, 640))
  self:addChild(aCloud1)]]
end

function ChapterMapScene:hideSelectDirUI()
  if not self.selectDirUI:isVisible() then
    return
  end
  local aDisplay = self.selectDirUI:getChildByName("arrow_lu")
  aDisplay:setVisible(false)
  aDisplay:stopAllActions()
  aDisplay:setPosition(ccp(self.luOriginalPosX, self.luOriginalPosY))
  aDisplay:getChildByName("light_lu"):stopAllActions()
  aDisplay:getChildByName("light_lu"):setOpacity(255)
  aDisplay = self.selectDirUI:getChildByName("arrow_ru")
  aDisplay:setVisible(false)
  aDisplay:stopAllActions()
  aDisplay:setPosition(ccp(self.ruOriginalPosX, self.ruOriginalPosY))
  aDisplay:getChildByName("light_ru"):stopAllActions()
  aDisplay:getChildByName("light_ru"):setOpacity(255)
  aDisplay = self.selectDirUI:getChildByName("arrow_rd")
  aDisplay:setVisible(false)
  aDisplay:stopAllActions()
  aDisplay:setPosition(ccp(self.rdOriginalPosX, self.rdOriginalPosY))
  aDisplay:getChildByName("light_rd"):stopAllActions()
  aDisplay:getChildByName("light_rd"):setOpacity(255)
  aDisplay = self.selectDirUI:getChildByName("arrow_ld")
  aDisplay:setVisible(false)
  aDisplay:stopAllActions()
  aDisplay:setPosition(ccp(self.ldOriginalPosX, self.ldOriginalPosY))
  aDisplay:getChildByName("light_ld"):stopAllActions()
  aDisplay:getChildByName("light_ld"):setOpacity(255)
  self.selectDirUI:setVisible(false)
end

function ChapterMapScene:showSelectDirUI()
  if self.selectDirUI:isVisible() then
    return
  end
  self.selectDirUI:setVisible(true)
  local aDisplay
  for _, aDir in ipairs(self.moveDirections) do
    if aDir == 1 then
      aDisplay = self.selectDirUI:getChildByName("arrow_lu")
      aDisplay:setVisible(true)
      local arr = CCArray:create()
      arr:addObject(CCMoveBy:create(select_dir_animate_duration, ccp(-select_dir_move_height * 2, select_dir_move_height)))
      arr:addObject(CCMoveBy:create(select_dir_animate_duration, ccp(select_dir_move_height * 2, -select_dir_move_height)))
      aDisplay:runAction(CCRepeatForever:create(CCSequence:create(arr)))
      arr = CCArray:create()
      arr:addObject(CCFadeOut:create(select_dir_animate_duration))
      arr:addObject(CCFadeIn:create(select_dir_animate_duration))
      aDisplay:getChildByName("light_lu"):runAction(CCRepeatForever:create(CCSequence:create(arr)))
    elseif aDir == 2 then
      aDisplay = self.selectDirUI:getChildByName("arrow_ru")
      aDisplay:setVisible(true)
      local arr = CCArray:create()
      arr:addObject(CCMoveBy:create(select_dir_animate_duration, ccp(select_dir_move_height * 2, select_dir_move_height)))
      arr:addObject(CCMoveBy:create(select_dir_animate_duration, ccp(-select_dir_move_height * 2, -select_dir_move_height)))
      aDisplay:runAction(CCRepeatForever:create(CCSequence:create(arr)))
      arr = CCArray:create()
      arr:addObject(CCFadeOut:create(select_dir_animate_duration))
      arr:addObject(CCFadeIn:create(select_dir_animate_duration))
      aDisplay:getChildByName("light_ru"):runAction(CCRepeatForever:create(CCSequence:create(arr)))
    elseif aDir == 3 then
      aDisplay = self.selectDirUI:getChildByName("arrow_rd")
      aDisplay:setVisible(true)
      local arr = CCArray:create()
      arr:addObject(CCMoveBy:create(select_dir_animate_duration, ccp(select_dir_move_height * 2, -select_dir_move_height)))
      arr:addObject(CCMoveBy:create(select_dir_animate_duration, ccp(-select_dir_move_height * 2, select_dir_move_height)))
      aDisplay:runAction(CCRepeatForever:create(CCSequence:create(arr)))
      arr = CCArray:create()
      arr:addObject(CCFadeOut:create(select_dir_animate_duration))
      arr:addObject(CCFadeIn:create(select_dir_animate_duration))
      aDisplay:getChildByName("light_rd"):runAction(CCRepeatForever:create(CCSequence:create(arr)))
    elseif aDir == 4 then
      aDisplay = self.selectDirUI:getChildByName("arrow_ld")
      aDisplay:setVisible(true)
      local arr = CCArray:create()
      arr:addObject(CCMoveBy:create(select_dir_animate_duration, ccp(-select_dir_move_height * 2, -select_dir_move_height)))
      arr:addObject(CCMoveBy:create(select_dir_animate_duration, ccp(select_dir_move_height * 2, select_dir_move_height)))
      aDisplay:runAction(CCRepeatForever:create(CCSequence:create(arr)))
      arr = CCArray:create()
      arr:addObject(CCFadeOut:create(select_dir_animate_duration))
      arr:addObject(CCFadeIn:create(select_dir_animate_duration))
      aDisplay:getChildByName("light_ld"):runAction(CCRepeatForever:create(CCSequence:create(arr)))
    end
  end
  local aPos2 = self:convertFromCoorToMapOrthogonalSpace(self.currentPos)
  self.selectDirUI:setPosition(aPos2)
  self.selectDirUI:setZOrder(self:getZorderFromMapPosition(self.currentPos))
  self.tiledMap.refCocosObj:reorderChild(self.leadRole.refCocosObj, self:getZorderFromMapPosition(self.currentPos))
  if #self.moveDirections > 1 then
    self:removeMapEventListener()
  else
    self:addMapEventListener()
  end
end

function ChapterMapScene:setLeadRoleAndMapPosition(  )
  if self.currentFinishedStep == 0 then
    local aStartPointCor = self.tiledMap:getStartPointCoordinate()
    self.currentPos = ccp(aStartPointCor.x, self.tiledMap.mapSize.height - 1 - aStartPointCor.y)
  end
	--print(string.format("startPoint:%d, %d", aStartPointCor.x, aStartPointCor.y))
	
	local aPos2 = self:convertFromCoorToMapOrthogonalSpace(self.currentPos)
	self.leadRole:setPosition(aPos2)

	local aWinSize = CCDirector:sharedDirector():getWinSize()
	self:correctMapPosition(ccp(-(aPos2.x - aWinSize.width / 2), -(aPos2.y - aWinSize.height / 2) - map_offset_y))
end

function ChapterMapScene:correctMapPosition( aMapPosition )
	local aWinSize = CCDirector:sharedDirector():getWinSize()
	local aNewPos2 = ccp(-aMapPosition.x, -aMapPosition.y)		--屏幕相对于地图左下角的坐标
	local aNewPos3 = self:convertToMapSpace(aNewPos2)		--屏幕相对于地图斜角坐标系的坐标

	local aMinX, aMaxX, aMinY, aMaxY		--屏幕相对于地图斜角坐标系的坐标的范围值
	aMinX = aWinSize.height / (2 * math.sin(map_radian))
	aMaxX = (self.tiledMap.tileSize.width * self.tiledMap.mapSize.width - aWinSize.width) / (2 * math.cos(map_radian))
	aMinY = 0
	aMaxY = (self.tiledMap.tileSize.height * self.tiledMap.mapSize.height - aWinSize.height) / (2 * math.sin(map_radian)) - aWinSize.width / (2 * math.cos(map_radian))
	aNewPos3.x = math.max(math.min(aNewPos3.x, aMaxX), aMinX)	--修正值
	aNewPos3.y = math.max(math.min(aNewPos3.y, aMaxY), aMinY)	--修正值
	local aNewPos4 = self:convertToMapOrthogonalSpace(aNewPos3)		--屏幕相对于地图左下角的坐标
	local aRealPos = ccp(-aNewPos4.x, -aNewPos4.y)		--真实坐标

	self.tiledMap:setPosition(aRealPos)
end

function ChapterMapScene:convertToMapSpace( aPosition )
	local result = ccp(0, 0)
	result.x = (aPosition.x / math.cos(map_radian) + (self.tiledMap.tileSize.height * self.tiledMap.mapSize.height / 2 - aPosition.y) / math.sin(map_radian)) / 2
	result.y = (aPosition.x / math.cos(map_radian) - (self.tiledMap.tileSize.height * self.tiledMap.mapSize.height / 2 - aPosition.y) / math.sin(map_radian)) / 2
	return result
end

function ChapterMapScene:convertToMapOrthogonalSpace( aPosition )
	local result = ccp(0, 0)
	result.x = (aPosition.x + aPosition.y) * math.cos(map_radian)
	result.y = self.tiledMap.tileSize.height * self.tiledMap.mapSize.height / 2 - (aPosition.x - aPosition.y) * math.sin(map_radian)
	return result
end

function ChapterMapScene:convertFromCoorToMapOrthogonalSpace( aCor )
	local aPos1 = ccp((aCor.x + 0.5) * (self.tiledMap.tileSize.width / (2 * math.cos(map_radian))), (aCor.y + 0.5) * (self.tiledMap.tileSize.height / (2 * math.sin(map_radian))))	--相对于地图斜角坐标系的坐标
	return self:convertToMapOrthogonalSpace(aPos1)
end

function ChapterMapScene:updateEventIcons()
  local aStepIndex = 0
  local aChapterID = CountryManager:sharedManager().selectedChapterID
  local aMissionID = CountryManager:sharedManager().selectedMissionID
  local aTotalSteps = 0
  aTotalSteps, self.totalStepsOfCurrentMission, self.startStepsOfCurrentMission = CountryManager:sharedManager():getTotalStepsWithChapterID(aChapterID, aMissionID)
  local aCurrentPointCor = self.tiledMap:getStartPointCoordinate()
  aCurrentPointCor = ccp(aCurrentPointCor.x, self.tiledMap.mapSize.height - 1 - aCurrentPointCor.y)
  local aCurrentDir = self:defaultDirectionWithCoordinate(aCurrentPointCor)
  local aCurrentType = 1
  local aCurrentPoints = {aCurrentPointCor}
  local aCurrentDirs = {aCurrentDir}
  local aCurrentTypes = {aCurrentType}
  local aStepFlag = 0
  
  local aNum2 = self.tiledMap:getFirstGIDForEventSource()
  local aEventLayer = self.tiledMap:layerNamed("event")
  local aNewPoints
  local aNewDirs
  local aNewTypes
  local aMoveDirections
  local aOffsizeX
  local aOffsizeY
  local aNextPointCor
  local aNextCurrentDir
  local aNextType
  local aMapPosOfEvent
  local aNum1
  local aEventType
  local aEmptyBoxSprite
  local chapter_event_configs = CountryManager:sharedManager():getBattleChapterEventConfigs(aChapterID)
  self.chapter_event_configs = chapter_event_configs
  
  while aStepIndex < aTotalSteps do
    aStepFlag = aStepFlag + 1
    if aStepFlag == step_per_event then
      aStepIndex = aStepIndex + 1
      aStepFlag = 0
    end
    aNewPoints = {}
    aNewDirs = {}
    aNewTypes = {}
    for i = 1, #aCurrentPoints do
      aCurrentPointCor = aCurrentPoints[i]
      aCurrentDir = aCurrentDirs[i]
      aCurrentType = aCurrentTypes[i]
      aMoveDirections = self:moveDirectionOfLeadRole(aCurrentPointCor, aCurrentDir)
      assert(#aMoveDirections > 0, "No move direction in updateEventIcons!")
      aMoveDirections = self:getCorrectedDirections(aMoveDirections, aCurrentDir)
      for k, aMoveDir in ipairs(aMoveDirections) do
        aOffsizeX = 0
        aOffsizeY = 0
        aNextPointCor = ccp(0, 0)
        if aMoveDir == 1 then 		--左边
          aOffsizeX = -1
          aOffsizeY = 0
          aNextCurrentDir = LeadRoleDirection.kLeft
        elseif aMoveDir == 2 then 		--上边
          aOffsizeX = 0
          aOffsizeY = 1
          aNextCurrentDir = LeadRoleDirection.kUp
        elseif aMoveDir == 3 then 		--右边
          aOffsizeX = 1
          aOffsizeY = 0
          aNextCurrentDir = LeadRoleDirection.kRight
        elseif aMoveDir == 4 then 		--下边
          aOffsizeX = 0
          aOffsizeY = -1
          aNextCurrentDir = LeadRoleDirection.kDown
        end
        aNextPointCor.x = aCurrentPointCor.x + aOffsizeX
        aNextPointCor.y = aCurrentPointCor.y + aOffsizeY
        if #aMoveDirections > 1 then
          aNextType = k - 1 + aCurrentType
        else
          aNextType = aCurrentType
        end
        table.insert(aNewPoints, aNextPointCor)
        table.insert(aNewDirs, aNextCurrentDir)
        table.insert(aNewTypes, aNextType)
        
        aMapPosOfEvent = ccp(aNextPointCor.x, self.tiledMap.mapSize.height - 1 - aNextPointCor.y)
        if aStepFlag == 0 then
          aNum1, aEventType = CountryManager:sharedManager():tileGIDOffsizeWithStep(aNextType, chapter_event_configs[aStepIndex])
          aEventLayer:setTileGID(aNum2 + chapter_empty_event_gid_offsize, aMapPosOfEvent)
          if aEventType then
            if aStepIndex <= self.currentFinishedStep then
              if aEventType == ChapterEventIDs[2] then    --boss event
                local aPos2 = self:convertFromCoorToMapOrthogonalSpace(aNextPointCor)
                local aName
                if aStepIndex == aTotalSteps then
                  aName = "#map_chapter_boss_fall.png"
                else
                  aName = "#map_mission_boss_fall.png"
                end
                local aMissionBossFallSprite = Sprite:create(aName)
                aMissionBossFallSprite:setAnchorPoint(ccp(0.3, 0.2))
                aMissionBossFallSprite:setPosition(aPos2)
                self.tiledMap:addChildAt(aMissionBossFallSprite, map_element_z_order)
                --self.tiledMap:addChild(aMissionBossFallSprite)
                aMissionBossFallSprite:setZOrder(self:getZorderFromMapPosition(aNextPointCor))
              end
            else
              if aEventType == ChapterEventIDs[7] or aEventType == ChapterEventIDs[3] or aEventType == ChapterEventIDs[4] or aEventType == ChapterEventIDs[5] or aEventType == ChapterEventIDs[1] then
                local aPos2 = self:convertFromCoorToMapOrthogonalSpace(aNextPointCor)
                local aMarkBottomSprite = Sprite:create("#map_mark_bottom.png")
                aMarkBottomSprite:setPosition(aPos2)
                self.tiledMap:addChildAt(aMarkBottomSprite, map_element_z_order)
                --self.tiledMap:addChild(aMarkBottomSprite)
                aMarkBottomSprite:setZOrder(self:getZorderFromMapPosition(aNextPointCor))
                local aMarkSprite = Sprite:create("#map_mark.png")
                aMarkSprite:setAnchorPoint(ccp(0.6, 0.1))
                aMarkSprite:setPosition(ccp(aMarkBottomSprite:getContentSize().width / 2.0, aMarkBottomSprite:getContentSize().height / 2.0))
                aMarkBottomSprite:addChild(aMarkSprite)
                local arr = CCArray:create()
                arr:addObject(CCMoveBy:create(mark_move_duration, ccp(0, mark_move_distance)))
                arr:addObject(CCMoveBy:create(mark_move_duration, ccp(0, -mark_move_distance)))
                aMarkSprite:runAction(CCRepeatForever:create(CCSequence:create(arr)))
                local aKey = string.format("%d_%d", aNextPointCor.x, aNextPointCor.y)
                self.markList[aKey] = aMarkBottomSprite
              elseif aEventType == ChapterEventIDs[2] then    --boss event
                local aPos2 = self:convertFromCoorToMapOrthogonalSpace(aNextPointCor)
                local aName
                if aStepIndex == aTotalSteps then
                  aName = "#map_chapter_boss.png"
                else
                  aName = "#map_mission_boss.png"
                end
                local aMissionBossSprite = Sprite:create(aName)
                aMissionBossSprite:setAnchorPoint(ccp(0.5, 0.1))
                aMissionBossSprite:setPosition(aPos2)
                self.tiledMap:addChildAt(aMissionBossSprite, map_element_z_order)
                --self.tiledMap:addChild(aMissionBossSprite)
                aMissionBossSprite:setZOrder(self:getZorderFromMapPosition(aNextPointCor))
              end
            end
          end
          if (aStepIndex == self.currentFinishedStep) and (aNextType == self.currentRouteId) then
            self.currentPos = aNextPointCor
          end
        else
          aEventLayer:setTileGID(aNum2 + chapter_not_event_gid_offsize, aMapPosOfEvent)
        end
      end
    end
    aCurrentPoints = aNewPoints
    aCurrentDirs = aNewDirs
    aCurrentTypes = aNewTypes
  end
end

function ChapterMapScene:getCorrectedDirections(aMoveDirections, aCurrentDir)
  local result = {}
  local aDir
  if aCurrentDir == LeadRoleDirection.kLeft then
    aDir = 1
  elseif aCurrentDir == LeadRoleDirection.kUp then
    aDir = 2
  elseif aCurrentDir == LeadRoleDirection.kRight then
    aDir = 3
  elseif aCurrentDir == LeadRoleDirection.kDown then
    aDir = 4
  end
  local aStartIndex = 1
  for k, v in ipairs(aMoveDirections) do
    if aDir >= v then
      aStartIndex = k
      break
    end
  end
  for aIndex = aStartIndex, aStartIndex + #aMoveDirections - 1 do
    table.insert(result, aMoveDirections[(aIndex - 1) % #aMoveDirections + 1])
  end
  return result
end

function ChapterMapScene:moveCommandReceived(aSelectedDir)
  local GameInitData = DataManager.getGameInitData()
  local aBattleMissionConfig = MetaManager.battle_mission[self.currentMissionId]
  if tonumber(aBattleMissionConfig.levelMin, 10) > GameInitData.sharkUser.level then
    self:showLevelLimitPanel(tonumber(aBattleMissionConfig.levelMin, 10))
    return
  end
  
  if CountryManager:sharedManager().missionIDInChallenge ~= self.currentMissionId then
    CountryManager:sharedManager():checkMissionComplete()
    local aCurrentTime = CountryManager:sharedManager():getMissionCurrentBattleTime(self.currentMissionId)
    local aLimitTime = CountryManager:sharedManager():getMissionBattleLimit(self.currentMissionId)
    if aCurrentTime >= aLimitTime then
      local maxResetNum = MetaManager.vip_setting[DataManager.getCurrUser().vipLevel].extraMissionPerDay
      if DailyDataManager.getResetMissionNum() >= maxResetNum then
        self:showCannotBuyMissionCountPanel()
      else
        self:showTimeLimitPanel(self.currentMissionId, aBattleMissionConfig.battleWinPrice, aSelectedDir)
      end
      return
    end
  end
  
  if BagCalcManager.isFull() then
    --旧的提示会卡
    -- local aContent = Localization:getInstance():getText("bagFull_move")
    -- SuspensionLabel:showContent(self, aContent)
    local text = Localization:getInstance():getText("bagFull_move")
    self.targetInfoPanel = NewPackageFullPanel:show()
    return
  end
  --[[
  local a, b = BagCalcManager.getEnergyPropList()
  print(a)
  print(table.tostring(b))
  ]]
  if DataManager.GameMetaData.battleSettingConfig.missionStepEnergy > CalculationManager.calcComplex_getEnergyNow() then
    local hasEnergyProp, energyPropList = BagCalcManager.getEnergyPropList()
    if hasEnergyProp then
      self:showUseEnergyProptPanel(energyPropList)
    else
      self:showEnergyLimitPanel()
    end
    return
  end
  
  if math.mod(self.currentFinishedStep, 5) == 0 then
    local aMissionRemindConfig = MetaManager.mission_remind[self.currentMissionId]
    if aMissionRemindConfig then
      --
      local sharkUser = DataManager.getGameInitData().sharkUser
      local additionalCardIdsList = sharkUser.additionalCardIds:split(",")
      local userGrid = 1
      if type(additionalCardIdsList) == "table" then
        userGrid = userGrid + #additionalCardIdsList
      end
      if aMissionRemindConfig.cardNum > userGrid then
        local maxNum = MetaManager.user_level[sharkUser.level].maxQueueCardNum
        if aMissionRemindConfig.cardNum <= maxNum then  --够了
          self:showEquipCardPanel(true, {selectedDir = aSelectedDir})
        else
          self:showEquipCardPanel(false, {selectedDir = aSelectedDir})
        end
        return
      end
    end
  end
  
  self:moveOnFromEquipCardPanel({selectedDir = aSelectedDir})
end

function ChapterMapScene:readyToMoveToNextTile()
  
  local function downFinished()
    local aEventID = CountryManager:sharedManager():getNextEventID(self.currentMissionId, self.currentFinishedStep + 1, self.currentRouteId)
    self:handleEvent(aEventID)
    
  end
  self.leadRole:stopAllActions()
  self:disableUserInterface()
  local aPos2 = self:convertFromCoorToMapOrthogonalSpace(self.currentPos)
  local arr = CCArray:create()
  arr:addObject(CCMoveTo:create((self.leadRole:getPositionY() - aPos2.y) * lead_role_up_duration / lead_role_up_distance, aPos2))
  arr:addObject(CCCallFunc:create(downFinished))
  self.leadRole:runAction(CCSequence:create(arr))
  
end

function ChapterMapScene:leadRoleMoveToNextTile(callBackFunc)
  self.moving = true
  self:moveWithDirection(self.moveDirections[self.selectDir], callBackFunc)
end

function ChapterMapScene:readyToTriggerEventAction(callBackFunc)
  --[[
  local function checkNewUserGuide()
    Set_ShareData( "Walk_Finished", 1)
    local guide_status_check_entry
    local function checkGuideStatus( dt )
      if Get_ShareData("Walk_Finished") == 2 then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(guide_status_check_entry)
        self:resetProgress()
        callBackFunc()
      end
    end
    guide_status_check_entry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(checkGuideStatus, 0, false)
  end
  ]]
  local function checkDialog()
    local shouldRunDialog
    local aConversationId
    shouldRunDialog, aConversationId = self:whetherShouldRunDialog(2)
    if not shouldRunDialog then
      --checkNewUserGuide()
      self:resetProgress()
      callBackFunc()
    else
      local originalGuideCallback = getGuideFinishCallback()
      local function guideFinished()
        CanonPlayBackgroundMusic("music/m_map.mp3", true)
        RegisterOnGuideFinishCallback(originalGuideCallback)
      end
      RegisterOnGuideFinishCallback(guideFinished)
      Run_Script_Using_Dialog_Index(aConversationId, 2)
      local dialog_status_check_entry
      local function checkDialogStatus( dt )
        if Get_ShareData("Dialog_Running") == 0 then
          CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(dialog_status_check_entry)
          --checkNewUserGuide()
          self:resetProgress()
          callBackFunc()
        end
      end
      dialog_status_check_entry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(checkDialogStatus, 0, false)
    end
  end
  
  checkDialog()
end

function ChapterMapScene:moveWithDirection(aDir, callBackFunc)
  local aOffsizeX = 0
  local aOffsizeY = 0
  local aNextCurrentDirection
  if aDir == 1 then 		--左边
    aOffsizeX = -1
    aOffsizeY = 0
    aNextCurrentDirection = LeadRoleDirection.kLeft
  elseif aDir == 2 then 		--上边
    aOffsizeX = 0
    aOffsizeY = 1
    aNextCurrentDirection = LeadRoleDirection.kUp
  elseif aDir == 3 then 		--右边
    aOffsizeX = 1
    aOffsizeY = 0
    aNextCurrentDirection = LeadRoleDirection.kRight
  elseif aDir == 4 then 		--下边
    aOffsizeX = 0
    aOffsizeY = -1
    aNextCurrentDirection = LeadRoleDirection.kDown
  end
  local function oneTileMoveFinished(  )
    self.currentPos.x = self.currentPos.x + aOffsizeX
    self.currentPos.y = self.currentPos.y + aOffsizeY
    self.leadRole:setZOrder(self:getZorderFromMapPosition(self.currentPos))
    self.currentDirection = aNextCurrentDirection
    self.moveDirections = self:moveDirectionOfLeadRole(self.currentPos, self.currentDirection)
    self.passedTileNum = self.passedTileNum + 1
    if self.passedTileNum == step_per_event then
      self.passedTileNum = 0
      self.moving = false
      --
      self:readyToTriggerEventAction(callBackFunc)
    else
      self:leadRoleMoveToNextTile(callBackFunc)
    end
  end
  local aNextPos = self:convertFromCoorToMapOrthogonalSpace(ccp(self.currentPos.x + aOffsizeX, self.currentPos.y + aOffsizeY))
  local array = CCArray:create()
  array:addObject(CCMoveTo:create(duration_per_tile, aNextPos))
  array:addObject(CCCallFunc:create(oneTileMoveFinished))
  local action = CCSequence:create(array)
  self.leadRole:runAction(action)
end

function ChapterMapScene:moveDirectionOfLeadRole( aCurrentPos, aCurrentDir )
  --print("__%d_%d__%s", aCurrentPos.x, aCurrentPos.y, aCurrentDir)
	local result = {}
	for i = 1, 4 do
		local aOffsizeX = 0
		local aOffsizeY = 0
		if i == 1 then 		--判断左边
			if aCurrentDir ~= LeadRoleDirection.kRight then
				aOffsizeX = -1
				aOffsizeY = 0
			end
		elseif i == 2 then 		--判断上边
			if aCurrentDir ~= LeadRoleDirection.kDown then
				aOffsizeX = 0
				aOffsizeY = 1
			end
		elseif i == 3 then 		--判断右边
			if aCurrentDir ~= LeadRoleDirection.kLeft then
				aOffsizeX = 1
				aOffsizeY = 0
			end
		elseif i == 4 then 		--判断下边
			if aCurrentDir ~= LeadRoleDirection.kUp then
				aOffsizeX = 0
				aOffsizeY = -1
			end
		end
		if not (aOffsizeX == 0 and aOffsizeY == 0) then
			if self:whetherValidTileCoordinate(ccp(aCurrentPos.x + aOffsizeX, aCurrentPos.y + aOffsizeY)) then
				local aDirectionLayer = self.tiledMap:layerNamed("direction")
				local aTileGid = aDirectionLayer:tileGIDAt(ccp(aCurrentPos.x + aOffsizeX, self.tiledMap.mapSize.height - 1 - (aCurrentPos.y + aOffsizeY)))
				if aTileGid and aTileGid ~= 0 then
					local aProperties = self.tiledMap:propertiesForGID(aTileGid)
					if aProperties and aProperties:objectForKey("direction") then
            if not self:isReverseDirection((tolua.cast(aProperties:objectForKey("direction"), "CCString")):getCString(), i) then
              table.insert(result, i)
            end
					end
				end
			end
		end
	end
	return result
end

function ChapterMapScene:isReverseDirection(aTileDefaultDir, i)
  if (aTileDefaultDir == LeadRoleDirection.kUp) and (i == 4) then
    return true
  elseif (aTileDefaultDir == LeadRoleDirection.kDown) and (i == 2) then
    return true
  elseif (aTileDefaultDir == LeadRoleDirection.kLeft) and (i == 3) then
    return true
  elseif (aTileDefaultDir == LeadRoleDirection.kRight) and (i == 1) then
    return true
  end
  return false
end

function ChapterMapScene:defaultDirectionWithCoordinate( aCor )
	
	local result = nil
	local aDirectionLayer = self.tiledMap:layerNamed("direction")
	local aTileGid = aDirectionLayer:tileGIDAt(ccp(aCor.x, self.tiledMap.mapSize.height - 1 - aCor.y))
	if aTileGid and aTileGid ~= 0 then
		local aProperties = self.tiledMap:propertiesForGID(aTileGid)
		if aProperties then
			result = (tolua.cast(aProperties:objectForKey("direction"), "CCString")):getCString()
		end
	end
	assert(result, "No default direction!")
	return result
end

function ChapterMapScene:whetherValidTileCoordinate( aCor )
	if aCor.x >= 0 and aCor.x < self.tiledMap.mapSize.width and aCor.y >= 0 and aCor.y < self.tiledMap.mapSize.height then
		return true
	else
		return false
	end
end

function ChapterMapScene:showDecreaseEnergy()
  RewardManager:getReward({{itemType = ResourceEnum.ENERGY, amount = -DataManager.GameMetaData.battleSettingConfig.missionStepEnergy}})
  local aPos2 = self:convertFromCoorToMapOrthogonalSpace(self.currentPos)
  local aLRPos2World = self.tiledMap:convertToWorldSpace(aPos2)
  local aSprite = Sprite:create("#stamina_lost.png")
  aSprite:setPosition(ccp(aLRPos2World.x, aLRPos2World.y + card_original_height * card_scale_factor))
  aSprite:setOpacity(0)
  self:addChildAt(aSprite, 10001)
  local function exitActionFinished()
    if (type(aSprite) == "table") and (type(aSprite.parent) == "table") and aSprite.parent.refCocosObj and aSprite.refCocosObj then
      aSprite:removeFromParentAndCleanup(true)
    end
  end
  local arr = CCArray:create()
  arr:addObject(CCFadeIn:create(0.3))
  --arr:addObject(CCDelayTime:create(0.1))
  arr:addObject(CCFadeOut:create(0.3))
  arr:addObject(CCCallFunc:create(exitActionFinished))
  aSprite:runAction(CCSequence:create(arr))
  
  arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(0, 50)))
  --arr:addObject(CCDelayTime:create(0.1))
  arr:addObject(CCMoveBy:create(0.3, ccp(0, 50)))
  aSprite:runAction(CCSequence:create(arr))
  --[[
  AutoDisappearLabel:showContent(self, Localization:getInstance():getText("stage_consumeEnergy", {num = DataManager.GameMetaData.battleSettingConfig.missionStepEnergy}), ccp(aLRPos2World.x, aLRPos2World.y + card_original_height * card_scale_factor))]]
end

function ChapterMapScene:handleEvent(aEventID)
  --print(aEventID)
  self:disableUserInterface()
  if aEventID == "event_battle" then
    self:handleBattleEvent()
  elseif aEventID == "event_boss" then
    self:handleBossEvent()
  elseif aEventID == "event_money" then
    self:handleCoinEvent()
  elseif aEventID == "event_exp" then
    self:handleExpEvent()
  elseif aEventID == "event_card" then
    self:handleCardEvent()
  elseif aEventID == "event_random" then
    self:handleRandomEvent()
  elseif not aEventID then
    self:handleEmptyEvent()
  end
end

local guide_step_list = {1, 3, 4, 6, 8, 9}



function ChapterMapScene:eventHandleFinished(dataInfo)
  local function checkNewUserGuide()
    if Get_ShareData("New_User_Guide_Running") == 1 then
      Set_ShareData( "Walk_Step", self.currentFinishedStep )
      Set_ShareData( "Walk_Finished", 1 )
      -- Director:sharedDirector():getRunningScene():resetTouchFlag()
    end
    --[[
    local guide_status_check_entry
    local function checkGuideStatus( dt )
      if Get_ShareData("Walk_Finished") == 2 then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(guide_status_check_entry)
      end
    end
    guide_status_check_entry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(checkGuideStatus, 0, false)]]
  end
  
  local shouldTriggerGuide = true
  if CountryManager:sharedManager():getMaxFinishedMissionID() >= self.currentMissionId then
    shouldTriggerGuide = false
  else
    if (math.modf(self.currentMissionId / 100) == 1001) and (indexOfObject(guide_step_list, self.currentFinishedStep) ~= 0) then
      shouldTriggerGuide = true
    else
      shouldTriggerGuide = false
    end
  end
  if shouldTriggerGuide then
    checkNewUserGuide()
  else
    
  end
  self:enableUserInterface()
  
  if dataInfo and dataInfo.encounterMultiPlayerBoss then
    self:enterMultiplayerBossChallengeScene(dataInfo.multiPlayerBossInfo)
  end
  
  self:refreshAddCardButton()
end

function ChapterMapScene:enterMultiplayerBossChallengeScene(multiPlayerBossInfo)
  self:disableUserInterface()
  self.mapUI:setVisible(false)
  local aColorLayer = LayerColor:create()
  aColorLayer:setOpacity(kDarkOpacity)
  aColorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(aColorLayer)
  local fspt = FlashSprite:create("map/others/flashPack/BOSSIN")
  -- local aTexture = CCTextureCache:sharedTextureCache():addImage("pic/worldboss02.png")
  -- local aSize = aTexture:getContentSize()
  -- local card3_spf = CCSpriteFrame:createWithTexture(aTexture, CCRectMake(0,0,aSize.width, aSize.height))
  local bossId = DataManager.GameMetaData.activityMultiplayerBossConfig.encounterCardId
  local card3_spf = getFullCardSpriteFrame(tonumber(bossId))--改成新boss 2014-6-9
  -- card3_spf:setPosition(ccp(360,630))
  -- self.ui:addChildAt(card3_spf, 3)
  fspt:addChangeInstance("card2_full", card3_spf)
  fspt:changeAnimation(2)
  fspt:setLoop(false)
  local fspt_co = CocosObject.new(fspt)
  local aTempLayer
  local function onTouchEvent(evt)
    aTempLayer:removeEventListener(DisplayEvents.kTouchBegin, onTouchEvent)
    aTempLayer:removeFromParentAndCleanup(true)
    fspt:changeAnimation(4)
    fspt:setLoop(false)
    local function multiBossExitAnimationEnd(anim)
      local argv = {enterScene="ChapterMapScene",returnScene="ChapterMapScene",params={data = multiPlayerBossInfo}}
      self:replaceScene(MultiplayerBossChallengeScene, argv)
    end
    fspt:registerEndAnimationScriptHandler(multiBossExitAnimationEnd)
    local aColorLayer = LayerColor:create()
    aColorLayer:setColor(ccc3(0,0,0))
    aColorLayer:setOpacity(0)
    aColorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(aColorLayer)
    aColorLayer:runAction(CCFadeIn:create(0.4))
    
    
  end
  local function multiBossEnterAnimationEnd(anim)
    fspt:unregisterEndAnimationScriptHandler()
    fspt:changeAnimation(3)
    fspt:setLoop(true)
    aTempLayer = Layer:create()
    aTempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(aTempLayer)
    aTempLayer:addEventListener(DisplayEvents.kTouchBegin, onTouchEvent)
  end
  fspt:registerEndAnimationScriptHandler(multiBossEnterAnimationEnd)
  
  self:addChild(fspt_co)
end

function ChapterMapScene:doBattleEnterAction(eventData)
  local aBlackBg = Sprite:create("#black.png")
  aBlackBg:setPosition(ccp(visibleSize.width / 2.0 - visibleSize.width, visibleSize.height / 2.0))
  aBlackBg:setScaleX(360)
  aBlackBg:setOpacity(0)
  self:addChild(aBlackBg)
  local aTitle = Sprite:create("#enatk.png")
  aTitle:setPosition(ccp(visibleSize.width / 2.0 - visibleSize.width, visibleSize.height / 2.0))
  aTitle:setScale(2)
  self:addChild(aTitle)
  local aBackType
  local function blackExitFinished()
    aBlackBg:removeFromParentAndCleanup(true)
    local aFinishedType
    local aBattleMissionId = self.currentMissionId
    if eventData.win then
      eventData.missionId = self.currentMissionId
      eventData.finishedStep = self.currentFinishedStep + 1
      eventData.routeId = self.currentRouteId
      aFinishedType = CountryManager:sharedManager():moveToNextStep(self.currentMissionId, self.currentFinishedStep + 1, self.currentRouteId)
      self:resetMissionData()
      if aFinishedType == ChapterEventFinishedType.kChapterFinished then
        aBackType = BattleBackType.kCityMainScene
      elseif aFinishedType == ChapterEventFinishedType.kMissionFinished then
        aBackType = BattleBackType.kChapterMapScene
      elseif aFinishedType == ChapterEventFinishedType.kEventFinished then
        aBackType = BattleBackType.kChapterMapScene
      end
    else
      aBackType = BattleBackType.kChapterMapScene
    end
    eventData.missionID = aBattleMissionId
    if CountryManager:sharedManager():getMaxFinishedMissionID() < eventData.missionID then
      eventData.forbidSkip = true
    end
    Director:sharedDirector():replaceScene(BattleScene:create(eventData, aBackType, BattleEnterEnum.kChapterMapScene, aFinishedType))
  end
  
  local function titleExitFinished()
    aTitle:removeFromParentAndCleanup(true)
    local arr = CCArray:create()
    arr:addObject(CCFadeOut:create(0.2))
    arr:addObject(CCCallFunc:create(blackExitFinished))
    aBlackBg:runAction(CCSequence:create(arr))
  end
  
  local function sceneFadeOut()
    local aColorLayer = LayerColor:create()
    aColorLayer:setColor(ccc3(0,0,0))
    aColorLayer:setOpacity(0)
    aColorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(aColorLayer)
    aColorLayer:runAction(CCFadeIn:create(0.4))
  end
  
  local function titleEnterFinished()
    local arr = CCArray:create()
    arr:addObject(CCDelayTime:create(0.5))
    arr:addObject(CCMoveBy:create(0.1, ccp(-20, 0)))
    arr:addObject(CCCallFunc:create(sceneFadeOut))
    local arr2 = CCArray:create()
    arr2:addObject(CCFadeOut:create(0.2))
    arr2:addObject(CCMoveBy:create(0.2, ccp(20 + visibleSize.width, 0)))
    arr:addObject(CCSpawn:create(arr2))
    arr:addObject(CCCallFunc:create(titleExitFinished))
    aTitle:runAction(CCSequence:create(arr))
  end
  
  local function blackBgEnterFinished()
    aTitle:runAction(CCFadeIn:create(0.2))
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.2, ccp(visibleSize.width, 0)))
    arr:addObject(CCCallFunc:create(titleEnterFinished))
    aTitle:runAction(CCSequence:create(arr))
  end
  aBlackBg:runAction(CCFadeIn:create(0.2))
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.2, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(blackBgEnterFinished))
  aBlackBg:runAction(CCSequence:create(arr))
end

function ChapterMapScene:handleBattleEvent()
  local function triggerBattleSucceed(evt)
    local function moveFinished()
      self:removeMaskAtPos(self.currentPos)
      self:showDecreaseEnergy()
      
      self:doBattleEnterAction(evt.data)
    end
    
    self:leadRoleMoveToNextTile(moveFinished)
  end
  
  local function mapEventFailed(evt)
    self:handleMoveError(evt.data.retCode)
  end
  
  local params = {missionId = self.currentMissionId, step = self.currentFinishedStep + 1, routeId = self.currentRouteId, battleType = 1 , DoNotCaptureFailueMessage = true}
  --[[print(params.missionId)
  print(params.step)
  print(params.routeId)
  print(params.battleType)]]
  local request = TriggerBattleRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.TriggerBattleSucceed, triggerBattleSucceed)
  request:addEventListener(RequestNotifyEnum.MapEventFailed, mapEventFailed)
  request:start()
end

function ChapterMapScene:doBossEnterAction(eventData)
  CanonPlayBackgroundMusic("music/m_instance.mp3", true)
  self.mapUI:setVisible(false)
  local aColorLayer = LayerColor:create()
  aColorLayer:setOpacity(kDarkOpacity)
  aColorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(aColorLayer)
  local fspt
  local fspt_co
  local aMapBossNameLabel
  local aMapBossStarLabel
  local aBackType
  local function disappearActionFinished()
    local newMissionId
    local aFinishedType
    local aBattleMissionId = self.currentMissionId
    if eventData.win then
      eventData.missionId = self.currentMissionId
      eventData.finishedStep = self.currentFinishedStep + 1
      eventData.routeId = self.currentRouteId
      --local whetherToCityMain = not (self.currentMissionId >= CountryManager:sharedManager().countryData.maxFinishedMissionId)
      aFinishedType, newMissionId = CountryManager:sharedManager():moveToNextStep(self.currentMissionId, self.currentFinishedStep + 1, self.currentRouteId)
      self:resetMissionData()
      if aFinishedType == ChapterEventFinishedType.kChapterFinished then
        aBackType = BattleBackType.kCityMainScene
      elseif aFinishedType == ChapterEventFinishedType.kMissionFinished then
        --[[
        if whetherToCityMain then
          aBackType = BattleBackType.kCityMainScene
        else
          aBackType = BattleBackType.kChapterMapScene
        end]]
        aBackType = BattleBackType.kChapterMapScene
      elseif aFinishedType == ChapterEventFinishedType.kEventFinished then
        aBackType = BattleBackType.kChapterMapScene
      end
    else
      aBackType = BattleBackType.kChapterMapScene
    end
    eventData.missionID = aBattleMissionId
    if (eventData.win and newMissionId) or (not eventData.win and (CountryManager:sharedManager():getMaxFinishedMissionID() < eventData.missionID)) then
      eventData.forbidSkip = true
    end
    if aFinishedType == ChapterEventFinishedType.kChapterFinished then
      if CountryManager:sharedManager():getLastChapterIDWithCountryIDInConfig(max_unlock_city_id) == CountryManager:sharedManager().selectedChapterID then
        eventData.showAllFinishedPanel = true
      end
    end
    if eventData.win then
      eventData.showQuery = true
      if newMissionId then
        eventData.newMissionId = newMissionId
      end
    end
    
    Director:sharedDirector():replaceScene(BattleScene:create(eventData, aBackType, BattleEnterEnum.kChapterMapScene, aFinishedType, newMissionId, 1))
  end
  --[[
  local function bossDisappearAction()
    local aColorLayer = LayerColor:create()
    aColorLayer:setColor(ccc3(0,0,0))
    aColorLayer:setOpacity(0)
    aColorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(aColorLayer)
    aColorLayer:runAction(CCFadeIn:create(0.24))
    local arr = CCArray:create()
    arr:addObject(CCScaleTo:create(0.12, 1.75 * 0.85))
    arr:addObject(CCScaleTo:create(0.12, 1.75 * 4))
    arr:addObject(CCCallFunc:create(disappearActionFinished))
    card3_co:runAction(CCSequence:create(arr))
    card3_co:runAction(CCFadeOut:create(0.24))
  end]]
  
  local function bossExitAnimationEnd(anim)
    fspt:unregisterEndAnimationScriptHandler()
    disappearActionFinished()
  end
  
  local function startDisappearAction()
    fspt:changeAnimation(1)
    fspt:setLoop(false)
    fspt:registerEndAnimationScriptHandler(bossExitAnimationEnd)
    
    aMapBossNameLabel:doDisappearAction()
    aMapBossStarLabel:doDisappearAction()
    
    local aColorLayer = LayerColor:create()
    aColorLayer:setColor(ccc3(0,0,0))
    aColorLayer:setOpacity(0)
    aColorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(aColorLayer)
    aColorLayer:runAction(CCFadeIn:create(0.4))
  end
  
  local aTempLayer
  local function onTouchEvent(evt)
    aTempLayer:removeEventListener(DisplayEvents.kTouchBegin, onTouchEvent)
    aTempLayer:removeFromParentAndCleanup(true)
    startDisappearAction()
  end
  
  local aBattleMonsterGroupConfig
  for _, aConfig in pairs(MetaManager.battle_monster_group) do
    if (math.modf(aConfig.id / 100) == self.currentMissionId) and (aConfig.id % 10 == 2) then
      aBattleMonsterGroupConfig = aConfig
      break
    end
  end
  local aCardID = MetaManager.battle_monster[tonumber(aBattleMonsterGroupConfig.monsterIdList:split("|")[1], 10)].cardId
  local card3_spf = getFullCardSpriteFrame(aCardID)
  fspt = FlashSprite:create("map/others/flashPack/BOSSIN")
  fspt:addChangeInstance("card2_full", card3_spf)
  fspt:changeAnimation(0)
  fspt:setLoop(false)
  fspt_co = CocosObject.new(fspt)
  
  local function bossEnterAnimationEnd(anim)
    fspt:unregisterEndAnimationScriptHandler()
    aTempLayer = Layer:create()
    aTempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(aTempLayer)
    aTempLayer:addEventListener(DisplayEvents.kTouchBegin, onTouchEvent)
  end
  fspt:registerEndAnimationScriptHandler(bossEnterAnimationEnd)
  
  self:addChild(fspt_co)
  local aCardMetaConfig = MetaManager.card_meta[aCardID]
  local aNewCardId = aCardID + 1 - aCardMetaConfig.evolutionLevel
  aMapBossNameLabel = MapBossNameLabel:showContent(self, Localization:getInstance():getText(MetaManager.card_meta[aNewCardId].name), visibleSize.width / 2.0, 535)
  aMapBossStarLabel = MapBossStarLabel:showContent(self, aCardMetaConfig.rare, visibleSize.width / 2.0, 600)
end

function ChapterMapScene:handleBossEvent()
  local function triggerBossSucceed(evt)
    local function moveFinished()
      self:showDecreaseEnergy()
      
      self:doBossEnterAction(evt.data)
    end
    
    self:leadRoleMoveToNextTile(moveFinished)
  end
  
  local function mapEventFailed(evt)
    self:handleMoveError(evt.data.retCode)
  end
  
  local params = {missionId = self.currentMissionId, step = self.currentFinishedStep + 1, routeId = self.currentRouteId, battleType = 2 , DoNotCaptureFailueMessage = true}
  --[[print(params.missionId)
  print(params.step)
  print(params.routeId)
  print(params.battleType)]]
  local request = TriggerBattleRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.TriggerBattleSucceed, triggerBossSucceed)
  request:addEventListener(RequestNotifyEnum.MapEventFailed, mapEventFailed)
  request:start()
end

function ChapterMapScene:handleCoinEvent()
  local function triggerCoinSucceed(event)
    local function moveFinished()
      self:removeMaskAtPos(self.currentPos)
      self:showDecreaseEnergy()
      
      --self:doCoinEventAction(event.data)
      self:doRandomCoinEventAction(event.data)
    end
    
    self:leadRoleMoveToNextTile(moveFinished)
  end
  
  local function mapEventFailed(evt)
    self:handleMoveError(evt.data.retCode)
  end
  
  local params = {missionId = self.currentMissionId, step = self.currentFinishedStep + 1, routeId = self.currentRouteId , DoNotCaptureFailueMessage = true}
  local request = TriggerCoinEventRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.TriggerCoinSucceed, triggerCoinSucceed)
  request:addEventListener(RequestNotifyEnum.MapEventFailed, mapEventFailed)
  request:start() 
end

function ChapterMapScene:doCoinEventAction(eventData)
  local aFinishedType = CountryManager:sharedManager():moveToNextStep(self.currentMissionId, self.currentFinishedStep + 1, self.currentRouteId)
  self:resetMissionData()
  local aReward = eventData.rewards[1]
  local aEventLayer = self.tiledMap:layerNamed("event")
  local aMapPosOfEvent = ccp(self.currentPos.x, self.tiledMap.mapSize.height - 1 - self.currentPos.y)
  aEventLayer:removeTileAt(aMapPosOfEvent)
  local aFullBoxSprite = Sprite:createWithSpriteFrameName("box_moneyFull.png")
  local aPos2 = self:convertFromCoorToMapOrthogonalSpace(self.currentPos)
  aFullBoxSprite:setScale(box_scale_factor)
  aFullBoxSprite:setPosition(aPos2)
  self.tiledMap:addChild(aFullBoxSprite)
  local aPos3 = ccp(0,0)
  aPos3.x = aPos2.x + self.tiledMap:getPositionX()
  aPos3.y = aPos2.y - aFullBoxSprite:getContentSize().height / 2.0 + self.tiledMap:getPositionY()
  
  local function getRewardFunc()
    RewardManager:getReward(eventData.rewards)
  end
  
  self:sprinkleCoins(aFullBoxSprite, aPos3, aReward.amount, aFinishedType, getRewardFunc)
end

function ChapterMapScene:sprinkleCoins(aFullBoxSprite, aLocation, aCoinNum, aFinishedType, aGetRewardFunc)
  local aNum
  aCoinNum = tonumber(aCoinNum, 10)
  if aCoinNum <= 100 then
    aNum = 5
  elseif aCoinNum <= 1000 then
    aNum = 8
  elseif aCoinNum <= 10000 then
    aNum = 10
  else
    aNum = 12
  end
  
  local function doLabelAction()
    local aBuilder = LayoutBuilder:createWithContentsOfFile("scene/map_new.json")
    local aLabel = aBuilder:build("coinEventLabel")
    aLabel:getChildByName("txt_coinEventNum"):getChildByName("txt_coinEventNum"):setString(string.format("+%d", aCoinNum))
    aLabel:setPosition(aLocation)
    self:addChild(aLabel)
    
    local function removeLabel()
      aLabel:removeFromParentAndCleanup(true)
    end
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.8, ccp(0, 150)))
    arr:addObject(CCCallFunc:create(removeLabel))
    aLabel:runAction(CCSequence:create(arr))
    aLabel:getChildByName("txt_coinEventNum"):getChildByName("txt_coinEventNum"):runAction(CCFadeOut:create(0.8))
    aLabel:getChildByName("icn_common_goldCoin"):runAction(CCFadeOut:create(0.8))
  end
  
  local aCoinSpriteList = {}
  local aFallDownNum = 0
  local aCollectNum = 0
  local function coinFallDownFinished()
    aFallDownNum = aFallDownNum + 1
    if aFallDownNum >= aNum then
      local aDestinationPos = self.BaseUi:getChildByName("home_menu_title"):getChildByName("icon_silverCoin"):getPosition()
      aDestinationPos = self.BaseUi:getChildByName("home_menu_title"):convertToWorldSpace(ccp(aDestinationPos.x, aDestinationPos.y))
      for i, aCoin in ipairs(aCoinSpriteList) do
        local function coinCollectFinished()
          aCollectNum = aCollectNum + 1
          aCoin:removeFromParentAndCleanup(true)
          if aCollectNum >= aNum then
            aGetRewardFunc()
            local aEmptyBoxSprite = Sprite:createWithSpriteFrameName("box_moneyEmpty.png")
            aEmptyBoxSprite:setScale(box_scale_factor)
            aEmptyBoxSprite:setPosition(ccp(aFullBoxSprite:getPositionX(), aFullBoxSprite:getPositionY()))
            self.tiledMap:addChild(aEmptyBoxSprite)
            aFullBoxSprite:removeFromParentAndCleanup(true)
            self:eventHandleFinished()
            if aFinishedType == ChapterEventFinishedType.kEventFinished then
            
            elseif aFinishedType == ChapterEventFinishedType.kMissionFinished then
              CCMessageBox("Mission Complete!", "Mission Complete!")
            elseif aFinishedType == ChapterEventFinishedType.kChapterFinished then
              CCMessageBox("Chapter Complete!", "Chapter Complete!")
              self:moveToCityMain()
            end
          end
        end
        
        local arr = CCArray:create()
        arr:addObject(CCDelayTime:create(0.05 * (i - 1)))
        if i == 1 then
          arr:addObject(CCCallFunc:create(doLabelAction))
        end
        arr:addObject(CCMoveTo:create(0.3, ccp(aDestinationPos.x, aDestinationPos.y)))
        arr:addObject(CCCallFunc:create(coinCollectFinished))
        aCoin:runAction(CCSequence:create(arr))
      end
      
    end
  end
  
  for i = 1, aNum do
    math.randomseed(100 * i + os.time())
    local aDistance = math.random(-40, 40)
    local aCoin = Sprite:create("map/others/icon_jingbi.png")
    aCoin:setScale(0.5)
    aCoin:setPosition(aLocation)
    aCoin:setOpacity(0)
    self:addChild(aCoin)
    table.insert(aCoinSpriteList, aCoin)
    
    aCoin:runAction(CCFadeIn:create(0.2))
    aCoin:runAction(CCScaleTo:create(0.3, 1.0))
    local arr = CCArray:create()
    arr:addObject(CCJumpBy:create(0.3, ccp(aDistance, 0), 70, 1))
    arr:addObject(CCJumpBy:create(0.2, ccp(aDistance / 2, 0), 20, 1))
    arr:addObject(CCJumpBy:create(0.1, ccp(aDistance / 3, 0), 10, 1))
    arr:addObject(CCCallFunc:create(coinFallDownFinished))
    aCoin:runAction(CCSequence:create(arr))
  end
end

function ChapterMapScene:handleExpEvent()
  local function triggerExpSucceed(event)
    local function moveFinished()
      self:removeMaskAtPos(self.currentPos)
      self:showDecreaseEnergy()
      
      --self:doExpEventAction(event.data)
      self:doRandomExpEventAction(event.data)
    end
    
    self:leadRoleMoveToNextTile(moveFinished)
    
  end
  
  local function mapEventFailed(evt)
    self:handleMoveError(evt.data.retCode)
  end
  
  local params = {missionId = self.currentMissionId, step = self.currentFinishedStep + 1, routeId = self.currentRouteId , DoNotCaptureFailueMessage = true}
  local request = TriggerExpEventRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.TriggerExpSucceed, triggerExpSucceed)
  request:addEventListener(RequestNotifyEnum.MapEventFailed, mapEventFailed)
  request:start() 
end

function ChapterMapScene:doExpEventAction(eventData)
  local aFinishedType = CountryManager:sharedManager():moveToNextStep(self.currentMissionId, self.currentFinishedStep + 1, self.currentRouteId)
  self:resetMissionData()
  local aReward = eventData.rewards[1]
  --print("exp num " .. aReward.amount)
  local aEventLayer = self.tiledMap:layerNamed("event")
  local aMapPosOfEvent = ccp(self.currentPos.x, self.tiledMap.mapSize.height - 1 - self.currentPos.y)
  aEventLayer:removeTileAt(aMapPosOfEvent)
  local aFullBoxSprite = Sprite:createWithSpriteFrameName("box_expFull.png")
  aFullBoxSprite:setScale(box_scale_factor)
  local aPos2 = self:convertFromCoorToMapOrthogonalSpace(self.currentPos)
  aFullBoxSprite:setPosition(aPos2)
  self.tiledMap:addChild(aFullBoxSprite)
  local aPos3 = ccp(0,0)
  aPos3.x = aPos2.x + self.tiledMap:getPositionX()
  aPos3.y = aPos2.y - aFullBoxSprite:getContentSize().height / 2.0 + self.tiledMap:getPositionY()
  
  local function getRewardFunc()
    RewardManager:getReward(eventData.rewards)
  end
  
  self:sprinkleExps(aFullBoxSprite, aPos3, aReward.amount, aFinishedType, getRewardFunc)
end

function ChapterMapScene:sprinkleExps(aFullBoxSprite, aLocation, aExpNum, aFinishedType, aGetRewardFunc)
  local aNum
  aExpNum = tonumber(aExpNum, 10)
  if aExpNum <= 100 then
    aNum = 5
  elseif aExpNum <= 1000 then
    aNum = 8
  elseif aExpNum <= 10000 then
    aNum = 10
  else
    aNum = 12
  end
  
  local function doLabelAction()
    local aBuilder = LayoutBuilder:createWithContentsOfFile("scene/map_new.json")
        local aLabel = aBuilder:build("expEventLabel")
        aLabel:getChildByName("txt_coinEventNum"):getChildByName("txt_coinEventNum"):setString(string.format("+%d", aExpNum))
    aLabel:setPosition(aLocation)
    self:addChild(aLabel)
    
    local function removeLabel()
      aLabel:removeFromParentAndCleanup(true)
    end
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.8, ccp(0, 150)))
    arr:addObject(CCCallFunc:create(removeLabel))
    aLabel:runAction(CCSequence:create(arr))
    aLabel:getChildByName("txt_coinEventNum"):getChildByName("txt_coinEventNum"):runAction(CCFadeOut:create(0.8))
        aLabel:getChildByName("icon_expEvent"):runAction(CCFadeOut:create(0.8))
  end
  
  local aCoinSpriteList = {}
  local aFallDownNum = 0
  local aCollectNum = 0
  local function coinFallDownFinished()
    aFallDownNum = aFallDownNum + 1
    if aFallDownNum >= aNum then
      local aDestinationPos = self.BaseUi:getChildByName("home_menu_title"):getChildByName("icon_playerExp"):getPosition()
      aDestinationPos = self.BaseUi:getChildByName("home_menu_title"):convertToWorldSpace(ccp(aDestinationPos.x, aDestinationPos.y))
      for i, aCoin in ipairs(aCoinSpriteList) do
        local function coinCollectFinished()
          aCollectNum = aCollectNum + 1
          aCoin:removeFromParentAndCleanup(true)
          if aCollectNum >= aNum then
            aGetRewardFunc()
            local aEmptyBoxSprite = Sprite:createWithSpriteFrameName("box_expEmpty.png")
            aEmptyBoxSprite:setScale(box_scale_factor)
            aEmptyBoxSprite:setPosition(ccp(aFullBoxSprite:getPositionX(), aFullBoxSprite:getPositionY()))
            self.tiledMap:addChild(aEmptyBoxSprite)
            aFullBoxSprite:removeFromParentAndCleanup(true)
            local function checkUserLevelUpCallback()
              self:eventHandleFinished()
              if aFinishedType == ChapterEventFinishedType.kEventFinished then
              
              elseif aFinishedType == ChapterEventFinishedType.kMissionFinished then
                CCMessageBox("Mission Complete!", "Mission Complete!")
              elseif aFinishedType == ChapterEventFinishedType.kChapterFinished then
                CCMessageBox("Chapter Complete!", "Chapter Complete!")
                self:moveToCityMain()
              end
            end
            UserLevelManager.checkUserLevelUp(checkUserLevelUpCallback)
          end
        end
        
        local arr = CCArray:create()
        arr:addObject(CCDelayTime:create(0.05 * (i - 1)))
        if i == 1 then
          arr:addObject(CCCallFunc:create(doLabelAction))
        end
        arr:addObject(CCMoveTo:create(0.3, ccp(aDestinationPos.x, aDestinationPos.y)))
        arr:addObject(CCCallFunc:create(coinCollectFinished))
        aCoin:runAction(CCSequence:create(arr))
      end
      
    end
  end
  
  for i = 1, aNum do
    math.randomseed(100 * i + os.time())
    local aDistance = math.random(-40, 40)
    local aCoin = Sprite:create("map/others/icon_guangqiu.png")
    aCoin:setScale(0.5)
    aCoin:setPosition(aLocation)
    aCoin:setOpacity(0)
    self:addChild(aCoin)
    table.insert(aCoinSpriteList, aCoin)
    
    aCoin:runAction(CCFadeIn:create(0.2))
    aCoin:runAction(CCScaleTo:create(0.3, 1.0))
    local arr = CCArray:create()
    arr:addObject(CCJumpBy:create(0.3, ccp(aDistance, 0), 70, 1))
    arr:addObject(CCJumpBy:create(0.2, ccp(aDistance / 2, 0), 20, 1))
    arr:addObject(CCJumpBy:create(0.1, ccp(aDistance / 3, 0), 10, 1))
    arr:addObject(CCCallFunc:create(coinFallDownFinished))
    aCoin:runAction(CCSequence:create(arr))
  end
end

function ChapterMapScene:handleCardEvent()
  local function triggerCardSucceed(event)
    local function moveFinished()
      self:removeMaskAtPos(self.currentPos)
      self:showDecreaseEnergy()
      
      --self:doCardEventAction(event.data)
      self:doCardEventAction(event.data, true)
    end
    
    self:leadRoleMoveToNextTile(moveFinished)
  end
  
  local function mapEventFailed(evt)
    self:handleMoveError(evt.data.retCode)
  end
  
  local params = {missionId = self.currentMissionId, step = self.currentFinishedStep + 1, routeId = self.currentRouteId , DoNotCaptureFailueMessage = true}
  local request = TriggerCardEventRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.TriggerCardSucceed, triggerCardSucceed)
  request:addEventListener(RequestNotifyEnum.MapEventFailed, mapEventFailed)
  request:start() 
end

function ChapterMapScene:doCardEventAction(eventData, whetherRandom)
  CanonPlayEffect("music/sfx_card_possess.wav")
  local aFinishedType = CountryManager:sharedManager():moveToNextStep(self.currentMissionId, self.currentFinishedStep + 1, self.currentRouteId)
  self:resetMissionData()
  RewardManager:getReward(eventData.rewards)
  local rewards = eventData.rewards
  if(not rewards or #rewards <= 0) then
    self:eventHandleFinished({encounterMultiPlayerBoss = eventData.encounterMultiPlayerBoss, multiPlayerBossInfo = eventData.multiPlayerBossInfo})
    if aFinishedType == ChapterEventFinishedType.kEventFinished then
    
    elseif aFinishedType == ChapterEventFinishedType.kMissionFinished then
      CCMessageBox("Mission Complete!", "Mission Complete!")
    elseif aFinishedType == ChapterEventFinishedType.kChapterFinished then
      CCMessageBox("Chapter Complete!", "Chapter Complete!")
      self:moveToCityMain()
    end
    return 
  end
  local aReward = rewards[1]
  
  local aFullBoxSprite
  if not whetherRandom then
    local aEventLayer = self.tiledMap:layerNamed("event")
    local aMapPosOfEvent = ccp(self.currentPos.x, self.tiledMap.mapSize.height - 1 - self.currentPos.y)
    aEventLayer:removeTileAt(aMapPosOfEvent)
    aFullBoxSprite = Sprite:createWithSpriteFrameName("box_cardFull.png")
    aFullBoxSprite:setScale(box_scale_factor)
    local aPos2 = self:convertFromCoorToMapOrthogonalSpace(self.currentPos)
    aFullBoxSprite:setPosition(aPos2)
    self.tiledMap:addChild(aFullBoxSprite)
  end
  
  self:popuoutCard(eventData, aFullBoxSprite, aReward, aFinishedType, whetherRandom)
end

function ChapterMapScene:popuoutCard(eventData, aFullBoxSprite, aReward, aFinishedType, whetherRandom)
  local card3_co
  local card_back
  local aTempLayer
  local function cardExitActinoFinished()
    card3_co:removeFromParentAndCleanup(true)
    if not whetherRandom then
      local aEmptyBoxSprite = Sprite:createWithSpriteFrameName("box_cardEmpty.png")
      aEmptyBoxSprite:setScale(box_scale_factor)
      aEmptyBoxSprite:setPosition(ccp(aFullBoxSprite:getPositionX(), aFullBoxSprite:getPositionY()))
      self.tiledMap:addChild(aEmptyBoxSprite)
      aFullBoxSprite:removeFromParentAndCleanup(true)
    end
    
    self:eventHandleFinished({encounterMultiPlayerBoss = eventData.encounterMultiPlayerBoss, multiPlayerBossInfo = eventData.multiPlayerBossInfo})
    if aFinishedType == ChapterEventFinishedType.kEventFinished then
    
    elseif aFinishedType == ChapterEventFinishedType.kMissionFinished then
      CCMessageBox("Mission Complete!", "Mission Complete!")
    elseif aFinishedType == ChapterEventFinishedType.kChapterFinished then
      CCMessageBox("Chapter Complete!", "Chapter Complete!")
      self:moveToCityMain()
    end
  end
  
  local function onTouchEvent(evt)
    CanonPlayEffect("music/sfx_card_possess2.wav")
    
    local aCardName = Localization:getInstance():getText(MetaManager.card_meta[aReward.metaId].name)
    local aContent = Localization:getInstance():getText("gotCard", {name = aCardName})
    SuspensionLabel:showContent(self, aContent, nil, 1.0)
    
    aTempLayer:removeEventListener(DisplayEvents.kTouchBegin, onTouchEvent)
    aTempLayer:removeFromParentAndCleanup(true)
    local arr = CCArray:create()
    arr:addObject(CCMoveBy:create(0.05, ccp(0, -30)))
    arr:addObject(CCMoveBy:create(0.25, ccp(0, 230)))
    arr:addObject(CCCallFunc:create(cardExitActinoFinished))
    card3_co:runAction(CCSequence:create(arr))
    local children = card3_co.refCocosObj:getChildren()
    local len = children:count()
    for i = 0, len - 1 do
      local aNode = children:objectAtIndex(i)
      local className = toluahelper.getClass(aNode)
      local child
      if className == "CCLabelBMFont" then
        child = tolua.cast(aNode, "CCLabelBMFont")
      else
        child = tolua.cast(aNode, "CCNodeRGBA")
      end
      arr = CCArray:create()
      arr:addObject(CCDelayTime:create(0.05))
      arr:addObject(CCFadeOut:create(0.25))
      child:runAction(CCSequence:create(arr))
    end
  end
  
  local function cardActinoFinished()
    aTempLayer = Layer:create()
    aTempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(aTempLayer)
    aTempLayer:addEventListener(DisplayEvents.kTouchBegin, onTouchEvent)
  end
  
  local function setBackVisible()
    card_back:setVisible(true)
  end
  
  local function setBackInvisible()
    card_back:setVisible(false)
  end
  
  card3_co = getBigCanonCardNoInfoByMetaId(aReward.metaId)
  card3_co:setPosition( ccp(visibleSize.width / 2.0, visibleSize.height / 2.0 - 100))
  card3_co:setScale(0.3)
  self:addChild(card3_co)
  card3_co:runAction(CCOrbitCamera:create(0.0, 1.0, 0.0, 0.0, -180.0, 0.0, 0.0))
  
  card_back = Sprite:create("#card_back.png")
  card3_co:addChild(card_back)
  local children = card3_co.refCocosObj:getChildren()
  local len = children:count()
  for i = 0, len - 1 do
    local aNode = children:objectAtIndex(i)
    local className = toluahelper.getClass(aNode)
    local child
    if className == "CCLabelBMFont" then
      child = tolua.cast(aNode, "CCLabelBMFont")
    else
      child = tolua.cast(aNode, "CCNodeRGBA")
    end
    child:setOpacity(0)
    child:runAction(CCFadeIn:create(0.2))
  end
  local arr = CCArray:create()
  local arr2 = CCArray:create()
  local arr5 = CCArray:create()
  arr5:addObject(CCMoveBy:create(0.2, ccp(0, 130)))
  arr5:addObject(CCMoveBy:create(0.05, ccp(0, -30)))
  arr2:addObject(CCSequence:create(arr5))
  arr:addObject(CCSpawn:create(arr2))
  arr:addObject(CCDelayTime:create(0.3))
  local arr3 = CCArray:create()
  local orbitAction = CCOrbitCamera:create(0.9, 1.0, 0.0, 0.0, -720.0, 0.0, 0.0)
  arr3:addObject(orbitAction)
  arr3:addObject(CCScaleTo:create(0.9, 1.5))
  local arr4 = CCArray:create()
  arr4:addObject(CCDelayTime:create(0.15))
  arr4:addObject(CCCallFunc:create(setBackInvisible))
  arr4:addObject(CCDelayTime:create(0.3))
  arr4:addObject(CCCallFunc:create(setBackVisible))
  arr4:addObject(CCDelayTime:create(0.3))
  arr4:addObject(CCCallFunc:create(setBackInvisible))
  arr3:addObject(CCSequence:create(arr4))
  arr:addObject(CCEaseOut:create(CCSpawn:create(arr3), 2.5))
  arr:addObject(CCCallFunc:create(cardActinoFinished))
  card3_co:runAction(CCSequence:create(arr))
  
end

function ChapterMapScene:handleEmptyEvent()
  local function continueAutoMove(dt)
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.continueMoveScriptEntry)
    self:readyToMoveToNextTile()
  end
  
  local function triggerEmptySucceed(event)
    local function moveFinished()
      self:showDecreaseEnergy()
      local aFinishedType = CountryManager:sharedManager():moveToNextStep(self.currentMissionId, self.currentFinishedStep + 1, self.currentRouteId)
      self:resetMissionData()
      if aFinishedType == ChapterEventFinishedType.kEventFinished then
      
      elseif aFinishedType == ChapterEventFinishedType.kMissionFinished then
        CCMessageBox("Mission Complete!", "Mission Complete!")
      elseif aFinishedType == ChapterEventFinishedType.kChapterFinished then
        CCMessageBox("Chapter Complete!", "Chapter Complete!")
        self:moveToCityMain()
        return
      end
      
      if BagCalcManager.isFull() then
        self:eventHandleFinished()
        --旧的提示会卡
        -- local aContent = Localization:getInstance():getText("bagFull_move")
        -- SuspensionLabel:showContent(self, aContent)
        local text = Localization:getInstance():getText("bagFull_move")
        self.targetInfoPanel = NewPackageFullPanel:show()
      else
        self:disableUserInterface()
        self.continueMoveScriptEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(continueAutoMove, 0.5, false)
      end
    end
    
    self:leadRoleMoveToNextTile(moveFinished)
  end
  
  local function mapEventFailed(evt)
    self:handleMoveError(evt.data.retCode)
  end
  
  local params = {missionId = self.currentMissionId, step = self.currentFinishedStep + 1, routeId = self.currentRouteId , DoNotCaptureFailueMessage = true}
  local request = TriggerEmptyEventRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.TriggerEmptySucceed, triggerEmptySucceed)
  request:addEventListener(RequestNotifyEnum.MapEventFailed, mapEventFailed)
  request:start()
end

function ChapterMapScene:removeMaskAtPos(aCurrentPos)
  local aKey = string.format("%d_%d", aCurrentPos.x, aCurrentPos.y)
  self.markList[aKey]:removeFromParentAndCleanup(true)
  self.markList[aKey] = nil
end

function ChapterMapScene:handleRandomEvent()
  local function continueAutoMove(dt)
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.continueMoveScriptEntry)
    self:readyToMoveToNextTile()
  end
  
  local function triggerRandomSucceed(event)
    local function moveFinished()
      self:removeMaskAtPos(self.currentPos)
      self:showDecreaseEnergy()
      --print("eventType:" .. event.data.eventType)
      if event.data.eventType == 1 then   --battle
        self:doBattleEnterAction(event.data)
      elseif event.data.eventType == 3 then   --coin
        self:doRandomCoinEventAction(event.data)
      elseif event.data.eventType == 5 then   --card
        self:doCardEventAction(event.data, true)
      elseif event.data.eventType == 6 then   --normal exp
        self:doRandomExpEventAction(event.data)
      end
    end
    
    self:leadRoleMoveToNextTile(moveFinished)
  end
  
  local function mapEventFailed(evt)
    self:handleMoveError(evt.data.retCode)
  end
  
  local params = {missionId = self.currentMissionId, step = self.currentFinishedStep + 1, routeId = self.currentRouteId , DoNotCaptureFailueMessage = true}
  local request = TriggerRandomEventRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.TriggerRandomSucceed, triggerRandomSucceed)
  request:addEventListener(RequestNotifyEnum.MapEventFailed, mapEventFailed)
  request:start()
end

function ChapterMapScene:doRandomCoinEventAction(eventData)

  CanonPlayEffect("music/sfx_money_possess.wav")
  local aFinishedType = CountryManager:sharedManager():moveToNextStep(self.currentMissionId, self.currentFinishedStep + 1, self.currentRouteId)
  self:resetMissionData()
  RewardManager:getReward(eventData.rewards)
  local amount = eventData.rewards[1].amount
  local aPos2 = self:convertFromCoorToMapOrthogonalSpace(self.currentPos)
  local aLRPos2World = self.tiledMap:convertToWorldSpace(aPos2)
  --DOUBLE_REWARD_MODIFY
  local doubleRewardStr = nil
  if Activity_DoubleRewardLayer.getRewardEnableById(Activity_DoubleRewardLayer.MOUDLE_CHAPTERS) then
    --闯关多倍奖励已开启
    local doubleRate = Activity_DoubleRewardLayer.getRewardMultipleById(Activity_DoubleRewardLayer.MOUDLE_CHAPTERS)
    amount = amount / doubleRate
    doubleRewardStr = "x" .. doubleRate
  end

  MapEventLabel:showContent(self, "#sliver_coin.png", string.format("/%d", amount), aLRPos2World.x, aLRPos2World.y, doubleRewardStr)
  local function finishEvent()
    self:eventHandleFinished({encounterMultiPlayerBoss = eventData.encounterMultiPlayerBoss, multiPlayerBossInfo = eventData.multiPlayerBossInfo})
  end
  if eventData.encounterMultiPlayerBoss then
    local arr = CCArray:create()
    arr:addObject(CCDelayTime:create(1.1))
    arr:addObject(CCCallFunc:create(finishEvent))
    self:runAction(CCSequence:create(arr))
  else
    finishEvent()
  end
  
  if aFinishedType == ChapterEventFinishedType.kEventFinished then
  
  elseif aFinishedType == ChapterEventFinishedType.kMissionFinished then
    CCMessageBox("Mission Complete!", "Mission Complete!")
  elseif aFinishedType == ChapterEventFinishedType.kChapterFinished then
    CCMessageBox("Chapter Complete!", "Chapter Complete!")
    self:moveToCityMain()
  end
end

function ChapterMapScene:doRandomExpEventAction(eventData)
  CanonPlayEffect("music/sfx_exp_possess.wav")
  local aFinishedType = CountryManager:sharedManager():moveToNextStep(self.currentMissionId, self.currentFinishedStep + 1, self.currentRouteId)
  self:resetMissionData()
  local amount = 0
  if #eventData.rewards ~= 0 then
    amount = eventData.rewards[1].amount
  end
  local aPos2 = self:convertFromCoorToMapOrthogonalSpace(self.currentPos)
  local aLRPos2World = self.tiledMap:convertToWorldSpace(aPos2)
  if amount ~= 0 then
    MapEventLabel:showContent(self, "#EXP.png", string.format("/%d", amount), aLRPos2World.x, aLRPos2World.y)
    RewardManager:getReward(eventData.rewards)
  end

  local function add_Exp_callback()
    local function checkUserLevelUpCallback()
      local function finishEvent()
        self:eventHandleFinished({encounterMultiPlayerBoss = eventData.encounterMultiPlayerBoss, multiPlayerBossInfo = eventData.multiPlayerBossInfo})
      end
      if eventData.encounterMultiPlayerBoss then
        local arr = CCArray:create()
        arr:addObject(CCDelayTime:create(1.1))
        arr:addObject(CCCallFunc:create(finishEvent))
        self:runAction(CCSequence:create(arr))
      else
        finishEvent()
      end
      
      if aFinishedType == ChapterEventFinishedType.kEventFinished then
      
      elseif aFinishedType == ChapterEventFinishedType.kMissionFinished then
        CCMessageBox("Mission Complete!", "Mission Complete!")
      elseif aFinishedType == ChapterEventFinishedType.kChapterFinished then
        CCMessageBox("Chapter Complete!", "Chapter Complete!")
        self:moveToCityMain()
      end
    end
    
    UserLevelManager.checkUserLevelUp(checkUserLevelUpCallback)
  end
  local levelLabel = g_BaseUISceneObject:getChildByName("home_menu_title"):getChildByName("txt_home_lv"):getChildByName("font")
  local expLabel = g_BaseUISceneObject:getChildByName("home_menu_title"):getChildByName("txt_icon_playerExp_num"):getChildByName("font")
  local expBar = g_BaseUISceneExpBar[0]
  doUIActionForAddedExp(levelLabel, expLabel, expBar, add_Exp_callback)
end

function ChapterMapScene:resetMissionData()
  self.currentMissionId = CountryManager:sharedManager().missionContext.missionId
  self.currentRouteId = CountryManager:sharedManager().missionContext.routeId
  self.currentFinishedStep = CountryManager:sharedManager().missionContext.finishedStep
end

function ChapterMapScene:doFloatAction()
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(lead_role_up_duration, ccp(0, lead_role_up_distance)))
  arr:addObject(CCMoveBy:create(lead_role_up_duration, ccp(0, -lead_role_up_distance)))
  self.leadRole:runAction(CCRepeatForever:create(CCSequence:create(arr)))
end

function ChapterMapScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function ChapterMapScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  --
  CanonPlayBackgroundMusic("music/m_map.mp3", true)
  self:disableUserInterface()
end

function ChapterMapScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  --[[
  local layerNameList = {"rock", "hill", "shuguo", "event", "grass"}
  for i = 1, #layerNameList do
		local aTMXLayer = self.tiledMap:layerNamed(layerNameList[i])
    local aLayerSize = aTMXLayer:getLayerSize()
		for j = 0, aLayerSize.width - 1 do
      for k = 0, aLayerSize.height - 1 do
        local aChild = aTMXLayer:tileAt(ccp(j, k))
        if aChild then
          aChild:setOpacity(0)
          aChild:runAction(CCFadeIn:create(0.5))
        end
      end
    end
	end]]--
  if not self.ignoreAction then
    self.tiledMap:setScale(0.5)
    local arr = CCArray:create()
    arr:addObject(CCEaseOut:create(CCScaleTo:create(1.0, 1.0), 1.5))
    arr:addObject(CCCallFunc:create(enterActionFinished))
    self.tiledMap:runAction(CCSequence:create(arr))
    
    local fspt = FlashSprite:create("map/others/flashPack/Cloud")
    fspt:changeAnimation(0)
    fspt:setLoop(false)
    local fspt_co = CocosObject.new(fspt)
    local function onCloudFlashAnimationEnd(anim)
      fspt:unregisterEndAnimationScriptHandler()
      self:removeChild(fspt_co)
      --Set_ShareData( "Cloud_Finished", 1 )
	  self.fspt = nil;
    end
self.fspt = fspt
    fspt:registerEndAnimationScriptHandler(onCloudFlashAnimationEnd)
    self:addChild(fspt_co)
  else
    local arr = CCArray:create()
    arr:addObject(CCCallFunc:create(enterActionFinished))
    self.tiledMap:runAction(CCSequence:create(arr))
  end
end

function ChapterMapScene:dispose()
if self.fspt and self.fspt.unregisterEndAnimationScriptHandler then
self.fspt:unregisterEndAnimationScriptHandler()
end
ChapterMapScene.super.dispose(self)
end

function ChapterMapScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  
  local function exeNewGuide()
	if IsGuideExecuted(GuideConfig.kRisk3) and not IsGuideExecuted(GuideConfig.kCardOn) and DataManager.getCurrUser().level >= 5 then --主要新手引导的最后一个执行完后，才执行这个
		ExeNewGuide(GuideConfig.kCardOn)
	end
  end
  
  local checkDialogRunEntry
  local function checkDialogRun( dt )
    if Get_ShareData( "New_User_Guide_Running" ) ~= 1 then
      CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(checkDialogRunEntry)
      checkDialogRunEntry = nil
      exeNewGuide()
    end
	end
  checkDialogRunEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(checkDialogRun, 0, false)
  
  --
  --self:doFloatAction()
  self.moveDirections = self:moveDirectionOfLeadRole(self.currentPos, self.currentDirection)
  self:startScheduleUpdateMapPos()
  
  local function checkNewUserGuide()
    --print("ready to:" .. self.currentFinishedStep)
    Set_ShareData( "Walk_Step", self.currentFinishedStep)
  end
  
  local showUnlockContent = true
  if (not self.newMissionId) or (not existInMissionUnlockConfig(self.newMissionId)) then
    showUnlockContent = false
  end
  if not showUnlockContent then
    --print("not showUnlockContent")
    --print("____3")
    self:enableUserInterface()
    --print("____4")
    checkNewUserGuide()
    --print("____5")
    Set_ShareData( "Cloud_Finished", 1 )
    
    if self.multiBossInfo and self.multiBossInfo.encounterMultiPlayerBoss then
      self:enterMultiplayerBossChallengeScene(self.multiBossInfo.multiPlayerBossInfo)
    end
    
    return
  end
  
  Set_ShareData( "Cloud_Finished", 1 )
  local function unlockCallback(aSceneType)
    if aSceneType == UnlockReturnSceneEnum.kEliteScene then
      self:moveToElite()
    end
  end
  local aPanel = MissionUnlockContentPanel:create(self, unlockCallback, self.newMissionId)
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function ChapterMapScene:moveToElite()
  self:replaceScene(EliteMissionScene)
end

function ChapterMapScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function ChapterMapScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
  self:disableUserInterface()
end

function ChapterMapScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  --[[
  local layerNameList = {"rock", "hill", "shuguo", "event", "grass"}
  for i = 1, #layerNameList do
		local aTMXLayer = self.tiledMap:layerNamed(layerNameList[i])
    local aLayerSize = aTMXLayer:getLayerSize()
		for j = 0, aLayerSize.width - 1 do
      for k = 0, aLayerSize.height - 1 do
        local aChild = aTMXLayer:tileAt(ccp(j, k))
        if aChild then
          aChild:runAction(CCFadeOut:create(0.5))
        end
      end
    end
	end]]--
  local arr = CCArray:create()
  --arr:addObject(CCFadeOut:create(0.5))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.leadRole:runAction(CCSequence:create(arr))
end

function ChapterMapScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function ChapterMapScene:back()
  self:replaceScene(MainMenuScene)
  --[[
  local argv = {enterScene="ChapterMapScene",returnScene=nil,params={notReset=false}}
  self.ignoreAction = false
  self:replaceScene(CityMainScene, argv)]]
end

function ChapterMapScene:moveToCityMain()
  local argv = {enterScene="ChapterMapScene",returnScene=nil,params={notReset=false}}
  self.ignoreAction = false
  self:replaceScene(CityMainScene, argv)
end

function ChapterMapScene:enableUserInterface()
  --print("____enableUserInterface")
  if self.userInterfaceEnabled == 1 then
    return
  end
  self.userInterfaceEnabled = 1
  self.targetInfoPanel = nil
  if self.tempLayer then
    self.tempLayer:removeFromParentAndCleanup(true)
  end
  self:showSelectDirUI()
  Set_ShareData( "Menu_Can_Click_In_Map", 1 )
end

function ChapterMapScene:disableUserInterface()
  if self.userInterfaceEnabled == 0 then
    return
  end
  self.userInterfaceEnabled = 0
  self.tempLayer = Layer:create()
  self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self.targetInfoPanel = self.tempLayer
  self:addChild(self.tempLayer)
  self:hideSelectDirUI()
  
end

function ChapterMapScene:showEnergyLimitPanel()
  --[[
  CanonMessageBox.showText(
    ShowButtonType.ID_OK_CANCEL,
    getTextByKey("stage_noEnergy"),
    {
      callBackFunc = function()
        self:showMainActorPanel()
      end
    }
  )
  --]]
  --[[
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kMapEnergyLimit)
  self:addChild(aPanel)
  aPanel:scaleIn()
  --]]
  local function callback()
  end
  local aPanel = EENPSupplyPanel:create(self, {supplyType = EESupplyTypeEnum.Energy, callback = callback})
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function ChapterMapScene:showEquipCardPanel(gridEnough, trainOpt)
  local aPanel
  if gridEnough then
    aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.putonCardEnough, trainOpt )
  else
    aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.putonCardNotEnough, trainOpt )
  end
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function ChapterMapScene:moveOnFromEquipCardPanel(trainOpt)
  local aSelectedDir = trainOpt.selectedDir
  if aSelectedDir then
    for aIndex, aValue in ipairs(self.moveDirections) do
      if aValue == aSelectedDir then
          self.currentRouteId = self.currentRouteId + aIndex - 1
        break
      end
    end
    self.selectDir = aIndex
  else
    self.selectDir = 1
  end
  self:readyToMoveToNextTile()
end

function ChapterMapScene:showUseEnergyProptPanel(energyPropList)
  local function callback(aEnergyPropId)
    self:recoveryEnergy(aEnergyPropId)
  end
  local aPanel = EEPSupplyPanel:create(self, energyPropList, callback, true)
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function ChapterMapScene:showMainActorPanel()
  self.targetInfoPanel = MainActorPanel:create( self )
  PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
end

function ChapterMapScene:recoveryEnergy(aEnergyPropId)
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

function ChapterMapScene:panelDismiss()
  self:enableUserInterface()
end

function ChapterMapScene:showLevelLimitPanel(aLevelLimit)
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kMapChallengeLevelLimit, {levelLimit = aLevelLimit})
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function ChapterMapScene:showCannotBuyMissionCountPanel()
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kCannotBuyMissionCount, {})
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function ChapterMapScene:showTimeLimitPanel(aMissionId, aGoldNum, aSelectedDir)
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kMapChallengeTimeLimit, {missionId = aMissionId, glodNum = aGoldNum, extraArgs = {selectedDir = aSelectedDir}})
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function ChapterMapScene:readyToResetMissionCompleteCount(aMissionId, extraArgs)
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
    self:moveCommandReceived(extraArgs.selectedDir)
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

function ChapterMapScene:showGemLimitPanel()
  local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
  self:addChild(aPanel)
  aPanel:scaleIn()
  --[[
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kGemLimit)
  self:addChild(aPanel)
  aPanel:scaleIn()
  ]]
end

function ChapterMapScene:moveToIAPShop()
  self:replaceScene(ShopScene, {params = {tabIndex = TABLEVIEW_TAB_INDEX.CHARGE}})
end

function ChapterMapScene:handleMoveError(aErrorCode)
  local function canonMessageBoxCallback()
    self:enableUserInterface()
  end
  if aErrorCode == 710514 then
    CanonMessageBox:showSpecialErrorBox( ShowErrorCodeType.EC_REQUISITE_ENERGY_NOT_ENOUGH , nil , canonMessageBoxCallback)
    -- local hasEnergyProp, energyPropList = BagCalcManager.getEnergyPropList()
    -- if hasEnergyProp then
    --   self:showUseEnergyProptPanel(energyPropList)
    -- else
    --   self:showEnergyLimitPanel()
    -- end
  elseif aErrorCode == 710516 then
    self:enableUserInterface()
      --旧的提示会卡
      -- local aContent = Localization:getInstance():getText("bagFull_move")
      -- SuspensionLabel:showContent(self, aContent)
      local text = Localization:getInstance():getText("bagFull_move")
      self.targetInfoPanel = NewPackageFullPanel:show()
  elseif aErrorCode == 710404 then
    CanonMessageBox:showSpecialErrorBox( ShowErrorCodeType.EC_TRIGGER_BATTLE_EVENT , nil , canonMessageBoxCallback)
  else 
    CanonMessageBox:showCommUnHandleErrorBox(tonumber(aErrorCode), nil, canonMessageBoxCallback)
  end
end

function ChapterMapScene:whetherShouldRunDialog(activeOpportunity)
  local aStep = self.currentFinishedStep + 1
  local aMissionId
  for _, aConfig in pairs(self.chapter_event_configs) do
    if aConfig.step == aStep then
      aMissionId = aConfig.missionId
    end
  end
  
  if CountryManager:sharedManager():getMaxFinishedMissionID() >= self.currentMissionId then
    return false
  end
  local aConversationId = 0
  
  for _, aBattleChapterEventConfig in pairs(MetaManager.battle_chapter_event) do
    if (aBattleChapterEventConfig.missionId == aMissionId) and (aStep == aBattleChapterEventConfig.step) then
        if (self.currentRouteId == 1) then
          aConversationId = aBattleChapterEventConfig.conversation1
        elseif (self.currentRouteId == 2) then
          aConversationId = aBattleChapterEventConfig.conversation2
        elseif (self.currentRouteId == 3) then
          aConversationId = aBattleChapterEventConfig.conversation3
        end
      break
    end
  end
  if type(aConversationId) == "string" then
    aConversationId = tonumber(aConversationId:split("|")[1])
  end
  if aConversationId == 0 then
    return false
  end
  
  local foundFlag = false
  for _, aEventConversationConfig in ipairs(MetaManager.event_conversation) do
    if aEventConversationConfig.dialogId == aConversationId then
      foundFlag = true
      if aEventConversationConfig.activeOpportunity == activeOpportunity then
        return true, aConversationId
      end
    else
      if foundFlag then
        break
      end
    end
  end
  
  return false
end

function ChapterMapScene:refreshAddCardButton()
  if self.isDisposed then
    return
  end
  local showBtn = #CommonManager.getQueueData() < MetaManager.user_level[DataManager.getCurrUser().level].maxQueueCardNum and Get_ShareData("New_User_Guide_Running") ~= 1
  self.mapUI:getChildByName("story_bg_2"):setVisible(showBtn)
  self.mapUI:getChildByName("txt_newon"):setVisible(showBtn)
  self.mapUI:getChildByName("jiaren"):setVisible(showBtn)
  self.btnAddCard:setEnable(showBtn)
 end
