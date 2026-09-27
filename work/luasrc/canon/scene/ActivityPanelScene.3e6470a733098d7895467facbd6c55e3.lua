--------------------------------------------------------------------------------
-- ActivityPanelScene.lua - 活动统一显示界面
-- author: xiaojie.bai & chao.dang
-- date: 2013-09-26 10:40
--------------------------------------------------------------------------------

require "canon.scene.BaseUIScene"
require "canon.panel.EliteEnterPanel"
require "canon.models.ActivityPanelManager" 
require "canon.panel.CalendarSignInPanel"
require "canon.layer.Activity_NewUserContinueLoginShowLayer" 
require "canon.layer.Activity_ChargeRewardLayer"
require "canon.layer.Activity_LevelRaceLayer"
require "canon.layer.Activity_GachaPointsLayer"
require "canon.layer.Activity_NewYearLayer"
require "canon.layer.Activity_MonthCardLayer"
require "canon.layer.Activity_LotteryFortuneLayer"
require "canon.layer.Activity_WealthGodLayer"
require "canon.layer.Activity_NewChargeRewardLayer"
conditionalRequire "canon.layer.Activity_MultiplayerBossLayer"
require "canon.layer.Activity_NewYear8DaysLayer"
require "canon.layer.Activity_GemConsumeRewardsLayer"
require "canon.layer.Activity_SilverDiceLayer"
require "canon.layer.Activity_SoulPrayerLayer"
require "canon.request.GetLevelRaceInfoRequest"
require "canon.request.GetGachaPointsInfoRequest"
require "canon.request.TreasureboxPointsInfoGetRequest"
require "canon.request.DiceGetInfoRequest"
require "canon.request.GetInvitationInfoRequest"
conditionalRequire "canon.request.GetMultiplayserBossInfoRequest"
require "canon.manager.NotificationManager" 
require "canon.layer.Activity_FireworksLayer"
require "canon.layer.Activity_SwornLayer"
require "canon.layer.Activity_TreasureboxRankLayer"
require "canon.layer.Activity_PraiseLayer"
require "canon.layer.Activity_InvitationCodeLayer"
require "canon.data.AccountPlatformLogin"
require "canon.layer.Activity_MysteryShopLayer"
require "canon.request.GetSecretShopListRequest"
require "canon.layer.Activity_ContendLayer"
require "canon.request.SeckillGetInfoRequest"
require "canon.layer.Activity_SeckillLayer"
require "canon.layer.Activity_PhoneChargeLayer"
require "canon.request.GetAccumulateGemsRequest"
require "canon.layer.Activity_DailyFirstChargeLayer"
require "canon.layer.Activity_WantedLayer"
require "canon.layer.Activity_FestivalLayer"
require "canon.request.GetTaskInfoRequest"
require "canon.layer.Activity_ChargeFeedbackLayer"
require "canon.layer.Activity_QuestionLayer"
require "canon.request.QuestionActWeekRewardRequest"
require "canon.layer.Activity_DoubleRewardLayer"
require "canon.layer.Activity_CardOldToNewLayer"
require "canon.layer.Activity_BlowBalloonLayer"
require "canon.request.BlowBalloonActInfoRequest"
require "canon.layer.Activity_MerryChristmasLayer"
require "canon.layer.Activity_CrossMultiplayerBossLayer"
require "canon.request.GetCrossBossInfoRequest"
require "canon.layer.Activity_FacebookShareLayer"
require "canon.layer.Activity_FountainLayer"
require "canon.layer.Activity_ConsumeRewardsLayer"
require "canon.layer.Activity_GachaXiaoyuLayer"
require "canon.request.CrossGachaXiaoyuRequest"

require "canon.layer.Activity_rechargeLayer"
require "canon.layer.Activity_ExchangeDailyLayer"
require "canon.layer.Activity_ChallengeMysteriousLayer"
require "canon.layer.Activity_MySteriousShopLayer"

-- require "canon.request.ActiveRechangeRequest"
ActivityPanelScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

local DICT_PANEL = {}
local PANEL_NAME_DICT = {
              Activity_EatPeach = Activity_EatPeachLayer,
							Activity_SignIn = CalendarSignInPanel,
							Activity_ContinueLoginNew = Activity_NewUserContinueLoginShowLayer, 
							Activity_CowStage = Activity_CowstageLayer,
							Activity_WorldBoss = Activity_WorldBossLayer,
							Activity_LevelRace = Activity_LevelRaceLayer,
							Activity_GachaPoints = Activity_GachaPointsLayer,
							Activity_GachaXiaoyu = Activity_GachaXiaoyuLayer,
							Activity_NewyearRecharge = Activity_NewYearLayer,
							Activity_ChargeReward = Activity_ChargeRewardLayer,
              Activity_GemCard = Activity_MonthCardLayer,
              Activity_FortuneNow = Activity_LotteryFortuneLayer,
              Activity_goldGod = Activity_WealthGodLayer, 
              Activity_NewChargeReward = Activity_NewChargeRewardLayer,
              Activity_MultiplayerBoss = Activity_MultiplayerBossLayer,
              Activity_throwDice = Activity_SilverDiceLayer,
              Activity_DayReward = Activity_NewYear8DaysLayer,--0.1185
              Activity_Fireworks = Activity_FireworksLayer,--0.1851137
              Activity_GemConsume = Activity_GemConsumeRewardsLayer,
              Activity_SwornBrothers = Activity_SwornLayer,  --0.736
              Activity_Pray = Activity_SoulPrayerLayer,
              Activity_Treasurebox = Activity_TreasureboxRankLayer,--0.193926
              Activity_Praise = Activity_PraiseLayer,--0.328
              Activity_InvitationCode = Activity_InvitationCodeLayer,
	            Activity_SecretShop = Activity_MysteryShopLayer,
	            Activity_Contend = Activity_ContendLayer,--0.21056
              Activity_Seckill = Activity_SeckillLayer,
              Activity_PhoneCharge = Activity_PhoneChargeLayer,
              Activity_DailyFirstCharge = Activity_DailyFirstChargeLayer,
              Activity_Wanted = Activity_WantedLayer,
              Activity_Challenge = Activity_FestivalLayer,
              Activity_ChargeFeedback = Activity_ChargeFeedbackLayer,
              Activity_Question = Activity_QuestionLayer,
              Activity_DoubleSilver = Activity_DoubleRewardLayer,
              Activity_BlowBalloon = Activity_BlowBalloonLayer,
              Activity_CardExchange = Activity_CardOldToNewLayer,
              Activity_MerryChristmas = Activity_MerryChristmasLayer,
              Activity_CrossBoss    = Activity_CrossMultiplayerBossLayer,
	            Activity_FbShare = Activity_FacebookShareLayer,
              Activity_LimitReward = Activity_rechargeLayer,
              Activity_FountainWish    = Activity_FountainLayer,
              Activity_ConsumeRewards = Activity_ConsumeRewardsLayer,
              Activity_ExchangeDaily = Activity_ExchangeDailyLayer,
              Activity_mysterious = Activity_ChallengeMysteriousLayer,
              Activity_mysteriousShop = Activity_MySteriousShopLayer,
						}
local PANEL_TIP_DICT = {}   --dictionary for showing subscript
local PANEL_PARTICLE_DICT = {}    --dictionary for showing particle
local ACTIVITY_STATUS_INFO

function ActivityPanelScene:ctor()
	self.title = getTextByKey("home_activityBtn")
	self.sceneExit = false
  self.curSceneEnum = SceneEnum.ActivityScene
end

function ActivityPanelScene:create(argv)
  local scene = ActivityPanelScene.new()
  
  scene.enabledPanels = {}
  scene.panelPool = {}

  if isInAppleReview() then
    PANEL_NAME_DICT = {
     Activity_SignIn = CalendarSignInPanel,
	 Activity_ChargeReward = Activity_ChargeRewardLayer,
    }
    if argv then
      argv.selectPanelName = "Activity_EatPeach"
    end
  end

  scene.argv = argv
  
  scene.selectedPanelIdx = 1
  scene.selectedPanelName = nil
  scene.selectedPanel = nil
  scene:initScene()
  return scene
end

function ActivityPanelScene:back()
  if self.argv and self.argv.returnScene == "CardRebirthScene" then
    self:replaceScene(CardRebirthScene)
  else
  	self:replaceScene(MainMenuScene)
  end
end

function ActivityPanelScene:initPanelsInfo()
  DICT_PANEL = {}
  for k,v in ipairs(MetaManager.activity_panel) do
    local activityInfo = {
      name = v.panelName,
      order = v.order,
      head = {
        textKey = v.nameKey,
        icon = "pic/activityIcons/"..v.icon .. ".png",
        icon_selected = "pic/activityIcons/".."icon_Activity_waikuang.png", 
        isNew = v.isnew
      },
      panel = nil
    }
    table.insert(DICT_PANEL, activityInfo)                    
  end
  
  local function activitySortFunc(a, b)
    return a.order < b.order
  end
  table.sort(DICT_PANEL, activitySortFunc)
  
  --refer to activity_panel.lua
  for k,v in ipairs(DICT_PANEL) do 
	if PANEL_NAME_DICT[v.name] then
		v.panel = PANEL_NAME_DICT[v.name]
	end
  end 
end

function ActivityPanelScene:initEnabledPanels()
  for _, value in ipairs(DICT_PANEL) do
    if value.panel then
      local enable = value.panel.enable()
      -- if value.name == "Activity_LimitReward" then 
      --   print("~~~~~~~~~~~~~~~~~~~~~ 限时充值end =  "..tostring(enable))
      -- end
      if(enable) then
        if value.name == "Activity_LevelRace" then
          local rewardType
          local defaultRewardType
          for _, aDisplayType in pairs(DataManager.GameMetaData.activityLevelRaceConfig.displayTypes) do
            if aDisplayType.id == DataManager.getServerid() then
              rewardType = aDisplayType.type
            end
            if aDisplayType.id == 0 then
              defaultRewardType = aDisplayType.type
            end
          end
          if not rewardType then
            rewardType = defaultRewardType
          end
          value.head.text = getTextByKey(value.head.textKey .. "_type" .. rewardType)
        else
          value.head.text = getTextByKey(value.head.textKey)
        end
        
        
        table.insert(self.enabledPanels, value)
        
        if value.name == self.argv then
          self.selectedPanelIdxEx = #self.enabledPanels
        end
      end
    end
  end
end

local PARTICLE_TAG = 1234
local EXTRAHEIGHT = 10

function ActivityPanelScene:createHeadTableView()
  local enabledPanels = self.enabledPanels
  local scene = self;
  local selectedPanelIdx = self.selectedPanelIdx
  
  local HeadTableViewRenderer = class(TableViewRenderer)
  function HeadTableViewRenderer:ctor(width, height)
    self.list = enabledPanels
  end
  
  function HeadTableViewRenderer:buildCell(container)
    local layer = Layer:create()
		layer:setPositionY(layer:getPositionY() - EXTRAHEIGHT / 2 )
    container:addChild(layer)
    layer:setTag(1024)
  end
  
  function HeadTableViewRenderer:setData(rawCocosObj, index)
    local cellLayer = self:getChildByTag(rawCocosObj, 1024)
    cellLayer:removeAllChildrenWithCleanup(true)
    
    local function addParticle()
      local rewardParticle = CCParticleSystemQuad:create(ParticlePathConstants.FxStarline)
			rewardParticle:setPositionType(kCCPositionTypeRelative)
			rewardParticle:setPosition(ccp(0, 148))
			rewardParticle:setTag(PARTICLE_TAG)
			cellLayer:addChild(rewardParticle, 1000)
			local particleMoveArray = CCArray:create()
			local particleMoveTime = 0.4
			particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(148, 0)))
			particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(0, -148)))
			particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(-148, 0)))
			particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(0, 148)))
			rewardParticle:runAction(CCRepeatForever:create(CCSequence:create(particleMoveArray)))
    end
    
    local enablePanel = enabledPanels[index + 1]
    local icon = enablePanel.head.icon
    local selectedIcon = enablePanel.head.icon_selected
    

    local pic = CCSprite:create(icon)
    pic:setAnchorPoint(ccp(0, 0))
    cellLayer:addChild(pic)
		
		if cellLayer:getChildByTag(PARTICLE_TAG) then
			cellLayer:removeChildByTag(PARTICLE_TAG, true)
		end
		
		if PANEL_PARTICLE_DICT[enablePanel.name] then
			addParticle()
		end
    
    local selectPic = CCSprite:create(selectedIcon)
    selectPic:setAnchorPoint(ccp(0, 0))
    cellLayer:addChild(selectPic)
    
    if(scene.selectedPanelIdx == index + 1) then
      selectPic:setVisible(true)
    else
      selectPic:setVisible(false)
    end
    
    local activityNameBg = CCSprite:create("pic/activityIcons/activityNameBG.png")
    activityNameBg:setPosition(pic:getContentSize().width/2,pic:getContentSize().height*0.15)
    pic:addChild(activityNameBg)
    
    local text = ArtLabelTTF:create(enablePanel.head.text,nil,30)
    text:setPosition(pic:getContentSize().width/2,pic:getContentSize().height*0.15)
    pic:addChild(text)
    
    local activityTag = cellLayer:getChildByTag(-200)
    if activityTag then
      activityTag:removeFromParentAndCleanup(true)
    end
    if PANEL_TIP_DICT[enablePanel.name] > 0 then
      activityTag = CCSprite:create(UI_RES_PATH.."/mainmenu_scene_new/mainmenu_scene_tips_little.png")
      activityTag:setPosition(ccp(pic:getContentSize().width - activityTag:getContentSize().width/2, pic:getContentSize().height - activityTag:getContentSize().height/2))
      cellLayer:addChild(activityTag)
      activityTag:setTag(-200)
      local aLabel = CCLabelTTF:create(tostring(PANEL_TIP_DICT[enablePanel.name]), "Helvetica", 28)
      aLabel:setPosition(activityTag:getContentSize().width/2, activityTag:getContentSize().height/2)
      activityTag:addChild(aLabel)
    end
  end
  
  local function onListItemTouch(evt)
    if self.targetInfoPanel then
      return
    end 
    local index = evt.data + 1
    if(self.selectedPanelIdx == index) then
      return nil
    end
    self:replacePanel(index)
  end
  
  local renderer = HeadTableViewRenderer.new(ActivityPanelManager.DICT.ITEM_HEAD_WIDTH, ActivityPanelManager.DICT.ITEM_HEAD_HEIGHT)
  local aTableView = TableView:create(renderer, ActivityPanelManager.DICT.TB_HEAD_WIDTH, ActivityPanelManager.DICT.TB_HEAD_HEIGHT + EXTRAHEIGHT)
  aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
  aTableView:setPosition(ccp(ActivityPanelManager.DICT.TB_HEAD_POSX, ActivityPanelManager.DICT.TB_HEAD_POSY))
  aTableView:setDirection(kCCScrollViewDirectionHorizontal)
  
  ViewControlUtil.refreshAndLocateTableView(aTableView, selectedPanelIdx)
  
  return aTableView
end

function ActivityPanelScene:resetTipInfoUI()
  if (type(self.headUI) == "table") and self.headUI.refCocosObj then
    self.headUI:reloadData()
    ViewControlUtil.refreshAndLocateTableView(self.headUI, self.selectedPanelIdx)
  end
end

function ActivityPanelScene:replacePanel(idx, oriented)
  if  self.isChangeingScene then
    return 
  end 
  
  local extraArgs
  
  local function changePanel()
    self.selectedPanelIdx = idx
    self.selectedPanelName = self.enabledPanels[self.selectedPanelIdx].name
    local panel = self.panelPool[self.selectedPanelName]
    if(not panel) then
      --print(extraArgs)
      local extraArgs2
      if oriented then
        extraArgs2 = self.argv.orientedParams
      end
      panel = self.enabledPanels[self.selectedPanelIdx].panel:create(self, extraArgs, extraArgs2)
      self.panelPool[self.selectedPanelName] = panel
    elseif type(panel.resetExtraArgs) == "function" then
      panel:resetExtraArgs(extraArgs)
    end
    if type(self.selectedPanel) == "table" and type(self.selectedPanel.panelExit) == "function" then
        self.selectedPanel:panelExit()
    end
        
    if self.lastSelectedPanelName and self.lastSelectedPanelName == "Activity_GemConsume" then
        self.panelPool[self.lastSelectedPanelName] = nil
        self:removeChild(self.selectedPanel, true)
    else
        --self:removeChild(self.selectedPanel, false)
        if self.lastSelectedPanelName then
          self.panelPool[self.lastSelectedPanelName] = nil
        end
        self:removeChild(self.selectedPanel, true)
    end 
    
    self.lastSelectedPanelName = self.selectedPanelName
     
    self.selectedPanel = panel
    self:addChildAt(self.selectedPanel, 2)
    if type(self.selectedPanel) == "table" and type(self.selectedPanel.panelEnter) == "function" then
        self.selectedPanel:panelEnter()
    end
    
    ViewControlUtil.refreshAndLocateTableView(self.headUI, self.selectedPanelIdx)
    
    if self.selectedPanel.refCocosObj then
      self.selectedPanel:setPositionX(self.selectedPanel:getPositionX() - visibleSize.width)
      local arr = CCArray:create()
      arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
      self.selectedPanel:runAction(CCSequence:create(arr))
    end
  end
  
  if self.enabledPanels[idx].name == "Activity_LevelRace" then
    local function getLevelRaceInfoSucceed(event)
		if self.sceneExit then
			return
		end
      extraArgs = event.data.levelRaceRanks or {}
      changePanel()
    end 
    local function getLevelRaceInfoFailed(event)
		if self.sceneExit then
			return
		end
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
      CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    end
    local params = {}
    local request = GetLevelRaceInfoRequest.new(params, rpc.SendingPriority.kHigh)
    request:addEventListener(RequestNotifyEnum.GetLevelRaceInfoSucceed, getLevelRaceInfoSucceed)
    request:addEventListener(RequestNotifyEnum.GetLevelRaceInfoFailed, getLevelRaceInfoFailed)
    request:start()
  elseif self.enabledPanels[idx].name == "Activity_GachaPoints" then
    local function getGachaPointsInfoSucceed(event)
		if self.sceneExit then
			return
		end
      extraArgs = event.data or {}
      changePanel()
    end 
    local function getGachaPointsInfoFailed(event)
		if self.sceneExit then
			return
		end
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
      CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    end
    local params = {}
    local request = GetGachaPointsInfoRequest.new(params, rpc.SendingPriority.kHigh)
    request:addEventListener(RequestNotifyEnum.GetGachaPointsInfoSucceed, getGachaPointsInfoSucceed)
    request:addEventListener(RequestNotifyEnum.GetGachaPointsInfoFailed, getGachaPointsInfoFailed)
    request:start()
  elseif self.enabledPanels[idx].name == "Activity_GachaXiaoyu" then
  --小玉嫁到
    local function getCrossGachaInfoSucceed(event)
		if self.sceneExit then
			return
		end
      extraArgs = event.data or {}
      changePanel()
    end 
    local function getCrossGachaInfoFailed(event)
		if self.sceneExit then
			return
		end
		
		if event.data.retCode == 714781 then  --activity closed
			local function closeCanonMessageBox()
				local scene = MainMenuScene.create()
				Director:sharedDirector():replaceScene( scene )
			end
			local text = Localization:getInstance():getText("activity_timeOver")
			Director:mgr():run().targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		else
			local function closeCanonMessageBox()
			end
			local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
			CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		end
    end
    local params = {}
	--[[test use 诏令天下
	local request = GetGachaPointsInfoRequest.new(params, rpc.SendingPriority.kHigh)
    request:addEventListener(RequestNotifyEnum.GetGachaPointsInfoSucceed, getCrossGachaInfoSucceed)
    request:addEventListener(RequestNotifyEnum.GetGachaPointsInfoFailed, getCrossGachaInfoFailed)
	--end--]]
    local request = GetCrossGachaInfoRequest.new(params, rpc.SendingPriority.kHigh)
    request:addEventListener(RequestNotifyEnum.GetCrossGachaInfoSucceed, getCrossGachaInfoSucceed)
    request:addEventListener(RequestNotifyEnum.GetCrossGachaInfoFailed, getCrossGachaInfoFailed)
    request:start()
  elseif self.enabledPanels[idx].name == "Activity_Treasurebox" then
    local function getTreasureInfoSucceed(event)
      --print("getTreasureInfoSucceed! event = " .. table.tostring(event))
      if self.sceneExit then
        return
      end
      extraArgs = event.data or {}
      changePanel()
    end 
    local function getTreasureInfoFailed(event)
      if self.sceneExit then
        return
      end
      TreasureboxPointsInfoGetRequest.onFailedDefault(event)
    end
    TreasureboxPointsInfoGetRequest.sendRequest(false, getTreasureInfoSucceed, getTreasureInfoFailed)
  elseif self.enabledPanels[idx].name == "Activity_Seckill" then
    local function getSeckillInfoSucceed(event)
      --print("getTreasureInfoSucceed! event = " .. table.tostring(event))
      if self.sceneExit then
        return
      end
      SeckillGetInfoRequest.onSucceedDefault(event)
      extraArgs = event.data or {}
      changePanel()
    end 
    local function getSeckillInfoFailed(event)
      if self.sceneExit then
        return
      end
      SeckillGetInfoRequest.onFailedDefault(event)
    end
    SeckillGetInfoRequest.sendRequest(getSeckillInfoSucceed, getSeckillInfoFailed)
  elseif self.enabledPanels[idx].name == "Activity_WorldBoss" then
	  local function onGetWorldBossInfo(response)
		if self.sceneExit then
			return
		end
		  WorldBossScene.worldBossInfo = response.data
		  WorldBossScene.worldBossInfo.worldBossMonster.totalHp = tonumber(WorldBossScene.worldBossInfo.worldBossMonster.totalHp)
		  WorldBossScene.worldBossInfo.worldBossMonster.leftHp = tonumber(WorldBossScene.worldBossInfo.worldBossMonster.leftHp)
		  if WorldBossScene.lastFightAnimTime == nil then
			local hour, minute, during = Activity_WorldBossLayer.getWorldBossTime()
			self.curTime = TimeUtil.getServerTimeSeconds()
			local todayTimeFormat = os.date("*t", self.curTime)
			WorldBossScene.lastFightAnimTime = os.time{year=todayTimeFormat.year, month=todayTimeFormat.month, day=todayTimeFormat.day, hour=hour, min=minute}
		  end
		  changePanel()
		end
    local request = GetWorldBossInfoRequest.new(nil, rpc.SendingPriority.kHigh)
    request:addEventListener( RequestNotifyEnum.getWorldBossInfoSuccessd, onGetWorldBossInfo )
    request:start()
  elseif self.enabledPanels[idx].name == "Activity_MultiplayerBoss" then
    if self.panelPool["Activity_MultiplayerBoss"] then
      changePanel()
    else
      local function successCallback(data)
        if self.sceneExit then
          return
        end
        extraArgs = data or {}
        changePanel()
      end
      
      local function failureCallback(data)
        if self.sceneExit then
          return
        end
        if data.retCode == 714520 then
          local function closeCanonMessageBox()
            self:replaceScene(MainMenuScene)
          end
          local text = Localization:getInstance():getText("activityNian_timeOver")
          CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        else
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = data.retCode})
          CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        end
      end
      
      MultiplayerBossScene.doPreparationBeforeEnterMultiplayerBossPanel(successCallback, failureCallback)
    end
  elseif self.enabledPanels[idx].name == "Activity_InvitationCode" then
    local function getInvitationInfoSucceed(event)
      --print("getTreasureInfoSucceed! event = " .. table.tostring(event))
      if self.sceneExit then
        return
      end
      extraArgs = {}
      local param = {invitePlayerNum = 0 ,gainedInviteRewardNum = 0,hasInvited = false ,deviceId =""}
      if event.data.sharkAccountInvitation == nil then
        table.insert(extraArgs , param)
      else
        table.insert(extraArgs , event.data.sharkAccountInvitation)
      end
      table.insert(extraArgs , event.data.deviceHasInvited)
      changePanel()
    end 
    local function getInvitationInfoFailed(event)
      if self.sceneExit then
        return
      end
      -- TreasureboxPointsInfoGetRequest.onFailedDefault(event)
    end
    local param = {deviceId = getDeviceId()}
    -- local param = {deviceId = "43680D43-3517-433D-93D3-4F8C61BAD"}
    GetInvitationInfoRequest.sendRequest(param, getInvitationInfoSucceed, getInvitationInfoFailed)
  elseif self.enabledPanels[idx].name == "Activity_SecretShop" then
    local function successCallback(data)
      if self.sceneExit then
        return
      end
      extraArgs = data.data or {}
      changePanel()
    end

    local function failureCallback(data)
      if self.sceneExit then
        return
      end
      -- if data.retCode == 714520 then
      --   local function closeCanonMessageBox()
      --     self:replaceScene(MainMenuScene)
      --   end
      --   local text = Localization:getInstance():getText("activityNian_timeOver")
      --   CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
      -- else
      --   local function closeCanonMessageBox()
      --   end
      --   local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = data.retCode})
      --   CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
      -- end
    end

    GetSecretShopListRequest.sendRequest(successCallback , failureCallback)
  elseif self.enabledPanels[idx].name == "Activity_DailyFirstCharge" then
      changePanel()
  elseif self.enabledPanels[idx].name == "Activity_PhoneCharge" then
    local function successCallback(data)
      PhoneChargeGetInfoRequest.onSucceedDefault(data)
      if self.sceneExit then
        return
      end
      extraArgs = data.data or {}
      changePanel()
    end

    PhoneChargeGetInfoRequest.sendRequest(successCallback, PhoneChargeGetInfoRequest.onFailedDefault)
  elseif self.enabledPanels[idx].name == "Activity_Question" then
    local function successCallback(evt)
      if self.sceneExit then
        return
      end

      extraArgs = evt.data
      changePanel()
    end
    local function failedCallback(evt)
      local errorCode = tonumber(evt.data)
      CanonMessageBox:showCommUnHandleErrorBox(errorCode)
    end

    local RewardRequest = QuestionActWeekRewardRequest.new({}, rpc.SendingPriority.kHigh)
    RewardRequest:addEventListener(RequestNotifyEnum.QuestionActWeekRewardRequestSucceed, successCallback)
    RewardRequest:addEventListener(RequestNotifyEnum.QuestionActWeekRewardRequestFailed, failedCallback)
    RewardRequest:start()
  elseif self.enabledPanels[idx].name == "Activity_Challenge" then
    local function successCallback(data)
      if self.sceneExit then
        return
      end
      extraArgs = data.data or {}
      changePanel()
    end

    local function failureCallback(data)
      if self.sceneExit then
        return
      end
    end

    GetTaskInfoRequest.sendRequest(successCallback , failureCallback)
  elseif self.enabledPanels[idx].name == "Activity_GemCard" then
    local function getAccumulateGemsSucceed(response)
      if self.sceneExit then
        return
      end
		  extraArgs = {buyConditionGem = tonumber(response.data.accumulateGems)}
		  changePanel()
		end
    local request = GetAccumulateGemsRequest.new(nil, rpc.SendingPriority.kHigh)
    request:addEventListener( RequestNotifyEnum.GetAccumulateGemsSucceed, getAccumulateGemsSucceed )
    request:start()
  elseif self.enabledPanels[idx].name == "Activity_BlowBalloon" then
    local featureName = DataManager.GameMetaData.activityBalloonConfig.featureNameReward
    local activityClose = not MaintenanceManager.isActivityOpen(featureName)
    if activityClose then
      local function callback()
        Director:sharedDirector():replaceScene(MainMenuScene:create())
      end
      CanonMessageBox:Show( getTextByKey("activity-treasurebox-over"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 ,callback)
      return
    end

    local function successCallback(evt)
      if self.sceneExit then
        return
      end
      extraArgs = evt.data or {gainYesterdayPointReward = false , balloonRanks = {}}
      changePanel()
    end
    
    local function failedCallback(evt)
      local errorCode = tonumber(evt.data)
      if errorCode == 714690 then
        CanonMessageBox:Show( getTextByKey("activity-treasurebox-over"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40)
      else
        CanonMessageBox:showCommUnHandleErrorBox(errorCode)
      end
    end

    local RewardRequest = BlowBalloonActInfoRequest.new({}, rpc.SendingPriority.kHigh)
    RewardRequest:addEventListener(RequestNotifyEnum.BlowBalloonActInfoRequestSucceed, successCallback)
    RewardRequest:addEventListener(RequestNotifyEnum.BlowBalloonActInfoRequestFailed, failedCallback)
    RewardRequest:start()
  elseif self.enabledPanels[idx].name == "Activity_CrossBoss" then
    local function successCallback(data)
      if self.sceneExit then
        return
      end
      extraArgs = data.data or {}
      changePanel()
    end

    local function failureCallback(data)
      if self.sceneExit then
        return
      end
    end

    GetCrossBossInfoRequest.sendRequest( {} ,successCallback , failureCallback)

  elseif self.enabledPanels[idx].name == "Activity_ConsumeRewards" then
    --多重好礼 获取数据
    local function onAfterSucceed(evt)
      if self.sceneExit then
        return
      end
      changePanel()
      --更新角标数
      self:resetTipInfoForActivity("Activity_ConsumeRewards")
    end
    ConsumeRewardGetInfoRequest.sendRequestDefalut(onAfterSucceed)
    
  elseif self.enabledPanels[idx].name == "Activity_LimitReward" then
    local limitRechargeData = Activity_rechargeLayer.getRechargeData()
    extraArgs = limitRechargeData
    --[[
    print("____________________________rewards recharge ")
    print("rewards "..table.tostring(limitRechargeData.rewards))
    print("recharge "..table.tostring(limitRechargeData.recharge))
    ]]
    changePanel()
  else
    changePanel()
  end
end

function ActivityPanelScene:setHeadTableViewEnable(isEnable)
  if self.headUI then
      self.headUI:setTouchEnabled(isEnable)
  end 
end 

function ActivityPanelScene:setTableViewsEnabledInner(isEnable)
  if self.headUI then
      self.headUI:setTouchEnabled(isEnable)
  end
  if self.selectedPanel and self.selectedPanel.setTouchEnabled then
    self.selectedPanel:setTouchEnabled(isEnable)
  end
end

function ActivityPanelScene:resetAllTipInfoData()
  for k, v in pairs(PANEL_NAME_DICT) do
    local aTipNum, aParticleStatus = v.getTipNum()
    if aTipNum >= 0 then
      PANEL_TIP_DICT[k] = aTipNum
    end
    PANEL_PARTICLE_DICT[k] = aParticleStatus
  end
end

function ActivityPanelScene:resetAllTipInfo()
  self:resetAllTipInfoData()
  
  self:resetTipInfoUI()
end

function ActivityPanelScene:resetTipInfoForActivity(activityName)
  local aTipNum, aParticleStatus = PANEL_NAME_DICT[activityName].getTipNum()
  if (aTipNum ~= PANEL_TIP_DICT[activityName]) or (aParticleStatus ~= PANEL_PARTICLE_DICT[activityName]) then
    PANEL_TIP_DICT[activityName] = aTipNum
    PANEL_PARTICLE_DICT[activityName] = aParticleStatus
    
    self:resetTipInfoUI()
  end
  
end

function ActivityPanelScene:onInit()
	BaseUIScene.initBackGround(self)
  
  self:resetAllTipInfoData()
  
  self:initPanelsInfo()
  
  self:initEnabledPanels()
	if self.argv and self.argv.selectPanelName then
		if type(self.enabledPanels) == "table" then
			for key, enablePanel in pairs(self.enabledPanels) do
				if enablePanel.name == self.argv.selectPanelName then
					self.selectedPanelIdxEx = key
					break;
				end
			end
		end
	end
  if( self.selectedPanelIdxEx ) then 
    self.selectedPanelIdx = self.selectedPanelIdxEx
  end
  
  self.bgMaskLayer = LayerColor:create()
  self.bgMaskLayer:setOpacity(kDarkOpacity)
  self.bgMaskLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(self.bgMaskLayer)
  
  self.headUI = self:createHeadTableView()
  
  self:addChild(self.headUI)
  
  BaseUIScene.onInit(self)
  
  self.gemChangeListener = function(ee)
    local shouldResetParticle = false
    if type(self.enabledPanels) == "table" then
			for _, enablePanel in pairs(self.enabledPanels) do
				if enablePanel.name == "Activity_goldGod" then
					shouldResetParticle = true
					break
				end
			end
		end
    if shouldResetParticle then
      self:resetTipInfoForActivity("Activity_goldGod")
    end
  end
  NotificationManager:addEventListener(DataChangedNotifyEnum.GemDataChanged,self.gemChangeListener)
  
  if not tipInfoShowTime then
    tipInfoShowTime = TimeUtil.getYmd()
  end
  local function checkSwitchDay()
    local aTempTime = TimeUtil.getYmd()
    if tipInfoShowTime ~= aTempTime then
      tipInfoShowTime = aTempTime
      
      self:resetAllTipInfo()
    end
  end
  self.checkSwitchDayFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(checkSwitchDay, 15, false)

  HeMemDataHolder:setInteger("Activity_SecretShopTips" , 0)
  
  local function checkMysteryShopReflesh(  )
    -- body
    local aTempTime = TimeUtil.getServerTimeSeconds()
    -- local lastRefleshTime = 0
    local targetTime = 0
    local newRefreshInterval = string.split(MetaManager.getGameSettingConfig().secretShopConfig.newRefreshInterval, '|')
    local todayTimestamp = TimeUtil.getTodayTimestampBy(0,0,0)
    local currentTime = TimeUtil.getServerTimeSeconds()
    local currentToatalTimestamp = todayTimestamp + newRefreshInterval[1]
    --print("todayTimestamp"..todayTimestamp)
    local fourHour = 0
    for i=1,#newRefreshInterval do
      if currentTime < currentToatalTimestamp then
        fourHour = newRefreshInterval[i]
        break
      else
        currentToatalTimestamp = currentToatalTimestamp + newRefreshInterval[i + 1]
      end
    end

    -- local fourHour = 14400
    --local fourHour = 300
    local gameInitData = DataManager.getGameInitData()
    if(not gameInitData.sharkUserSecretShop) then
      self.lastRefleshTime = -1
    else
      self.lastRefleshTime = gameInitData.sharkUserSecretShop.lastRefreshSecond
    end
    if (aTempTime - self.lastRefleshTime >= tonumber(fourHour)) then
      if self.lastSelectedPanelName and self.lastSelectedPanelName == "Activity_SecretShop" then
        HeMemDataHolder:setInteger("Activity_SecretShopTips" , 0)
        self:resetTipInfoForActivity("Activity_SecretShop")
      else
        HeMemDataHolder:setInteger("Activity_SecretShopTips" , 1)
        self:resetTipInfoForActivity("Activity_SecretShop")
      end
      local dis = aTempTime - self.lastRefleshTime
      local freshTimes = math.modf(dis / fourHour)
      gameInitData.sharkUserSecretShop.lastRefreshSecond = self.lastRefleshTime + freshTimes * fourHour
      self.lastRefleshTime = gameInitData.sharkUserSecretShop.lastRefreshSecond
      DataManager.setGameInitData(gameInitData)
    end
  end
  self.checkRefleshFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(checkMysteryShopReflesh, 5, false)
end

function ActivityPanelScene:dispose()
	self.sceneExit = true
  NotificationManager:removeEventListener(DataChangedNotifyEnum.GemDataChanged, self.gemChangeListener)
  if self.checkSwitchDayFunc then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.checkSwitchDayFunc )
  end
  if self.checkRefleshFunc then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.checkRefleshFunc )
  end
  ActivityPanelScene.super.dispose(self)
end

function ActivityPanelScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function ActivityPanelScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  CanonPlayBackgroundMusic("music/background.mp3", true)
end

function ActivityPanelScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  self.targetInfoPanel = nil
  
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.headUI:setPositionX(self.headUI:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.headUI:runAction(CCSequence:create(arr))
end

function ActivityPanelScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  if next(self.enabledPanels) ~= nil then
    local oriented
    if self.argv and self.argv.oriented then
      oriented = self.argv.oriented
    end
    self:replacePanel(self.selectedPanelIdx, oriented)
  end
end

function ActivityPanelScene:doExitAnimation()
	self.sceneExit = true
  self:preExitAnimation()
  self:startExitAnimation()
end

function ActivityPanelScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
  self.activitySceneExit = true
end

function ActivityPanelScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(-(visibleSize.width + visibleSize.width / 2.0), 0)))
  if self.selectedPanel then
	self.selectedPanel:runAction(CCSequence:create(arr))
  end
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.headUI:runAction(CCSequence:create(arr))
end

function ActivityPanelScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function ActivityPanelScene.getOriginalTipDict()
  for k, v in pairs(PANEL_NAME_DICT) do
		PANEL_TIP_DICT[k] = 0
	end
  return PANEL_TIP_DICT
end

function ActivityPanelScene.getOriginalParticleDict()
  for k, v in pairs(PANEL_NAME_DICT) do
		PANEL_PARTICLE_DICT[k] = nil
	end
  return PANEL_PARTICLE_DICT
end

function ActivityPanelScene.setStatusInfo(aStatusInfo)
  ACTIVITY_STATUS_INFO = aStatusInfo or {}
end

function ActivityPanelScene.setMBStatusInfo(hasUnDefeatedBoss, ungainedRewardNum)
  ACTIVITY_STATUS_INFO = ACTIVITY_STATUS_INFO or {}
  ACTIVITY_STATUS_INFO.hasUnDefeatedBoss = hasUnDefeatedBoss
  ACTIVITY_STATUS_INFO.ungainedRewardNum = ungainedRewardNum
end

function ActivityPanelScene.getStatusInfo()
  return ACTIVITY_STATUS_INFO or {}
end

function ActivityPanelScene.getPanelNameDict()
  return PANEL_NAME_DICT
end