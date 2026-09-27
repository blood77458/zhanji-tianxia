--------------------------------------------------------------------------------
-- Activity_EatPeachLayer.lua --吃桃活动
-- author: dang chao
-- updated: 2013-09-27
--------------------------------------------------------------------------------
require "canon.request.ActivityEatPeachRequest"
require "canon.manager.MaintenanceManager"
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

Activity_EatPeachLayer = class(Layer)
function Activity_EatPeachLayer:ctor()
    self.container = nil
    self.moveBlackBg = nil
    self.moveTextLabel = nil
    self.peachIcon = nil
    self.peachBgLight = nil
    self.eatPeachBtn = nil
    self.eatWhichPeach = nil
end

function Activity_EatPeachLayer:create( container )
    self.container = container
    local s = Activity_EatPeachLayer.new()
    s:initLayer()
    return s
end

function Activity_EatPeachLayer:setActivity_EatPeachLayerVisible(isVisible)
	self:setVisible(isVisible)
end 

function Activity_EatPeachLayer:setPeachVisible(isVisible)
     self.moveBlackBg:setVisible(isVisible)
     self.moveTextLabel:setVisible(isVisible)
     self.peachIcon:setVisible(isVisible)
     self.peachBgLight:setVisible(isVisible)
end 

function Activity_EatPeachLayer:panelDismiss()
    --self.eatPeachBtn:setEnabled(true)
    self.container.targetInfoPanel = nil
end

function Activity_EatPeachLayer:enable(curTimeStamp)
    local isEnable = MaintenanceManager.isActivityOpen("activity1Rest")
    return isEnable
end 

function Activity_EatPeachLayer:refreshEatPeachInfo()
  self.eatWhichPeach = nil
  self:setPeachVisible(false)
  
  local eatPeachInfo = DataManager.getGameInitData().sharkUserExtend.lstEatPeachInfo
  local isEnable1,isPeachOpen_1,t1,curState1 = MaintenanceManager.isActivityOpen("activity1Rest")
  local isEnable2,isPeachOpen_2,t2,curState2 = MaintenanceManager.isActivityOpen("activity2Rest")
  if isPeachOpen_1 then
    self.leftStateLabel:setText(getTextByKey("activity_activityActive"))
  else
    if curState1 == 0 then
      self.leftStateLabel:setText(getTextByKey("activity_activityClose"))
    else
      self.leftStateLabel:setText(getTextByKey("activity_activityExpired"))
    end 
  end
  if isPeachOpen_2 then
    self.rightStateLabel:setText(getTextByKey("activity_activityActive"))
  else
    if curState2 == 0 then
      self.rightStateLabel:setText(getTextByKey("activity_activityClose"))
    else
      self.rightStateLabel:setText(getTextByKey("activity_activityExpired"))
    end 
  end 
  local today = os.date("%x", TimeUtil.getServerTimeSeconds())
  for k,v in pairs(eatPeachInfo) do   
    local lastEatPeachTime = os.date("%x",v.eatPeachTime)
    if TimeUtil.getPasseddDaysToNow(v.eatPeachTime) == 0 then --判断为同一天
      if v.featureName == "activity1Rest" then
        self.leftStateLabel:setText(getTextByKey("activity_activityComplete"))
      elseif v.featureName == "activity2Rest" then
        self.rightStateLabel:setText(getTextByKey("activity_activityComplete"))
      end 
    end 
  end
  --
  if self.leftStateLabel:getText() == getTextByKey("activity_activityActive") then
    self.eatWhichPeach = "activity1Rest"
  end
  if self.rightStateLabel:getText() == getTextByKey("activity_activityActive") then
    self.eatWhichPeach = "activity2Rest"
  end
  self.leftStateLabel:construct()
  self.rightStateLabel:construct()
  if self.eatWhichPeach then
    self:setPeachVisible(true)
    self:runPeachEnterAction()
  end 
end 

function getEatPeachTime(peachName)
    local time1,time2 = 0
    for k,v in pairs(MaintenanceManager.ActivityOnOffConfigData) do 
        if v.name == peachName then
            time1 = v.activityOpen:split(":")[1]
            time2 = time1 + v.activityDuring / 60
            if time2 > 24 then
                time2 = time2 - 24
            end 
            break
        end
    end 
    return time1,time2
end 
function Activity_EatPeachLayer:initLayer()
    Activity_EatPeachLayer.super.initLayer(self)
    
    local function onClickEatPeachBtn(evt)
        --print("click eat peach btn")
        if not self.peachIcon:isVisible() then
            return
        end 
        local stNow, stNextTime, stAllTime, isEnergyFull, stMax = CalculationManager.calcComplex_getEnergyNow()
        if isEnergyFull then
            local aPanel = MessageBoxPanel:create(self, MessageBoxType.kEnergyFullCanNotEatPeach)
            self:addChild(aPanel) 
            aPanel:scaleIn()
            --self.eatPeachBtn:setEnabled(false)
            self.container.targetInfoPanel = aPanel
            return
        end 
        local function eatPeachRequestFinish(e)
            local gameInitData = DataManager.getGameInitData()
            local eatPeachInfo = gameInitData.sharkUserExtend.lstEatPeachInfo
            local existed
            for k,v in pairs(eatPeachInfo) do
              if (v.featureName == self.eatWhichPeach) then
                existed = true
                v.eatPeachTime = TimeUtil.getServerTimeSeconds()
                break
              end
            end
            if not existed then
              table.insert(eatPeachInfo, {featureName == self.eatWhichPeach, eatPeachTime = TimeUtil.getServerTimeSeconds()})
            end
            DataManager.setGameInitData(gameInitData)
            self:refreshEatPeachInfo()
            self.container:resetTipInfoForActivity("Activity_EatPeach")
            local aContent = Localization:getInstance():getText("activity_tips", {num = e.data.gainedEnergy})
            local susLabel = SuspensionLabel:showContent(self, aContent)
            susLabel:setPosition(ccp(360,600))
			--
			local energyInfo = {{itemType = 3,amount = e.data.gainedEnergy}}
			RewardManager:getReward( energyInfo )
        end 
        
        local function eatPeachRequestFailed(failData)
            local errorCode = tonumber(failData.data)
		    if errorCode == 714102 then
		        self.container.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("activity_activityExpired"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		        self:refreshEatPeachInfo()
            self.container:resetTipInfoForActivity("Activity_EatPeach")
		    else
		        CanonMessageBox:showCommUnHandleErrorBox(errorCode)
		    end
        end
        
        local params = {featureName = self.eatWhichPeach}
        local request = EatPeachRequest.new( params, rpc.SendingPriority.kHigh )
        request:addEventListener( RequestNotifyEnum.EatPeachSucceed, eatPeachRequestFinish )
        request:addEventListener( RequestNotifyEnum.EatPeachFailed, eatPeachRequestFailed )
        request:start()
    end 
    --init UI	
    local bg = CCSprite:create("pic/activityIcons/Activity_EatPeach_Bg.png")
    self:addChild(CocosObject.new(bg))
    bg:setPosition(ccp( 361, 495 ))
    --local bgSize = bg:getBounds().size
    self.peachIcon = Sprite:create("pic/Activity_EatPeach_Peach.png")
    self.peachBgLight = CCSprite:create("pic/activityIcons/Activity_EatPeach_PeachLight.png")
    self.moveBlackBg = CCSprite:create("pic/activityIcons/Activity_EatPeach_Text_Bg.png")
    self.moveTextLabel = TextField:create(getTextByKey( "activity_tapTip" ))
    self.moveTextLabel:setFontSize(35)
    --self.peachIcon:setPosition(ccp(bgSize.width/2,bgSize.height*0.35))
    self.peachIcon:setPosition(ccp(361,360))
    --self.peachBgLight:setPosition(ccp(bgSize.width/2,bgSize.height*0.35))
    self.peachBgLight:setPosition(ccp(361,360))
    --self.moveBlackBg:setPosition(ccp(bgSize.width/2,bgSize.height*0.25))
    self.moveBlackBg:setPosition(ccp(361,260))
    --self.moveTextLabel:setPosition(ccp(bgSize.width/2,bgSize.height*0.25))
    self.moveTextLabel:setPosition(ccp(361,260))
    local peach1Time1,peach1Time2 = getEatPeachTime("activity1Rest")
    local peach2Time1,peach2Time2 = getEatPeachTime("activity2Rest")
    self.leftOpenTimeLabel = ArtLabelTTF:create(getTextByKey( Localization:getInstance():getText("activity_firstTime",{time1 = peach1Time1,time2 = peach1Time2}) ),nil,30)
    self.rightOpenTimeLabel = ArtLabelTTF:create(getTextByKey( Localization:getInstance():getText("activity_secondTime",{time1 = peach2Time1,time2 = peach2Time2}) ),nil,30)
    --self.leftOpenTimeLabel:setFontSize(30)
    --self.rightOpenTimeLabel:setFontSize(30)
    self.leftOpenTimeLabel:setPosition(ccp(150,200))
    self.rightOpenTimeLabel:setPosition(ccp(600,200))
    
    self.leftStateLabel = ArtLabelTTF:create("",nil,30)
    --self.leftStateLabel:setFontSize(30)
    self.leftStateLabel:setPosition(ccp(150,150))
    self.rightStateLabel = ArtLabelTTF:create("",nil,30)
    --self.rightStateLabel:setFontSize(30)
    self.rightStateLabel:setPosition(ccp(600,150))
    
    self:addChild(CocosObject.new(self.leftStateLabel))
    self:addChild(CocosObject.new(self.rightStateLabel))
    self:addChild(CocosObject.new(self.leftOpenTimeLabel))
    self:addChild(CocosObject.new(self.rightOpenTimeLabel))
    self:addChild(CocosObject.new(self.peachBgLight))
    self:addChild(CocosObject.new(self.moveBlackBg))
    self:addChild(self.peachIcon)
    self:addChild(self.moveTextLabel)
    
    self.eatPeachBtn = Button:create( self.peachIcon)
    self.eatPeachBtn:addEventListener( Events.kStart,onClickEatPeachBtn ,self)
    
    self:refreshEatPeachInfo()
	
	local particle = CCParticleSystemQuad:create("effect/fx_flower.plist")
	particle:setPosition(ccp(360, 440))
	self:addChild(CocosObject.new(particle))
  
    local function checkPeachState()
      local aPeach
      local eatPeachInfo = DataManager.getGameInitData().sharkUserExtend.lstEatPeachInfo
      local isEnable1,isPeachOpen_1,t1,curState1 = MaintenanceManager.isActivityOpen("activity1Rest")
      local isEnable2,isPeachOpen_2,t2,curState2 = MaintenanceManager.isActivityOpen("activity2Rest")
      local function hasEatPeach(aPeachName)
        local today = os.date("%x", TimeUtil.getServerTimeSeconds())
        for k,v in pairs(eatPeachInfo) do   
          local lastEatPeachTime = os.date("%x",v.eatPeachTime)
          if ((TimeUtil.getPasseddDaysToNow(v.eatPeachTime))) and (v.featureName == aPeachName) then
            return true
          end 
        end
        return false
      end
      if isPeachOpen_1 then
        if not hasEatPeach("activity1Rest") then
          aPeach = "activity1Rest"
        end
      elseif isPeachOpen_2 then
        if not hasEatPeach("activity2Rest") then
          aPeach = "activity2Rest"
        end
      end
      if aPeach ~= self.eatWhichPeach then
        self:refreshEatPeachInfo()
        self.container:resetTipInfoForActivity("Activity_EatPeach")
      end
    end
    self.checkPeachStateFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(checkPeachState, 15, false)
end

function Activity_EatPeachLayer:dispose()
  if self.checkPeachStateFunc then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.checkPeachStateFunc )
  end
  Activity_EatPeachLayer.super.dispose(self)
end

function Activity_EatPeachLayer:runPeachEnterAction()
    self.moveBlackBg:setPosition(ccp(self.moveBlackBg:getPositionX()-visibleSize.width,self.moveBlackBg:getPositionY()))
    self.moveTextLabel:setPosition(ccp(self.moveTextLabel:getPositionX()+visibleSize.width,self.moveTextLabel:getPositionY()))
    self.peachIcon:setScale(0.01)
    self.peachBgLight:setScale(0.01)
    local arr1 = CCArray:create()
    arr1:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width+10, 0)))
    arr1:addObject(CCMoveBy:create(0.1, ccp(-10, 0)))
    self.moveBlackBg:runAction(CCSequence:create(arr1))
    local arr2 = CCArray:create()
    arr2:addObject(CCMoveBy:create(0.3, ccp(-visibleSize.width-10, 0)))
    arr2:addObject(CCMoveBy:create(0.1, ccp(10, 0)))
    self.moveTextLabel:runAction(CCSequence:create(arr2))
    local arr3 = CCArray:create()
    arr3:addObject(CCScaleTo:create(0.3,1.1))
    arr3:addObject(CCScaleTo:create(0.1,1))
    local function peachIconHeartBeat()
        local arr = CCArray:create()
        arr:addObject(CCScaleTo:create(0.8,1.3))
        arr:addObject(CCScaleTo:create(0.8,1))
        self.peachIcon:runAction(CCRepeatForever:create(CCSequence:create(arr)))
    end 
    arr3:addObject(CCCallFunc:create(peachIconHeartBeat))
    self.peachIcon:runAction(CCSequence:create(arr3))
    local arr4 = CCArray:create()
    arr4:addObject(CCScaleTo:create(0.3,1.5))
    arr4:addObject(CCScaleTo:create(0.1,1.4))
    local function peachBgLightHeartBeat()
        local arr = CCArray:create()
        arr:addObject(CCScaleTo:create(0.8,1.7))
        arr:addObject(CCScaleTo:create(0.8,1.4))
        self.peachBgLight:runAction(CCRepeatForever:create(CCSequence:create(arr)))
        self.peachBgLight:runAction(CCRepeatForever:create(CCRotateBy:create(1.5,90)))
    end 
    arr4:addObject(CCCallFunc:create(peachBgLightHeartBeat))
    self.peachBgLight:runAction(CCSequence:create(arr4))
end 

function Activity_EatPeachLayer:startEnterAnimation_Run()
        
end 

function Activity_EatPeachLayer:startExitAnimation_Run()
end

function Activity_EatPeachLayer.getTipNum()
  if not Activity_EatPeachLayer.enable() then
    return 0
  end
  
  ----make sure that at least default values exist in activityInfo
  local gameInitData = DataManager.getGameInitData()
  local eatPeachInfo = gameInitData.sharkUserExtend.lstEatPeachInfo
  if not eatPeachInfo then
    eatPeachInfo = {{featureName = "activity1Rest", eatPeachTime = 0}, {featureName = "activity2Rest", eatPeachTime = 0}}
    gameInitData.sharkUserExtend.lstEatPeachInfo = eatPeachInfo
    DataManager.setGameInitData(gameInitData)
  else
    local hasRest1
    local hasRest2
    for k,v in pairs(eatPeachInfo) do
      if v.featureName == "activity1Rest" then
        hasRest1 = true
      end
      if v.featureName == "activity2Rest" then
        hasRest2 = true
      end
    end
    if not hasRest1 then
      table.insert(eatPeachInfo, {featureName = "activity1Rest", eatPeachTime = 0})
    end
    if not hasRest2 then
      table.insert(eatPeachInfo, {featureName = "activity2Rest", eatPeachTime = 0})
    end
    DataManager.setGameInitData(gameInitData)
  end
  
  local _,isPeachOpen_1 = true--MaintenanceManager.isActivityOpen("activity1Rest")  --modified by jet:enable函数中已经判断过了，不需要再次判断
  local _,isPeachOpen_2 = MaintenanceManager.isActivityOpen("activity2Rest")
  if (not isPeachOpen_1) and (not isPeachOpen_2) then
    return 0
  end
  
  local hasPeach
  
  ----
  local today = os.date("%x", TimeUtil.getServerTimeSeconds())
  for k,v in pairs(eatPeachInfo) do   
    local lastEatPeachTime = os.date("%x",v.eatPeachTime)
    if TimeUtil.getPasseddDaysToNow(v.eatPeachTime) ~= 0 then --不是同一天的判断
      if (v.featureName == "activity1Rest") and isPeachOpen_1 then
        hasPeach = true
        break
      end
      if (v.featureName == "activity2Rest") and isPeachOpen_2 then
        hasPeach = true
        break
      end
    end 
  end
  if hasPeach then
    return 1
  else
    return 0
  end
end