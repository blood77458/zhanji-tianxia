require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.Button"
require "hecore.display.Sprite"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "hecore.ui.TableView"
require "canon.data.MetaManager"
require "canon.panel.RobFragmentBeforePanel"
require "canon.request.GetRobUserListRequest"
require "canon.panel.RouletteRewardPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local table_width = 704
local table_height = 745
local table_posX = 15
local table_posY = 225
local item_width = 690
local item_height = 160

local enter_animation_duration = 0.3
local enter_animation_cell_duration = 0.15

beastFrameNameDic = {
  [1] = "rob_art_exhibit_qinglong",
  [2] = "rob_art_exhibit_baihu",
  [3] = "rob_art_exhibit_zhuque",
  [4] = "rob_art_exhibit_xuanwu",
}

--
-- RobFragmentScene
--

local function refreshButtonSelected(evt)
  local aScene = evt.context
  
  local function successCallback(data)
    print(table.serialize(data))
     aScene:refreshSelf(data)
  end
  
  local function failureCallback(data)
    if data.retCode == 716019 then
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("beast_fragmentLimit")
      aScene.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    else
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = data.retCode})
      aScene.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    end
  end
  
  RobFragmentScene.doPreparationBeforeReplaceToFragmentScene(aScene.beastFragmentId, successCallback, failureCallback)
end

g_savedFragmentIndex = nil

RobFragmentScene = class(BaseUIScene)

function RobFragmentScene:ctor()
	
end

function RobFragmentScene:create(argv)
  local s = RobFragmentScene.new()
  if argv then 
      self.argv = argv 
  else
      self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
	
	if not self.argv.params then
		self.argv.params = {}
	end
	if self.argv.params.beginIndex ~= nil then
		g_savedFragmentIndex = self.argv.params.beginIndex
	else
		self.argv.params.beginIndex = g_savedFragmentIndex
	end
	
  self.robPlayers = self.argv.params.robPlayers
  self.robRobots = self.argv.params.robRobots
  self.beastFragmentId = self.argv.params.beastFragmentId
  self.leftTime = self.argv.params.leftTime
  if not self.leftTime then
    self.leftTime = -1
  end
  self.startTime = TimeUtil.getServerTimeSeconds()
  s:initScene()
  return s
end

function RobFragmentScene:onInit()
	BaseUIScene.initBackGround(self)
  
  self.currentRobPlayer = nil
  
  self.title = Localization:getInstance():getText("beast_title")
  
  local builder = LayoutBuilder:createWithContentsOfFile("scene/rob.json")
  local ui = builder:build("rob_getplayer")
  self:addChild(ui)
  self.robUI = ui
  
  self.uiGroup1 = ui:getChildByName("art_exhibit")
  self.uiGroup2 = ui:getChildByName("bg_red")
  self.uiGroup3 = ui:getChildByName("renovate_player")
  self.uiGroup4 = ui:getChildByName("txt_getplayer_info")
  
  local beastId = math.fmod(math.modf(self.beastFragmentId / 100, 10), 1000)
  local fragmentList = MetaManager.beast_meta[beastId].attrs.beastFragmentId:split("|")
  local fragmentIndex
  for k, v in ipairs(fragmentList) do
    local fragmentFormat = tostring(self.beastFragmentId)
    if v == fragmentFormat then
      fragmentIndex = k
      break
    end
  end

  self.uiGroup1:getChildByName("art_exhibit_baihu"):setDisplayFrame(createSpriteFrame(UI_RES_PATH.."/rob/"..beastFrameNameDic[beastId]..".png"))
  
  self.uiGroup1:getChildByName("art_exhibit_1"):setDisplayFrame(createSpriteFrame(UI_RES_PATH.."/rob/"..string.format("rob_art_exhibit_%d", fragmentIndex)..".png"))
  
  local aRefreshLabel = self.uiGroup3:getChildByName("txt")
  aRefreshLabel:setString(Localization:getInstance():getText("beastRob_refreshBtn"))
  local refreshButton = Button:create(self.uiGroup3)
  refreshButton:addEventListener(Events.kStart, refreshButtonSelected, self)
  
  self:createAllRobList()
  self.fragmentOwnerTableView = self:createFragmentOwnerTableView()
  ui:addChildAt(self.fragmentOwnerTableView, 2)
  self.fragmentOwnerTableView:reloadData()
  self.originalOffsetY = self.fragmentOwnerTableView:getContentOffset().y
  
  self.uiGroup4:getChildByName("txt"):setString(Localization:getInstance():getText("beastRob_noOpponent"))
  if (#self.robPlayers + #self.robRobots)== 0 then
    self.uiGroup4:setVisible(true)
  else
    self.uiGroup4:setVisible(false)
  end
  
  BaseUIScene.onInit(self)
end

function RobFragmentScene:refreshSelf(data)
  for k, _ in pairs(self.allRobList) do
		self.allRobList[k] = nil
	end
  self.robPlayers = data.robUserList
  self.robRobots = data.robRobotList
  -- for _, v in ipairs(robPlayers) do
  --   table.insert(self.robPlayers, v)
  -- end
  self:createAllRobList()
  self.fragmentOwnerTableView:removeFromParentAndCleanup(true)
  self.fragmentOwnerTableView = self:createFragmentOwnerTableView()
  self.robUI:addChildAt(self.fragmentOwnerTableView, 2)
  self.fragmentOwnerTableView:reloadData()
  self.originalOffsetY = self.fragmentOwnerTableView:getContentOffset().y
  
  if (#self.robPlayers + #self.robRobots) == 0 then
    self.uiGroup4:setVisible(true)
  else
    self.uiGroup4:setVisible(false)
  end
end

function RobFragmentScene:createAllRobList(  )
  -- body
  self.allRobList = {}
  for k,v in pairs(self.robPlayers) do
      local player = { level = v.level  , lastChallengeTime = v.lastChallengeTime , uid = v.uid , mainCardId = v.mainCardId , 
                      rank = v.rank , mainCardMetaId = v.mainCardMetaId , nickName = v.nickName , playerOrRobot = 0 , robotId = -1, unionName = v.unionName}
      table.insert(self.allRobList , player)
    end
    for k,v in pairs(self.robRobots) do
      local robotNickName  = getTextByKey(v.nameKey)
      local player = { level = v.level  , lastChallengeTime = -1 , uid = -1 , mainCardId = -1 , 
                      rank = -1 , mainCardMetaId = v.mainCardMetaId , nickName = robotNickName , playerOrRobot = 1 , robotId = v.robotId, unionName = nil}
      table.insert(self.allRobList , player)
    end
end

function RobFragmentScene:createFragmentOwnerTableView()
  local cellTag = 1024
  local buttonTag = {-15}
  local aRobFragmentScene = self
  local FragmentOwnerTableViewRenderer = class(TableViewRenderer)
  function FragmentOwnerTableViewRenderer:ctor(width, height)   
    self.list = aRobFragmentScene.allRobList
  end
  function FragmentOwnerTableViewRenderer:buildCell(container)
    local builder = LayoutBuilder:createWithContentsOfFile("scene/rob.json")
    local aCell = builder:build("rob_getplayer_list")
    container:addChild(aCell)
    aCell:setTag(cellTag)
    
    aCell:getChildByName("frame_card"):setVisible(false)
    aCell:getChildByName("bg_card"):setVisible(false)
    local aCardDisplay = aCell:getChildByName("normal_card_big")
    aCardDisplay:setTag(-10)
    aCardDisplay:setVisible(false)
    
    local aNameLabel = aCell:getChildByName("txt_formation_card_name")
    aNameLabel:setTag(-11)
    aNameLabel = aNameLabel:getChildByName("txt")
    aNameLabel:setTag(-10)
    
    local aLevelNumLabel = aCell:getChildByName("txt_lv_num")
    aLevelNumLabel:setTag(-12)
    aLevelNumLabel = aLevelNumLabel:getChildByName("font")
    aLevelNumLabel:setTag(-10)
    
    local aRankLabel = aCell:getChildByName("txt_area_rank")
    local aTempPosX = aRankLabel:getPositionX()
    aRankLabel:setTag(-13)
    aRankLabel = aRankLabel:getChildByName("txt")
    aRankLabel:setTag(-10)
    aRankLabel:setDimensions(CCSizeMake(0,aRankLabel:getDimensions().height))
    aRankLabel:setString(Localization:getInstance():getText("beastRob_arenaRank"))
    
    local aRankNumLabel = aCell:getChildByName("rob_txt_rank")
    aRankNumLabel:setPositionX(aTempPosX + aRankLabel:getTexture():getContentSize().width)
    aRankNumLabel:setTag(-14)
    aRankNumLabel = aRankNumLabel:getChildByName("txt")
    aRankNumLabel:setTag(-10)
    
    local aButtonDisplay = aCell:getChildByName("btn_getplayer")
    aButtonDisplay:setTag(-15)
    local challangeLabel = aButtonDisplay:getChildByName("txt")
    challangeLabel:setTag(-10)
    challangeLabel:setString(Localization:getInstance():getText("beastRob_robBtn"))
    local challangBg = aButtonDisplay:getChildByName("btn")
    challangBg:setTag(-11)
    
    local aUnionNameLabel = aCell:getChildByName("txt_guild_name2")
    aUnionNameLabel:setTag(-16)
    aUnionNameLabel = aUnionNameLabel:getChildByName("txt")
    aUnionNameLabel:setTag(-10)
  end
  function FragmentOwnerTableViewRenderer:setData( rawCocosObj, index )
    
    local aCell = self:getChildByTag(rawCocosObj, cellTag)
    local originalCard3_co = aCell:getChildByTag(-20)
    if originalCard3_co then
      originalCard3_co:removeFromParentAndCleanup(true)
    end
    
    local aCardDisplay =  aCell:getChildByTag(-10)
    local card3_co = getHeadIconCanonCardByMetaId(self.list[index + 1].mainCardMetaId)
    card3_co:setPosition(ccp(aCardDisplay:getPositionX(), aCardDisplay:getPositionY()))
    card3_co:setScale(0.9)
    aCell:addChild(card3_co.refCocosObj, 100)
    card3_co:setTag(-20)
    card3_co:dispose()
    
    local aNameLabel = aCell:getChildByTag(-11):getChildByTag(-10)
    setNodeText(aNameLabel, self.list[index + 1].nickName)
    
    local aLevelNumLabel = aCell:getChildByTag(-12):getChildByTag(-10)
    setNodeText(aLevelNumLabel, string.format("%d", self.list[index + 1].level))
    
    local aRankNumLabel = aCell:getChildByTag(-14)
    aRankNumLabel = aRankNumLabel:getChildByTag(-10)
    if self.list[index + 1].rank < 0 then
      setNodeText(aRankNumLabel, Localization:getInstance():getText("beastRob_arenaOutOfRank"))
    else
      setNodeText(aRankNumLabel, string.format("%d", self.list[index + 1].rank))
    end
    
    local aUnionNameLabel = aCell:getChildByTag(-16)
    if self.list[index + 1].unionName then
      aUnionNameLabel:setVisible(true)
      setNodeText(aUnionNameLabel:getChildByTag(-10), Localization:getInstance():getText("union_name_txt", {name = self.list[index + 1].unionName}))
    else
      aUnionNameLabel:setVisible(false)
    end
  end
  local function onListItemTouch( evt )
    local aIndex = evt.data + 1
    local newCell = self.fragmentOwnerTableView:cellAtIndex(aIndex - 1)
    local posInCell = newCell:convertToNodeSpace(evt.globalPosition)
    
    local buttonDisplay = newCell:getChildByTag(cellTag):getChildByTag(-15)
    local challengeDisplay = buttonDisplay:getChildByTag(-11)
    if posInCell.x > buttonDisplay:getPositionX() and
      posInCell.x < (buttonDisplay:getPositionX() + challengeDisplay:getContentSize().width) and
      posInCell.y > (buttonDisplay:getPositionY() - challengeDisplay:getContentSize().height) and
      posInCell.y < buttonDisplay:getPositionY() then
      self:showRobFragmentBeforePanel(aRobFragmentScene.allRobList[aIndex])
    end
  end
  local renderer = FragmentOwnerTableViewRenderer.new(item_width, item_height)
  local aTableView = TableView:create(renderer, table_width, table_height, cellTag, buttonTag, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
  --aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
  aTableView:setPosition(ccp(table_posX, table_posY))
  return aTableView
end

function RobFragmentScene:enableUserInterface()
  if self.fragmentOwnerTableView and self.fragmentOwnerTableView.refCocosObj then
    self.fragmentOwnerTableView:setTouchEnabled(true)
  end
end

function RobFragmentScene:disableUserInterface()
  self.fragmentOwnerTableView:setTouchEnabled(false)
end

function RobFragmentScene:panelDismiss()
  self:enableUserInterface()
end

function RobFragmentScene:setTableViewsEnabledInner(aEnabled)
  self.fragmentOwnerTableView:setTouchEnabled(aEnabled)
end

function RobFragmentScene:showRobFragmentBeforePanel(aRobPlayer)
  self.currentRobPlayer = aRobPlayer
  self:disableUserInterface()
  local aPanel = RobFragmentBeforePanel:create(self, {robPlayer = self.currentRobPlayer, beastFragmentId = self.beastFragmentId, leftTime = self.leftTime, startTime = self.startTime})
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function RobFragmentScene:showNotEnoughEventPointPanel()
  local hasProp, eventPointPropList = BagCalcManager.getEventPointPropList()
  if hasProp then
    self:showUseEventPointProptPanel(eventPointPropList)
  else
    self:showEventPointLimitPanel()
  end
end

function RobFragmentScene:showUseEventPointProptPanel(eventPointPropList)
  local function callback(aEventPointPropId)
    self:recoveryEventPoint(aEventPointPropId)
  end
  local aPanel = EEPSupplyPanel:create(self, eventPointPropList, callback)
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function RobFragmentScene:recoveryEventPoint(aEventPointPropId)
  local function usePropSucceed(event)
    local aReward = {
      {	itemType = ResourceEnum.PROP, metaId = aEventPointPropId, amount = -1
      },
      {	itemType = ResourceEnum.EVENTPOINT,
        amount = event.data.rewards[1].amount,
      }
    }
    RewardManager:getReward(aReward)
    CanonPlayEffect("music/sfx_engly_lvup.wav")
    SuspensionLabel:showContent(self, getTextByKey("propInfo_eventPointReplenished"))
    self:showRobFragmentBeforePanel(self.currentRobPlayer)
  end
  
  local function usePropFailed(event)
    if event.data.retCode == 712309 then
      local function closeCanonMessageBox()
      end
      self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("propInfo_eventPointFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    elseif event.data.retCode == 712301 then
      local function closeCanonMessageBox()
      end
      local aPropMetaConfig = MetaManager.prop_meta[aEventPointPropId]
      self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("popup_noProp", {propname = Localization:getInstance():getText(aPropMetaConfig.name)}), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    end
  end
  
  local request = UsePropRequest.new( {propId = aEventPointPropId, amount = 1}, rpc.SendingPriority.kHigh )
	request:addEventListener( RequestNotifyEnum.UsePropSucceed, usePropSucceed )
	request:addEventListener( RequestNotifyEnum.UsePropFailed, usePropFailed )
	request:start()
end

function RobFragmentScene:showEventPointLimitPanel()
  local function callback()
  end
  local aPanel = EENPSupplyPanel:create(self, {supplyType = EESupplyTypeEnum.EventPoint, callback = callback})
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function RobFragmentScene:showMainActorPanel()
  self.targetInfoPanel = MainActorPanel:create( self )
  PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
end

function RobFragmentScene:generateAnimatedCells()
  self.animatedCells = {}
  for i = 1, #self.robPlayers + #self.robRobots do
    if (self.newOffsetY - self.originalOffsetY) < i * item_height and (self.newOffsetY - self.originalOffsetY + table_height + item_height) > i * item_height then
      table.insert(self.animatedCells, self.fragmentOwnerTableView:cellAtIndex(i - 1))
    end
  end
end

function RobFragmentScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function RobFragmentScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  --
  CanonPlayBackgroundMusic("music/background.mp3", true)
end

function RobFragmentScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  for _, aChild in ipairs(self.uiGroup1.list) do
    aChild:setOpacity(0)
    aChild:runAction(CCFadeIn:create(enter_animation_duration))
  end
  
  for _, aChild in ipairs(self.uiGroup3.list) do
    aChild:setOpacity(0)
    aChild:runAction(CCFadeIn:create(enter_animation_duration))
  end
  
  self.newOffsetY = self.fragmentOwnerTableView:getContentOffset().y
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
  
  self.uiGroup4:setPositionX(self.uiGroup4:getPositionX() - visibleSize.width)
  self.uiGroup4:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  
  self.fragmentOwnerTableView:setPositionX(self.fragmentOwnerTableView:getPositionX() - visibleSize.width)
  self.fragmentOwnerTableView:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  
  self.uiGroup2:setPositionX(self.uiGroup2:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.uiGroup2:runAction(CCSequence:create(arr))
  
end

function RobFragmentScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  --
end

function RobFragmentScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function RobFragmentScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function RobFragmentScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  for _, aChild in ipairs(self.uiGroup1.list) do
    aChild:runAction(CCFadeOut:create(enter_animation_duration))
  end
  
  self.uiGroup3:setVisible(false)
  --[[
  for _, aChild in ipairs(self.uiGroup3.list) do
    aChild:runAction(CCFadeOut:create(enter_animation_duration))
  end
  ]]
  
  self.newOffsetY = self.fragmentOwnerTableView:getContentOffset().y
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
  
  self.uiGroup4:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  
  self.fragmentOwnerTableView:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.uiGroup2:runAction(CCSequence:create(arr))
  
end

function RobFragmentScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function RobFragmentScene:back()
  if self.argv.returnScene == "BeastScene" then
		local function doPrerationSucceed(fragmentsInfo)
			local argv = {enterScene="RobFragmentScene",returnScene="MainMenuScene",params={fragmentsInfo=fragmentsInfo, beginIndex = self.argv.params.beginIndex}}
			self:replaceScene(BeastScene, argv)
		end
				
		local function doPrerationFailed()
			self.isChangeingScene = false
		end
				
		BeastScene.doPreparationBeforeReplaceToBeastScene(doPrerationSucceed, doPrerationFailed)
  end
end

function RobFragmentScene.doPreparationBeforeReplaceToFragmentScene(beastFragmentId, successCallback, failureCallback)
	local function getRobListRequestSucceed(evt)
    if successCallback then
			successCallback(evt.data)
		end
  end

  local function getRobListRequestFailed(evt)
		if failureCallback then
			failureCallback(evt.data)
		end
  end

  local function sendGetRobListRequest(beastFragmentId)
    local request = GetRobUserListRequest.new( {beastFragmentId = beastFragmentId}, rpc.SendingPriority.kHigh )
    request:addEventListener( RequestNotifyEnum.GetRobUserListSucceed, getRobListRequestSucceed )
    request:addEventListener( RequestNotifyEnum.GetRobUserListFailed, getRobListRequestFailed )
    request:start()
  end

  sendGetRobListRequest(beastFragmentId)
end

function RobFragmentScene.doPreparationBeforeReplaceToBattleScene(extraArgs, successCallback, failureCallback)
  local function robBeastFragmentSucceed(event)
    if successCallback then
			successCallback(event.data)
		end
  end
  local function robBeastFragmentFailed(event)
    if failureCallback then
			failureCallback(event.data)
		end
  end
  local params = {beastFragmentId = extraArgs.beastFragmentId, enemyUid = extraArgs.enemyUid , robType = extraArgs.robType , robotId = extraArgs.robotId}
  local request = RobBeastFragmentRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.RobBeastFragmentSucceed, robBeastFragmentSucceed)
  request:addEventListener(RequestNotifyEnum.RobBeastFragmentFailed, robBeastFragmentFailed)
  request:start()
end



