require "canon.request.GainPraiseRewardRequest"
require "canon.request.GetRecordPraiseIdRequest"
require "canon.luajava.CanonEnvInjector"
require "canon.customUI.CanonGoodIcon"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

Activity_PraiseLayer = class(Layer)

function Activity_PraiseLayer:ctor()
  self.container = nil
end

function Activity_PraiseLayer:create( container )
  self.container = container
  local s = Activity_PraiseLayer.new()
  s:initLayer()
  return s
end

function Activity_PraiseLayer:enable(curTimeStamp)
    if not DataManager.GameMetaData.activityPraiseConfig then
      return false
    end
    local isEnable = MaintenanceManager.isActivityOpen(DataManager.GameMetaData.activityPraiseConfig.featureName)
    return isEnable
    --local isEnable = MaintenanceManager.isActivityOpen("cowStage")
    --return isEnable
    -- return true
end 

function Activity_PraiseLayer:panelDismiss()
    self.container.targetInfoPanel = nil
end

function Activity_PraiseLayer:dispose()
  Activity_PraiseLayer.super.dispose(self)
end

function Activity_PraiseLayer:initLayer()
    Activity_PraiseLayer.super.initLayer(self)

    self.builder = LayoutBuilder:createWithContentsOfFile("scene/dianzan.json")
    self.builder.useArtLabelTTF = true
	self.mainUI = self.builder:build("bg_good")
	self:addChild(self.mainUI)

	local activity = DataManager.getSharkActivity()
	if not activity.recordPraiseIds then
		activity.recordPraiseIds = {}
	end
	local recordPraiseIds = activity.recordPraiseIds

	local activity = DataManager.getSharkActivity()
	if not activity.gainedPraiseRewardIds then
		activity.gainedPraiseRewardIds = {}
	end
	local gainedPraiseRewardIds = activity.gainedPraiseRewardIds
	
	-- local GameData = DataManager.getGameInitData()
	-- local recordPraiseIds = GameData.sharkActivity.recordPraiseIds or {}
	-- local gainedPraiseRewardIds = GameData.sharkActivity.gainedPraiseRewardIds or {}

	local isRecordPraiseIdsArray = {false,false,false}
	for k,v in pairs(recordPraiseIds) do
		isRecordPraiseIdsArray[v] = true
	end
	local isGainedPraiseRewardIdsArray = {false , false , false}
	for k,v in pairs(gainedPraiseRewardIds) do
		isGainedPraiseRewardIdsArray[v] = true
	end
	local urls = {}
	if isPubgameTW() then
		urls = {
	[1] = "https://www.facebook.com/ValkyrieofSango",
	[2] = "https://www.facebook.com/groups/1556881017880284/",
	[3] = "http://goo.gl/HqHVIS"
}
	else
		urls = {
	[1] = "https://www.facebook.com/senki",
	[2] = "https://www.facebook.com/groups/652040481516004/",
	[3] = "https://www.facebook.com/photo.php?fbid=3987261976159&set=gm.652464438140275"
}
	end
	

	local rewardIds = DataManager.GameMetaData.activityPraiseConfig.praiseRewardItems

	self.praiseButtonList = {}
	self.rewardButtonList = {}
	local function onClickPraise( evt )
		-- body
		local function requestPraiseSucceed(data , response )
			-- body
			local activity = DataManager.getSharkActivity()
			if not activity.recordPraiseIds then
				activity.recordPraiseIds = {}
			end

			table.insert(activity.recordPraiseIds , data)
			DataManager.setSharkActivity(activity)

			local list_good = self.mainUI:getChildByName("list_good"..data)
			self.praiseButtonList[data]:setEnable(true)
			self.praiseButtonList[data]:setVisible(true)
			list_good:getChildByName("btn_exchange").touchEnabled = true

			self.rewardButtonList[data]:setEnable(true)
			self.rewardButtonList[data]:setVisible(true)
			list_good:getChildByName("btn_guildoption").touchEnabled = true
		end
		local function requestPraiseFailed( response )
			-- body
		end
		-- local params = {praiseId = evt.context}
  --       local request = GetRecordPraiseIdRequest.new( params, rpc.SendingPriority.kHigh )
		-- request:addEventListener( RequestNotifyEnum.GetRecordPraiseIdSucceed, requestPraiseSucceed )
	 --    request:addEventListener( RequestNotifyEnum.GetRecordPraiseIdFailed, requestPraiseFailed )
	 --    request:start()
	 	local clickContext = evt.context

	 	local activity = DataManager.getSharkActivity()
	 	local havePrasised = false
		if activity.recordPraiseIds then
			for k,v in pairs(activity.recordPraiseIds) do
				if v == clickContext then
					havePrasised = true
				end
			end
		end
		if not havePrasised then
			GetRecordPraiseIdRequest.sendRequest(clickContext , requestPraiseSucceed , requestPraiseFailed)
		end
	    
	    if __IOS then
	    	local url = NSURL:URLWithString(urls[evt.context])
        	UIApplication:sharedApplication():openURL(url)
	    end

	    if __ANDROID then
            CanonEnvInjector:openURL(urls[evt.context])
        end

	end

	local function onClickReward( evt )

		if BagCalcManager.isFull() then
	        local aContent = Localization:getInstance():getText("rewardPopup_inventoryFullTxt")
	        -- SuspensionLabel:showContent(self.container, aContent)
	        NewPackageFullPanel:show()
	        return
	      end

		local function requestRewardSucceed(data , response )
			local list_good = self.mainUI:getChildByName("list_good"..data)
			list_good:getChildByName("btn_guildoption"):setVisible(false)
			list_good:getChildByName("btn_guildoption_inactive"):getChildByName("txt"):setString(getTextByKey("battleWin_gotReward"))

			local activity = DataManager.getSharkActivity()
			if not activity.gainedPraiseRewardIds then
				activity.gainedPraiseRewardIds = {}
			end

			table.insert(activity.gainedPraiseRewardIds , data)
			DataManager.setSharkActivity(activity)

			local function onGet(  )
	          -- body
	          RewardManager:getReward(response.data.rewards)
	        end
	        
	        local aRewardPanel = RewardReviewPanel:create( self.container, {rewardList = response.data.rewards, rewardTitle = Localization:getInstance():getText("activity_newyear_rewardTitle"), callback = onGet} )
	        self.container:addChild(aRewardPanel)
	        aRewardPanel:scaleIn()

	        self.container:resetTipInfoForActivity("Activity_Praise")
		end
		local function requestRewardFailed( response )
			
		end
		-- local params = {praiseId = evt.context}
  --       local request = GainPraiseRewardRequest.new( params, rpc.SendingPriority.kHigh )
		-- request:addEventListener( RequestNotifyEnum.GainPraiseRewardSucceed, requestRewardSucceed )
	 --    request:addEventListener( RequestNotifyEnum.GainPraiseRewardFailed, requestRewardFailed )
	 --    request:start()
	 	local clickContext = evt.context
		GainPraiseRewardRequest.sendRequest(clickContext , requestRewardSucceed , requestRewardFailed)
	end

	-- local packageRewardList = MetaManager.getRewardInfoByID(rewardPackageId)

	self.mainUI:getChildByName("txt_instructions1"):getChildByName("txt"):setString(getTextByKey("join_activity_Dec1"))
	self.mainUI:getChildByName("txt_instructions2"):getChildByName("txt"):setString(getTextByKey("join_activity_Dec2"))

	for i=1,3 do
		-- self.mainUI:getChildByName("list_good"..i):getChildByName(btn_guildoption)
		local list_good  = self.mainUI:getChildByName("list_good"..i)
		self.praiseButtonList[i] = Button:create(list_good:getChildByName("btn_exchange"))
		self.praiseButtonList[i]:addEventListener(Events.kStart,onClickPraise,i)
	    self.mainUI:addChild(self.praiseButtonList[i])

	    self.rewardButtonList[i] = Button:create(list_good:getChildByName("btn_guildoption"))
	    self.rewardButtonList[i]:addEventListener(Events.kStart,onClickReward,i)
	    self.mainUI:addChild(self.rewardButtonList[i])

	    local packageRewardList = MetaManager.getRewardInfoByID(rewardIds[i].rewardPackId)
	    local rewardDetails = ""
	    for i=1,#packageRewardList do
	    	local str = CanonGoodIcon.getGoodNameByPackageRewardInfo(packageRewardList[i])
	    	rewardDetails = rewardDetails .. tostring(str) .. " "
	    	print(str)
	    end
	    list_good:getChildByName("btn_guildoption"):getChildByName("txt"):setString(getTextByKey("reward_claimBtn"))
	    list_good:getChildByName("btn_guildoption_inactive"):getChildByName("txt"):setString(getTextByKey("reward_claimBtn"))
	    list_good:getChildByName("btn_exchange"):getChildByName("txt"):setString(getTextByKey("join_fb_DecBtn"..i))
	    list_good:getChildByName("txt_announcement_title"):getChildByName("txt"):setString(getTextByKey("join_fb_Dec"..i))
	    list_good:getChildByName("txt_dianzan1"):getChildByName("txt"):setString(rewardDetails)
	    if i == 3 then
	    	list_good:getChildByName("icon_facebook"):setDisplayFrame(createSpriteFrame("Item/Picture/icon_line.png"))
	    end

	    if isRecordPraiseIdsArray[i] then
	    	self.praiseButtonList[i]:setEnable(true)
	    	self.praiseButtonList[i]:setVisible(true)
	    	list_good:getChildByName("btn_exchange").touchEnabled = true
	    else
	    	self.rewardButtonList[i]:setEnable(false)
	    	self.rewardButtonList[i]:setVisible(false)
	    	list_good:getChildByName("btn_guildoption").touchEnabled = false
	    end

	    if isGainedPraiseRewardIdsArray[i] then
	    	list_good:getChildByName("btn_guildoption"):setVisible(false)
	    	list_good:getChildByName("btn_guildoption_inactive"):getChildByName("txt"):setString(getTextByKey("battleWin_gotReward"))
	    	-- list_good:getChildByName("btn_guildoption"):getChildByName("btn_inactive"):setVisible(true)
	    end
	end
end

function Activity_PraiseLayer.getTipNum()
  if not Activity_PraiseLayer.enable() then
    return 0
  end

  local GameData = DataManager.getGameInitData()
  if GameData.sharkActivity == nil or GameData.sharkActivity.gainedPraiseRewardIds == nil then
  	return 3
  end

  local gainedPraiseRewardIds = GameData.sharkActivity.gainedPraiseRewardIds

  return 3 - #gainedPraiseRewardIds
end