--------------------------------------------------------------------------------
-- Activity_WorldBossLayer.lua --世界Boss
-- author: silian
--------------------------------------------------------------------------------
require "canon.request.ActivityWorldBossRequest"
require "canon.manager.MaintenanceManager"
require "canon.scene.WorldBossScene"
require "canon.panel.WorldBossAutoFightPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

Activity_WorldBossLayer = class(Layer)
function Activity_WorldBossLayer:ctor()
    self.container = nil
end

function Activity_WorldBossLayer:create( container )
    self.container = container
    local s = Activity_WorldBossLayer.new()
    s:initLayer()
    return s
end

function Activity_WorldBossLayer:panelDismiss()
    --self.eatPeachBtn:setEnabled(true)
    self.container.targetInfoPanel = nil
end

function Activity_WorldBossLayer:enable(curTimeStamp)
    local isEnable = MaintenanceManager.isActivityOpen(DataManager.GameMetaData.activityWorldBossConfig.featureName)
    return isEnable
end 


function Activity_WorldBossLayer.getWorldBossTime()
	--为了和线上兼容，原版晚上那次对应的字段名不变，新加活动点字段名为：xxx1
	--有可能玩家重登陆，配置更新，但前端代码还未动更
    local hour, minute, during = 0	--原版活动时间晚上
	local hour1, minute1, during1 = 0 -- 新加的一次活动时间中午
	local bossFinded,boss1Finded = false
    for k,v in pairs(MaintenanceManager.ActivityOnOffConfigData) do 
        if v.name == "worldBoss" then
            hour = tonumber(v.activityOpen:split(":")[1])
            minute = tonumber(v.activityOpen:split(":")[2])
            during = v.activityDuring
			boss1Finded = true
        elseif v.name == "worldBoss1" then
            hour1 = tonumber(v.activityOpen:split(":")[1])
            minute1 = tonumber(v.activityOpen:split(":")[2])
            during1 = v.activityDuring
			boss2Finded = true
        end
		if bossFinded and boss1Finded then
			break
		end
    end 
	local worldBossTime = TimeUtil.getTodayTimestampBy(hour, minute, 0)
	local prepareTime = worldBossTime - DataManager.GameMetaData.activityWorldBossConfig.prepareTime
	local finishTime = worldBossTime + (during*60)
	
	local worldBossTime1 = TimeUtil.getTodayTimestampBy(hour1, minute1, 0)
	local prepareTime1 = worldBossTime1 - DataManager.GameMetaData.activityWorldBossConfig.prepareTime
	local finishTime1 = worldBossTime1 + (during*60)
	
	local separationHour = DataManager.GameMetaData.activityWorldBossConfig.dantengTime
	local separationTime  = TimeUtil.getTodayTimestampBy(separationHour, 0, 0) --两次活动的分隔点，该时间点前玩家可以领取第一次活动的奖励，过此时间第一次活动奖励不可领
	local wordbossTimeInfo = {
		hour = hour,minute = minute,during = during,hour1 = hour1, minute1 = minute1, during1 = during1,worldBossTime = worldBossTime,prepareTime = prepareTime,finishTime = finishTime,worldBossTime1 = worldBossTime1,prepareTime1 = prepareTime1,finishTime1 = finishTime1,separationHour = separationHour,separationTime = separationTime
	}
	return wordbossTimeInfo
end

function Activity_WorldBossLayer.isWorldBossFightTime()
    local curTime = TimeUtil.getServerTimeSeconds()
	local wordbossTimeInfo = Activity_WorldBossLayer.getWorldBossTime()
	local worldbossMiddayOpen = MaintenanceManager.isActivityOpen(DataManager.GameMetaData.activityWorldBossConfig.featureName2)
	if (curTime >= wordbossTimeInfo.worldBossTime and curTime <= wordbossTimeInfo.finishTime) or (worldbossMiddayOpen and curTime >= wordbossTimeInfo.worldBossTime1 and curTime <= wordbossTimeInfo.finishTime1) then
		return true
	end
	
	return false
end




function Activity_WorldBossLayer:showAutoFight()
	self.bossUI:getChildByName("txt_lefttop"):setVisible(false)
	self.bossUI:getChildByName("txt_timetop"):setVisible(false)
	self.bossUI:getChildByName("txt_leftbottom"):setVisible(false)
	self.bossUI:getChildByName("txt_middle"):getChildByName("txt"):setString(getTextByKey("worldBoss_autoTxt"))
	self.bossUI:getChildByName("txt_timebottom"):setVisible(false)
	self.bossUI:getChildByName("btn_battle_start"):setVisible(false)
end

function Activity_WorldBossLayer:updateShowAutoFight()
	if WorldBossScene.worldBossInfo.worldBossUser.autoChallenge then
		self.bossUI:getChildByName("icon_checkbox"):setVisible(true)
	else
		self.bossUI:getChildByName("icon_checkbox"):setVisible(false)
	end
end

function Activity_WorldBossLayer:initLayer()
  world_boss_enter_status = true
  self.container:resetTipInfoForActivity("Activity_WorldBoss")
  
    Activity_WorldBossLayer.super.initLayer(self)
    
	local builder = LayoutBuilder:createWithContentsOfFile("scene/boss.json")
	builder.useArtLabelTTF = true
    self.bossUI = builder:build("boss")
	self:addChild(self.bossUI)
	
	local pos = self.bossUI:getChildByName("txt_middle"):getPosition()
	--self.bossUI:getChildByName("txt_middle"):setPosition(ccp (pos.x - 30, pos.y) )
	
	local bossPic = MetaManager.getWorldBossLevelMeta(WorldBossScene.worldBossInfo.worldBossMonster.level).cardPic
	bossPic = "pic/" .. bossPic .. ".png"
	local cardDisplay = Sprite:create(bossPic)
	self.bossUI:getChildByName("boss_temporary"):removeChildren(true)
	cardDisplay:setPosition(ccp(80, 0))
	self.bossUI:getChildByName("boss_temporary"):addChild(cardDisplay)
	
	self.bossUI:getChildByName("nicebg"):removeChildren(true)
	local spt = Sprite:create("pic/nicebg.png")
	spt:setScaleY(1.4)
	spt:setScaleX(1.9)
	spt:setPosition(ccp(360, -310))
	self.bossUI:getChildByName("nicebg"):addChild(spt)
	
	self.curTime = TimeUtil.getServerTimeSeconds()
	self.wordbossTimeInfo = Activity_WorldBossLayer.getWorldBossTime()
	self.worldbossMiddayOpen = MaintenanceManager.isActivityOpen(DataManager.GameMetaData.activityWorldBossConfig.featureName2)
	local battleTimeStr = ""..self.wordbossTimeInfo.hour..":"
	if self.wordbossTimeInfo.minute < 10 then
		battleTimeStr = battleTimeStr .. "0" .. self.wordbossTimeInfo.minute 
	else
		battleTimeStr = battleTimeStr .. self.wordbossTimeInfo.minute
	end
	local battleTimeStr1 = ""..self.wordbossTimeInfo.hour1..":"
	if self.wordbossTimeInfo.minute1 < 10 then
		battleTimeStr1 = battleTimeStr1 .. "0" .. self.wordbossTimeInfo.minute1 
	else
		battleTimeStr1 = battleTimeStr1 .. self.wordbossTimeInfo.minute1
	end
	
	local function updateUI()
		if WorldBossScene.worldBossInfo.worldBossMonster.gainAutoReward then --已经领取自动战斗奖励了
			self.showAutoBtn = false
			self:showAutoFight()
		elseif self.worldbossMiddayOpen and self.curTime < self.wordbossTimeInfo.prepareTime1 then --在中午活动之前
			--固定
			if not self.uiChange1 then
				self.uiChange1 = true
				self.bossUI:getChildByName("txt_lefttop"):setVisible(false)
				self.bossUI:getChildByName("txt_timetop"):setVisible(false)
				self.bossUI:getChildByName("txt_middle"):setVisible(true)
				self.bossUI:getChildByName("txt_leftbottom"):setVisible(true)
				self.bossUI:getChildByName("txt_timebottom"):setVisible(true)
				self.bossUI:getChildByName("btn_battle_start"):setVisible(false)
				self.bossUI:getChildByName("txt_middle"):getChildByName("txt"):setString(getTextByKey("worldBoss_activityTxt", {num1 = battleTimeStr1,num2 = battleTimeStr}))
				self.bossUI:getChildByName("txt_leftbottom"):getChildByName("txt"):setString(getTextByKey("worldBoss_activityCountdown"))
			end
			--变化
			local leftTimeString = TimeUtil.formatTime(self.wordbossTimeInfo.worldBossTime1 - self.curTime)
			self.bossUI:getChildByName("txt_timebottom"):getChildByName("txt"):setString(leftTimeString)
			
		elseif self.worldbossMiddayOpen and self.curTime >= self.wordbossTimeInfo.prepareTime1 and self.curTime < self.wordbossTimeInfo.worldBossTime1 then	--中午那次活动准备时间
			self.showAutoBtn = false
			if WorldBossScene.worldBossInfo.worldBossUser.autoChallenge then
				self:showAutoFight()
			else
				--固定
				if not self.uiChange2 then
					self.uiChange2 = true
					self.bossUI:getChildByName("txt_lefttop"):setVisible(true)
					self.bossUI:getChildByName("txt_timetop"):setVisible(true)
					self.bossUI:getChildByName("txt_middle"):setVisible(true)
					self.bossUI:getChildByName("txt_leftbottom"):setVisible(false)
					self.bossUI:getChildByName("txt_timebottom"):setVisible(false)
					self.bossUI:getChildByName("btn_battle_start"):setVisible(true)
					self.bossUI:getChildByName("btn_battle_start"):getChildByName("txt"):setString(getTextByKey("worldBoss_battleBtn"))
					self.bossUI:getChildByName("txt_lefttop"):getChildByName("txt"):setString(getTextByKey("worldBoss_activityCountdown"))
					local pos = self.bossUI:getChildByName("txt_middle"):getPosition()
				--	self.bossUI:getChildByName("txt_middle"):setPosition(ccp( pos.x - 50, pos.y) )
					self.bossUI:getChildByName("txt_middle"):getChildByName("txt"):setString(getTextByKey("worldBoss_activityPrepare"))
				end
				--变化
				local leftTimeString = TimeUtil.formatTime(self.wordbossTimeInfo.worldBossTime1 - self.curTime)
				self.bossUI:getChildByName("txt_timetop"):getChildByName("txt"):setString(leftTimeString)
			end
		elseif self.worldbossMiddayOpen and (self.curTime > self.wordbossTimeInfo.finishTime1 or self.bossKilled) and self.curTime < self.wordbossTimeInfo.separationTime then --中午那次活动结束或Boss 被杀至该次活动领奖结束之间
			--固定
			if not self.uiChange3 then
				self.uiChange3 = true
				self.bossUI:getChildByName("txt_lefttop"):setVisible(false)
				self.bossUI:getChildByName("txt_timetop"):setVisible(false)
				self.bossUI:getChildByName("txt_middle"):setVisible(true)
				self.bossUI:getChildByName("txt_leftbottom"):setVisible(true)
				self.bossUI:getChildByName("txt_timebottom"):setVisible(true)
				self.bossUI:getChildByName("btn_battle_start"):setVisible(true)
				local separationHourTimeStr = self.wordbossTimeInfo.separationHour..":00"
				self.bossUI:getChildByName("txt_middle"):getChildByName("txt"):setString(getTextByKey("worldBoss_end",{num1 = separationHourTimeStr}))
				self.bossUI:getChildByName("txt_leftbottom"):getChildByName("txt"):setString(getTextByKey("worldBoss_activityCountdown"))
				self.bossUI:getChildByName("btn_battle_start"):getChildByName("txt"):setString(getTextByKey("worldBoss_resultBtn"))
				if self.curTime < self.wordbossTimeInfo.finishTime1 then
					self.showAutoBtn = false
				end
			end
			--变化
			local leftTimeString = TimeUtil.formatTime(self.wordbossTimeInfo.worldBossTime - self.curTime)
			self.bossUI:getChildByName("txt_timebottom"):getChildByName("txt"):setString(leftTimeString)
			
		elseif (self.worldbossMiddayOpen and self.curTime >= self.wordbossTimeInfo.separationTime and self.curTime < self.wordbossTimeInfo.prepareTime) 
				--中午那次活动领奖结束至晚上活动准备之前
				or ((self.worldbossMiddayOpen == false or self.worldbossMiddayOpen == nil )and self.curTime < self.wordbossTimeInfo.prepareTime )
				--中午那次活动不开情况下，晚上那次活动的准备时间点前统一处理
				then 
			--固定
			if not self.uiChange4 then
				self.uiChange4 = true
				self.bossUI:getChildByName("txt_lefttop"):setVisible(false)
				self.bossUI:getChildByName("txt_timetop"):setVisible(false)
				self.bossUI:getChildByName("txt_middle"):setVisible(true)
				self.bossUI:getChildByName("txt_leftbottom"):setVisible(true)
				self.bossUI:getChildByName("txt_timebottom"):setVisible(true)
				self.bossUI:getChildByName("btn_battle_start"):setVisible(false)
				if self.worldbossMiddayOpen then
					self.bossUI:getChildByName("txt_middle"):getChildByName("txt"):setString(getTextByKey("worldBoss_activityTxt", {num1 = battleTimeStr1,num2 = battleTimeStr}))
				else
					self.bossUI:getChildByName("txt_middle"):getChildByName("txt"):setString(getTextByKey("worldBoss_time1", {num1 = battleTimeStr}))
				end
				
				self.bossUI:getChildByName("txt_leftbottom"):getChildByName("txt"):setString(getTextByKey("worldBoss_activityCountdown"))
			end
			--变化
			local leftTimeString = TimeUtil.formatTime(self.wordbossTimeInfo.worldBossTime - self.curTime)
			self.bossUI:getChildByName("txt_timebottom"):getChildByName("txt"):setString(leftTimeString)
		elseif self.curTime >= self.wordbossTimeInfo.prepareTime and self.curTime < self.wordbossTimeInfo.worldBossTime then --晚上活动准备时间
			self.showAutoBtn = false
			if WorldBossScene.worldBossInfo.worldBossUser.autoChallenge then
				self:showAutoFight()
			else
				--固定
				if not self.uiChange5 then
					self.uiChange5 = true
					self.bossUI:getChildByName("txt_lefttop"):setVisible(true)
					self.bossUI:getChildByName("txt_timetop"):setVisible(true)
					self.bossUI:getChildByName("txt_middle"):setVisible(true)
					self.bossUI:getChildByName("txt_leftbottom"):setVisible(false)
					self.bossUI:getChildByName("txt_timebottom"):setVisible(false)
					self.bossUI:getChildByName("btn_battle_start"):setVisible(true)
					self.bossUI:getChildByName("txt_lefttop"):getChildByName("txt"):setString(getTextByKey("worldBoss_activityCountdown"))
					local pos = self.bossUI:getChildByName("txt_middle"):getPosition()
			--		self.bossUI:getChildByName("txt_middle"):setPosition(ccp( pos.x - 50, pos.y) )
					self.bossUI:getChildByName("txt_middle"):getChildByName("txt"):setString(getTextByKey("worldBoss_activityPrepare"))
					self.bossUI:getChildByName("btn_battle_start"):getChildByName("txt"):setString(getTextByKey("worldBoss_battleBtn"))
				end
				--变化
				local leftTimeString = TimeUtil.formatTime(self.wordbossTimeInfo.worldBossTime - self.curTime)
				self.bossUI:getChildByName("txt_timetop"):getChildByName("txt"):setString(leftTimeString)
			end
		elseif self.curTime > self.wordbossTimeInfo.finishTime or self.bossKilled then --晚上活动结束或Boss 被杀
			self.bossUI:getChildByName("txt_lefttop"):setVisible(false)
			self.bossUI:getChildByName("txt_timetop"):setVisible(false)
			self.bossUI:getChildByName("txt_middle"):setVisible(true)
			self.bossUI:getChildByName("txt_leftbottom"):setVisible(false)
			self.bossUI:getChildByName("txt_timebottom"):setVisible(false)
			self.bossUI:getChildByName("btn_battle_start"):setVisible(true)
			self.bossUI:getChildByName("txt_middle"):getChildByName("txt"):setString(getTextByKey("worldBoss_end2"))
			self.bossUI:getChildByName("btn_battle_start"):getChildByName("txt"):setString(getTextByKey("worldBoss_resultBtn"))
			if self.curTime < self.wordbossTimeInfo.finishTime then
				self.showAutoBtn = false
			end
			if self.updateTimeFunc then
				CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.updateTimeFunc )
			end
		else --正是可以杀Boss的时候
			if WorldBossScene.worldBossInfo.worldBossUser.autoChallenge then
				 self:showAutoFight()
			else
				if not self.uiChange6 then
					self.uiChange6 = true
					self.bossUI:getChildByName("txt_lefttop"):setVisible(false)
					self.bossUI:getChildByName("txt_timetop"):setVisible(false)
					self.bossUI:getChildByName("txt_middle"):setVisible(true)
					self.bossUI:getChildByName("txt_leftbottom"):setVisible(false)
					self.bossUI:getChildByName("txt_timebottom"):setVisible(false)
					self.bossUI:getChildByName("btn_battle_start"):setVisible(true)
					local pos = self.bossUI:getChildByName("txt_middle"):getPosition()
			--		self.bossUI:getChildByName("txt_middle"):setPosition(ccp( pos.x - 50, pos.y) )
					self.bossUI:getChildByName("txt_middle"):getChildByName("txt"):setString(getTextByKey("worldBoss_activityBattle"))
					self.bossUI:getChildByName("btn_battle_start"):getChildByName("txt"):setString(getTextByKey("worldBoss_battleBtn"))
				end
			end
	 
			self.showAutoBtn = false
		end
		
	end
	local function updateTime()
		self.curTime = self.curTime + 1
		updateUI()
	end
	
	if WorldBossScene.worldBossInfo.worldBossMonster.leftHp <= 0 then
		self.bossKilled = true
	else
		self.bossKilled = false
	end
	
	self.showAutoBtn = true 
	updateUI()
	self.updateTimeFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc( updateTime, 1, false )
	
	--enter world boss
	local function onClickEnterWorldBoss(evt)
		local function onGetWorldBossInfo(response)
			WorldBossScene.worldBossInfo = response.data
			WorldBossScene.worldBossInfo.worldBossMonster.totalHp = tonumber(WorldBossScene.worldBossInfo.worldBossMonster.totalHp)
			WorldBossScene.worldBossInfo.worldBossMonster.leftHp = tonumber(WorldBossScene.worldBossInfo.worldBossMonster.leftHp)
			self.container:replaceScene(WorldBossScene)
		end
		
		local request = GetWorldBossInfoRequest.new(nil, rpc.SendingPriority.kHigh)
		request:addEventListener( RequestNotifyEnum.getWorldBossInfoSuccessd, onGetWorldBossInfo )
		request:start()
		self.bossUI:getChildByName("btn_battle_start"):setVisible(false)
    end
    self.enterWorldBossBtn = Button:create( self.bossUI:getChildByName("btn_battle_start"))
    self.enterWorldBossBtn:addEventListener( Events.kStart,onClickEnterWorldBoss ,self)


    local function onClickAutoFight(evt)
    	if not self.showAutoBtn then
			return
		end
		
    	local vipLevel = DataManager.getGameInitData().sharkUser.vipLevel
    	if not VipManager.isOwnPriv(vipLevel, 16) then
				local requireVipLevel = VipManager.getStartUpVipLevel(16)
				self.container.targetInfoPanel = VipWarningPanel:create( self.container, requireVipLevel)
		        PopoutManager:sharedManager():popout(self.container.targetInfoPanel, kPopoutDir.kScale, true, false , self.container)
				do return end
		end
		
		local nowGems = CalculationManager.calcComplex_getGemsNow()
		if nowGems < 200 then
			local function onReplaceScene()
                -- self.container:setTableViewsEnabled(true)
                -- self.container.targetInfoPanel = nil
                -- PopoutManager:sharedManager():pullin(self.container, kPopoutDir.kScale )
			end
			local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene})
			self.container:addChild(aPanel)
			aPanel:scaleIn()
			do return end
		end
		
		
		if WorldBossScene.worldBossInfo.worldBossUser.autoChallenge then
			local function onSetAutoWorldBoss(response)
				print( "SetAutoWorldBossRequest info" )
				if WorldBossScene.worldBossInfo.worldBossUser.autoChallenge then
					WorldBossScene.worldBossInfo.worldBossUser.autoChallenge = false
					--self.showAutoBtn = false
				end
				self:updateShowAutoFight()
			end
    		local params = { autoChallenge = false }
			local request = SetAutoWorldBossRequest.new(params, rpc.SendingPriority.kHigh)
			request:addEventListener( RequestNotifyEnum.setAutoWorldBossSuccessd, onSetAutoWorldBoss )
			request:start()
    	else
    		self.container.targetInfoPanel = WorldBossAutoFightPanel:create( self.container, self)
		    PopoutManager:sharedManager():popout(self.container.targetInfoPanel, kPopoutDir.kScale, true, false , self.container)
    	end
		
    end

    self:updateShowAutoFight()

    self.bossUI:getChildByName("txt_autobattle"):getChildByName("txt"):setString(getTextByKey("worldBoss_auto"))

    local btn = Button:create( self.bossUI:getChildByName("bg_checkbox"))
    btn:addEventListener( Events.kStart,onClickAutoFight ,self)

    btn = Button:create( self.bossUI:getChildByName("icon_checkbox"))
    btn:addEventListener( Events.kStart,onClickAutoFight ,self)
	
	btn = Button:create( self.bossUI:getChildByName("txt_autobattle"))
    btn:addEventListener( Events.kStart,onClickAutoFight ,self)
	
	if not self.showAutoBtn then
		self.bossUI:getChildByName("bg_checkbox"):setVisible(false)
		self.bossUI:getChildByName("icon_checkbox"):setVisible(false)
		self.bossUI:getChildByName("txt_autobattle"):setVisible(false)
	end
	 
end

function Activity_WorldBossLayer:confirmAutoFight()
	--if WorldBossScene.worldBossInfo.worldBossUser.autoChallenge then
	--	self.showAutoBtn = true
	--else
	--	self.showAutoBtn = false
	--end
	self:updateShowAutoFight()
end

function Activity_WorldBossLayer:startEnterAnimation_Run()
        
end 

function Activity_WorldBossLayer:startExitAnimation_Run()
end

function Activity_WorldBossLayer:dispose()
	if self.updateTimeFunc then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry( self.updateTimeFunc )
	end
end

world_boss_enter_status = false
function Activity_WorldBossLayer.getTipNum()
	if not Activity_WorldBossLayer.enable() then
		return 0
	end

	if world_boss_enter_status then
		return 0
	end

	local curTime = TimeUtil.getServerTimeSeconds()
	local wordbossTimeInfo = Activity_WorldBossLayer.getWorldBossTime()
	local worldbossMiddayOpen = MaintenanceManager.isActivityOpen(DataManager.GameMetaData.activityWorldBossConfig.featureName2)
	if (curTime >= wordbossTimeInfo.prepareTime and curTime <= wordbossTimeInfo.finishTime) or (worldbossMiddayOpen and curTime >= wordbossTimeInfo.prepareTime1 and curTime <= wordbossTimeInfo.finishTime1) then
		return 1
	else
		return 0
	end
  
end