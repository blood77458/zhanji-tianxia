
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

Activity_FacebookShareLayer = class(Layer)


function Activity_FacebookShareLayer:ctor()
  self.container = nil
end

function Activity_FacebookShareLayer:create( container )
  self.container = container
  local s = Activity_FacebookShareLayer.new()
  s:initLayer()
  return s
end

function Activity_FacebookShareLayer:enable(curTimeStamp)
	if not FacebookShareManager.isOpenFacebookShareFunc() then
		return false
	end
    if not DataManager.GameMetaData.fbShareConfig then
		return false
    end
    local isEnable = MaintenanceManager.isActivityOpen(DataManager.GameMetaData.fbShareConfig.featureName)
    return isEnable
end 

function Activity_FacebookShareLayer:panelDismiss()
    self.container.targetInfoPanel = nil
end

function Activity_FacebookShareLayer:dispose()
  Activity_FacebookShareLayer.super.dispose(self)
end

function Activity_FacebookShareLayer:updateUI()
	local gameData = DataManager.getGameInitData()
	
	if gameData.sharkFbShare then
	else
		gameData["sharkFbShare"] = {}
		gameData.sharkFbShare["sharkFbShareActivity"] = { 
															fbShare	= false,
															inviteFbFriendList = {},
															gainedReward = false,
														}
	end
	DataManager.setGameInitData(gameData)
	local facebookShareActivityInfo = gameData.sharkFbShare.sharkFbShareActivity
	--bind state
	if isBindFacebook() then
		self.bindList:getChildByName("lbl_complete02"):setVisible(true)
		self.bindList:getChildByName("lbl_to_do"):setVisible(false)
		self.bindBtn:setEnable(false)
		self.bindList:getChildByName("btn"):getChildByName("normal"):setVisible(false)
	else
		self.bindList:getChildByName("lbl_complete02"):setVisible(false)
		self.bindList:getChildByName("lbl_to_do"):setVisible(false)--self.bindList:getChildByName("lbl_to_do"):setVisible(true)
		self.bindBtn:setEnable(true)
		self.bindList:getChildByName("btn"):getChildByName("normal"):setVisible(true)
	end
	--share state
	if facebookShareActivityInfo.fbShare then
		self.shareList:getChildByName("txt_01"):getChildByName("txt"):setString(getTextByKey("FBactivity_sharetxt" , {num1 = 1, num2 = 1}))
		self.shareList:getChildByName("lbl_complete02"):setVisible(true)
		self.shareList:getChildByName("lbl_to_do"):setVisible(false)
		self.shareBtn:setEnable(false)
		self.shareList:getChildByName("btn"):getChildByName("normal"):setVisible(false)
	else
		self.shareList:getChildByName("txt_01"):getChildByName("txt"):setString(getTextByKey("FBactivity_sharetxt" , {num1 = 0, num2 = 1}))
		self.shareList:getChildByName("lbl_complete02"):setVisible(false)
		self.shareList:getChildByName("lbl_to_do"):setVisible(false)--self.shareList:getChildByName("lbl_to_do"):setVisible(true)
		self.shareBtn:setEnable(true)
		self.shareList:getChildByName("btn"):getChildByName("normal"):setVisible(true)
	end
	--invite state
	local inviteFriendNum = table.getn(facebookShareActivityInfo.inviteFbFriendList)
	
	if self.requestInviteFriendNum <= inviteFriendNum then
		self.inviteList:getChildByName("lbl_complete02"):setVisible(true)
		self.inviteList:getChildByName("lbl_to_do"):setVisible(false)
		self.inviteBtn:setEnable(false)
		self.inviteList:getChildByName("btn"):getChildByName("normal"):setVisible(false)
		--需求修改 显示邀请数 不超过 配置值
		inviteFriendNum = self.requestInviteFriendNum
	else
		self.inviteList:getChildByName("lbl_complete02"):setVisible(false)
		self.inviteList:getChildByName("lbl_to_do"):setVisible(false)--self.inviteList:getChildByName("lbl_to_do"):setVisible(true)
		self.inviteBtn:setEnable(true)
		self.inviteList:getChildByName("btn"):getChildByName("normal"):setVisible(true)
	end
	
	self.inviteList:getChildByName("txt_01"):getChildByName("txt"):setString(getTextByKey("FBactivity_invitetxt" , {num1 = inviteFriendNum, num2 = self.requestInviteFriendNum}))
	
	--recieve state
	if facebookShareActivityInfo.gainedReward then
		--已经领取奖励
		self.gainRewardBtn:setEnable(false)
		self.mainUI:getChildByName("btn_receeive"):getChildByName("btn"):setVisible(false)
	else
		if isBindFacebook() and facebookShareActivityInfo.fbShare and self.requestInviteFriendNum <= inviteFriendNum then
			--已满足领奖条件
			self.gainRewardBtn:setEnable(true)
			self.mainUI:getChildByName("btn_receeive"):getChildByName("btn"):setVisible(true)
		else
			--不满足领奖条件
			self.gainRewardBtn:setEnable(false)
			self.mainUI:getChildByName("btn_receeive"):getChildByName("btn"):setVisible(false)
		end
	end
end

function Activity_FacebookShareLayer:initLayer()
    Activity_FacebookShareLayer.super.initLayer(self)

    self.builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity.json")
    self.builder.useArtLabelTTF = true
	self.mainUI = self.builder:build("FB_share")
	self:addChild(self.mainUI)
	
	--获得活动时间
	local timeTable = MaintenanceManager:getStartAndEndTime(DataManager.GameMetaData.fbShareConfig.featureName)

	--固定文字
	self.mainUI:getChildByName("txt_LA11_06"):getChildByName("txt"):setString(getTextByKey("cardExchange_duration"))--本期活动时间:
	self.mainUI:getChildByName("txt_LA11_07"):getChildByName("txt"):setString(getTextByKey("cardExchange_time", {month1 = timeTable[1].month , day1 = timeTable[1].day , month2 = timeTable[2].month, day2 = timeTable[2].day}))--{month1}月{day1}日—{month2}月{day2}日
	
	--data
	self.requestInviteFriendNum = DataManager.GameMetaData.fbShareConfig.requestNum
	self.finialRewardId = DataManager.GameMetaData.fbShareConfig.finalReward
	--list--
	self.bindList = self.mainUI:getChildByName("list_01")
	self.shareList = self.mainUI:getChildByName("list_02")
	self.inviteList = self.mainUI:getChildByName("list_03")
	for i = 1,3 do
		self.mainUI:getChildByName("list_0"..i):getChildByName("lbl_complete02"):setVisible(false)
		self.mainUI:getChildByName("list_0"..i):getChildByName("lbl_to_do"):setVisible(false)
	end
	--图标显示
	self.bindList:getChildByName("icon_prop_invitation"):setVisible(false)
	self.bindList:getChildByName("icon_prop_share"):setVisible(false)
	self.shareList:getChildByName("icon_prop_invitation"):setVisible(false)
	self.shareList:getChildByName("icon_prop_binding"):setVisible(false)
	self.inviteList:getChildByName("icon_prop_binding"):setVisible(false)
	self.inviteList:getChildByName("icon_prop_share"):setVisible(false)
	--文本显示
	self.bindList:getChildByName("txt_01"):getChildByName("txt"):setString(getTextByKey("FBactivity_bindtxt"))
	--按钮文字
	self.bindList:getChildByName("btn"):getChildByName("txt"):setString(getTextByKey("FBactivity_bind"))
	self.shareList:getChildByName("btn"):getChildByName("txt"):setString(getTextByKey("FBactivity_share"))
	self.inviteList:getChildByName("btn"):getChildByName("txt"):setString(getTextByKey("FBactivity_invite"))
	
	--领奖按钮
	self.mainUI:getChildByName("btn_receeive"):getChildByName("txt"):setString(getTextByKey("FBactivity_exchange"))
	
	--领奖预览
	local finalRewardId = DataManager.GameMetaData.fbShareConfig.finalReward
	local finalRewardConfig = MetaManager.getRewardInfoByID(finalRewardId) or {}
	local rewardItem = self.mainUI:getChildByName("Prop_fbjinbi0")
	rewardItem:setVisible(false)
	if #finalRewardConfig > 0 then
		local itemName = CanonGoodIcon.getGoodNameByPackageRewardInfo(finalRewardConfig[1])
		self.mainUI:getChildByName("txt_01"):getChildByName("txt"):setString(itemName)
		
		local params = {}
		params.sourceSizes = {135, 135}
		local itemIcon = CanonGoodIcon.createGoodIcon(finalRewardConfig[1].itemType, finalRewardConfig[1].metaId, 0, params)
		
		itemIcon:setPosition(ccp(rewardItem:getPositionX()+rewardItem:getContentSize().width/2, rewardItem:getPositionY()-rewardItem:getContentSize().height/2))
		self.mainUI:addChild(itemIcon)	
		
		
		local function onClickRewardIconBtn(evt)
			CanonGoodIcon.popoutGoodPanel(finalRewardConfig[1].itemType, finalRewardConfig[1].metaId)
		end
		self.finalRewardBtn = Button:create(itemIcon)
		self.finalRewardBtn:addEventListener( Events.kStart, onClickRewardIconBtn, self ) 
	end
	--初始化按钮
	self.bindBtn = Button:create(self.bindList:getChildByName("btn"))
	self.shareBtn = Button:create(self.shareList:getChildByName("btn"))
	self.inviteBtn = Button:create(self.inviteList:getChildByName("btn"))
	self.gainRewardBtn = Button:create(self.mainUI:getChildByName("btn_receeive"))
	
	local function onClickShareBtn(evt)
		local currUser = DataManager.getCurrUser()
		local captionPara = getTextByKey("Fbactivity_share_txt6",{name1 = currUser.nickName})--"Activity Share caption"
		local namePara = getTextByKey("Fbactivity_share_txt3")--"Activity Share namePara"
		local descPara = getTextByKey("Fbactivity_share_txt5")--"Activity Share descPara"
		local function sendShareCallback()
			local function ShareFacebookActivitySucc()
				local gameData = DataManager.getGameInitData()
				gameData.sharkFbShare.sharkFbShareActivity.fbShare	= true
				DataManager.setGameInitData(gameData)
				self:updateUI()
			end
			local function ShareFacebbookActivityFail(response)
				local errorCode = tonumber(response.data)
				CanonMessageBox:showCommUnHandleErrorBox(errorCode)
			end
			local params = {}
			local request = ShareFacebookActivityeRequest.new(params, rpc.SendingPriority.kHigh)
			request:addEventListener(RequestNotifyEnum.ShareFacebookActivitySucceed, ShareFacebookActivitySucc)
			request:addEventListener(RequestNotifyEnum.ShareFacebookActivityFailed, ShareFacebbookActivityFail)
			request:start() 
		end
		feedFacebook(sendShareCallback,captionPara,namePara,descPara)
	end
	
	local function onClickInviteBtn(evt)
		local captionPara = ""
		local namePara = getTextByKey("Fbactivity_share_txt3")
		local descPara = getTextByKey("Fbactivity_share_txt5")
		local function sendInviteCallback(friendData)
			local friendList = friendData.to
			--he_log_info("++++++++++++friendList = " .. friendList)
			friendList = friendList:split(",")
			local function FacebookInviteFriendSucc()
				--he_log_info("++++++++++++invite facebook succ")
				local gameData = DataManager.getGameInitData()
				
				-- 更新本地邀請好友數據
				for k,v in pairs(friendList) do
					local newFriend = true
					for ck,cv in pairs(gameData.sharkFbShare.sharkFbShareActivity.inviteFbFriendList) do
						if v == cv then
							newFriend = false
							break
						end
					end
					if newFriend then
						table.insert(gameData.sharkFbShare.sharkFbShareActivity.inviteFbFriendList,v)
					end
				end
				DataManager.setGameInitData(gameData)
				self:updateUI()
			end
			local function FacebookInviteFriendFail(response)
				local errorCode = tonumber(response.data)
				CanonMessageBox:showCommUnHandleErrorBox(errorCode)
			end
			
			
			local params = { fbFriendIds = friendList}
			local request = FacebookInviteFriendRequest.new(params, rpc.SendingPriority.kHigh)
			request:addEventListener(RequestNotifyEnum.FacebookInviteFriendSucceed, FacebookInviteFriendSucc)
			request:addEventListener(RequestNotifyEnum.FacebookInviteFriendFailed, FacebookInviteFriendFail)
			request:start() 
		end
		sendRequestToFacebook(sendInviteCallback,captionPara,namePara,descPara)
	end
	
	local function onClickBindBtn(evt)
		DataManager.clearData()
		Director:sharedDirector():replaceScene(LoginScene:create())
	end

	local function onClickGainBtn(evt)
		if BagCalcManager.isFull() then
			NewPackageFullPanel:show()
			return
		end
		local function FacebookGainRewardSucc(response)
			local gameData = DataManager.getGameInitData()
			gameData.sharkFbShare.sharkFbShareActivity.gainedReward	= true
			DataManager.setGameInitData(gameData)
			self:updateUI()	
			
			 local RewardPanel = GetRewardInfoPanel:create( self.container, response.data.rewards )
			 PopoutManager:sharedManager():popout( RewardPanel, kPopoutDir.kScale, true, false ,self.container )
			 RewardManager:getReward(response.data.rewards)
        end
		
		local function FacebookGainRewardFail(response)
			local errorCode = tonumber(response.data)
			CanonMessageBox:showCommUnHandleErrorBox(errorCode)
		end
		local params = { }
		local request = FacebookGainActivityRewardRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(RequestNotifyEnum.FacebookGainActivityRewardSucceed, FacebookGainRewardSucc)
		request:addEventListener(RequestNotifyEnum.FacebookGainActivityRewardFailed, FacebookGainRewardFail)
		request:start() 
	end

	self.bindBtn:addEventListener( Events.kStart, onClickBindBtn, self ) 
	self.shareBtn:addEventListener( Events.kStart, onClickShareBtn, self ) 
	self.inviteBtn:addEventListener( Events.kStart, onClickInviteBtn, self ) 
	self.gainRewardBtn:addEventListener( Events.kStart, onClickGainBtn, self ) 
	
	--update UI
	self:updateUI()
end

function Activity_FacebookShareLayer.getTipNum()
	if not Activity_FacebookShareLayer.enable() then
		return 0
	end
	
	local gameData = DataManager.getGameInitData()
	
	if gameData.sharkFbShare then
	else
		gameData["sharkFbShare"] = {}
		gameData.sharkFbShare["sharkFbShareActivity"] = { 
															fbShare	= false,
															inviteFbFriendList = {},
															gainedReward = false,
														}
	end
	DataManager.setGameInitData(gameData)
	if gameData.sharkFbShare.sharkFbShareActivity.gainedReward then
		return 0
	else
		return 1
	end--  判断是否领取完FB奖励
end