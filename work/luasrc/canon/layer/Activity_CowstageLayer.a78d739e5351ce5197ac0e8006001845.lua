--------------------------------------------------------------------------------
-- Activity_CowstageLayer.lua --牧场活动（奶牛大战）
-- author: dang chao
-- updated: 2013-10-04
--------------------------------------------------------------------------------
require "canon.request.ActivityCowStageRequest"
require "canon.manager.MaintenanceManager"
require "canon.manager.BagCalcManager"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

Activity_CowstageLayer = class(Layer)
function Activity_CowstageLayer:ctor()
    self.container = nil
    self.cowstage = {}
end

function Activity_CowstageLayer:create( container )
    local s = Activity_CowstageLayer.new()
    self.container = container
    s:initLayer()
    return s
end

function Activity_CowstageLayer:setActivity_CowstageLayerVisible(isVisible)
	self:setVisible(isVisible)
end 

function Activity_CowstageLayer:enable(curTimeStamp)
    if not DataManager.GameMetaData.activityCowStageConfig then
      return false
    end
    
    return true
end 

function Activity_CowstageLayer.whetherActivityOpen()
  local activityOpen = false
  for _, aFeatureName in pairs(DataManager.GameMetaData.activityCowStageConfig.featureNamesList) do
    --[[
    for k,v in pairs(MaintenanceManager.ActivityOnOffConfigData) do 
      if v.name == aFeatureName then
        
      end
    end
    ]]
    if MaintenanceManager.isActivityOpen(aFeatureName) then
      activityOpen = true
      break
    end
  end
  return activityOpen
end

function Activity_CowstageLayer:panelDismiss()
    self.container.targetInfoPanel = nil
end

function Activity_CowstageLayer:refreshCowstageInfo()
  local lastCowStageInfo = {}
  for k,v in pairs(DailyDataManager.getLstCowStageInfo()) do 
      table.insert(lastCowStageInfo,v.cowStageId, {challengTimes = v.challengeNums})
  end 

  local isEnable = Activity_CowstageLayer.whetherActivityOpen()
  for k,v in pairs(self.cowstage) do 
      local challengeTimes 
      if lastCowStageInfo[v.challengeCowstageId] then
          challengeTimes = lastCowStageInfo[v.challengeCowstageId].challengTimes
      else
          challengeTimes = 0
      end 
	  
	  if v.challengeTimesLabel.refCocosObj then
		  v.challengeTimesLabel:setString("("..challengeTimes.."/"..MetaManager.cow_stage[v.challengeTag].maxChallengesPerDay..")")
		  challengeTimes = MetaManager.cow_stage[v.challengeTag].maxChallengesPerDay - challengeTimes
		  
		  if challengeTimes <= 0  or not isEnable then
			  --v.challengeTimesLabel:setColor(ccc3(255,0,0))
			  v.challengeBtn:setEnable(false)
			  v.challengeBtnPic:getChildByName("bg_btn_active"):setVisible(false)
		  end 
	  end
  end 
end 

function Activity_CowstageLayer:enableUserTouch(isEnable)
    for k,v in pairs(self.cowstage) do 
        v.challengeBtn:setEnable(isEnable)
    end
end 

function Activity_CowstageLayer:panelDismiss()
    self:enableUserTouch(true)
    self.container.targetInfoPanel = nil
end

function Activity_CowstageLayer:initLayer()
    Activity_CowstageLayer.super.initLayer(self)
    self.cowstage = {}
    local function onChallengeCowStageBtnClick(evt)
        --print(evt.context)
        local function closeCanonMessageBox()
            self.container:setHeadTableViewEnable(true)
        end 
        local gameInitData = DataManager.getGameInitData()
        if gameInitData.sharkUser.level < MetaManager.cow_stage[evt.context].playerLevelLimit then
            
            self.container.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("stageLevelLimite", {stageLevelLimite = MetaManager.cow_stage[evt.context].playerLevelLimit}), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
            self.container:setHeadTableViewEnable(false)
            return
        end
        local energy,_,_,_,maxEnergy = CalculationManager.calcComplex_getEnergyNow() 
        local consumeEnergy = MetaManager.cow_stage[evt.context].consumeEnergy
        if energy < consumeEnergy then
            local hasEnergyProp, energyPropList = BagCalcManager.getEnergyPropList()
            if hasEnergyProp then
              local function callback(aEnergyPropId)
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
                  SuspensionLabel:showContent(self.container, getTextByKey("propInfo_energyReplenished"))
                end
                
                local function usePropFailed(event)
                  if event.data.retCode == 712308 then
                    CanonMessageBox:Show( getTextByKey("propInfo_energyFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
                  elseif event.data.retCode == 712301 then
                    local aPropMetaConfig = MetaManager.prop_meta[aEnergyPropId]
                    CanonMessageBox:Show( getTextByKey("popup_noProp", {propname = Localization:getInstance():getText(aPropMetaConfig.name)}), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
                  end
                end
                
                local request = UsePropRequest.new( {propId = aEnergyPropId}, rpc.SendingPriority.kHigh )
                request:addEventListener( RequestNotifyEnum.UsePropSucceed, usePropSucceed )
                request:addEventListener( RequestNotifyEnum.UsePropFailed, usePropFailed )
                request:start()
              end
              local aPanel = EEPSupplyPanel:create(self.container, energyPropList, callback, true)
              self.container:addChild(aPanel)
              aPanel:scaleIn()
            else
              local function callback()
              end
              local aPanel = EENPSupplyPanel:create(self.container, {supplyType = EESupplyTypeEnum.Energy, callback = callback})
              self.container:addChild(aPanel)
              aPanel:scaleIn()
            end
            
            return
        end 
        
		if BagCalcManager.isFull() then
		    self.container.targetInfoPanel = NewPackageFullPanel:show()
            self.container:setHeadTableViewEnable(false)
		    return
		end
		local curContext = evt.context
        local function requestChallengeCowstageFinish(response)
            if response.data.win then
                local energyInfo = {{itemType = 3,amount = -consumeEnergy}}
                RewardManager:getReward( energyInfo )
                local cowStageInfo = DailyDataManager.getLstCowStageInfo()
                local existed
                for _, aCowStageInfo in pairs(cowStageInfo) do
                  if MetaManager.cow_stage[curContext].id == aCowStageInfo.cowStageId then
                    existed = true
                    aCowStageInfo.challengeNums = aCowStageInfo.challengeNums + 1
                    break
                  end
                end
                if not existed then
                  table.insert(cowStageInfo, {cowStageId = MetaManager.cow_stage[curContext].id, challengeNums = 1})
                end
                DailyDataManager.setLstCowStageInfo(cowStageInfo)
            end 
			response.data.selectId = MetaManager.cow_stage[curContext].id
			Director:sharedDirector():replaceScene(BattleScene:create(response.data, BattleBackType.kActivityCowStage, BattleEnterEnum.kActivityCowStage, 2))
        end 
	
	local function requestChallengeCowstageFailed(failData)
		local errorCode = tonumber(failData.data)
		if errorCode == 714123 then
			self.container.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("activity_activityExpired"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		        self:refreshCowstageInfo()
		else
		        CanonMessageBox:showCommUnHandleErrorBox(errorCode)
		end
	end 
        local params = {cowStageId = MetaManager.cow_stage[evt.context].id}
        local request = ChallengeCowStageRequest.new( params, rpc.SendingPriority.kHigh )
	    request:addEventListener( RequestNotifyEnum.ChallengeCowStageSucceed, requestChallengeCowstageFinish )
	    request:addEventListener( RequestNotifyEnum.ChallengeCowStageFailed, requestChallengeCowstageFailed )
	    request:start()
	
    end
    --cow stage config
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/cowstage_new.json")
	self.mainUI = self.builder:build("cowstage")
	self:addChild(self.mainUI)
	self.builder.useArtLabelTTF = true
    --init UI	
    self.mainUI:getChildByName("cowstage_title"):setVisible(false)
	self.mainUI:getChildByName("cowstage_list"):setVisible(false)
	self.mainUI:getChildByName("cowstage_info_font"):getChildByName("cowstage_info_font"):setString(getTextByKey("cow_activityDesc"))
	self.mainUI:getChildByName("cowstage_info_font_1"):getChildByName("cowstage_info_font"):setString(getTextByKey("cow_activityDesc2"))
	local cowstageIntervalY = 180 
	local cowstageBeginPosX = self.mainUI:getChildByName("cowstage_list"):getPositionX()
	local cowstageBeginPosY = self.mainUI:getChildByName("cowstage_list"):getPositionY()
	
	local cowAdsPic = CCSprite:create("pic/cow.png")
	cowAdsPic:setAnchorPoint(ccp(0.5,1))
    self.mainUI:addChild(CocosObject.new(cowAdsPic))
    cowAdsPic:setPosition(ccp(visibleSize.width/2,880))
	for i = 1 , 3 do 
	    local cowstage = self.builder:build("cowstage_list")
	    cowstage:getChildByName("cowstage_normal_card_small"):setVisible(false)
	    cowstage:setPosition(ccp(cowstageBeginPosX,cowstageBeginPosY-(i-1)*cowstageIntervalY))
	    --cowstage:getChildByName("font_information3"):getChildByName("font_information3"):setString(getTextByKey("cowStageName_100"..i))
	    cowstage:getChildByName("cowstage_font_information3"):setVisible(false)
	    local txtSize = 30
	    local txtColor = cowstage:getChildByName("cowstage_font_information3"):getChildByName("font_information3"):getColor()
	    local txtPosX = cowstage:getChildByName("cowstage_font_information3"):getPositionX()
	    local txtPosY = cowstage:getChildByName("cowstage_font_information3"):getPositionY()
	    
	    local difficultyNameLabel = ArtLabelTTF:create(getTextByKey("cowStageName_100"..i),nil,txtSize)
	    difficultyNameLabel:setCenterColor(txtColor)
	    difficultyNameLabel:setSize(txtSize)
	    difficultyNameLabel:setTextAnchorPoint(ccp(0,1))
	    difficultyNameLabel:construct()
	    difficultyNameLabel:setPosition(ccp(txtPosX,txtPosY))
	    cowstage:addChild(CocosObject.new(difficultyNameLabel))
	    local aCard = MetaManager.card_meta[MetaManager.cow_stage[i].cardId]
	    local aCardName
	    if aCard then
	        aCardName = aCard.name
	    else
	        aCardName = MetaManager.cow_stage[i].cardId
	    end 
	    local cardPic = getBackpackHeadIconCanonCardByMetaId(MetaManager.cow_stage[i].cardId)
	    --cardPic:setScale(0.5)
	    cowstage:addChild(cardPic)
	    cardPic:setPosition(ccp(cowstage:getChildByName("cowstage_normal_card_small"):getPositionX(),cowstage:getChildByName("cowstage_normal_card_small"):getPositionY()))
	    cowstage:getChildByName("cowstage_font_information2"):getChildByName("font_information2"):setString(getTextByKey(Localization:getInstance():getText("cow_dropDesc",{cardName = getTextByKey(aCardName)})))
	    cowstage:getChildByName("cowstage_font_information1"):getChildByName("font_information1"):setString(getTextByKey(Localization:getInstance():getText("cow_challengeCost",{num = MetaManager.cow_stage[i].consumeEnergy})))
	    cowstage:getChildByName("cowstage_btn_yellow_short"):getChildByName("font"):setString(getTextByKey("cow_challenge"))
	    cowstage:getChildByName("cowstage_font_information4"):getChildByName("font_information2"):setString("")
	    local challengeCowstageBtn = Button:create(cowstage:getChildByName("cowstage_btn_yellow_short"))
	    challengeCowstageBtn:addEventListener(Events.kStart,onChallengeCowStageBtnClick,i)
	    
	    self:addChild(cowstage)
	    
	    table.insert(self.cowstage , {challengeTag = i,
	                                  challengeCowstageId = MetaManager.cow_stage[i].id,
                                      challengeTimesLabel = cowstage:getChildByName("cowstage_font_information4"):getChildByName("font_information2"),
                                      challengeBtn = challengeCowstageBtn,
                                      challengeBtnPic = cowstage:getChildByName("cowstage_btn_yellow_short")})
	end 
	
	
	local scheduler = nil
    local function refreshCowstageInfoFunc()
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(scheduler)
        self:refreshCowstageInfo()
		self.container:setTouchEnabled(true)
		self.container:setHeadTableViewEnable(true)
    end 
	self.container:setTouchEnabled(false)
	self.container:setHeadTableViewEnable(false)
    scheduler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(refreshCowstageInfoFunc,0.1,false)
    
end

function Activity_CowstageLayer:runPeachEnterAction()
    
end 

function Activity_CowstageLayer:startEnterAnimation_Run()
        
end 

function Activity_CowstageLayer:startExitAnimation_Run()
end

function Activity_CowstageLayer.getTipNum()
  if not Activity_CowstageLayer.enable() then
    return 0
  end
  
  local activityOpen = Activity_CowstageLayer.whetherActivityOpen()
  if not activityOpen then
    return 0
  end
  
  local leftChallengeNum = 0
  local cowStageInfo = DailyDataManager.getLstCowStageInfo()
  local userLevel = DataManager.getCurrUser().level
  for _, aCowStageConfig in pairs(MetaManager.cow_stage) do
    if userLevel >= aCowStageConfig.playerLevelLimit then
      local existed
      for _, aCowStageInfo in pairs(cowStageInfo) do
        if aCowStageConfig.id == aCowStageInfo.cowStageId then
          existed = true
          leftChallengeNum = leftChallengeNum + aCowStageConfig.maxChallengesPerDay - aCowStageInfo.challengeNums
          break
        end
      end
      if not existed then
        leftChallengeNum = leftChallengeNum + aCowStageConfig.maxChallengesPerDay
      end
    end
  end
  
  return leftChallengeNum
end