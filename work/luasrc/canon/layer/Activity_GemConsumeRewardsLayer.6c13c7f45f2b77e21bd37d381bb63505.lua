
require "canon.request.ActivityGemConsumeRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

Activity_GemConsumeRewardsLayer = class(Layer)

function Activity_GemConsumeRewardsLayer:ctor()
    self.container = nil
    self.gemConsumeRewards = {}
end

function Activity_GemConsumeRewardsLayer:create( container )
    local s = Activity_GemConsumeRewardsLayer.new()
    self.container = container
    s:initLayer()
    return s
end

function Activity_GemConsumeRewardsLayer:setActivity_GemConsumeRewardsLayerVisible(isVisible)
	self:setVisible(isVisible)
end 

function Activity_GemConsumeRewardsLayer:enable(curTimeStamp)
    if not DataManager.GameMetaData.activityGemConsumeConfig then
        return false
    end
    local isEnable = MaintenanceManager.isActivityOpen("activityGemConsume")
    return isEnable
end 

function Activity_GemConsumeRewardsLayer:panelDismiss()
    self.container.targetInfoPanel = nil
end

function Activity_GemConsumeRewardsLayer:initLayer()
    Activity_GemConsumeRewardsLayer.super.initLayer(self)
    self.gemConsumeRewards = {}
    local refreshGemConsumeInfo
    local gemConsumeMeta = DataManager.GameMetaData.activityGemConsumeConfig.gemConsumeRewards
    --
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/cost_event.json")
    self.builder.useArtLabelTTF = true
	self.mainUI = self.builder:build("cost_event")
	self:addChild(self.mainUI)
    --init UI	
    self.mainUI:getChildByName("txt_cost_event1"):getChildByName("txt"):setString(getTextByKey("activity_consume_text"))
	self.mainUI:getChildByName("txt_cost_event3"):getChildByName("txt"):setString(getTextByKey("activity_consume_text1")..":")
	self.mainUI:getChildByName("txt_cost_event5"):getChildByName("txt"):setString(getTextByKey("activity_consume_text5"))
	self.mainUI:getChildByName("txt_cost_event7"):getChildByName("txt"):setString(getTextByKey("activity_consume_text6"))
	
	local beginAndEndTime = MaintenanceManager:getStartAndEndTime("activityGemConsume")
	self.mainUI:getChildByName("txt_cost_event2"):getChildByName("txt"):setString(
	    beginAndEndTime[1].year..getTextByKey("activity_consume_text7")..beginAndEndTime[1].month..getTextByKey("activity_consume_text8")..beginAndEndTime[1].day..getTextByKey("activity_consume_text9").."-"..
        beginAndEndTime[2].year..getTextByKey("activity_consume_text7")..beginAndEndTime[2].month..getTextByKey("activity_consume_text8")..beginAndEndTime[2].day..getTextByKey("activity_consume_text9"))
	self.mainUI:getChildByName("txt_cost_event4"):setVisible(false)
	
	local costGemLabel = self.mainUI:getChildByName("txt_cost_event6"):getChildByName("txt")
	costGemLabel:setVisible(false)
	local PARTICLE_TAG = 1234
	local function gainGemConsumeRewardBtnClick(evt)
	    if BagCalcManager.isFull() then
        --if true then
		    self.container.targetInfoPanel = NewPackageFullPanel:show()
            self.container:setHeadTableViewEnable(false)
		    return
		end 
        
        local function GainGemConsumeRewardSucc(response)
            local rewardList = response.data.rewards or {}
		    RewardManager:getReward(rewardList)
            
            refreshGemConsumeInfo(rewardList)
            
        end 
        local params = {rewardId = gemConsumeMeta[evt.context].id}
		local request = GainGemConsumeRewardsRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(RequestNotifyEnum.GainGemConsumeRewardsSucceed, GainGemConsumeRewardSucc)
		request:start()  
	end 
	
	local function gemConsumeRewardBoxBtnClick(evt)
	    local rewardList = MetaManager.getRewardInfoByID(gemConsumeMeta[evt.context].rewardPackageId) or {}
	    local aRewardPanel = RewardReviewPanel:create( self.container, {rewardList = rewardList, rewardTitle = Localization:getInstance():getText("activity_consume_gift")} )
        self.container:addChild(aRewardPanel)
        aRewardPanel:scaleIn()
	end
	
	local function addParticle(parentBtn)
	    local rewardParticle = CCParticleSystemQuad:create(ParticlePathConstants.FxStarline)
        rewardParticle:setPositionType(kCCPositionTypeRelative)
        rewardParticle:setPosition(ccp(0, 0))
        rewardParticle:setTag(PARTICLE_TAG)
        parentBtn:addChild(CocosObject.new(rewardParticle), 1000)
        local particleMoveArray = CCArray:create()
        local particleMoveTime = 0.4
        particleMoveArray:addObject(CCMoveBy:create(particleMoveTime*2, ccp(206, 0)))
        particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(0, -70)))
        particleMoveArray:addObject(CCMoveBy:create(particleMoveTime*2, ccp(-206, 0)))
        particleMoveArray:addObject(CCMoveBy:create(particleMoveTime, ccp(0, 70)))
        rewardParticle:runAction(CCRepeatForever:create(CCSequence:create(particleMoveArray)))
        return rewardParticle
	end 
	for i=1,6 do 
	    local gemConsumeItem = {}
	    local gemConsumeRewardBoxDisplay = self.mainUI:getChildByName("cost_event_item"..i)
	    local gemConsumeRewardBoxBtn = Button:create(gemConsumeRewardBoxDisplay)
        gemConsumeRewardBoxBtn:addEventListener(Events.kStart, gemConsumeRewardBoxBtnClick, i)
        
        local gainGemConsumeRewardDisplay = self.mainUI:getChildByName("btn_get_cost_reward"..i)
	    local gainGemConsumeRewardBtn = Button:create(gainGemConsumeRewardDisplay)
        gainGemConsumeRewardBtn:addEventListener(Events.kStart, gainGemConsumeRewardBtnClick, i)
        
        gainGemConsumeRewardDisplay:getChildByName("txt2"):setString(getTextByKey("activity_consume_reward2")..gemConsumeMeta[i].requireGold.." ")
        gainGemConsumeRewardDisplay:getChildByName("txt3"):setString(getTextByKey("activity_consume_get"))
        gainGemConsumeRewardDisplay:getChildByName("txt1"):setString(getTextByKey("activity_consume_reward"))
        
        local rewardParticle = addParticle(gainGemConsumeRewardDisplay)
        gemConsumeItem.gemConsumeRewardBoxDisplay = gemConsumeRewardBoxDisplay
        gemConsumeItem.gemConsumeRewardBoxBtn = gemConsumeRewardBoxBtn
        gemConsumeItem.gainGemConsumeRewardDisplay = gainGemConsumeRewardDisplay
        gemConsumeItem.gainGemConsumeRewardBtn = gainGemConsumeRewardBtn
        gemConsumeItem.rewardParticle = rewardParticle
        table.insert(self.gemConsumeRewards,gemConsumeItem)
        
        gainGemConsumeRewardDisplay:getChildByName("txt2"):setVisible(false)
        gainGemConsumeRewardDisplay:getChildByName("txt3"):setVisible(false)
        gainGemConsumeRewardDisplay:getChildByName("txt1"):setVisible(false)
        gainGemConsumeRewardDisplay:getChildByName("btn"):setVisible(false)
        gainGemConsumeRewardDisplay:getChildByName("icon_manycoin"):setVisible(false)
        rewardParticle:setVisible(false)
	end 
	refreshGemConsumeInfo = function (rewardList)
	    local function getGemConsumeInfoFinish(e)    
	        if rewardList then      
                local RewardPanel = GetRewardInfoPanel:create( self.container, rewardList)
                PopoutManager:sharedManager():popout( RewardPanel, kPopoutDir.kScale, true, false ,self.container )
	        end 
	        
	        local totalConsumeGems = e.data.consumeGems
	        costGemLabel:setString(totalConsumeGems)
	        costGemLabel:setVisible(true)
	        for i=1,6 do
	            self.gemConsumeRewards[i].gainGemConsumeRewardDisplay:getChildByName("txt1"):setVisible(false)
	            self.gemConsumeRewards[i].gainGemConsumeRewardDisplay:getChildByName("txt2"):setVisible(true)
	            self.gemConsumeRewards[i].gainGemConsumeRewardDisplay:getChildByName("txt3"):setVisible(false)
	            self.gemConsumeRewards[i].gainGemConsumeRewardDisplay:getChildByName("btn"):setVisible(false)
	            self.gemConsumeRewards[i].gainGemConsumeRewardDisplay:getChildByName("icon_manycoin"):setVisible(true)
	            self.gemConsumeRewards[i].gainGemConsumeRewardBtn:setEnable(false)
	            self.gemConsumeRewards[i].rewardParticle:setVisible(false)
	            local hasGained = false
	            for k,v in pairs(e.data.gainedRewards) do 
	                if v == gemConsumeMeta[i].id then
	                    hasGained = true
	                    self.gemConsumeRewards[i].gainGemConsumeRewardDisplay:getChildByName("txt2"):setVisible(false)
	                    self.gemConsumeRewards[i].gainGemConsumeRewardDisplay:getChildByName("txt3"):setVisible(true)
	                    self.gemConsumeRewards[i].gainGemConsumeRewardDisplay:getChildByName("icon_manycoin"):setVisible(false)
	                    break
	                end 
	            end 
	            
	            if not hasGained then
	                if totalConsumeGems  >= gemConsumeMeta[i].requireGold then
	                    self.gemConsumeRewards[i].gainGemConsumeRewardDisplay:getChildByName("txt1"):setVisible(true)
	                    self.gemConsumeRewards[i].gainGemConsumeRewardDisplay:getChildByName("txt2"):setVisible(false)
	                    self.gemConsumeRewards[i].gainGemConsumeRewardBtn:setEnable(true)
	                    self.gemConsumeRewards[i].gainGemConsumeRewardDisplay:getChildByName("btn"):setVisible(true)
	                    self.gemConsumeRewards[i].rewardParticle:setVisible(true)
	                end 
	            end
	        end 
          local homeInfo = ActivityPanelScene.getStatusInfo()
          homeInfo.gainedGemConsumeRewards = e.data.gainedRewards
          ActivityPanelScene.setStatusInfo(homeInfo)
          self.container:resetTipInfoForActivity("Activity_GemConsume")
        end 
        --send get gem consume info request
        local request = GetGemConsumeInfoRequest.new( params, rpc.SendingPriority.kHigh )
        request:addEventListener( RequestNotifyEnum.GetGemConsumeInfoSucceed, getGemConsumeInfoFinish )
        request:start()
	end
	
	local scheduler = nil
    local function refreshGemConsumeInfoFunc()
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(scheduler)
        refreshGemConsumeInfo()
        self.container:setTouchEnabled(true)
		self.container:setHeadTableViewEnable(true)
    end 
    self.container:setTouchEnabled(false)
	self.container:setHeadTableViewEnable(false)
    scheduler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(refreshGemConsumeInfoFunc,0.1,false)
    
    local function refreshLeftTimeFunc()
        local curTime = TimeUtil.getServerTimeSeconds()
        local leftTime = beginAndEndTime[2].activityEndTimeStamp - curTime
        if leftTime < 0 then
            leftTime = 0
        end 
        local leftDay = math.floor(leftTime / (24* 60 *60))
        leftTime = leftTime % (24* 60 *60)
        local leftHour = math.floor(leftTime / (60 * 60))
        leftTime = leftTime % (60 * 60)
        local leftMin = math.floor(leftTime  / 60)
        local leftSec = leftTime % 60
        if leftDay == 0 and leftHour == 0 and leftMin == 0 then
             for i=1,6 do
                self.gemConsumeRewards[i].gainGemConsumeRewardDisplay:getChildByName("btn"):setVisible(false)
                self.gemConsumeRewards[i].gainGemConsumeRewardBtn:setEnable(false)
                if self.gemConsumeRewards[i].rewardParticle:isVisible() then
                    self.gemConsumeRewards[i].rewardParticle:setVisible(false)
                    self.gemConsumeRewards[i].gainGemConsumeRewardDisplay:getChildByName("icon_manycoin"):setVisible(false)
                end 
             end 
        end 
        self.mainUI:getChildByName("txt_cost_event4"):getChildByName("txt"):setString(" "..leftDay..getTextByKey("activity_consume_text2")..leftHour..getTextByKey("activity_consume_text3")..leftMin..getTextByKey("activity_consume_text4"))
        self.mainUI:getChildByName("txt_cost_event4"):setVisible(true)
    end 
    self.leftTimeRefreshEntry =  CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(refreshLeftTimeFunc,1,false)
end

function Activity_GemConsumeRewardsLayer:dispose()
  if self.leftTimeRefreshEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.leftTimeRefreshEntry)
    self.leftTimeRefreshEntry = nil
  end
  Activity_GemConsumeRewardsLayer.super.dispose(self)
end

function Activity_GemConsumeRewardsLayer:startEnterAnimation_Run()
        
end 

function Activity_GemConsumeRewardsLayer:startExitAnimation_Run()
end

function Activity_GemConsumeRewardsLayer_JudgeRewardState(rewrdInfo)
    if not DataManager.GameMetaData.activityGemConsumeConfig or not rewrdInfo or not rewrdInfo.data then
        return 0
    end
    local canGainRewardNum = 0
    local totalConsumeGems = rewrdInfo.data.consumeGems

    local gemConsumeMeta = DataManager.GameMetaData.activityGemConsumeConfig.gemConsumeRewards
    for i=1,#gemConsumeMeta do
        local hasGained = false
	    for k,v in pairs(rewrdInfo.data.gainedGemConsumeRewards) do 
	        if v == gemConsumeMeta[i].id then
	            hasGained = true
                break
	        end 
	    end 
	            
	    if not hasGained then
	        if totalConsumeGems  >= gemConsumeMeta[i].requireGold then
	            canGainRewardNum = canGainRewardNum + 1
	        end 
	            
	    end 
            
    end 
    return canGainRewardNum
end

function Activity_GemConsumeRewardsLayer.getTipNum()
  if not Activity_GemConsumeRewardsLayer.enable() then
    return 0
  end
  
  local homeInfo = ActivityPanelScene.getStatusInfo()
  if not homeInfo.gainedGemConsumeRewards then
    return 0
  end
  
  local canGainRewardNum = 0
  local totalConsumeGems = homeInfo.consumeGems
  local gemConsumeMeta = DataManager.GameMetaData.activityGemConsumeConfig.gemConsumeRewards
  for i=1,#gemConsumeMeta do
    local hasGained = false
    for k,v in pairs(homeInfo.gainedGemConsumeRewards) do 
      if v == gemConsumeMeta[i].id then
        hasGained = true
        break
      end 
    end 
            
    if not hasGained then
      if totalConsumeGems  >= gemConsumeMeta[i].requireGold then
        canGainRewardNum = canGainRewardNum + 1
      end  
    end 
  end 
  return canGainRewardNum
end