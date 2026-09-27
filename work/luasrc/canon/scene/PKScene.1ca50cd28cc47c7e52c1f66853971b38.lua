--------------------------------------------------------------------------------
-- PKScene.lua - 比武界面
-- author: litong.sun
-- date: 2014-03-05
--------------------------------------------------------------------------------

require "canon.data.DataManager"
require "canon.data.MetaManager"
-- require "canon.panel.PKHelpPanel"
require "canon.panel.PKRewardPanel"
require "canon.request.PKGetPKInfoRequest"
require "canon.request.PKChallengePkUserRequest"
require "canon.request.PKGainPkBuffRequest"
require "canon.request.PKGetPkFoesRequest"
require "canon.request.PKGetPkTopRankUsersRequest"
require "canon.request.PKGainPkRewardsRequest"
require "canon.scene.BaseUIScene"
require "canon.scene.EmailScene"
require "canon.utils.StringUtil"
require "canon.utils.ViewControlUtil"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.PopoutManager"
require "hecore.ui.TableView"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local lastPKInfoTime = 0
local PKInfo = nil
local lastUid = nil
local enterType = 1
local canChallenge

local function timeToDate(time)
	return os.date("!*t", time + 8*3600) --北京时间
end

PKHelpPanel = class(Layer)

function PKHelpPanel:ctor()
end

function PKHelpPanel:create(container)
	local panel = PKHelpPanel.new()
	panel.container = container
	panel:initLayer()
	return panel
end

function PKHelpPanel:initLayer()
	PKHelpPanel.super.initLayer(self)

	local builder = LayoutBuilder:createWithContentsOfFile("scene/towerBabel.json")
	self.panelUI = builder:build("popup_towerBabel_rule")

	local offset = 180
	self.panelUI:getChildByName("txt_towerBabel_rule_title"):getChildByName("txt"):setString(getTextByKey("pk_session_title"))
	local text = self.panelUI:getChildByName("txt_towerBabel_rule"):getChildByName("txt")
	text:setDimensions(CCSizeMake(text:getDimensions().width, 0))
	text:setString(string.gsub(getTextByKey("pk_session_help"), "\\n", "\n"))
	text:setPositionY(text:getPositionY() - 32)
	local textBk = self.panelUI:getChildByName("white9_panel")
	textBk:setScaleY((textBk:getScaleY() * textBk:getContentSize().height + offset) / textBk:getContentSize().height)
	local panelBk = self.panelUI:getChildByName("new_green_bg9")
	panelBk:setScaleY((panelBk:getScaleY() * panelBk:getContentSize().height + offset) / panelBk:getContentSize().height)
	self.panelUI:getChildByName("huawen_fish_scales_L"):setPositionY(self.panelUI:getChildByName("huawen_fish_scales_L"):getPositionY() - offset)
	self.panelUI:getChildByName("huawen_fish_scales_R"):setPositionY(self.panelUI:getChildByName("huawen_fish_scales_R"):getPositionY() - offset)
	self.panelUI:getChildByName("btn_do_close"):setPositionY(self.panelUI:getChildByName("btn_do_close"):getPositionY() - offset)

	self.panelUI:getChildByName("btn_do_close"):getChildByName("txt"):getChildByName("txt"):setString(getTextByKey("close"))

	local function onClosePanel(evt)
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end
	local bt_panel_close = Button:create(self.panelUI:getChildByName("btn_close_sb"))
	bt_panel_close:addEventListener(Events.kStart, onClosePanel)

	local bt_panel_close = Button:create(self.panelUI:getChildByName("btn_do_close"))
	bt_panel_close:addEventListener(Events.kStart, onClosePanel)

	self:addChild(self.panelUI)
end

PKScene = class(BaseUIScene)

function PKScene:ctor()
	self.title = getTextByKey("pk_session_title")
	self.tabButton = {}
	self.tabPicActive = {}
	self.tabPicInActive = {}
	self.currentTab = 0
	self.playerPic = {}
	self.refreshStatus = 0 --到状态改变的时间自动刷新，计数
	self.refreshDelay = 10 + math.random(20)
  self.curSceneEnum = SceneEnum.PKScene
end


function PKScene:dispose()
	if self.scheduledRefreshHandle then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.scheduledRefreshHandle)
		self.scheduledRefreshHandle = nil
	end
	PKScene.super.dispose(self)
end

function PKScene:create(argv)
	local scene = PKScene.new()
	scene.argv = argv
	scene:initScene()
	return scene
end

function PKScene:onInit()
	BaseUIScene.initBackGround(self)
    
    --新UI加黑底
    local colorLayer = LayerColor:create()
    colorLayer:setOpacity(kDarkOpacity)
    colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(colorLayer)

	self.uiBuilder = LayoutBuilder:createWithContentsOfFile("scene/pk.json")
	self.uiBuilder.useArtLabelTTF = true
	self.background = self.uiBuilder:build("pk_title")
	self:addChild(self.background)

	local tabButton = {"btn_tab_pk1", "btn_tab_pk2", "btn_tab_pk3"}
	local tabTextKey = {"pk_title", "pk_foe_title", "pk_rank_title1"}
	for i = 1, 3 do
		local tab = self.background:getChildByName(tabButton[i])
		tab:getChildByName("txt"):setString(getTextByKey(tabTextKey[i]))
		self.tabPicActive[i] = tab:getChildByName("btn_arena_disable")--btn_arena_active
		self.tabPicInActive[i] = tab:getChildByName("btn_arena_active")--btn_arena_disable
		self.tabButton[i] = Button:create(tab)
		local function onClick()
			if not self.switchTab then
				self:showTab(i)
			end
		end
		self.tabButton[i]:addEventListener(Events.kStart, onClick)
		self.tabButton[i]:setEnable(i ~= 1)
		self.tabPicActive[i]:setVisible(i == 1)
		self.tabPicInActive[i]:setVisible(i ~= 1)
	end

	self.background:getChildByName("txt_pk13"):getChildByName("txt"):setString(getTextByKey("pk_session_rank"))
	self.background:getChildByName("txt_pk14"):getChildByName("txt"):setString(getTextByKey("pk_session_points"))
	self.background:getChildByName("txt_20"):getChildByName("txt"):setString(getTextByKey("pk_error_dec6"))

	self.mainUI = self.uiBuilder:build("pk")
	self.uiBuilder.useArtLabelTTF = false
	self:addChild(self.mainUI)
	local textTime1 = self.mainUI:getChildByName("txt_pk1"):getChildByName("txt")
	textTime1:setString(getTextByKey("pk_session_time"))
  	local textTime2 = self.mainUI:getChildByName("txt_pk_info"):getChildByName("txt")
	textTime2:setString(getTextByKey("sports_crossserver_text"))
	self.mainUI:getChildByName("txt_pk3"):getChildByName("txt"):setString(getTextByKey("pk_session_rank"))
	self.mainUI:getChildByName("txt_pk3_1"):getChildByName("txt"):setString(getTextByKey("pk_session_points"))
	self.textOver = ArtTextField:create(getTextByKey("pk_session_over"), nil, 28)
	self.textOver:setPosition(ccp(335, 942))
	self.mainUI:addChild(self.textOver)

	local picHelp = self.mainUI:getChildByName("sky_btn_qa")
	local btnHelp = Button:create(picHelp)
	local function onClickHelp()
		local panel = PKHelpPanel:create(self)
		PopoutManager:sharedManager():popout(panel, kPopoutDir.kScale, true, false, self)
	end
	btnHelp:addEventListener(Events.kStart, onClickHelp)

	local picShowReward = self.mainUI:getChildByName("icon_reward_tab")
	local btnShowReward = Button:create(picShowReward)
	local function onClickShowReward()
		if PKInfo and PKInfo.version then
			local panel = PKRewardPanel:create(self, self.uiBuilder, PKInfo.version)
			PopoutManager:sharedManager():popout(panel, kPopoutDir.kScale, true, false, self)
		end
	end
	btnShowReward:addEventListener(Events.kStart, onClickShowReward)

	local picPlayer = {"playerlist_m", "playerlist_l", "playerlist_r"}
	for i = 1, 3 do
		local pic = self.mainUI:getChildByName(picPlayer[i])
		-- pic:getChildByName("guide_other"):setVisible(false)
		pic.touchEnabled = false
		pic.touchChildren = false
	end

	self.mainUI:getChildByName("btn_fresh"):getChildByName("txt"):setString(getTextByKey("pk_session_refresh"))
	local picRefresh = self.mainUI:getChildByName("btn_fresh")
	self.btnRefresh = Button:create(picRefresh)
	local function onClickRefresh()
		if not self.requestPKInfo then
			self:refreshPKInfo()
		end
	end
	self.btnRefresh:addEventListener(Events.kStart, onClickRefresh)

	self.mainUI:getChildByName("btn_attackon"):getChildByName("txt"):setString(getTextByKey("pk_atk_title"))
	local picBless = self.mainUI:getChildByName("btn_attackon")
	self.btnBless = Button:create(picBless)
	local function onClickBless()
		local function onUseItem()
			local function onBlessSucceed()
				local aReward = {
					{itemType = ResourceEnum.PROP, metaId = DataManager.GameMetaData.pkSettingConfig.atkBuffId, amount = -1},
				}
				RewardManager:getReward(aReward)
				DailyDataManager.setPkBuffStatus(true)
				DailyDataManager.setPkBuffNum(DailyDataManager.getPkBuffNum() + 1)
				self:refreshBlessState()
			end
			local function onBlessFailed(e)
				local function closeCanonMessageBox()
				end
				local text = nil
				if e.data == 710540 then
					text = getTextByKey("pk_error_dec2")
					self:refreshPKInfo()
				elseif e.data == 710543 then
					text = getTextByKey("pk_error_dec4")
				else
					text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = e.data})
				end
				self.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
			end
			local request = PKGainPkBuffRequest.new(nil, rpc.SendingPriority.kHigh)
			request:addEventListener(RequestNotifyEnum.PKGainPkBuffSucceed, onBlessSucceed)
			request:addEventListener(RequestNotifyEnum.PKGainPkBuffFailed, onBlessFailed)
			request:start()
		end
		local hasProp = false
		local propDataList = DataManager.getPropsData()
		if DataManager.GameMetaData.pkSettingConfig then
			local atkBuffId = DataManager.GameMetaData.pkSettingConfig.atkBuffId
			for i, v in pairs(propDataList) do
				if v.metaId == atkBuffId and v.amount > 0 then
					hasProp = true
					break
				end
			end
		end
		if hasProp then
			self.targetInfoPanel = CanonMessageBox.showText(ShowButtonType.ID_OK_CANCEL, getTextByKey("pk_atk_use"), {text = getTextByKey("pk_atk_get"), callbackFunc = onUseItem}, nil, nil)
		else
			local function onGotoShop()
				self:replaceScene(ShopScene, {enterScene="PKScene", returnScene="PKScene", params={}})
			end
			self.targetInfoPanel = CanonMessageBox.showText(ShowButtonType.ID_RET_MONEY, getTextByKey("pk_atk_short"), nil, nil, {text = getTextByKey("gemCard_by"), callbackFunc = onGotoShop})
		end
	end
	self.btnBless:addEventListener(Events.kStart, onClickBless)

	self.mainUI:getChildByName("btn_getreward"):getChildByName("txt"):setString(getTextByKey("pk_session_get"))
	local picGetReward = self.mainUI:getChildByName("btn_getreward")
	self.btnGetReward = Button:create(picGetReward)
	local function onClickGetReward()
		if BagCalcManager.isFull() then
			NewPackageFullPanel:show()
			-- CanonMessageBox:Show(getTextByKey("arena_inventoryFullReward"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40)
			return
		end
		local function onGetRewardSucceed(e)
			PKInfo.gainReward = true
			if e and e.data and e.data.rewards then
				local rewardPanel = GetRewardInfoPanel:create(self, e.data.rewards)
				PopoutManager:sharedManager():popout(rewardPanel, kPopoutDir.kScale, true, false , self.container)
				RewardManager:getReward(e.data.rewards)
			end
			self:refreshGetRewardState()
		end
		local function onGetRewardFailed(e)
			local function closeCanonMessageBox()
			end
			local text = nil
			if e.data == 710541 then
				text = getTextByKey("pk_error_dec3")
				self:refreshPKInfo()
			elseif e.data == CommErrorCodes.GAIN_PK_REWARD_ERROR.code then
				CanonMessageBox:showCommErrorBox(CommErrorCodes.GAIN_PK_REWARD_ERROR)
				do return end
			else
				text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = e.data})
			end
			self.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		end
		local request = PKGainPkRewardsRequest.new(nil, rpc.SendingPriority.kHigh)
		request:addEventListener(RequestNotifyEnum.PKGainPkRewardsSucceed, onGetRewardSucceed)
		request:addEventListener(RequestNotifyEnum.PKGainPkRewardsFailed, onGetRewardFailed)
		request:start()
	end
	self.btnGetReward:addEventListener(Events.kStart, onClickGetReward)

	self.mainUI:getChildByName("txt_pk6"):getChildByName("txt"):setString(getTextByKey("pk_session_refresh1"))
	local buffEffect = DataManager.GameMetaData.pkSettingConfig and DataManager.GameMetaData.pkSettingConfig.atkBuffEffect or 0
	self.mainUI:getChildByName("txt_pk8"):getChildByName("txt"):setString(getTextByKey("pk_atk_txt", {num2 = buffEffect}))
	self.mainUI:getChildByName("txt_pk19_after"):getChildByName("txt"):setString(getTextByKey("pk_session_time2"))

	BaseUIScene.onInit(self)
end

function PKScene:back()
	self:replaceScene(CompeteScene)
end

function PKScene:setTableViewsEnabledInner(v)
	if self.listView then
		self.listView:setTouchEnabled(v)
	end
end

function PKScene:doEnterAnimation()
	self:preEnterAnimation()
	self:startEnterAnimation()
end

function PKScene:preEnterAnimation()
	BaseUIScene.preEnterAnimation(self)
	CanonPlayBackgroundMusic("music/background.mp3", true)
end

function PKScene:doExitAnimation()
	self:preExitAnimation()
	self:startExitAnimation()
end

function PKScene:startEnterAnimation()
	BaseUIScene.startEnterAnimation(self)
	self.background:setPositionX(self.background:getPositionX() - visibleSize.width)
	self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width*1.25)
	self:nodeAnimationFinished()
end

function PKScene:sufEnterAnimation()
	local function nodeActionFinished()
		BaseUIScene.sufEnterAnimation(self)
	end
	local function onRefreshFinished()
		local arr = CCArray:create()
		arr:addObject(CCMoveBy:create(0.2, ccp(visibleSize.width, 0)))
		arr:addObject(CCCallFunc:create(nodeActionFinished))
		self.background:runAction(CCSequence:create(arr))
		if not self.argv or self.argv.enterScene ~= "BattleScene" or not (PKInfo and PKInfo.status == 0) then
			enterType = 1
		end
		self:showTab(enterType)
		enterType = 1
	end

	local function refresh()
		self:refreshTick()
	end
	self:refreshTick(onRefreshFinished)
	self.scheduledRefreshHandle = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(refresh, 1, false)
end

function PKScene:startExitAnimation()
	BaseUIScene.startExitAnimation(self)

	local finishOnce = self.switchTab
	local function nodeActionFinished()
		if finishOnce then
			self:nodeAnimationFinished()
		else
			finishOnce = true
		end
	end

	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(0.2, ccp(-visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(nodeActionFinished))
	self.background:runAction(CCSequence:create(arr))
	self:runExitAnimation(nodeActionFinished)
	self.currentTab = 0
	if self.scheduledRefreshHandle then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.scheduledRefreshHandle)
		self.scheduledRefreshHandle = nil
	end
end

function PKScene:runEnterAnimation(callback)
	if self.currentTab == 1 then
		if callback then
			local arr = CCArray:create()
			arr:addObject(CCMoveBy:create(0.25, ccp(visibleSize.width*1.25, 0)))
			arr:addObject(CCCallFunc:create(callback))
			self.mainUI:runAction(CCSequence:create(arr))
		else
			self.mainUI:runAction(CCMoveBy:create(0.25, ccp(visibleSize.width*1.25, 0)))
		end
	else
		if self.listView then
			local animationItems = ViewControlUtil.generateAnimatedCells(self.listView)
			if #animationItems > 0 then
				for i,v in ipairs(animationItems) do
					v:setPositionX(v:getPositionX() - visibleSize.width)
					local arr = CCArray:create()
					arr:addObject(CCDelayTime:create(0.05*(i-1)))
					arr:addObject(CCMoveBy:create(0.2, ccp(visibleSize.width, 0)))
					if i == #animationItems and callback then
						arr:addObject(CCCallFunc:create(callback))
					end
					v:runAction(CCSequence:create(arr))
				end
			elseif callback then
				callback()
			end
		elseif callback then
			callback()
		end
	end
end

function PKScene:runExitAnimation(callback)
	if self.currentTab == 1 then
		if callback then
			local arr = CCArray:create()
			arr:addObject(CCMoveBy:create(0.25, ccp(-visibleSize.width*1.25, 0)))
			arr:addObject(CCCallFunc:create(callback))
			self.mainUI:runAction(CCSequence:create(arr))
		else
			self.mainUI:runAction(CCMoveBy:create(0.25, ccp(-visibleSize.width*1.25, 0)))
		end
	else
		if self.listView then
			local animationItems = ViewControlUtil.generateAnimatedCells(self.listView)
			if #animationItems > 0 then
				for i,v in ipairs(animationItems) do
					local arr = CCArray:create()
					arr:addObject(CCDelayTime:create(0.05*(i-1)))
					arr:addObject(CCMoveBy:create(0.2, ccp(-visibleSize.width, 0)))
					if i == #animationItems and callback then
						arr:addObject(CCCallFunc:create(callback))
					end
					v:runAction(CCSequence:create(arr))
				end
			elseif callback then
				callback()
			end
		elseif callback then
			callback()
		end
	end
end

function PKScene:showTab(tabIndex)
	if tabIndex == self.currentTab or tabIndex < 1 or tabIndex > 3 then
		return
	end
	self.switchTab = true
	local function currentTabFinished()
		self.currentTab = tabIndex
		local function onEnterFinished()
			self.switchTab = false
		end
		local function onRefreshFinished()
			self:runEnterAnimation(onEnterFinished)
		end
		self:refreshCurrentPage(onRefreshFinished)
	end
	if self.currentTab > 0 and self.currentTab <= 3 then
		self:runExitAnimation(currentTabFinished)
	else
		currentTabFinished()
	end
end

function PKScene:refreshCurrentPage(callback)
	for i = 1, 3 do
		self.tabButton[i]:setEnable(i ~= self.currentTab)
		self.tabPicActive[i]:setVisible(i == self.currentTab)
		self.tabPicInActive[i]:setVisible(i ~= self.currentTab)
	end
	local tab2 = self.background:getChildByName("btn_tab_pk2")
	local tab3 = self.background:getChildByName("btn_tab_pk3")
	if PKInfo and PKInfo.status == 0 then
		tab2:setVisible(true)
		tab3:setPositionX(tab2:getPositionX() * 2 - self.background:getChildByName("btn_tab_pk1"):getPositionX())
	else
		tab2:setVisible(false)
		tab3:setPositionX(tab2:getPositionX())
	end
	self.background:getChildByName("select_level_panel1"):setVisible(self.currentTab == 3)
	self.background:getChildByName("boss_h_line"):setVisible(self.currentTab == 3)
	-- self.background:getChildByName("boss_h_line2"):setVisible(self.currentTab == 3)
	self.background:getChildByName("txt_pk13"):setVisible(self.currentTab == 3)
	self.background:getChildByName("txt_pk14"):setVisible(self.currentTab == 3)
	self.background:getChildByName("txt_pk15"):setVisible(self.currentTab == 3)
	self.background:getChildByName("txt_pk13"):getChildByName("txt"):setString(getTextByKey("pk_session_rank") .. (PKInfo and PKInfo.rank or ""))
	self.background:getChildByName("txt_pk15"):getChildByName("txt"):setString(PKInfo and PKInfo.score or "")
	self.background:getChildByName("txt_20"):setVisible(false)
	if self.foeList and (#self.foeList > 0) then
		self.background:getChildByName("btn_tab_pk2"):getChildByName("icn_tixing_kong"):setVisible(true)
		self.background:getChildByName("btn_tab_pk2"):getChildByName("txt2"):setVisible(true)
		self.background:getChildByName("btn_tab_pk2"):getChildByName("txt2"):setString(tostring(#self.foeList))
	else
		self.background:getChildByName("btn_tab_pk2"):getChildByName("icn_tixing_kong"):setVisible(false)
		self.background:getChildByName("btn_tab_pk2"):getChildByName("txt2"):setVisible(false)
	end
	if self.currentTab == 1 then
		local pkBegin = false
		if not DataManager.GameMetaData.pkSettingConfig
			or (not MaintenanceManager.isStarted(DataManager.GameMetaData.pkSettingConfig.featureNamePkSession)
			and not MaintenanceManager.isStarted(DataManager.GameMetaData.pkSettingConfig.featureNameGainReward))
			then
			-- 活动未开
			tab2:setVisible(false)
			tab3:setVisible(false)
			if DataManager.GameMetaData.pkSettingConfig then
				local beginTime = MaintenanceManager:getStartAndEndTime(DataManager.GameMetaData.pkSettingConfig.featureNamePkSession)
				if beginTime and beginTime[1] then
					self.textOver:setFontSize(35)
					self.textOver:setString(getTextByKey("pk_session_start") .. getTextByKey("pk_session_start1", {num1=beginTime[1].month, num2=beginTime[1].day, num3 = 0}))
					self.textOver:setPositionY(568)
				end
			end
		else
			pkBegin = true
			tab3:setVisible(true)
			self.textOver:setFontSize(28)
			self.textOver:setString(getTextByKey("pk_session_over"))
			self.textOver:setPositionY(942)
		end
		local inFight = PKInfo and PKInfo.status == 0 and pkBegin
		local inReward = PKInfo and PKInfo.status == 1 and pkBegin
		if inFight then
			local beginWDay = nil
			local during = nil
			for k,v in pairs(MaintenanceManager.ActivityOnOffConfigData) do 
				if v.name == DataManager.GameMetaData.pkSettingConfig.featureNamePkSession then
					beginWDay = v.activityDate%7 + 1
					during = v.activityDuring
					break
				end
			end
			if beginWDay then
				local currentTime = TimeUtil.getServerTimeSeconds()
				local currentDate = timeToDate(currentTime)
				local beginTime = currentTime - currentDate.hour*3600 - currentDate.min*60 - currentDate.sec - (currentDate.wday - beginWDay)*24*3600
				if currentDate.wday < beginWDay then
					beginTime = beginTime - 7 * 24 * 3600
				end
				local beginDate = timeToDate(beginTime)
				local endDate = timeToDate(beginTime + during * 60)
				self.mainUI:getChildByName("txt_pk2"):getChildByName("txt"):setString(getTextByKey("pk_session_time1", {num1=beginDate.month, num2=beginDate.day, num3=string.format("%02d", beginDate.hour), num4=string.format("%02d", beginDate.min), num5=endDate.month, num6=endDate.day, num7=string.format("%02d", endDate.hour), num8=string.format("%02d", endDate.min)}))
				self:refreshBlessState()
			end
		end
		if inReward then
			self:refreshGetRewardState()
		end
		self.mainUI:getChildByName("txt_pk1"):setVisible(inFight)
		self.mainUI:getChildByName("txt_pk2"):setVisible(inFight)
		self.mainUI:getChildByName("icon_reward_tab"):setVisible(pkBegin)
		self.textOver:setVisible(inReward or not pkBegin)
    self.mainUI:getChildByName("txt_pk_info"):setVisible(false)
    if inFight then
      if AcrossFightManager.whetherCrossPkExistInServer() and not AcrossFightManager.isOpen() then
        local beginTime = TimeUtil.toServerTimestamp(AcrossFightManager.getNextCrossPkBeginTime())
        local currentTime = TimeUtil.getServerTimeSeconds()
        local timeStamp = beginTime - currentTime
        if timeStamp > 0  and timeStamp < 86400 * 7 then
          self.mainUI:getChildByName("txt_pk_info"):setVisible(true)
        end
      end
    end
		if PKInfo and PKInfo.score > 0 and pkBegin then
			self.mainUI:getChildByName("txt_pk3"):setVisible(true)
			self.mainUI:getChildByName("txt_pk3_1"):setVisible(true)
			self.mainUI:getChildByName("txt_pk4"):setVisible(true)
			self.mainUI:getChildByName("txt_pk5"):setVisible(true)
			self.mainUI:getChildByName("txt_pk4"):getChildByName("txt"):setString(PKInfo.rank)
			self.mainUI:getChildByName("txt_pk5"):getChildByName("txt"):setString(PKInfo.score)
		else
			self.mainUI:getChildByName("txt_pk3"):setVisible(false)
			self.mainUI:getChildByName("txt_pk3_1"):setVisible(false)
			self.mainUI:getChildByName("txt_pk4"):setVisible(false)
			self.mainUI:getChildByName("txt_pk5"):setVisible(false)
		end
		self.mainUI:getChildByName("txt_pk6"):setVisible(inFight)
		self.mainUI:getChildByName("txt_pk7"):setVisible(inFight)
		self.mainUI:getChildByName("txt_pk8"):setVisible(inFight)
		self.mainUI:getChildByName("btn_fresh"):setVisible(inFight)
		self.mainUI:getChildByName("btn_attackon"):setVisible(inFight)
		self.mainUI:getChildByName("btn_getreward"):setVisible(inReward)
		self.mainUI:getChildByName("txt_pk19_after"):setVisible(inReward)
		local playerPic = {"playerlist_m", "playerlist_l", "playerlist_r"}
		local playerInfo = {"playerlist_fo_m", "playerlist_fo_l", "playerlist_fo_r"}
    local playerUnionInfo = {"txt_s_name_combine1", "txt_s_name_combine2", "txt_s_name_combine3"}
		local scorePic = {"icon_high_score", "icon_many_score", "icon_normal_score", "icon_less_score"}
		local rankPic0 = {"icn_paiming1", "icn_paiming2", "icn_paiming3"}
		local rankPic1 = {"lbl_1st", "lbl_2nd", "lbl_3rd"}
		for i=1,3 do
			local localPic = self.mainUI:getChildByName(playerPic[i])
			local localInfo = self.mainUI:getChildByName(playerInfo[i])
      local localUnionInfo = self.mainUI:getChildByName(playerUnionInfo[i])
			if self.playerPic[i] then
				self.playerPic[i]:removeFromParentAndCleanup(true)
				self.playerPic[i] = nil
			end
			local score = localPic:getChildByName("icon_score")
			self.mainUI:getChildByName(rankPic0[i]):setVisible(inReward)
			self.mainUI:getChildByName(rankPic1[i]):setVisible(inReward)
			score:setVisible(inFight)
			if PKInfo and PKInfo.pkUserInfos and PKInfo.pkUserInfos[i] and pkBegin then
				if PKInfo.status == 0 then
					local drank = PKInfo.rank - PKInfo.pkUserInfos[i].rank
					local displayType = 0
					if DataManager.GameMetaData.pkDisplayPointsConfig and DataManager.GameMetaData.pkDisplayPointsConfig.items then
						for j,v in ipairs(DataManager.GameMetaData.pkDisplayPointsConfig.items) do
							if v.rankMin <= drank and v.rankMax >= drank then
								displayType = tonumber(v.displayType)
								break
							end
						end
					end
					for j=1,4 do
						score:getChildByName(scorePic[j]):setVisible(displayType == j-1)
					end
				end
				local card = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(PKInfo.pkUserInfos[i].mainCardMetaId))
				card:setAnchorPoint(ccp(0.5, 0))
				card:setScaleX(0.7)
				card:setScaleY(0.7)
				local posRef = localInfo:getChildByName("bg_player_name")
				local posX = localInfo:getPositionX() + posRef:getPositionX() + 0.5 * posRef:getContentSize().width
				local posY = localInfo:getPositionY() + posRef:getPositionY()
				card:setPosition(ccp(posX, posY))
				self.mainUI:addChildAt(card, i-1)
				self.playerPic[i] = card
				card.hitTestPoint = function (self, worldPosition, useGroupTest)
					local posX = self:getPositionX()
					local posY = self:getPositionY()
					return worldPosition.x > posX - 105 and worldPosition.x < posX + 105 and worldPosition.y > posY and worldPosition.y < posY + 300
				end
				local button = Button:create(card)
				local function onClickFight()
					if PKInfo and PKInfo.status == 0 and PKInfo.pkUserInfos and PKInfo.pkUserInfos[i] then
						if canChallenge then
							self:beginFight(PKInfo.pkUserInfos[i].uid, false)
						else
							CanonMessageBox:Show(getTextByKey("pk_error"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, nil, nil)
						end
          elseif tonumber(PKInfo.pkUserInfos[i].uid) ~= tonumber(DataManager.getCurrUser().uid) then
            local userDetailPanel = UserDetailPanel:create( self, {friendUid = PKInfo.pkUserInfos[i].uid} )
            PopoutManager:sharedManager():popout(userDetailPanel, kPopoutDir.kScale, true, false, self)
					end
				end
				button:addEventListener(Events.kStart, onClickFight)

				localPic:setVisible(true)
				localInfo:setVisible(true)
				localInfo:getChildByName("txt_player_level"):getChildByName("txt"):setString(tostring(PKInfo.pkUserInfos[i].level))
				localInfo:getChildByName("txt_player_name"):getChildByName("txt"):setString(PKInfo.pkUserInfos[i].nickName)
        if not PKInfo.pkUserInfos[i].unionName then
          localUnionInfo:setVisible(false)
        else
        	localUnionInfo:setVisible(true)
          localUnionInfo:getChildByName("txt_s_name"):getChildByName("txt"):setString(PKInfo.pkUserInfos[i].unionName)
        end
        
			else
				localPic:setVisible(false)
				localInfo:setVisible(false)
        localUnionInfo:setVisible(false)
			end
		end
		local function onGetFoesSucceed(e)
			local aFoeList = {}
			if e and e.data then
				aFoeList = e.data.pkUserInfos or {}
			end
			self.foeList = {}
			for _, aFoe in ipairs(aFoeList) do
				if aFoe.rivalNum > 0 then
					table.insert(self.foeList, aFoe)
				end
			end
			-- self.background:getChildByName("txt_20"):setVisible(self.foeList == nil or #self.foeList <= 0)
			if self.foeList and (#self.foeList > 0) then
				self.background:getChildByName("btn_tab_pk2"):getChildByName("icn_tixing_kong"):setVisible(true)
				self.background:getChildByName("btn_tab_pk2"):getChildByName("txt2"):setVisible(true)
				self.background:getChildByName("btn_tab_pk2"):getChildByName("txt2"):setString(tostring(#self.foeList))
			else
				self.background:getChildByName("btn_tab_pk2"):getChildByName("icn_tixing_kong"):setVisible(false)
				self.background:getChildByName("btn_tab_pk2"):getChildByName("txt2"):setVisible(false)
			end
			self:refreshList()
			if callback then
				callback()
			end
		end
		local function onGetFoesFailed(e)
			local function closeCanonMessageBox()
			end
			local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = e.data})
			self.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		end
		local request = PKGetPkFoesRequest.new(nil, rpc.SendingPriority.kHigh)
		request:addEventListener(RequestNotifyEnum.PKGetPkFoesSucceed, onGetFoesSucceed)
		request:addEventListener(RequestNotifyEnum.PKGetPkFoesFailed, onGetFoesFailed)
		request:start()
	elseif self.currentTab == 2 then
		local function onGetFoesSucceed(e)
			local aFoeList = {}
			if e and e.data then
				aFoeList = e.data.pkUserInfos or {}
			end
			self.foeList = {}
			for _, aFoe in ipairs(aFoeList) do
				if aFoe.rivalNum > 0 then
					table.insert(self.foeList, aFoe)
				end
			end
			self.background:getChildByName("txt_20"):setVisible(self.foeList == nil or #self.foeList <= 0)
			if self.foeList and (#self.foeList > 0) then
				self.background:getChildByName("btn_tab_pk2"):getChildByName("icn_tixing_kong"):setVisible(true)
				self.background:getChildByName("btn_tab_pk2"):getChildByName("txt2"):setVisible(true)
				self.background:getChildByName("btn_tab_pk2"):getChildByName("txt2"):setString(tostring(#self.foeList))
			else
				self.background:getChildByName("btn_tab_pk2"):getChildByName("icn_tixing_kong"):setVisible(false)
				self.background:getChildByName("btn_tab_pk2"):getChildByName("txt2"):setVisible(false)
			end
			self:refreshList()
			if callback then
				callback()
			end
		end
		local function onGetFoesFailed(e)
			local function closeCanonMessageBox()
			end
			local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = e.data})
			self.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		end
		local request = PKGetPkFoesRequest.new(nil, rpc.SendingPriority.kHigh)
		request:addEventListener(RequestNotifyEnum.PKGetPkFoesSucceed, onGetFoesSucceed)
		request:addEventListener(RequestNotifyEnum.PKGetPkFoesFailed, onGetFoesFailed)
		request:start()
	else
		local function onGetRankSucceed(e)
			if e and e.data then
				self.rankList = e.data.pkUserInfos or {}
				for i,v in ipairs(self.rankList) do
					if v.uid == DataManager.getCurrUser().uid then
						if PKInfo then
							PKInfo.rank = i
							PKInfo.score = v.score
							self.background:getChildByName("txt_pk13"):getChildByName("txt"):setString(getTextByKey("pk_session_rank") .. PKInfo.rank)
							self.background:getChildByName("txt_pk15"):getChildByName("txt"):setString(PKInfo.score)
						end
						break
					end
				end
			end
			self:refreshList()
			if callback then
				callback()
			end
		end
		local function onGetRankFailed(e)
			local function closeCanonMessageBox()
			end
			local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = e.data})
			self.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		end
		local request = PKGetPkTopRankUsersRequest.new(nil, rpc.SendingPriority.kHigh)
		request:addEventListener(RequestNotifyEnum.PKGetPkTopRankUsersSucceed, onGetRankSucceed)
		request:addEventListener(RequestNotifyEnum.PKGetPkTopRankUsersFailed, onGetRankFailed)
		request:start()
	end
end

function PKScene:refreshList()
	if self.listView then
		self:removeChild(self.listView)
		self.listView = nil
	end
	if self.currentTab ~= 2 and self.currentTab ~=3 then
		return
	end
	PKListViewRender = class(TableViewRenderer)
	function PKListViewRender:ctor()
		self.list = {}
	end
	function PKListViewRender:buildCell(container)
		local pkItem = nil
		if self.container.currentTab == 2 then
			pkItem = self.container.uiBuilder:build("list_revenge")
			pkItem:getChildByName("normal_card_small"):setAnchorPoint(ccp(0.5, 0.5))
			pkItem:getChildByName("normal_card_small"):setVisible(false)
			local tagTree = {normal_card_small = 101, txt_pk9 = {102, txt=201}, txt_pk_lv = {103, txt=201}, txt_pk20 = {104, txt=201}, btn_challenge_lt = {110, txt=201}}
			setCCNodeTagTree(pkItem, tagTree)
		else
			pkItem = self.container.uiBuilder:build("list_pk_ranking")
			pkItem:getChildByName("txt_pk11"):getChildByName("txt"):setString(getTextByKey("pk_session_points"))
			pkItem:getChildByName("normal_card_small"):setAnchorPoint(ccp(0.5, 0.5))
			pkItem:getChildByName("normal_card_small"):setVisible(false)
			local tagTree = {normal_card_small = 101, txt_pk9 = {102, txt=201}, txt_pk_lv = {103, txt=201}, txt_pk12 = {104, txt=201}, txt_pk10 = {105, txt=201}, lbl_st_combine = {106, lbl_1st=201,lbl_2nd=202,lbl_3rd=203}, txt_pk20 = {107, txt=201}}
			setCCNodeTagTree(pkItem, tagTree)
		end
		pkItem:setTag(111)
		container:addChild(pkItem)
	end
	function PKListViewRender:setData(rawCocosObj, index)
		local pkItem = self:getChildByTag(rawCocosObj, 111)
		local user = nil
		index = index + 1
		if self.container.currentTab == 2 then
			if self.container.foeList and self.container.foeList[index] then
				user = self.container.foeList[index]
			end
			if user then
				if user.unionName and (user.unionName ~= "") then
					pkItem:getChildByTag(104):getChildByTag(201):setVisible(true)
					setNodeText(pkItem:getChildByTag(104):getChildByTag(201), "【"..user.unionName.."】")
				else
					pkItem:getChildByTag(104):getChildByTag(201):setVisible(false)
				end
			else
				pkItem:getChildByTag(104):getChildByTag(201):setVisible(false)
			end
			setNodeText(pkItem:getChildByTag(110):getChildByTag(201), getTextByKey("pk_foe_txt") .. string.format("(%d)", user.rivalNum))
		else
			if self.container.rankList and self.container.rankList[index] then
				user = self.container.rankList[index]
				setNodeText(pkItem:getChildByTag(104):getChildByTag(201), tostring(user.score))
				if index <=3 then
					pkItem:getChildByTag(105):setVisible(false)
					pkItem:getChildByTag(106):setVisible(true)
					for i=1,3 do
						pkItem:getChildByTag(106):getChildByTag(200+i):setVisible(i == index)
					end
				else
					pkItem:getChildByTag(105):setVisible(true)
					setNodeText(pkItem:getChildByTag(105):getChildByTag(201), getTextByKey("pk_session_rank4", {num1=index}))
					pkItem:getChildByTag(106):setVisible(false)
				end
			end
			if user then
				if user.unionName and (user.unionName ~= "") then
					pkItem:getChildByTag(107):getChildByTag(201):setVisible(true)
					setNodeText(pkItem:getChildByTag(107):getChildByTag(201), "【"..user.unionName.."】")
				else
					pkItem:getChildByTag(107):getChildByTag(201):setVisible(false)
				end
			else
				pkItem:getChildByTag(107):getChildByTag(201):setVisible(false)
			end
		end
		local icon = pkItem:getChildByTag(120)
		if icon then
			icon:removeFromParentAndCleanup(true)
		end
		if user then
			local newMeta = CommonManager:getSelfAvatarMetaByUid( user.uid )
			if not newMeta then
				newMeta = user.mainCardMetaId
			end
			icon = getHeadIconCanonCardByMetaId(newMeta)
			ViewControlUtil.adjustItemByFrame(icon, CocosObject.new(pkItem:getChildByTag(101)))
			icon:setTag(120)
			pkItem:addChild(icon.refCocosObj, 2)
			setNodeText(pkItem:getChildByTag(102):getChildByTag(201), user.nickName)
			setNodeText(pkItem:getChildByTag(103):getChildByTag(201), tostring(user.level))
		end
	end
	local function onListItemTouch(e)
		if self.currentTab == 2 and self.foeList and self.foeList[e.data+1] then
			local cell = self.listView:cellAtIndex(e.data)
			local button = cell:getChildByTag(111):getChildByTag(110)
			if CocosObject.new(button):hitTestPoint(e.globalPosition, true) then
				self:beginFight(self.foeList[e.data+1].uid, true)
			end
    elseif self.currentTab == 3 and self.rankList and self.rankList[e.data+1] and tonumber(self.rankList[e.data+1].uid) ~= tonumber(DataManager.getCurrUser().uid) then
      local userDetailPanel = UserDetailPanel:create( self, {friendUid = self.rankList[e.data+1].uid} )
      PopoutManager:sharedManager():popout(userDetailPanel, kPopoutDir.kScale, true, false, self)
		end
	end
	local render = PKListViewRender.new(715, self.currentTab == 2 and 152 or 149)
	render.container = self
	if self.currentTab == 2 then
		self.listView = TableView:create(render, 720, 852, 111, 110, CCScale9Sprite:create(CCRectMake(0,0,0,0), "pic/scroll.png"), CCScale9Sprite:create(CCRectMake(0,0,0,0), "pic/scroll.png"))
	else
		self.listView = TableView:create(render, 720, 764, 111, nil, CCScale9Sprite:create(CCRectMake(0,0,0,0), "pic/scroll.png"), CCScale9Sprite:create(CCRectMake(0,0,0,0), "pic/scroll.png"))
	end
	self.listView:setPosition(ccp(0, 125))
	self.listView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch, self)
	self:addChild(self.listView)
	if self.currentTab == 2 then
		render.list = {}
		local num = self.foeList and #self.foeList or 0
		if DataManager.GameMetaData.pkSettingConfig then
			local num = math.min(DataManager.GameMetaData.pkSettingConfig.foeDisplayNum, num)
		end
		for i=1,num do render.list[i] = i end
	else
		render.list = {}
		local num = self.rankList and #self.rankList or 0
		if DataManager.GameMetaData.pkSettingConfig then
			local num = math.min(DataManager.GameMetaData.pkSettingConfig.rankListNum, num)
		end
		for i=1,num do render.list[i] = i end
	end
	self.listView:reloadData()
	self.listView.hitTestPoint = function (self, worldPosition, useGroupTest)
		return false -- 修复遮挡下方按钮的bug
	end
end

function PKScene:refreshBlessState()
	local enable = false
	local usedmax = false
	if not DailyDataManager.getPkBuffStatus() then
		local maxNum = DataManager.GameMetaData.pkSettingConfig and DataManager.GameMetaData.pkSettingConfig.atkBuffNum or 0
		if DailyDataManager.getPkBuffNum() < maxNum then
			enable = true
		else
			usedmax = true
		end
	end
	self.mainUI:getChildByName("btn_attackon"):getChildByName("txt"):setString(getTextByKey(enable and "pk_atk_title" or "pk_atk_got"))
	if usedmax then
		self.mainUI:getChildByName("txt_pk8"):getChildByName("txt"):setString(getTextByKey("pk_atk_limit"))
	else
		local buffEffect = DataManager.GameMetaData.pkSettingConfig and DataManager.GameMetaData.pkSettingConfig.atkBuffEffect or 0
		self.mainUI:getChildByName("txt_pk8"):getChildByName("txt"):setString(getTextByKey("pk_atk_txt", {num2 = buffEffect}))
	end
	self.mainUI:getChildByName("btn_attackon"):getChildByName("btn"):setVisible(enable)
	self.btnBless:setEnable(enable)
end

function PKScene:refreshGetRewardState()
	local enable = false
	if PKInfo and not PKInfo.gainReward and PKInfo.score > 0 and DataManager.GameMetaData.pkRewardConfig and DataManager.GameMetaData.pkRewardConfig.items then
		for i,v in ipairs(DataManager.GameMetaData.pkRewardConfig.items) do
			if v.sessionMin <= PKInfo.version and v.sessionMax >= PKInfo.version then
				for ireward, vreward in ipairs(v.metas) do
					if vreward.rank >= PKInfo.rank then
						enable = true
						break
					end
				end
				break
			end
		end
	end
	self.mainUI:getChildByName("btn_getreward"):getChildByName("btn"):setVisible(enable)
	self.btnGetReward:setEnable(enable)
end

function PKScene:refreshRefreshCDState()
	if PKInfo and PKInfo.status == 0 then
		local cd = 0
		local enable = false
		if DataManager.GameMetaData.pkSettingConfig then
			cd = lastPKInfoTime + DataManager.GameMetaData.pkSettingConfig.refreshCooldown - TimeUtil.getServerTimeSeconds()
			enable = cd <= 0
			if cd < 0 then cd = 0 end
		end
		if not self.isDisposed then
			self.mainUI:getChildByName("txt_pk7"):getChildByName("txt"):setString(string.format("%02d:%02d:%02d", math.floor(cd/3600), math.floor(cd/60)%60, cd%3600))
			self.mainUI:getChildByName("btn_fresh"):getChildByName("btn"):setVisible(enable)
			self.btnRefresh:setEnable(enable)
		end
	end
end

function PKScene:refreshTick(callback)
	if self.isDisposed then
		return
	end
	local currentTime = TimeUtil.getServerTimeSeconds()
	local needRefresh = false
	local fightOpen = DataManager.GameMetaData.pkSettingConfig and MaintenanceManager.isActivityOpen(DataManager.GameMetaData.pkSettingConfig.featureNamePkSession)
	--local rewardOpen = DataManager.GameMetaData.pkSettingConfig and MaintenanceManager.isActivityOpen(DataManager.GameMetaData.pkSettingConfig.featureNameGainReward)
	local fightStarted = DataManager.GameMetaData.pkSettingConfig and MaintenanceManager.isStarted(DataManager.GameMetaData.pkSettingConfig.featureNamePkSession)
	local rewardStarted = DataManager.GameMetaData.pkSettingConfig and MaintenanceManager.isStarted(DataManager.GameMetaData.pkSettingConfig.featureNameGainReward)
	if (fightStarted or rewardStarted) and currentTime >= lastPKInfoTime + 10 and not self.requestPKInfo then -- 自动刷新有10秒cd
		if lastUid ~= DataManager.getCurrUser().uid then -- 切换用户
			needRefresh = true
			lastUid = DataManager.getCurrUser().uid
		elseif lastPKInfoTime == 0 or not PKInfo then
			needRefresh = true
		else
			-- 状态改变跨天自动刷新
			if currentTime - lastPKInfoTime >= 7*24*3600 then
				needRefresh = true
			else
				local timeStatus = fightOpen and 0 or 1
				if timeStatus ~= PKInfo.status and timeToDate(currentTime).sec >= self.refreshDelay then
					needRefresh = true
				end
			end
			if not needRefresh then
				self.refreshStatus = 0
			elseif self.refreshStatus >= 2 then
				needRefresh = false
			else
				self.refreshStatus = self.refreshStatus + 1
			end
		end
	end
	self:refreshBlessState()
	if needRefresh then
		self:refreshPKInfo(callback)
	else
		self:refreshRefreshCDState()
		if callback then
			callback()
		end
	end
end

function PKScene:refreshPKInfo(callback)
	local function onRequestSucceed(e)
		canChallenge = true
		PKInfo = e.data
		lastPKInfoTime = TimeUtil.getServerTimeSeconds()
		if self and not self.isDisposed then
			if self.currentTab == 2 and PKInfo and PKInfo.status ~= 0 then
				self:showTab(1)
			else
				self:refreshCurrentPage()
			end
			self.requestPKInfo = false
			self:refreshRefreshCDState()
		end
		if callback then
			callback()
		end
	end
	local function onRequestFailed(e)
		lastPKInfoTime = TimeUtil.getServerTimeSeconds()
		if callback then
			callback()
		end
		if self then
			self.requestPKInfo = false
			self:refreshRefreshCDState()
		end
		local function closeCanonMessageBox()
		end
		local text = nil
		if e.data == 710542 then
			text = getTextByKey("pk_error_dec1")
		else
			text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = e.data})
		end
		CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	end
	local request = PKGetPKInfoRequest.new(nil, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.PKGetPkInfoSucceed, onRequestSucceed)
	request:addEventListener(RequestNotifyEnum.PKGetPkInfoFailed, onRequestFailed)
	if self then
		self.requestPKInfo = true
	end
	request:start()
end

function PKScene:beginFight(uid, revenge)
	if not DataManager.GameMetaData.pkSettingConfig then
		return
	end
	-- 精力
	if CalculationManager.calcComplex_getEPNow() < DataManager.GameMetaData.pkSettingConfig.eventPointCost then
		local hasProp, eventPointPropList = BagCalcManager.getEventPointPropList()
		if hasProp then
			local function callback(aEventPointPropId)
				local function usePropSucceed(event)
					local aReward = {
						{itemType = ResourceEnum.PROP, metaId = aEventPointPropId, amount = -1},
						{itemType = ResourceEnum.EVENTPOINT, amount = event.data.rewards[1].amount}
					}
					RewardManager:getReward(aReward)
					CanonPlayEffect("music/sfx_engly_lvup.wav")
					SuspensionLabel:showContent(self, getTextByKey("propInfo_eventPointReplenished"))
				end

				local function usePropFailed(event)
					local function closeCanonMessageBox()
					end
					if event.data.retCode == 712309 then
						self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("propInfo_eventPointFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
					elseif event.data.retCode == 712301 then
						local aPropMetaConfig = MetaManager.prop_meta[aEventPointPropId]
						self.targetInfoPanel = CanonMessageBox:Show(getTextByKey("popup_noProp", {propname = Localization:getInstance():getText(aPropMetaConfig.name)}), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
					end
				end

				local request = UsePropRequest.new( {propId = aEventPointPropId}, rpc.SendingPriority.kHigh )
				request:addEventListener( RequestNotifyEnum.UsePropSucceed, usePropSucceed )
				request:addEventListener( RequestNotifyEnum.UsePropFailed, usePropFailed )
				request:start()
			end
			local aPanel = EEPSupplyPanel:create(self, eventPointPropList, callback)
			self:addChild(aPanel)
			aPanel:scaleIn()
		else
			local aPanel = EENPSupplyPanel:create(self, {supplyType = EESupplyTypeEnum.EventPoint, callback = function() end})
			self:addChild(aPanel)
			aPanel:scaleIn()
		end
		return
	end
	-- 背包
	if BagCalcManager.isFull() then
		NewPackageFullPanel:show()
		-- CanonMessageBox:Show(getTextByKey("arena_inventoryFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40)
		return
	end

	local function onRequestSucceed(e)
		if not revenge then
			canChallenge = false
		end
		if e and e.data then
			if revenge and self.foeList then
				local remove = false
				for i = 1, #self.foeList do
					if self.foeList[i].uid == uid then
						remove = true
					end
					if remove then
						self.foeList[i] = self.foeList[i+1]
					end
				end
			end
			e.data.prevRank = PKInfo.rank
			e.data.forbidSkip = true
			if self.scheduledRefreshHandle then
				CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.scheduledRefreshHandle)
				self.scheduledRefreshHandle = nil
			end
			enterType = self.currentTab
			Director:sharedDirector():replaceScene(BattleScene:create(e.data, BattleBackType.kPKScene, BattleEnterEnum.kPKScene))
		end
		RewardManager:getReward({{itemType = ResourceEnum.EVENTPOINT, amount = -DataManager.GameMetaData.pkSettingConfig.eventPointCost}})
		DailyDataManager.setPkBuffStatus(false)
	end
	local function onRequestFailed(e)
		local function closeCanonMessageBox()
		end
		local text = nil
		if e.data == 710540 then
			text = getTextByKey("pk_error_dec2")
			self:refreshPKInfo()
		elseif e.data == CommErrorCodes.CHALLENAGE_PK_ERROR.code then
			CanonMessageBox:showCommErrorBox(CommErrorCodes.CREATE_USER_ERROR)
			do
				return
			end
		else
			text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = e.data})
		end
		self.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	end
	local request = PKChallengePkUserRequest.new({opponentUid = uid, type = revenge and 1 or 0}, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.PKChallengePkUserSucceed, onRequestSucceed)
	request:addEventListener(RequestNotifyEnum.PKChallengePkUserFailed, onRequestFailed)
	request:start()
end

function PKScene.refreshPKInfoStatic(callback)
	PKScene.refreshPKInfo(nil, callback)
end

function PKScene.getPKInfo()
	return PKInfo
end
