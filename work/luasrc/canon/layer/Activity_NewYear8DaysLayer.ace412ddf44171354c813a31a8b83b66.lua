require "canon.request.ActivityNewYear8DaysRequest"

Activity_NewYear8DaysLayer = class(Layer)

local dayRewardActivityStartAndEndTime
local dayRewardInfoGainIds
local oldTime
local PARTICLE_TAG = 1234
local function getCurRewardTime(rewardDate)
   local rewardDateList = rewardDate:split("/")
   local curRewardTime = os.time({day=rewardDateList[3] , month=rewardDateList[2],year=rewardDateList[1], hour=0, min=0, sec=0}) 
   return curRewardTime
end

function Activity_NewYear8DaysLayer:ctor()
    self.container = nil
end

function Activity_NewYear8DaysLayer:create( container )
    self.container = container
    local s = Activity_NewYear8DaysLayer.new()
    s:initLayer()
    return s
end

function Activity_NewYear8DaysLayer:enable(curTimeStamp)
    if not DataManager.GameMetaData.activityDayRewardConfig then
      return false
    end
    local isEnable = MaintenanceManager.isActivityOpen("activityDayReward")
    dayRewardActivityStartAndEndTime = MaintenanceManager:getStartAndEndTime("activityDayReward")
    if isEnable then
      local sharkActivity = DataManager.getSharkActivity()
      sharkActivity.dayRewardInfo = sharkActivity.dayRewardInfo or {}
      if (not sharkActivity.dayRewardInfo.gainedIds) then
        sharkActivity.dayRewardInfo.featureStartSeconds = 0
        sharkActivity.dayRewardInfo.gainedIds = {}
      end
      
      if dayRewardActivityStartAndEndTime[1].activityBeginTimeStamp ~= sharkActivity.dayRewardInfo.featureStartSeconds then
        sharkActivity.dayRewardInfo.gainedIds = {}
        sharkActivity.dayRewardInfo.featureStartSeconds = dayRewardActivityStartAndEndTime[1].activityBeginTimeStamp
      end 
      DataManager.setSharkActivity(sharkActivity)
      
      dayRewardInfoGainIds = sharkActivity.dayRewardInfo.gainedIds
    end
    return isEnable
end 



function Activity_NewYear8DaysLayer:initLayer()
    Activity_NewYear8DaysLayer.super.initLayer(self)
    
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/eight_day_event.json")
    self.builder.useArtLabelTTF = true
    self.mainUI = self.builder:build("eight_day_event")
    self:addChild(self.mainUI)
    
    -- local guide_other = self.mainUI:getChildByName("guide")
    -- guide_other:setVisible(false)
    -- local card3_spf = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(103167))
    -- card3_spf:setScale(1.39)
    -- card3_spf:setPosition(ccp(guide_other:getPositionX() + guide_other:getContentSize().width / 2.0, guide_other:getPositionY() - guide_other:getContentSize().height / 2.0 - 60))
    -- self.mainUI:addChildAt(card3_spf, 3)
    
    -- self.mainUI:getChildByName("txt_event_info1"):getChildByName("txt"):setString(getTextByKey("activity_day_text"))
    -- self.mainUI:getChildByName("txt_event_info2"):getChildByName("txt"):setString(getTextByKey("activity_day_text1"))
    
    -- self.mainUI:getChildByName("txt_event_info3"):getChildByName("txt"):setString(dayRewardActivityStartAndEndTime[1].month)  
    -- self.mainUI:getChildByName("txt_event_info4"):getChildByName("txt"):setString(getTextByKey("activity_day_text2"))
    -- self.mainUI:getChildByName("txt_event_info5"):getChildByName("txt"):setString(dayRewardActivityStartAndEndTime[1].day)
    -- self.mainUI:getChildByName("txt_event_info6"):getChildByName("txt"):setString(getTextByKey("activity_day_text3"))
    -- self.mainUI:getChildByName("txt_event_info7"):getChildByName("txt"):setString(dayRewardActivityStartAndEndTime[2].month)
    -- self.mainUI:getChildByName("txt_event_info8"):getChildByName("txt"):setString(getTextByKey("activity_day_text2"))
    -- self.mainUI:getChildByName("txt_event_info9"):getChildByName("txt"):setString(dayRewardActivityStartAndEndTime[2].day)
    -- self.mainUI:getChildByName("txt_event_info10"):getChildByName("txt"):setString(getTextByKey("activity_day_text4"))  
    self.mainUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("activity-sworn-title1"))
    local beginTime = dayRewardActivityStartAndEndTime[1].month..getTextByKey("activity_day_text2")..dayRewardActivityStartAndEndTime[1].day..getTextByKey("activity_day_text3")
    local endTime = dayRewardActivityStartAndEndTime[2].month..getTextByKey("activity_day_text2")..dayRewardActivityStartAndEndTime[2].day..getTextByKey("activity_day_text4")
    self.mainUI:getChildByName("txt_2"):getChildByName("txt"):setString(beginTime..endTime)

    self.mainUI:getChildByName("txt_1"):getChildByName("txt"):setColor(ccc3(102, 48, 0))
    self.mainUI:getChildByName("txt_1"):getChildByName("txt"):setAroundColor(ccc3(255, 255, 255))
    self.mainUI:getChildByName("txt_2"):getChildByName("txt"):setColor(ccc3(255, 102, 51))
    self.mainUI:getChildByName("txt_2"):getChildByName("txt"):setAroundColor(ccc3(255, 255, 255))

    
    self.rewardUITable = {}         
    local refreshDayRewardUI = nil                                                                                          
    local function GainRewardBtnClick(evt)
        local dayRewardId = evt.context
        if BagCalcManager.isFull() then
        --if true then
		    self.container.targetInfoPanel = NewPackageFullPanel:show()
            self.container:setHeadTableViewEnable(false)
		    return
		end 
		
		if TimeUtil.whetherSwitchDay(oldTime) then
		    oldTime = TimeUtil.getServerTimeSeconds()
		    self.container.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("activity_day_miss"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		    refreshDayRewardUI()
        self.container:resetTipInfoForActivity("Activity_DayReward")
		    return
		end 
		
		local function GainDayRewardSucc(succData)
		    print("GainDayRewardSucc")
		    --
		    local rewardList = MetaManager.getRewardInfoByID(DataManager.GameMetaData.activityDayRewardConfig.dayRewards[dayRewardId].rewardPackId) or {}
		    RewardManager:getReward(rewardList)
        
            local RewardPanel = GetRewardInfoPanel:create( self.container, rewardList)
            PopoutManager:sharedManager():popout( RewardPanel, kPopoutDir.kScale, true, false ,self.container )
		    --
		    local sharkActivity = DataManager.getSharkActivity()
		    table.insert(sharkActivity.dayRewardInfo.gainedIds,dayRewardId)
		    
		    DataManager.setSharkActivity(sharkActivity)
      
            dayRewardInfoGainIds = sharkActivity.dayRewardInfo.gainedIds
		    refreshDayRewardUI()
        self.container:resetTipInfoForActivity("Activity_DayReward")
		end
		
		local function GainDayRewardFail(failData)
		    print("GainDayRewardFail")
		    local errorCode = tonumber(failData.data)
		    if errorCode == 716220 then
		        self.container.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("activity_day_wrong"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		    elseif errorCode == 716221 then
		        self.container.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("activity_day_configure"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		    elseif errorCode == 716222 then
		        self.container.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("activity_day_gained"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		        
		        local sharkActivity = DataManager.getSharkActivity()
                table.insert(sharkActivity.dayRewardInfo.gainedIds,dayRewardId)
                DataManager.setSharkActivity(sharkActivity)
                dayRewardInfoGainIds = sharkActivity.dayRewardInfo.gainedIds
            elseif errorCode == 716223 then 
                self.container.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("activity_day_wrong"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		    else
		        CanonMessageBox:showCommUnHandleErrorBox(errorCode)
		    end 
		    refreshDayRewardUI()
        self.container:resetTipInfoForActivity("Activity_DayReward")
		end
		
		local params = {dayRewardId = dayRewardId}
		local request = GainDayRewardRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(RequestNotifyEnum.GainDayRewardSucceed, GainDayRewardSucc)
		request:addEventListener(RequestNotifyEnum.GainDayRewardFailed, GainDayRewardFail)
		request:start()  
    end
    
    local function showRewardPanel(rewardList)
      local aRewardPanel = RewardReviewPanel:create( self.container, {rewardList = rewardList, rewardTitle = Localization:getInstance():getText("activity_day_text5")} )
      self.container:addChild(aRewardPanel)
      aRewardPanel:scaleIn()
    end
    
    local function RewardBoxBtnClick(evt)
        showRewardPanel(MetaManager.getRewardInfoByID(DataManager.GameMetaData.activityDayRewardConfig.dayRewards[evt.context].rewardPackId) or {})
    end
    
   
    
    refreshDayRewardUI = function()
        for k,v in pairs(DataManager.GameMetaData.activityDayRewardConfig.dayRewards) do 
            local hasGained = false
            if dayRewardInfoGainIds ~= nil then
                for ck,cv in pairs(dayRewardInfoGainIds) do 
                    if v.id == cv then
                        hasGained = true
                        break
                    end
                end 
            end
            local gainRewardBtnDisplay
            local gainRewardBtn
            local rewardBoxBtnDisplay
            local rewardBoxBtn
            if (self.rewardUITable[v.id]) == nil then
                local dayRewardUI = {}
                --gain reward btn
                gainRewardBtnDisplay = self.mainUI:getChildByName("btn_get_eight_reward"..v.id)
                gainRewardBtn = Button:create(gainRewardBtnDisplay)
                gainRewardBtn:addEventListener(Events.kStart, GainRewardBtnClick, v.id)
                --reward box btn
                rewardBoxBtnDisplay = self.mainUI:getChildByName("eight_day_event_reward_item"..v.id)
                rewardBoxBtn = Button:create(rewardBoxBtnDisplay)
                rewardBoxBtn:addEventListener(Events.kStart, RewardBoxBtnClick, v.id)
                
                dayRewardUI.gainRewardBtnDisplay = gainRewardBtnDisplay
                dayRewardUI.rewardBoxBtnDisplay = rewardBoxBtnDisplay
                dayRewardUI.gainRewardBtn = gainRewardBtn
                dayRewardUI.rewardBoxBtn = rewardBoxBtn
                table.insert(self.rewardUITable,dayRewardUI)
            else
                gainRewardBtnDisplay = self.rewardUITable[v.id].gainRewardBtnDisplay
                gainRewardBtn = self.rewardUITable[v.id].gainRewardBtn
                rewardBoxBtnDisplay = self.rewardUITable[v.id].rewardBoxBtnDisplay
                rewardBoxBtn = self.rewardUITable[v.id].rewardBoxBtn
            end
            
            
           gainRewardBtnDisplay:getChildByName("txt_2"):setVisible(true)
           gainRewardBtnDisplay:getChildByName("txt_1"):setVisible(true)
           gainRewardBtnDisplay:getChildByName("btn"):setVisible(true)
           gainRewardBtn:setEnable(true)
            
            if hasGained then
                --has gained this day reward
                gainRewardBtn:setEnable(false)
                gainRewardBtnDisplay:getChildByName("txt_2"):setString(getTextByKey("activity_day_get"))
                gainRewardBtnDisplay:getChildByName("txt_1"):setVisible(false)
                gainRewardBtnDisplay:getChildByName("btn"):setVisible(false)
                
                rewardBoxBtnDisplay:getChildByName("icon_libao"):setVisible(false)
            else
                local curTime = TimeUtil.getServerTimeSeconds()
                local rewardTime = getCurRewardTime(v.date)
                if curTime - rewardTime < 0 then
                        --no arrival this day
                        gainRewardBtnDisplay:getChildByName("txt_2"):setVisible(false)
                        gainRewardBtnDisplay:getChildByName("txt_1"):setString(getTextByKey("activity_day_date"..v.id))
                        gainRewardBtn:setEnable(false)
                        
                        gainRewardBtnDisplay:getChildByName("btn"):setVisible(false)
                else
                    if curTime - rewardTime > 24*60*60 then
                        --miss this day reward
                        gainRewardBtn:setEnable(false)
                        gainRewardBtnDisplay:getChildByName("txt_2"):setString(getTextByKey("activity_day_miss"))
                        gainRewardBtnDisplay:getChildByName("txt_1"):setVisible(false)
                        gainRewardBtnDisplay:getChildByName("btn"):setVisible(false)
                        
                        rewardBoxBtnDisplay:getChildByName("icon_libao"):setVisible(false)
                    elseif curTime - rewardTime <= 24*60*60 then
                        --can gain this day reward
                        gainRewardBtnDisplay:getChildByName("txt_2"):setVisible(false)
                        gainRewardBtnDisplay:getChildByName("txt_1"):setString(getTextByKey("activity_day_date"..v.id))
                        --
                        local rewardParticle = CCParticleSystemQuad:create(ParticlePathConstants.FxStarline)
                        rewardParticle:setPositionType(kCCPositionTypeRelative)
                        rewardParticle:setPosition(ccp(0, 74))
                        rewardParticle:setTag(PARTICLE_TAG)
                        gainRewardBtnDisplay:getChildByName("btn"):addChild(CocosObject.new(rewardParticle), 1000)
                        local particleMoveArray = CCArray:create()
                        local particleMoveTime = 0.4
                        particleMoveArray:addObject(CCMoveBy:create(particleMoveTime*2, ccp(250, 0)))
                        particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(0, -74)))
                        particleMoveArray:addObject(CCMoveBy:create(particleMoveTime*2, ccp(-250, 0)))
                        particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(0, 74)))
                        rewardParticle:runAction(CCRepeatForever:create(CCSequence:create(particleMoveArray)))
                    end
                end
                
                oldTime = curTime
            end
            
        end
    end
    refreshDayRewardUI()
    
    local oldDate = TimeUtil.getYmd()
    local function checkSwitchDay()
      local aTempTime = TimeUtil.getYmd()
      if oldDate ~= aTempTime then
        oldDate = aTempTime
        refreshDayRewardUI()
        self.container:resetTipInfoForActivity("Activity_DayReward")
      end
    end
    self.checkSwitchDayFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(checkSwitchDay, 15, false)
end

function Activity_NewYear8DaysLayer:dispose()
  if self.checkSwitchDayFunc then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkSwitchDayFunc)
    self.checkSwitchDayFunc = nil
  end
  Activity_NewYear8DaysLayer.super.dispose(self)
end

function Activity_NewYear8DaysLayer:startEnterAnimation_Run()
        
end 

function Activity_NewYear8DaysLayer:startExitAnimation_Run()
end

function Activity_NewYear8DaysLayer_JudgeRewardInfo()
    if not DataManager.GameMetaData.activityDayRewardConfig then
      return false
    end
    local isEnable = MaintenanceManager.isActivityOpen("activityDayReward")
    dayRewardActivityStartAndEndTime = MaintenanceManager:getStartAndEndTime("activityDayReward")
    if isEnable then
      local sharkActivity = DataManager.getSharkActivity()
      sharkActivity.dayRewardInfo = sharkActivity.dayRewardInfo or {}
      if (not sharkActivity.dayRewardInfo.gainedIds) then
        sharkActivity.dayRewardInfo.featureStartSeconds = 0
        sharkActivity.dayRewardInfo.gainedIds = {}
      end
      
      if dayRewardActivityStartAndEndTime[1].activityBeginTimeStamp ~= sharkActivity.dayRewardInfo.featureStartSeconds then
        sharkActivity.dayRewardInfo.gainedIds = {}
        sharkActivity.dayRewardInfo.featureStartSeconds = dayRewardActivityStartAndEndTime[1].activityBeginTimeStamp
      end 
      DataManager.setSharkActivity(sharkActivity)
      
      dayRewardInfoGainIds = sharkActivity.dayRewardInfo.gainedIds
      --
        local hasRewardCanGain = false
        for k,v in pairs(DataManager.GameMetaData.activityDayRewardConfig.dayRewards) do 
            local hasGained = false
            if dayRewardInfoGainIds ~= nil then
                for ck,cv in pairs(dayRewardInfoGainIds) do 
                    if v.id == cv then
                        hasGained = true
                        break
                    end
                end 
            end 
                
            if hasGained then

            else
                local curTime = TimeUtil.getServerTimeSeconds()
                local rewardTime = getCurRewardTime(v.date)
                if curTime - rewardTime < 0 then
                    --no arrival this day
           
                else
                    if curTime - rewardTime > 24*60*60 then
                        --miss this day reward
                            
                    elseif curTime - rewardTime <= 24*60*60 then
                        --can gain this day reward
                        hasRewardCanGain  = true
                        break
                    end
                end
                    

            end
                
        end
        return hasRewardCanGain
    else
        return false
    end
end 

function Activity_NewYear8DaysLayer.getTipNum()
  if not Activity_NewYear8DaysLayer.enable() then
    return 0
  end
  
  local sharkActivity = DataManager.getSharkActivity()
  local gainIds = sharkActivity.dayRewardInfo.gainedIds
  local hasRewardCanGain
  local curTime = TimeUtil.getServerTimeSeconds()
  for k,v in pairs(DataManager.GameMetaData.activityDayRewardConfig.dayRewards) do 
    local hasGained
    if gainIds ~= nil then
      for ck,cv in pairs(gainIds) do 
        if v.id == cv then
          hasGained = true
          break
        end
      end 
    end 
        
    if not hasGained then
      
      local rewardTime = getCurRewardTime(v.date)
      if curTime - rewardTime < 0 then
        --no arrival this day
      else
        if curTime - rewardTime > 24*60*60 then
          --miss this day reward
        elseif curTime - rewardTime <= 24*60*60 then
          --can gain this day reward
          hasRewardCanGain  = true
          break
        end
      end
    end  
  end
  if hasRewardCanGain then
    return 1
  else
    return 0
  end
end