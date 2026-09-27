--------------------------------------------------------------------------------
-- New_UserContinueLoginShowPanel.lua --新连登7天奖励面板
-- author: dang chao
-- updated: 2015-01-07
--------------------------------------------------------------------------------
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

New_UserContinueLoginShowPanel = class(Layer)

--verison  = 1 
function New_UserContinueLoginShowPanel:ctor()
    self.container = nil
end

function New_UserContinueLoginShowPanel:enable()
	if isInAppleReview() then
		return false
	else
		local isEnable = true 
		
		local GameData = DataManager.getGameInitData()
		if GameData.sharkUserExtendMore and 
		   GameData.sharkUserExtendMore.continuousLoginRewardInfoV2 and 
		   GameData.sharkUserExtendMore.continuousLoginRewardInfoV2.gainRewardDays 
		then
			if table.getn(GameData.sharkUserExtendMore.continuousLoginRewardInfoV2.gainedContinuousLoginRewards) < 7 then
				
			else
				isEnable = false
			end 
		end
		
		
		return isEnable
	end
end

function New_UserContinueLoginShowPanel:create( container ,remainDays,todayFrom1970,closeCallBackFunc)
    self.container = container
	self.remainDays = remainDays
	self.todayFrom1970 = todayFrom1970
    self.closeCallBackFunc = closeCallBackFunc
    local GameData = DataManager.getGameInitData()
    if GameData.sharkUserExtend and GameData.sharkUserExtend.continuousLoginRewardInfoV2 then
        
       
        
    end 
	--self.starRewardInfo = MetaManager.consecutive_login_reward
    local s = New_UserContinueLoginShowPanel.new()
    s:initLayer()
	 
    return s
end
--------------------------------
--close get reward panel
--------------------------------
function New_UserContinueLoginShowPanel:panelDismiss()
	
end 
 
function New_UserContinueLoginShowPanel:initLayer()
    
	
    New_UserContinueLoginShowPanel.super.initLayer(self)
    
    local function onGainReward(evt)
		local function getContineLoginRewardSucceed(data)
			local GameData = DataManager.getGameInitData()
			if GameData.sharkUserExtendMore and GameData.sharkUserExtendMore.continuousLoginRewardInfoV2 then
				table.insert(GameData.sharkUserExtendMore.continuousLoginRewardInfoV2.gainedContinuousLoginRewards,7 - self.remainDays)
				GameData.sharkUserExtendMore.continuousLoginRewardInfoV2.gainRewardDays = self.todayFrom1970
			else
				--first see star
				if GameData.sharkUserExtendMore then
					GameData.sharkUserExtendMore["continuousLoginRewardInfoV2"] = { gainRewardDays = self.todayFrom1970,
																		gainedContinuousLoginRewards = {7 - self.remainDays}}
				else
					GameData["sharkUserExtendMore"] = {}
					GameData.sharkUserExtendMore["continuousLoginRewardInfoV2"] = { gainRewardDays = self.todayFrom1970,
																		gainedContinuousLoginRewards = {7 - self.remainDays}}
				end 
			end
			DataManager.setGameInitData(GameData)
					
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
			--self.container:setTableViewsEnabled(true)
			self.container.targetInfoPanel = nil
			if self.closeCallBackFunc and type(self.closeCallBackFunc) == "function" then
				self.closeCallBackFunc("ContinueLoginGotoActivityPanel")
			end
		end
		
		local function getContineLoginRewardFailed(err)
			if err.data.retCode == 714144 then
				--has gotten reward already
			end	
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
			--self.container:setTableViewsEnabled(true)
			self.container.targetInfoPanel = nil
			if self.closeCallBackFunc and type(self.closeCallBackFunc) == "function" then
				self.closeCallBackFunc()
			end
		end 
		local params = {}
		local request = GainContinueLoginRewardRequestV2.new( params, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.GainContinueLoginRewardV2Succeed, getContineLoginRewardSucceed )
		request:addEventListener( RequestNotifyEnum.GainContinueLoginRewardV2Failed, getContineLoginRewardFailed )
		request:start()
    end 
    
    --init UI	
	self.builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity_02.json")
    self.builder.useArtLabelTTF = true
    self.mainUI = self.builder:build("popup_7day")
    self:addChild(self.mainUI)
	
	local card = self.mainUI:getChildByName("common_normal_card_small_sb")
	card:setVisible(false)
	self.bigRewardCard = Sprite:create("pic/bg_7day.png")
	self.bigRewardCard:setPosition(ccp(card:getPositionX(),card:getPositionY()))
	self.mainUI:addChild(self.bigRewardCard)
	
	self.mainUI:getChildByName("btn"):getChildByName("txt"):setString(getTextByKey("consecutiveLogin_info"))
	
	--剩余天数得大奖
	local remainDayNums = 7
	if self.remainDays ~= nil  then
		remainDayNums = self.remainDays
	end
	if remainDayNums == 0 then
		self.mainUI:getChildByName("txt_4"):getChildByName("txt"):setString(getTextByKey("consecutiveLogin_describe3"))
		self.mainUI:getChildByName("txt_1"):setVisible(false)
		self.mainUI:getChildByName("txt_2"):setVisible(false)
		self.mainUI:getChildByName("txt_3"):setVisible(false)
	else
		self.mainUI:getChildByName("txt_4"):setVisible(false)
		self.mainUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("consecutiveLogin_describe1"))
		self.mainUI:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("consecutiveLogin_describe2"))
		self.mainUI:getChildByName("txt_2"):getChildByName("txt"):setString(remainDayNums)
	end
	
	local gainReward_Btn = Button:create(self.mainUI:getChildByName("btn"))
    gainReward_Btn:addEventListener(Events.kStart ,onGainReward )  
end
