require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.Button"
require "hecore.display.Sprite"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "canon.models.CountryManager"

local cityBG_posY = 170
local map_show_height = 915

local enter_animation_duration = 0.3
local enter_animation_cell_duration = 0.15
local cell_move_distance = 190
local table_width = 168
local table_height = 838
local table_posX = 546
local table_posY = 237
local item_width = 168
local item_height = 100

local reselect_city_animation_duration = 0.2
local arrow_animation_duration = 0.5
local arrow_animation_distance = 20
--
-- CitySelectScene
--

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

CitySelectScene = class(BaseUIScene)

function CitySelectScene:ctor()
	
end

function CitySelectScene:create()
  local s = CitySelectScene.new()
  s:initScene()
  return s
end
--[[
local function onTouchBegin(evt)
  local aCitySelectScene = evt.context
  aCitySelectScene.lastTouchLocation = evt.globalPosition
end

local function onTouchMove(evt)
  local aCitySelectScene = evt.context
  local aOffsize = ccp(evt.globalPosition.x - aCitySelectScene.lastTouchLocation.x, evt.globalPosition.y - aCitySelectScene.lastTouchLocation.y)
  aCitySelectScene:correctPositionWithOffsize(aOffsize)
  aCitySelectScene.lastTouchLocation = evt.globalPosition
end

local function onTouchEnd(evt)
  
end
]]
local function cityButtonSelected(evt)
  local aCountryID = evt.target.userdata
  local aCitySelectScene = evt.context
  
  local aNormalDisplay = aCitySelectScene.ui:getChildByName(string.format("cityButton_%d", aCountryID)):getChildByName("city_normal")
  aNormalDisplay:setVisible(false)
  local aSelectDisplay = aCitySelectScene.ui:getChildByName(string.format("cityButton_%d", aCountryID)):getChildByName("city_select")
  aSelectDisplay:setVisible(true)
  
  for aIndex, aBtDisplay in ipairs(aCitySelectScene.btDisplayList) do
    if aBtDisplay == aNormalDisplay then
      table.remove(aCitySelectScene.btDisplayList, aIndex)
      table.insert(aCitySelectScene.btDisplayList, aIndex, aSelectDisplay)
      break
    end
  end
  
  aCitySelectScene.inChallengeDisplay:setVisible(false)
  aCitySelectScene.inChallengeDisplay = aCitySelectScene.ui:getChildByName(string.format("cityButton_%d", aCountryID)):getChildByName("icon_challenge")
  aCitySelectScene.inChallengeDisplay:setVisible(true)
  
  CountryManager:sharedManager():selectCountryID(aCountryID)
  aCitySelectScene.currentCountryID = CountryManager:sharedManager().selectedCountryID
  aCitySelectScene:back()
end

local function enterButtonSelected(evt)
  local aCitySelectScene = evt.context
  CountryManager:sharedManager():selectCountryID(aCitySelectScene.currentCountryID)
  aCitySelectScene:back()
end

function CitySelectScene:onInit()
	BaseUIScene.initBackGround(self)
  self.currentCountryID = CountryManager:sharedManager().selectedCountryID
  self.title = CountryManager:sharedManager():getCountryName(self.currentCountryID)
  
  --self.lastTouchLocation = nil
  self.cityBG = nil
  self.btDisplayList = {}
  self.inChallengeDisplay = nil
  self.labelDisplayList = {}
  self.labelNameList = {}
  self.selectedCell = nil
  
  self.cityBG = Sprite:create("#citySelectBg.png")
  self.cityBG:setPosition(ccp(0, cityBG_posY))
  self.cityBG:setScale(2)
  self.cityBG:setAnchorPoint(ccp(0, 0))
  self:addChild(self.cityBG)
  --self.cityBG.touchEnabled = true
  self.original_bg_posX = self.cityBG:getPositionX()
  self.original_bg_posY = self.cityBG:getPositionY()
  
	local builder = LayoutBuilder:createWithContentsOfFile("scene/citySelect_new.json")
  self.ui = builder:build("citySelect")
  self.ui:setScale(0.5)
  self.cityBG:addChild(self.ui)
  
  self.arrowUI = builder:build("icon_selectfuck")
  self:addChild(self.arrowUI)
  self:setArrowOriginalPos()
  self:hiddenFocusArrow()
  
  local controlUI = builder:build("citySelect_btn_area")
  self:addChild(controlUI)
  self.controlUI = controlUI
  
  local enterButtonDisplay = controlUI:getChildByName("btn_go")
  local enterButton = Button:create(enterButtonDisplay)
  enterButton:addEventListener(Events.kStart, enterButtonSelected, self)
  
  local allCountryIDs = CountryManager:sharedManager():getAllCountryIDs()
  local GameInitData = DataManager.getGameInitData()
  self.openedCountryIDList = {}
  for i = 1, #allCountryIDs do
    local aCountryID = allCountryIDs[i]
    local aBattleCountryConfig = MetaManager.battle_country[aCountryID]
    if aCountryID <= CountryManager:sharedManager():getLastOpenedCountryID() and tonumber(aBattleCountryConfig.levelMin, 10) <= GameInitData.sharkUser.level then
      table.insert(self.openedCountryIDList, aCountryID)
    else
      break
    end
  end
  
  local opened_max_countryid
  for i = 1, #allCountryIDs do
    local aDisplay = self.ui:getChildByName(string.format("cityButton_%d", allCountryIDs[i]))
    local aCountryID = allCountryIDs[i]
    local aBattleCountryConfig = MetaManager.battle_country[aCountryID]
    local aNormalDisplay = aDisplay:getChildByName("city_normal")
    local aDisableDisplay = aDisplay:getChildByName("city_disable")
    local aSelectDisplay = aDisplay:getChildByName("city_select")
    local aChallengeDisplay = aDisplay:getChildByName("icon_challenge")
    aChallengeDisplay:getChildByName("txt_icon_challenge"):setString(Localization:getInstance():getText("cityInChallenge"))
    if aCountryID <= CountryManager:sharedManager():getLastOpenedCountryID() and tonumber(aBattleCountryConfig.levelMin, 10) <= GameInitData.sharkUser.level then
      opened_max_countryid = aCountryID
      aNormalDisplay:setVisible(true)
      aDisableDisplay:setVisible(false)
      aSelectDisplay:setVisible(false)
      table.insert(self.btDisplayList, aNormalDisplay)
    else
      if (not self.nextUnopenedCountryId) and (aCountryID <= max_unlock_city_id) then
        self.nextUnopenedCountryId = aCountryID
      end
      aNormalDisplay:setVisible(false)
      aDisableDisplay:setVisible(true)
      aSelectDisplay:setVisible(false)
      table.insert(self.btDisplayList, aDisableDisplay)
    end
    --[[
    if self.currentCountryID == aCountryID then
      aChallengeDisplay:setVisible(true)
      self.inChallengeDisplay = aChallengeDisplay
    else
      aChallengeDisplay:setVisible(false)
    end]]
    aChallengeDisplay:setVisible(false)
    
    local aCityNameLabel = self.ui:getChildByName(string.format("cityLabel_%d", allCountryIDs[i]))
    local aCityName = aCityNameLabel:getChildByName("txt_city")
    aCityName:setString(CountryManager:sharedManager():getCountryName(aCountryID))
    table.insert(self.labelNameList, aCityName)
    local aNormalCityNameBg = aCityNameLabel:getChildByName("bg_citySelect_select")
    local aDisableCityNameBg = aCityNameLabel:getChildByName("bg_citySelect_disable")
    if aCountryID <= CountryManager:sharedManager():getLastOpenedCountryID() and tonumber(aBattleCountryConfig.levelMin, 10) <= GameInitData.sharkUser.level then
      aNormalCityNameBg:setVisible(true)
      aDisableCityNameBg:setVisible(false)
      table.insert(self.labelDisplayList, aNormalCityNameBg)
    else
      aNormalCityNameBg:setVisible(false)
      aDisableCityNameBg:setVisible(true)
      table.insert(self.labelDisplayList, aDisableCityNameBg)
    end
  end
  
  local aDisplay = self.ui:getChildByName(string.format("cityButton_%d", opened_max_countryid))
  self.inChallengeDisplay = aDisplay:getChildByName("icon_challenge")
  self.inChallengeDisplay:setVisible(true)
  
  self:resetCityBGPosition(false)
  
  if self.nextUnopenedCountryId then
    table.insert(self.openedCountryIDList, self.nextUnopenedCountryId)
  end
  
  self.cityTableView = self:createCityTableView()
  self:addChild(self.cityTableView)
  self.cityTableView:reloadData()
  self.originalOffsetY = self.cityTableView:getContentOffset().y
  local aOffsetY = self.originalOffsetY + (indexOfObject(self.openedCountryIDList, self.currentCountryID) - 7) * item_height
  local maxOffsetY = self.originalOffsetY + item_height * #self.openedCountryIDList - table_height
  if aOffsetY > maxOffsetY then
    aOffsetY = maxOffsetY
  end
  if aOffsetY < self.originalOffsetY then
    aOffsetY = self.originalOffsetY
  end
  self.cityTableView:setContentOffset(ccp(0, aOffsetY), false)
  
  --[[
  self.cityBG:addEventListener(DisplayEvents.kTouchBegin, onTouchBegin, self)
  self.cityBG:addEventListener(DisplayEvents.kTouchMove, onTouchMove, self)
  self.cityBG:addEventListener(DisplayEvents.kTouchEnd, onTouchEnd, self)
  ]]
	BaseUIScene.onInit(self)
end

function CitySelectScene:setArrowOriginalPos()
  local arrow_u = self.arrowUI:getChildByName("icon_chapter_u")
  local arrow_d = self.arrowUI:getChildByName("icon_chapter_d")
  local arrow_l = self.arrowUI:getChildByName("icon_chapter_l")
  local arrow_r = self.arrowUI:getChildByName("icon_chapter_r")
  self.arrowUI.arrow_u_x = arrow_u:getPositionX()
  self.arrowUI.arrow_u_y = arrow_u:getPositionY()
  self.arrowUI.arrow_d_x = arrow_d:getPositionX()
  self.arrowUI.arrow_d_y = arrow_d:getPositionY()
  self.arrowUI.arrow_l_x = arrow_l:getPositionX()
  self.arrowUI.arrow_l_y = arrow_l:getPositionY()
  self.arrowUI.arrow_r_x = arrow_r:getPositionX()
  self.arrowUI.arrow_r_y = arrow_r:getPositionY()
end

function CitySelectScene:showFocusArrow(aPos)
  if aPos then
    self.arrowUI:setPosition(ccp(aPos.x, aPos.y))
  end
  local arrow_u = self.arrowUI:getChildByName("icon_chapter_u")
  local arrow_d = self.arrowUI:getChildByName("icon_chapter_d")
  local arrow_l = self.arrowUI:getChildByName("icon_chapter_l")
  local arrow_r = self.arrowUI:getChildByName("icon_chapter_r")
  arrow_u:setVisible(true)
  arrow_u:setOpacity(0)
  local array = CCArray:create()
  array:addObject(CCMoveBy:create(arrow_animation_duration, ccp(0, arrow_animation_distance)))
  array:addObject(CCMoveBy:create(arrow_animation_duration, ccp(0, -arrow_animation_distance)))
  arrow_u:runAction(CCRepeatForever:create(CCSequence:create(array)))
  arrow_u:runAction(CCFadeIn:create(reselect_city_animation_duration))
  arrow_d:setVisible(true)
  arrow_d:setOpacity(0)
  array = CCArray:create()
  array:addObject(CCMoveBy:create(arrow_animation_duration, ccp(0, -arrow_animation_distance)))
  array:addObject(CCMoveBy:create(arrow_animation_duration, ccp(0, arrow_animation_distance)))
  arrow_d:runAction(CCRepeatForever:create(CCSequence:create(array)))
  arrow_d:runAction(CCFadeIn:create(reselect_city_animation_duration))
  arrow_l:setVisible(true)
  arrow_l:setOpacity(0)
  array = CCArray:create()
  array:addObject(CCMoveBy:create(arrow_animation_duration, ccp(-arrow_animation_distance, 0)))
  array:addObject(CCMoveBy:create(arrow_animation_duration, ccp(arrow_animation_distance, 0)))
  arrow_l:runAction(CCRepeatForever:create(CCSequence:create(array)))
  arrow_l:runAction(CCFadeIn:create(reselect_city_animation_duration))
  arrow_r:setVisible(true)
  arrow_r:setOpacity(0)
  array = CCArray:create()
 array:addObject(CCMoveBy:create(arrow_animation_duration, ccp(arrow_animation_distance, 0)))
  array:addObject(CCMoveBy:create(arrow_animation_duration, ccp(-arrow_animation_distance, 0)))
  arrow_r:runAction(CCRepeatForever:create(CCSequence:create(array)))
  arrow_r:runAction(CCFadeIn:create(reselect_city_animation_duration))
end

function CitySelectScene:hiddenFocusArrow()
  local arrow_u = self.arrowUI:getChildByName("icon_chapter_u")
  local arrow_d = self.arrowUI:getChildByName("icon_chapter_d")
  local arrow_l = self.arrowUI:getChildByName("icon_chapter_l")
  local arrow_r = self.arrowUI:getChildByName("icon_chapter_r")
  arrow_u:stopAllActions()
  arrow_u:setPosition(ccp(self.arrowUI.arrow_u_x, self.arrowUI.arrow_u_y))
  arrow_u:setVisible(false)
  arrow_d:stopAllActions()
  arrow_d:setPosition(ccp(self.arrowUI.arrow_d_x, self.arrowUI.arrow_d_y))
  arrow_d:setVisible(false)
  arrow_l:stopAllActions()
  arrow_l:setPosition(ccp(self.arrowUI.arrow_l_x, self.arrowUI.arrow_l_y))
  arrow_l:setVisible(false)
  arrow_r:stopAllActions()
  arrow_r:setPosition(ccp(self.arrowUI.arrow_r_x, self.arrowUI.arrow_r_y))
  arrow_r:setVisible(false)
end

function CitySelectScene:resetCityBGPosition(animated)
  local aDisplay = self.ui:getChildByName(string.format("cityButton_%d", self.currentCountryID))
  local display_pos = aDisplay:getPosition()
  local aOffsize = ccp(visibleSize.width / 2.0 - display_pos.x - aDisplay:getGroupBounds().size.width / 2.0, visibleSize.height / 2.0 - display_pos.y + aDisplay:getGroupBounds().size.height / 2.0)
  
  local aNewPos = self:getCorrectedPositionWithOffsize(aOffsize)
  self:showFocusArrow(ccp(visibleSize.width / 2.0 + aNewPos.x - aOffsize.x, visibleSize.height / 2.0 + aNewPos.y - aOffsize.y))
  if animated then
    self.cityBG:runAction(CCMoveTo:create(reselect_city_animation_duration, aNewPos))
  else
    self.cityBG:setPosition(aNewPos)
  end
end

function CitySelectScene:getCorrectedPositionWithOffsize(aOffsize)
  local aNewPos = ccp(self.original_bg_posX + aOffsize.x, self.original_bg_posY)
  local aWinSize = CCDirector:sharedDirector():getWinSize()
  if aNewPos.x > 0 then
    aNewPos.x = 0
  elseif aNewPos.x < aWinSize.width - self.cityBG:getGroupBounds().size.width then
    aNewPos.x = aWinSize.width - self.cityBG:getGroupBounds().size.width
  end
  --[[
  if aNewPos.y > 0 then
    aNewPos.y = 0
  elseif aNewPos.y < aWinSize.height - self.cityBG:getGroupBounds().size.height then
    aNewPos.y = aWinSize.height - self.cityBG:getGroupBounds().size.height
  end
  ]]
  return aNewPos 
  --self.cityBG:setPosition(aNewPos)
end

function CitySelectScene:selectCityCell(newCell, cityIndex)
  local aButtonDisplay = self.selectedCell:getChildByTag(-15)
  self:hiddenFocusArrow()
  local challangBg_y = aButtonDisplay:getChildByTag(-11)
  local challangBg_b = aButtonDisplay:getChildByTag(-12)
  if challangBg_y:isVisible() then
    challangBg_y:setVisible(false)
    challangBg_b:setVisible(true)
  end
  self.selectedCell = newCell
  aButtonDisplay = self.selectedCell:getChildByTag(-15)
  challangBg_y = aButtonDisplay:getChildByTag(-11)
  challangBg_b = aButtonDisplay:getChildByTag(-12)
  challangBg_y:setVisible(true)
  challangBg_b:setVisible(false)
  
  self.currentCountryID = self.openedCountryIDList[cityIndex]
  --print(self.currentCountryID)
  self:resetCityBGPosition(true)
end

function CitySelectScene:createCityTableView()
  local cellTag = 1024
  local buttonTag = {-15}
  local aCitySelectScene = self
  local CityTableViewRenderer = class(TableViewRenderer)
  function CityTableViewRenderer:ctor(width, height)
    self.list = aCitySelectScene.openedCountryIDList
  end
  function CityTableViewRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile("scene/citySelect_new.json")
    local aCell = builder:build("citySelect_cell")
    container:addChild(aCell)
    aCell:setTag(cellTag)
    
    local aButtonDisplay = aCell:getChildByName("btn_selectcity")
    aButtonDisplay:setTag(-15)
    local challangeLabel = aButtonDisplay:getChildByName("txt")
    challangeLabel:setTag(-10)
    local challangBg_y = aButtonDisplay:getChildByName("btn_yellow_short")
    challangBg_y:setTag(-11)
    local challangBg_b = aButtonDisplay:getChildByName("btn_blue_short")
    challangBg_b:setTag(-12)
    local challangBg_gray = aButtonDisplay:getChildByName("btn_inactive")
    challangBg_gray:setTag(-13)
  end
  function CityTableViewRenderer:setData( rawCocosObj, index )
    local aCell = self:getChildByTag(rawCocosObj, cellTag)
    local aButtonDisplay = aCell:getChildByTag(-15)
    local challangeLabel = aButtonDisplay:getChildByTag(-10)
    setNodeText(challangeLabel, CountryManager:sharedManager():getCountryName(self.list[index + 1]))
    local challangBg_y = aButtonDisplay:getChildByTag(-11)
    local challangBg_b = aButtonDisplay:getChildByTag(-12)
    local challangBg_gray = aButtonDisplay:getChildByTag(-13)
    if aCitySelectScene.currentCountryID == self.list[index + 1] then
      challangBg_y:setVisible(true)
      challangBg_b:setVisible(false)
      challangBg_gray:setVisible(false)
      aButtonDisplay.ignoreTouch = false
      aCitySelectScene.selectedCell = aCell
    elseif aCitySelectScene.nextUnopenedCountryId == self.list[index + 1] then
      challangBg_y:setVisible(false)
      challangBg_b:setVisible(false)
      challangBg_gray:setVisible(true)
      aButtonDisplay.ignoreTouch = true
    else
      challangBg_y:setVisible(false)
      challangBg_b:setVisible(true)
      challangBg_gray:setVisible(false)
      aButtonDisplay.ignoreTouch = false
    end
  end
  local function onListItemTouch( evt )
    local aIndex = evt.data + 1
    local newCell = self.cityTableView:cellAtIndex(aIndex - 1)
    local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
    
    local buttonDisplay = newCell:getChildByTag(cellTag):getChildByTag(-15)
    local challengeDisplay = buttonDisplay:getChildByTag(-12)
    if posInCell.x > buttonDisplay:getPositionX() and
      posInCell.x < (buttonDisplay:getPositionX() + challengeDisplay:getContentSize().width) and
      posInCell.y > (buttonDisplay:getPositionY() - challengeDisplay:getContentSize().height) and
      posInCell.y < buttonDisplay:getPositionY() then
      if challengeDisplay:isVisible() then
        self:selectCityCell(newCell:getChildByTag(cellTag), aIndex)
      end
    end
  end
  local renderer = CityTableViewRenderer.new(item_width, item_height)
  local aTableView = TableView:create(renderer, table_width, table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
  --aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
  aTableView:setPosition(ccp(table_posX, table_posY))
  return aTableView
end

function CitySelectScene:generateAnimatedCells()
  self.animatedCells = {}
  for i = 1, #self.openedCountryIDList do
    if (self.newOffsetY - self.originalOffsetY) < i * item_height and (self.newOffsetY - self.originalOffsetY + table_height + item_height) > i * item_height then
      table.insert(self.animatedCells, self.cityTableView:cellAtIndex(i - 1))
    end
  end
end

function CitySelectScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function CitySelectScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  --
  CanonPlayBackgroundMusic("music/background.mp3", true)
  self:hiddenFocusArrow()
end

function CitySelectScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  for _, v in ipairs(self.btDisplayList) do
    v:setAlpha(0)
    v:runAction(CCFadeIn:create(enter_animation_duration))
  end
  
  for _, v in ipairs(self.labelDisplayList) do
    v:setAlpha(0)
    v:runAction(CCFadeIn:create(enter_animation_duration))
  end
  
  for _, v in ipairs(self.labelNameList) do
    v:setAlpha(0)
    v:runAction(CCFadeIn:create(enter_animation_duration))
  end
  
  for _, v in ipairs(self.inChallengeDisplay.list) do
    v:setAlpha(0)
    v:runAction(CCFadeIn:create(enter_animation_duration))
  end
  
  local table_bg = self.controlUI:getChildByName("other_gray9_panel")
  table_bg:setAlpha(0)
  table_bg:runAction(CCFadeIn:create(enter_animation_duration))
  
  local button_display = self.controlUI:getChildByName("btn_go")
  for _, v in ipairs(button_display.list) do
    v:setAlpha(0)
    v:runAction(CCFadeIn:create(enter_animation_duration))
  end
  
  local bottom_bg = self.controlUI:getChildByName("bg_inventory_red")
  for _, v in ipairs(bottom_bg.list) do
    v:setAlpha(0)
    v:runAction(CCFadeIn:create(enter_animation_duration))
  end
  
  self.newOffsetY = self.cityTableView:getContentOffset().y
  self:generateAnimatedCells()
  local aDuration
  if #self.animatedCells == 1 then
    aDuration = enter_animation_duration - enter_animation_cell_duration
  else
    aDuration = (enter_animation_duration - enter_animation_cell_duration) / (#self.animatedCells - 1)
  end
  for aIndex, aCell in ipairs(self.animatedCells) do
    aCell:setPositionX(aCell:getPositionX() + cell_move_distance)
    local arr = CCArray:create()
    arr:addObject(CCDelayTime:create(aDuration * (aIndex - 1)))
    arr:addObject(CCMoveBy:create(enter_animation_cell_duration, ccp(-cell_move_distance, 0)))
    aCell:runAction(CCSequence:create(arr))
  end
  
  self.cityBG:setAlpha(0)
  local arr = CCArray:create()
  arr:addObject(CCFadeIn:create(enter_animation_duration))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.cityBG:runAction(CCSequence:create(arr))
end

function CitySelectScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  --
  self:showFocusArrow()
end

function CitySelectScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function CitySelectScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function CitySelectScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  for _, v in ipairs(self.btDisplayList) do
    v:runAction(CCFadeOut:create(enter_animation_duration))
  end
  
  for _, v in ipairs(self.labelDisplayList) do
    v:runAction(CCFadeOut:create(enter_animation_duration))
  end
  
  for _, v in ipairs(self.labelNameList) do
    v:runAction(CCFadeOut:create(enter_animation_duration))
  end
  
  for _, v in ipairs(self.inChallengeDisplay.list) do
    v:runAction(CCFadeOut:create(enter_animation_duration))
  end
  
  
  for _, v in ipairs(self.arrowUI.list) do
    v:runAction(CCFadeOut:create(enter_animation_duration))
  end
  
  local table_bg = self.controlUI:getChildByName("other_gray9_panel")
  table_bg:runAction(CCFadeOut:create(enter_animation_duration))
  
  local button_display = self.controlUI:getChildByName("btn_go")
  for _, v in ipairs(button_display.list) do
    v:runAction(CCFadeOut:create(enter_animation_duration))
  end
  
  local bottom_bg = self.controlUI:getChildByName("bg_inventory_red")
  for _, v in ipairs(bottom_bg.list) do
    v:runAction(CCFadeOut:create(enter_animation_duration))
  end
  
  self.newOffsetY = self.cityTableView:getContentOffset().y
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
    arr:addObject(CCMoveBy:create(enter_animation_cell_duration, ccp(cell_move_distance, 0)))
    aCell:runAction(CCSequence:create(arr))
  end
  
  local arr = CCArray:create()
  arr:addObject(CCFadeOut:create(enter_animation_duration))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.cityBG:runAction(CCSequence:create(arr))
end

function CitySelectScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function CitySelectScene:setTableViewsEnabledInner(aEnabled)
  self.cityTableView:setTouchEnabled(aEnabled)
end

function CitySelectScene:back()
  local argv = {enterScene="CitySelectScene",returnScene=nil,params={notReset=true}}
  self:replaceScene(CityMainScene, argv)
end
