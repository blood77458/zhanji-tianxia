--------------------------------------------------------------------------------
-- GachaScene.lua - 求将界面
-- author: litong.sun
-- date: 2014-02-08
--------------------------------------------------------------------------------

require "canon.data.DataManager"
require "canon.data.MetaManager"
require "canon.manager.MaintenanceManager"
require "canon.manager.ParticleManager"
require "canon.models.EventManager"
require "canon.panel.GachaResultPanel"
require "canon.panel.GachaShowCardPanel"
require "canon.request.GachaCardFreeRequest"
require "canon.request.GachaCardRequest"
require "canon.request.GetGachaBroadcastRequest"
require "canon.scene.BaseUIScene"
require "hecore.ResourceLoader"
require "hecore.ui.LayoutBuilder"
require "canon.request.GachaCardByBoxRequest"
require "canon.request.GetSharkGachaBoxInfoRequest"
require "canon.request.RefreshGachaBoxRequest"
require "canon.panel.GachaBoxAttensionPanel"
require "canon.panel.ShowGachaBoxCardsPanel"
require "canon.panel.NewPackageFullPanel"


local visibleSize = CCDirector:sharedDirector():getVisibleSize()

GachaScene = class(BaseUIScene)

GachaActivityEnum = table.const{
	ACTIVITY_ALL_CLOSE = nil,
	YELLOW_CRYSTAL = 1,
	GACHA_BOX = 2,
	Niu_Dan = 3
}

local function sortGachaBoxCards( oldCards )
	local function sortFunc( a , b )
		if (a.id < b.id) then
			return true
		else
			return false
		end
	end
	table.sort(oldCards , sortFunc)
	local newCards = {}
	table.insert(newCards , specialCard)
	local cardsRare = {}
	for i=1,6 do
		cardsRare[i] = {}
	end
	for k,v in pairs(oldCards) do
		table.insert(cardsRare[MetaManager.card_meta[v.cardId].rare] , v)
	end

	for i=1,6 do
		for k,v in pairs(cardsRare[i]) do
			table.insert(newCards , v)
		end
	end
	return newCards
end

function GachaScene:selectActivity( )
	--在不消除黄水晶的情况下，加入扭蛋池活动
	-- do return GachaActivityEnum.GACHA_BOX end
	
	if MaintenanceManager.isActivityOpen("activityBoxGacha") then
		return GachaActivityEnum.GACHA_BOX
	elseif MaintenanceManager.isActivityOpen("activityGacha1") then
		return GachaActivityEnum.Niu_Dan
	elseif self.gachaConfig[5] and MaintenanceManager.isActivityOpen(self.gachaConfig[5].activityName) then
		return GachaActivityEnum.YELLOW_CRYSTAL
	else
		return GachaActivityEnum.ACTIVITY_ALL_CLOSE
	end
end

function GachaScene:ctor()
	self.title = getTextByKey("gacha_gachaTab")
	self.mainUI = {}
	self.tabPicActive = {}
	self.tabPicInActive = {}
	self.textBroadcast = {}
	self.AdSprite = {{}, {}, {}}
	self.gachaConfig = {}
	self.freeGacha = {}
	self.showButton = true
	self.maxFriendTimes = 0
	self.isChangingTab = false
end

function GachaScene:dispose()
	if self.scheduledRefreshHandle then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.scheduledRefreshHandle)
		self.scheduledRefreshHandle = nil
	end
	if self.showTabHandle then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.showTabHandle)
		self.showTabHandle = nil
	end
	GachaScene.super.dispose(self)
end

function GachaScene:create(argv)
	local scene = GachaScene.new()
	scene:initScene()
	scene.argv = argv or {returnScene = nil}
	Set_ShareData("Run_Into_Gacha", 1)
	return scene
end

function GachaScene:onInit()
	BaseUIScene.initBackGround(self)

	self.uiBuilder = LayoutBuilder:createWithContentsOfFile("scene/gacha_new.json")
	self.uiBuilder.useArtLabelTTF = true
	self.topMenu = self.uiBuilder:build("scene/top_menu")
	self:addChild(self.topMenu)

	local tabPicActive = {"btn_beg_tab_inactive", "btn_activity_tab_inactive", "btn_friends_inactive"}--"btn_beg_tab_active", "btn_activity_tab_active", "btn_friends_active"
	local tabPicInActive = {"btn_beg_tab_active", "btn_activity_tab_active", "btn_friends_active"}--"btn_beg_tab_inactive", "btn_activity_tab_inactive", "btn_friends_inactive"
	local tabText = {"txt_beg_tab", "txt_activity_tab", "txt_friends_tab"}
	local tabTextKey = {"gacha_gachaTab", "gacha_eventTab", "gacha_friendTab"}
	for i = 1, 3 do
		self.tabPicActive[i] = self.topMenu:getChildByName(tabPicActive[i])
		local textActive = self.tabPicActive[i]:getChildByName(tabText[i])
		textActive:getChildByName("txt"):setString(getTextByKey(tabTextKey[i]))

		self.tabPicInActive[i] = self.topMenu:getChildByName(tabPicInActive[i])
		local textInActive = self.tabPicInActive[i]:getChildByName(tabText[i])
		textInActive:getChildByName("txt"):setString(getTextByKey(tabTextKey[i]))
		-- textInActive:getChildByName("txt"):setColor(ccc3(50, 50, 50))

		local button = Button:create(self.tabPicInActive[i])
		local function onClickButton()
			for i = 1, #self.mainUI do
				if self.mainUI[i]:numberOfRunningActions() > 0 then
					return
				end
			end
			self:showTab(i)
		end
		button:addEventListener(Events.kStart, onClickButton)
	end
	self.tab3ActiveX = self.tabPicActive[3]:getPositionX()
	self.tab3InActiveX = self.tabPicInActive[3]:getPositionX()

	local payPic = self.topMenu:getChildByName("btn_pay_top")
	payPic:getChildByName("txt_pay_top"):getChildByName("txt"):setString(getTextByKey("payBtn"))
	payPic:setVisible(false)

	for i,v in pairs(MetaManager.gacha_card) do
		self.gachaConfig[v.id] = v
	end

	BaseUIScene.onInit(self)
end

function GachaScene:back()
	self.ignoreAction = false
	-- print("~~~~~~~~~~~~~~~~~~~~~~self.argv.returnScene = "..self.argv.returnScene)
	if self.argv.returnScene == "Activity_GachaPointsLayer" then
		self:replaceScene(ActivityPanelScene)
	elseif self.argv.returnScene == "Activity_GachaXiaoyuLayer" then
		self:replaceScene(ActivityPanelScene,{selectPanelName = "Activity_GachaXiaoyu"})
	elseif self.argv.returnScene == "Activity_ExchangeDailyLayer" then
		self:replaceScene(ActivityPanelScene,{selectPanelName = "Activity_ExchangeDaily"})
	elseif self.argv.returnScene == "ShopScene" then
		self:replaceScene( ShopScene, {params = {tabIndex = TABLEVIEW_TAB_INDEX.CHARGE}} )
	elseif self.argv.returnScene == "DailyTargetScene" then
		DailyTargetScene.gotoDailyTargetScene()
	else -- if self.argv.returnScene == "MainMenuScene" then
		self:replaceScene(MainMenuScene)
	end
end

function GachaScene:doEnterAnimation()
	self:preEnterAnimation()
	self:startEnterAnimation()
end

function GachaScene:doExitAnimation()
	self:preExitAnimation()
	self:startExitAnimation()
end

function GachaScene:startEnterAnimation()
	BaseUIScene.startEnterAnimation(self)

	local function nodeActionFinished()
		self:nodeAnimationFinished()
	end

	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(0.2, ccp(visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(nodeActionFinished))
	self.topMenu:setPositionX(self.topMenu:getPositionX() - visibleSize.width)
	self.topMenu:runAction(CCSequence:create(arr))

	local function showTabEntry()
		if self.showTabHandle then
			CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.showTabHandle)
			self.showTabHandle = nil
		end
		self:showTab(1)
	end
	self.showTabHandle = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(showTabEntry, 0, false)

	local function refresh()
		self:refreshFreeGachaTime()
	end
	self.scheduledRefreshHandle = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(refresh, 1, false)
end

function GachaScene:startExitAnimation()
	BaseUIScene.startExitAnimation(self)

	local function nodeActionFinished()
		self:nodeAnimationFinished()
	end

	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(0.2, ccp(-visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(nodeActionFinished))
	self.topMenu:runAction(CCSequence:create(arr))
	self.mainUI[self.currentTab]:runAction(CCMoveBy:create(0.2, ccp(-visibleSize.width, 0)))
	self.currentTab = 0

	if self.scheduledRefreshHandle then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.scheduledRefreshHandle)
		self.scheduledRefreshHandle = nil
	end
end

function GachaScene:showTab(tabIndex)
	if tabIndex == self.currentTab or tabIndex < 1 or tabIndex > 3 or self.isChangingTab then
		return
	end

	self.isChangingTab = true

	local function changeTab( )
		if self.mainUI[tabIndex] == nil then
			self:createPage(tabIndex)
		end

		local function currentTabFinished()
			self.currentTab = tabIndex
			self.isChangingTab = false
			self.mainUI[tabIndex]:runAction(CCMoveBy:create(0.2, ccp(visibleSize.width, 0)))
			for i = 1, 3 do
				self.tabPicActive[i]:setVisible(i == tabIndex)
				self.tabPicInActive[i]:setVisible(i ~= tabIndex)
			end
			self:refreshActivity()
			self:refreshButton()
			self:refreshFreeGachaTime()
			self:refreshAd()
			self:refreshMaxGachaNum()
			local textBroadcastName = {"txt_show_broadcast_1", "txt_show_broadcast_2", "txt_show_broadcast_3"}
			for i = 1, #textBroadcastName do
				local txt = self.mainUI[tabIndex]:getChildByName(textBroadcastName[i]):getChildByName("txt")
				if self.textBroadcast[i] then
					txt:setString(self.textBroadcast[i]:getString())
				else
					txt:setString("")
				end
				self.textBroadcast[i] = txt
			end
			self:refreshBroadcast()
		end
		if self.mainUI[self.currentTab] then
			local arr = CCArray:create()
			arr:addObject(CCMoveBy:create(0.2, ccp(-visibleSize.width, 0)))
			arr:addObject(CCDelayTime:create(0.1))
			arr:addObject(CCCallFunc:create(currentTabFinished))
			self.mainUI[self.currentTab]:runAction(CCSequence:create(arr))
		else
			currentTabFinished()
		end
	end

	if tabIndex == 2 then
		if self:selectActivity() == GachaActivityEnum.GACHA_BOX then
			local function getGachaBoxInfoSuccessedResponse( evt )
				self.gachaBoxCard = evt.data.gachaBoxCard
				self.gachaSpecialCard = nil
				for k,v in pairs(self.gachaBoxCard) do
					if v.special == true then
						self.gachaSpecialCard = v
					end
				end

				changeTab()
			end

			local function getGachaBoxInfoFailedResponse( evt )
				
			end
			GetSharkGachaBoxInfoRequest.sendRequest(nil , getGachaBoxInfoSuccessedResponse , getGachaBoxInfoFailedResponse)
			return
		elseif self:selectActivity() == GachaActivityEnum.Niu_Dan then

		end
	end
	changeTab()
end

function GachaScene:createPage(tabIndex)
	local uiName = {"scene/scene_high_and_mid", "scene/scene_activity", "scene/scene_friend"}
	if self:selectActivity() == GachaActivityEnum.YELLOW_CRYSTAL then

	elseif self:selectActivity() == GachaActivityEnum.GACHA_BOX then
		uiName = {"scene/scene_high_and_mid", "gacha_activity", "scene/scene_friend"}
	elseif self:selectActivity() == GachaActivityEnum.Niu_Dan then
		uiName = {"scene/scene_high_and_mid", "scene/scene_activity_new", "scene/scene_friend"}
	end
	-- local uiName = {"scene/scene_high_and_mid", "scene/scene_activity", "scene/scene_friend"}
	self.mainUI[tabIndex] = self.uiBuilder:build(uiName[tabIndex])
	self.mainUI[tabIndex]:setPositionX(self.mainUI[tabIndex]:getPositionX() - visibleSize.width)
	self:addChild(self.mainUI[tabIndex])

	local function createGachaButton(name, gachaType, gachaTimes)
		local function onClick()
			self:runGacha(gachaType, gachaTimes)
		end
		local pic = self.mainUI[tabIndex]:getChildByName(name)
		local btn = Button:create(pic)
		btn:addEventListener(Events.kStart, onClick)
		return btn
	end
	if tabIndex == 1 then
		createGachaButton("btn_high_run_1", 3, 1)
		createGachaButton("btn_high_run_10", 3, 10)
		createGachaButton("btn_mid_run_1", 2, 1)
		createGachaButton("btn_mid_run_10", 2, 10)
		self.mainUI[tabIndex]:getChildByName("txt_first_ten_info"):getChildByName("txt"):setString(getTextByKey("gacha_tenTimes_tips"))
		self.progressRp = ProgressBar:create(self.mainUI[tabIndex]:getChildByName("new_gacha_bar_cb"):getChildByName("new_gacha_bar"))
		self.mainUI[tabIndex]:getChildByName("txt_new_gacha1"):setZOrder(999)
		self.mainUI[tabIndex]:getChildByName("txt_new_gacha2"):setZOrder(998)
		self.mainUI[tabIndex]:getChildByName("new_gacha_bar_cb"):setZOrder(997)
	elseif tabIndex == 2 then

		local function yellowCrystalFunc( )
			--add by zheng.che @ 2014-12-1
			if self.mainUI[tabIndex]:getChildByName("sky_btn_qa") then
				--不显示问号
				self.mainUI[tabIndex]:getChildByName("sky_btn_qa"):setVisible(false)
			end
			
			-- createGachaButton("btn_activity_run_1", 4, 1)
			-- createGachaButton("btn_activity_run_10", 4, 10)
			--您当前拥有请柬：
			self.mainUI[tabIndex]:getChildByName("txt_activity_1"):getChildByName("txt"):setString(getTextByKey("gacha_activity_points"))
			--使用{num}个请柬可以参觐一次
			self.mainUI[tabIndex]:getChildByName("txt_activity_3_1"):getChildByName("txt"):setString(getTextByKey("gacha_activity_txt1", {num = self:getGachaCost(5)}))
			--在活动期间普通求将与至尊求将均可获得请柬
			self.mainUI[tabIndex]:getChildByName("txt_activity_3_2"):getChildByName("txt"):setString(getTextByKey("gacha_activity_txt2"))
			--活动结束时间：{year}年{month}月{day}日{time}
			local actNode = self:getActivityConfigNode()
			if actNode then
				local timeTable = MaintenanceManager:getStartAndEndTime(actNode.activityName)
				self.mainUI[tabIndex]:getChildByName("txt_activity_3_3"):getChildByName("txt"):setString(getTextByKey("gacha_activity_txt3", {year = timeTable[2].year, month = timeTable[2].month, day = timeTable[2].day, time = timeTable[2].time}))
			end
			--活动结束后女王会离开，请柬也将失效。
			self.mainUI[tabIndex]:getChildByName("txt_activity_3_4"):getChildByName("txt"):setString(getTextByKey("gacha_activity_txt4"))
			--参觐
			self.mainUI[tabIndex]:getChildByName("btn_activity_gacha"):getChildByName("txt"):setString(getTextByKey("gacha_activity_gachaBtn"))
			--放烟花
			self.boomButton = createGachaButton("btn_activity_gacha", 5, 1)
		end

		local function gachaBoxFunc()
			-- 点将台问号按钮没了 谁记得是因为啥去掉的...? 总之现在问题是看不见按钮但可以点击 (那就先允许显示吧 by mia) modified by zheng.che @ 2015-2-6
			-- --add by zheng.che @ 2014-12-1
			-- if self.mainUI[tabIndex]:getChildByName("sky_btn_qa") then
			-- 	--不显示问号
			-- 	self.mainUI[tabIndex]:getChildByName("sky_btn_qa"):setVisible(false)
			-- end
			
			local freshCost = DataManager.GameMetaData.activityGachaBoxConfig.refreshCost[1].amount
			local gachaCost = DataManager.GameMetaData.activityGachaBoxConfig.requisites[1].amount

			local function refreshUI()
				local iconZOrder = nil
				if self.icon then
					iconZOrder = self.icon:getZOrder()
					self.icon:removeFromParentAndCleanup(true)
				end

				local params = {sourceSizes = {130,130}}
				-- params.sourceDisplay = self.mainUI[tabIndex]:getChildByName("normal_card_small")
				params.showInCenter = true
				self.icon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, self.gachaSpecialCard.cardId, 0, params)
				self.icon:setPosition(ccp(self.mainUI[tabIndex]:getChildByName("normal_card_small"):getPositionX() + 130 / 2,
					self.mainUI[tabIndex]:getChildByName("normal_card_small"):getPositionY() - 130 / 2))
				if iconZOrder then
					self.mainUI[tabIndex]:addChildAt(self.icon , iconZOrder)
				else
					self.mainUI[tabIndex]:addChild(self.icon)
				end

				local function onClickIconButton(evt)
					CanonGoodIcon.popoutGoodPanel(ResourceEnum.CARD, self.gachaSpecialCard.cardId)
				end
				self.iconButton = Button:create(self.icon)
				self.iconButton:addEventListener(Events.kStart, onClickIconButton)

				local specialCardName = CanonGoodIcon.getGoodName(ResourceEnum.CARD, self.gachaSpecialCard.cardId, 0, {withoutAmount = true})
				self.mainUI[tabIndex]:getChildByName("txt_gacha_activity1"):getChildByName("txt"):setString(specialCardName)
				self.mainUI[tabIndex]:getChildByName("txt_gacha_activity6"):setZOrder(999)
				if self.gachaSpecialCard.cardStatus then
					self.mainUI[tabIndex]:getChildByName("btn_need_gem_dianjiang2"):getChildByName("txt_gacha_activity8"):getChildByName("txt"):setVisible(true)
					self.mainUI[tabIndex]:getChildByName("btn_need_gem_dianjiang2"):getChildByName("txt_gacha_activity7"):getChildByName("txt"):setVisible(false)
					self.mainUI[tabIndex]:getChildByName("btn_need_gem_dianjiang2"):getChildByName("gacha_icon_cionEvent_sb"):setVisible(false)
					self.mainUI[tabIndex]:getChildByName("txt_gacha_activity5"):getChildByName("txt"):setString(getTextByKey("boxGacha_tips2"))
				else
					self.mainUI[tabIndex]:getChildByName("btn_need_gem_dianjiang2"):getChildByName("txt_gacha_activity8"):getChildByName("txt"):setVisible(false)
					self.mainUI[tabIndex]:getChildByName("btn_need_gem_dianjiang2"):getChildByName("txt_gacha_activity7"):getChildByName("txt"):setVisible(true)
					self.mainUI[tabIndex]:getChildByName("btn_need_gem_dianjiang2"):getChildByName("gacha_icon_cionEvent_sb"):setVisible(true)
					-- self.mainUI[tabIndex]:getChildByName("btn_need_gem_dianjiang2"):getChildByName("txt_gacha_activity7"):getChildByName("txt"):setString(Localization:getInstance():getText("boxGacha_refreshBtn", {gold = freshCost}))
					self.mainUI[tabIndex]:getChildByName("txt_gacha_activity5"):getChildByName("txt"):setString(getTextByKey("boxGacha_tips1"))
				end

			end

			local function refreshUI2()
				if self.gachaSpecialCard.cardStatus then
					self.backLayer:setVisible(true)
					self.iconButton:setEnable(false)
				else
					self.backLayer:setVisible(false)
					self.iconButton:setEnable(true)
				end


				self.mainUI[tabIndex]:getChildByName("txt_gacha_activity4"):getChildByName("txt"):setString("/"..tostring(#self.gachaBoxCard))
				local recievedCardsCount = 0
				for k,v in pairs(self.gachaBoxCard) do
					if v.cardStatus then
						recievedCardsCount = recievedCardsCount + 1
					end
				end
				self.recievedCount = recievedCardsCount
				self.mainUI[tabIndex]:getChildByName("txt_gacha_activity3"):getChildByName("txt"):setString(tostring(recievedCardsCount))
			end  
			-- self.mainUI[tabIndex]:getChildByName("normal_card_small"):setVisible(false)
			-- Localization:getInstance():getText("boxGacha_gachaBtn", {gola = gachaCost})
			self.mainUI[tabIndex]:getChildByName("txt_gacha_activity2"):getChildByName("txt"):setString(getTextByKey("boxGacha_text1")..getTextByKey("boxGacha_text2"))
			self.mainUI[tabIndex]:getChildByName("btn_need_gem_dianjiang"):getChildByName("txt_gacha_activity7"):getChildByName("txt"):setString(Localization:getInstance():getText("boxGacha_gachaBtn", {gold = gachaCost}))
			self.mainUI[tabIndex]:getChildByName("btn_need_gem_dianjiang2"):getChildByName("txt_gacha_activity8"):getChildByName("txt"):setString(getTextByKey("boxGacha_freeRefreshBtn"))
			self.mainUI[tabIndex]:getChildByName("btn_need_gem_dianjiang2"):getChildByName("txt_gacha_activity7"):getChildByName("txt"):setString(Localization:getInstance():getText("boxGacha_refreshBtn", {gold = freshCost}))
			refreshUI()

			local sourceDisplay = self.mainUI[tabIndex]:getChildByName("normal_card_small")

			self.backLayer = LayerColor:create()
			self.backLayer:setColor(ccc3( 0, 0, 0 ))
			self.backLayer.refCocosObj:setOpacity( 170 )
			self.backLayer:setContentSize(CCSizeMake( 130, 130 ))
			self.backLayer:setPosition(ccp(sourceDisplay:getPositionX(), sourceDisplay:getPositionY() -130))

			local recievedSpr = Sprite:create("pic/signInIcon_obtain.png")
			recievedSpr:setPosition(ccp(130 / 2,130 / 2 ))
			recievedSpr:setScale(0.9)
			self.backLayer:addChild(recievedSpr)
			self.mainUI[tabIndex]:addChild( self.backLayer )

			-- self.buttonLayer = LayerColor:create()
			-- self.buttonLayer.refCocosObj:setOpacity( 0 )
			
			-- self.buttonLayer:setContentSize(CCSizeMake( sourceDisplay:getGroupBounds().size.width, sourceDisplay:getGroupBounds().size.height ))
			-- self.buttonLayer:setPosition(ccp(sourceDisplay:getPositionX(), sourceDisplay:getPositionY() -sourceDisplay:getGroupBounds().size.height))
			-- self.mainUI[tabIndex]:addChild( self.buttonLayer , 10000)

			self.mainUI[tabIndex]:getChildByName("txt_gacha_activity6"):setZOrder(999)
			local timeTable = MaintenanceManager:getStartAndEndTime("activityBoxGacha")
			self.mainUI[tabIndex]:getChildByName("txt_gacha_activity6"):getChildByName("txt"):setString(getTextByKey("gacha_activity_txt3", {year = timeTable[2].year, month = timeTable[2].month, day = timeTable[2].day, time = timeTable[2].time}))

			local function onShowGachaBoxAttension(evt)
				self.targetInfoPanel = GachaBoxAttensionPanel:create(self)
				PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
			end

			local showGachaBoxAttensionButton = Button:create(self.mainUI[tabIndex]:getChildByName("sky_btn_qa"))
			showGachaBoxAttensionButton:addEventListener(Events.kStart, onShowGachaBoxAttension)

			local function onShowCardBox( evt )
				local aRewardPanel = ShowGachaBoxCardsPanel:create( self, {rewardList = sortGachaBoxCards(self.gachaBoxCard)} )
			    self:addChild(aRewardPanel)
			    aRewardPanel:scaleIn()
			end

			local showCardBoxButton = Button:create(self.mainUI[tabIndex]:getChildByName("icon_miiarycommanders_view"))
			showCardBoxButton:addEventListener(Events.kStart, onShowCardBox)
			
			refreshUI2()

			self.mainUI[tabIndex]:getChildByName("gacha_activity_ad"):setVisible(false)

			local function onGachaButton(evt)
				if self.recievedCount == #self.gachaBoxCard then
					SuspensionLabel:showContent(self, getTextByKey("boxGacha_complete"))
					return
				end
				if BagCalcManager.isFull() then
		    		NewPackageFullPanel:show()
		    		-- CanonMessageBox:Show(getTextByKey("shop_inventoryFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40) 
		    		return
		    	end
				if CalculationManager.calcComplex_getGemsNow() < tonumber(gachaCost) then
		    		local function onReplaceScene()
			          self:setTableViewsEnabled(true)
			          self.targetInfoPanel = nil
			        end
			        local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene})
			        self:addChild(aPanel)
			        aPanel:scaleIn()
			        return
			    end

			    local function gachaCardByBoxSucceedResponse( response )
			    	-- response.data.rewards
			    	for k,v in pairs(self.gachaBoxCard) do
			    		if v.id == response.data.rewards[1].id then
			    			v.cardStatus = true
			    		end
			    	end
			    	local rewardsTable = {}
			    	table.insert(rewardsTable , response.data.rewards[1].reward)
			    	RewardManager:getReward(rewardsTable)
			    	RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -gachaCost})
			    	local function onShowCardFinish()
						local function gachaFunc(gachaType, gachaTimes)
							onGachaButton(nil)
						end
						local panel = GachaResultPanel:create(self, rewardsTable, gachaCost, ResourceEnum.GEMS, 6, 1, gachaFunc, 1, 0, 0)
						PopoutManager:sharedManager():popout(panel, nil, true, false, self)
						refreshUI()
						refreshUI2()
						self:refreshAd()

						if ( not (tonumber(Get_ShareData( "New_User_Guide_Running" ))==1) ) then
							self:refreshBroadcast()
						else
							Set_ShareData( "GachaBroadcast_Request_Running", 0 )
						end
			    	end
			    	--版署 由于增加了非卡牌的奖励 显示武将的时候需要过滤
					local showCardRewards = {}
					for i, v in ipairs(rewardsTable) do
						if v.itemType == ResourceEnum.CARD then
							table.insert(showCardRewards, v)
						end
					end
			    	local panel = GachaShowCardPanel:create(self, showCardRewards, 1, onShowCardFinish, 6)
					PopoutManager:sharedManager():popout(panel, nil, true, false, self)

			    end
			    local function gachaCardByBoxFailedResponse( response )
			    	
			    end
			    GachaCardByBoxRequest.sendRequest(nil , gachaCardByBoxSucceedResponse , gachaCardByBoxFailedResponse)
			end

			local function onRefreshButton( evt )
				local usingGems = (not self.gachaSpecialCard.cardStatus)

			    local function refreshSucceedResponse( response )
			    	local isFreeRefresh = self.gachaSpecialCard.cardStatus
					self.gachaBoxCard = response.data.gachaBoxCard
					self.gachaSpecialCard = nil
					for k,v in pairs(self.gachaBoxCard) do
						if v.special == true then
							self.gachaSpecialCard = v
						end
					end
					if not isFreeRefresh then
						RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -freshCost})
					end

					refreshUI()
					refreshUI2()
					self:refreshAd()
			    end

			    local function refreshFailedResponse( response )
			    	
			    end

				if usingGems and CalculationManager.calcComplex_getGemsNow() >= tonumber(freshCost) then
					function onConfirm()
						local params
					    if self.gachaSpecialCard.cardStatus then
							params = {refreshType = 2}
						else
							params = {refreshType = 1}
						end
					    RefreshGachaBoxRequest.sendRequest(params , refreshSucceedResponse , refreshFailedResponse)
					end
					CanonMessageBox:Show(getTextByKey("boxGacha_refresh_confirmText"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, nil, onConfirm, nil)
					return
				end

				if usingGems and CalculationManager.calcComplex_getGemsNow() < tonumber(freshCost) then
		    		local function onReplaceScene()
			          self:setTableViewsEnabled(true)
			          self.targetInfoPanel = nil
			        end
			        local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene})
			        self:addChild(aPanel)
			        aPanel:scaleIn()
			        return
			    end

			    local params
			    if self.gachaSpecialCard.cardStatus then
					params = {refreshType = 2}
				else
					params = {refreshType = 1}
				end
			    RefreshGachaBoxRequest.sendRequest(params , refreshSucceedResponse , refreshFailedResponse)
			end
			local gachaButton = Button:create(self.mainUI[tabIndex]:getChildByName("btn_need_gem_dianjiang"))
			gachaButton:addEventListener(Events.kStart, onGachaButton)

			local refreshButton = Button:create(self.mainUI[tabIndex]:getChildByName("btn_need_gem_dianjiang2"))
			refreshButton:addEventListener(Events.kStart, onRefreshButton)
		end


		local function niudanFunc()
			--问号按钮处理 add by zheng.che @ 2014-12-1
			if self.mainUI[tabIndex]:getChildByName("sky_btn_qa") then
				local function onQaBtnClick(evt)
					local gachaNode = nil
					for i,v in ipairs(DataManager.GameMetaData.gachaCardConfig.gachaNodes) do
						if v.id == 4 then
							gachaNode = v
							break
						end
					end

					local metaIds = string.split(gachaNode.showCards, ",")
					local cardNames = {}
					for i, v in ipairs(metaIds) do
						table.insert(cardNames, CanonGoodIcon.getGoodName(ResourceEnum.CARD, tonumber(v), 0, {withoutAmount = true}))
					end
					local nameStr = table.join(cardNames, getTextByKey("boxGacha_text3_2"))

					local aInfoPanel = ActivityInfoPanel:create(self, getTextByKey("boxGacha_text3", {names = nameStr}))
					self:addChild(aInfoPanel)
					aInfoPanel:scaleIn()
				end
				local qaButton = Button:create(self.mainUI[tabIndex]:getChildByName("sky_btn_qa"))
				qaButton:addEventListener(Events.kStart, onQaBtnClick, self)
			end

			local winSize = CCDirector:sharedDirector():getWinSize()

			local timeTable = MaintenanceManager:getStartAndEndTime("activityGacha1")
			self.mainUI[tabIndex]:getChildByName("txt_activity_3_5"):getChildByName("txt"):setString(getTextByKey("gacha_activityGacha_time", {year = timeTable[2].year, month = timeTable[2].month, day = timeTable[2].day, time = timeTable[2].time}))
			self.mainUI[tabIndex]:getChildByName("txt_activity_3_1"):getChildByName("txt"):setString(getTextByKey("gacha_activityGacha_desc"))
			
			self.mainUI[tabIndex]:getChildByName("btn_mid_run_1"):getChildByName("txt_money_cost"):getChildByName("txt"):setString(self:getGachaCost(4) .. "  " .. getTextByKey("gacha_times_1"))
			self.mainUI[tabIndex]:getChildByName("btn_mid_run_10"):getChildByName("txt_money_cost"):getChildByName("txt"):setString(Localization:getInstance():getText("gacha_tenPlusOne", {goldNum = self:getGachaCost(4)*10}))

			local midPosX = (winSize.width - 142) / 2
			local iconY = self.mainUI[tabIndex]:getChildByName("txt_activity_3_1"):getPositionY() - 48;
			self.mainUI[tabIndex]:getChildByName("activity_item1"):setPositionXY(midPosX,iconY)
			self.mainUI[tabIndex]:getChildByName("activity_item2"):setPositionXY(midPosX + 220,iconY)
			self.mainUI[tabIndex]:getChildByName("activity_item3"):setPositionXY(midPosX - 220,iconY)

			local gachaNode = nil
			for i,v in ipairs(DataManager.GameMetaData.gachaCardConfig.gachaNodes) do
				if v.id == 4 then
					gachaNode = v
					break
				end
			end

			local metaId = string.split(gachaNode.showCards, ",")
			local params = {sourceSizes = {130,130}}
			for i=1,3 do
				local goodType = ResourceEnum.CARD
				local icon = CanonGoodIcon.createGoodIcon(goodType, tonumber(metaId[i]), 0, params)

				local posX = self.mainUI[tabIndex]:getChildByName("activity_item"..i):getChildByName("normal_card_small"):getPositionX() + 130 / 2
				local posY = self.mainUI[tabIndex]:getChildByName("activity_item"..i):getChildByName("normal_card_small"):getPositionY() - 130 / 2
				icon:setPositionXY(posX,posY)

				self.mainUI[tabIndex]:getChildByName("activity_item"..i):addChild(icon);

				local goodName = CanonGoodIcon.getGoodName(goodType, tonumber(metaId[i]), 0, {withoutAmount = true})
				self.mainUI[tabIndex]:getChildByName("activity_item"..i):getChildByName("txt_item_name"):getChildByName("txt"):setString(goodName)
				self.mainUI[tabIndex]:getChildByName("activity_item"..i):getChildByName("txt_item_name"):setPositionXY(posX/2 - 52,posY - 74)

				local function onClickIconButton(evt)
					CanonGoodIcon.popoutGoodPanel(ResourceEnum.CARD, evt.target.cardId)
				end

				local iconBtn = Button:create(icon)
				iconBtn.cardId = tonumber(metaId[i])
				iconBtn:addEventListener(Events.kStart, onClickIconButton)
			end

			local function onOneTimeBtn(evt)
				local freeGacha = self.freeGacha[4]
				if freeGacha then
					self:niudanRequest(4,0)
				else
					self:niudanRequest(4,1)
				end
			end

			local function onTenTimeBtn(evt)
				self:niudanRequest(4,10)
			end

			local oneTimeBtn = Button:create(self.mainUI[tabIndex]:getChildByName("btn_mid_run_1"))
			oneTimeBtn:addEventListener(Events.kStart, onOneTimeBtn)

			local tenTimeBtn = Button:create(self.mainUI[tabIndex]:getChildByName("btn_mid_run_10"))
			tenTimeBtn:addEventListener(Events.kStart, onTenTimeBtn)
		end

		if self:selectActivity() == GachaActivityEnum.YELLOW_CRYSTAL then
			yellowCrystalFunc()
		elseif self:selectActivity() == GachaActivityEnum.GACHA_BOX then
			gachaBoxFunc()
		elseif self:selectActivity() == GachaActivityEnum.Niu_Dan then
			niudanFunc()
		end
		
	elseif tabIndex == 3 then
		createGachaButton("btn_friend_run_1", 1, 1)
		createGachaButton("btn_friend_run_10", 1, -1)
		self.btnFriend1X = self.mainUI[tabIndex]:getChildByName("btn_friend_run_1"):getPositionX()
	end
end

function GachaScene:niudanRequest(gachaType,gachaTimes)
	if BagCalcManager.isFull() then
		NewPackageFullPanel:show()
		return
	end

	local function onGachaSucceed( evt )
		if evt.data.free then --如果是免费求将，则用服务器给的数据更新当前时间信息
			local InitData = DataManager.getGameInitData()
			InitData.sharkUserExtend.countdownFreeGachaInfos = evt.data.countdownFreeGachaInfos
			DataManager.setGameInitData(InitData)
			self:refreshFreeGachaTime()
		end
		if #evt.data.rewards >= 10 then
			local InitData = DataManager.getGameInitData()
			local times = InitData.sharkUserExtend.seniorGachaTenTimes or 0
			InitData.sharkUserExtend.seniorGachaTenTimes = times + 1
			DataManager.setGameInitData(InitData)
		end
		RewardManager:getReward(evt.data.rewards)

		if not evt.data.free then
			--RewardManager:getReward({{itemType = ResourceEnum.GEMS, amount = -self:getGachaCost(4)*math.min(10, #evt.data.rewards)}})
			--版署 由于增加了非卡牌的奖励 计算扣金币次数要改(过滤掉卡牌以外的数量)
			local costTimes = 0
			for i, v in ipairs(evt.data.rewards) do
				if v.itemType == ResourceEnum.CARD then
					costTimes = costTimes + 1
				end
			end
			RewardManager:getReward({{itemType = ResourceEnum.GEMS, amount = -self:getGachaCost(4)*math.min(10, costTimes)}})
		end

		local gachaNode = nil
		if DataManager.GameMetaData.gachaCardConfig then
			for i,v in ipairs(DataManager.GameMetaData.gachaCardConfig.gachaNodes) do
				if v.id == 4 then
					gachaNode = v
					break
				end
			end
		end

		local function onShowCardFinish()
			if #evt.data.rewards > 0 then
				local gachaTimes = #evt.data.rewards
				local nextTime = math.min(10, gachaTimes)
				local function gachaFunc(gachaType, gachaTimes)
					self:niudanRequest(gachaType,gachaTimes)
				end

				local panel = GachaResultPanel:create(self, evt.data.rewards, self:getGachaCost(4), ResourceEnum.GEMS, 4, #evt.data.rewards, gachaFunc, nextTime, 0, 0)
				PopoutManager:sharedManager():popout(panel, nil, true, false, self)
			end
			self:refreshButton()
			self:refreshAd()
			if ( not (tonumber(Get_ShareData( "New_User_Guide_Running" ))==1) ) then
				self:refreshBroadcast()
			else
				Set_ShareData( "GachaBroadcast_Request_Running", 0 )
			end
			Set_ShareData( "Run_Gacha_Animation", 1 )
		end

    	--版署 由于增加了非卡牌的奖励 显示武将的时候需要过滤
		local showCardRewards = {}
		for i, v in ipairs(evt.data.rewards) do
			if v.itemType == ResourceEnum.CARD then
				table.insert(showCardRewards, v)
			end
		end
		if #showCardRewards > 0 then
			local panel = GachaShowCardPanel:create(self, showCardRewards, 1, onShowCardFinish, 4)
			PopoutManager:sharedManager():popout(panel, nil, true, false, self)
		else
			onShowCardFinish()
		end
	end

	local function onGachaFailed( e )
		--print(table.tostring(e.data))
		if e.data == 710513 then
			local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
			self:addChild(aPanel)
			aPanel:scaleIn()
		elseif e.data == 712901 or e.data == 712902 then --在前端已作判断，此处仅作为错误预防
			CanonMessageBox:Show( getTextByKey("gacha_vipLevelInsufficient")
				, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
		elseif e.data == 710516 then --在前端已作判断，此处仅作为错误预防
			NewPackageFullPanel:show()
			-- CanonMessageBox:Show( getTextByKey("gacha_inventoryFull")
			-- 	, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
		elseif e.data == 712203 then --在前端已作判断，此处仅作为错误预防
			CanonMessageBox:Show( getTextByKey("gacha_friendshipPointInsufficient")
				, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
		elseif e.data == 712201 then --在前端已作判断，此处仅作为错误预防
			CanonMessageBox:showCommUnHandleErrorBox( e.data )
		elseif e.data == 712202 then --在前端已作判断，此处仅作为错误预防
			CanonMessageBox:showCommUnHandleErrorBox( e.data )
		elseif e.data == 712204 then
			CanonMessageBox:Show( getTextByKey("gacha_activityDisabled") --在前端已作判断，此处仅作为错误预防
				, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
		elseif self.freeGacha[4] then --免费求将还有其它的
			if e.data == 712205 then
				CanonMessageBox:Show( "不能免费！" --在前端已作判断，此处仅作为错误预防
					, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
			elseif e.data == 712206 then
				CanonMessageBox:Show( "还没到免费的时间！" --在前端已作判断，此处仅作为错误预防
					, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
			end
		end
	end

	local params = {gachaId = gachaType , time = gachaTimes}
	if gachaTimes == 0 then
		local params = {gachaId = gachaType}
		local request = GachaCardFreeRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(RequestNotifyEnum.GachaCardFreeSucceed, onGachaSucceed)
		request:addEventListener(RequestNotifyEnum.GachaCardFreeFailed, onGachaFailed)
		request:start()
	else
		local request = GachaCardRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(RequestNotifyEnum.GachaCardSucceed, onGachaSucceed)
		request:addEventListener(RequestNotifyEnum.GachaCardFailed, onGachaFailed)
		request:start()
	end
end

function GachaScene:refreshActivity()
	self.showActivity = self:selectActivity()
	-- self.showActivity = self.gachaConfig[5] and MaintenanceManager.isActivityOpen(self.gachaConfig[5].activityName)
	if self.showActivity then
		self.tabPicActive[2]:setVisible(self.currentTab == 2)
		self.tabPicInActive[2]:setVisible(self.currentTab ~= 2)
		self.tabPicActive[3]:setPositionX(self.tab3ActiveX)
		self.tabPicInActive[3]:setPositionX(self.tab3InActiveX)
		if not self.activityParticle then
			self.activityParticle = ParticleManager.geneParticle(ParticlePathConstants.FxStarline, ccp(self.tabPicActive[2]:getPositionX() + 3, self.tabPicActive[2]:getPositionY()), 1, 1000, self.topMenu)
			self.activityParticle.refCocosObj:setPositionType(kCCPositionTypeRelative);
			ParticleManager.moveParticle(self.activityParticle, 0.7, {ccp(169, 0), ccp(24, -53), ccp(-169, 0), ccp(-24, 53)})
		end
	else
		self.tabPicActive[2]:setVisible(false)
		self.tabPicInActive[2]:setVisible(false)
		self.tabPicActive[3]:setPositionX(self.tabPicActive[2]:getPositionX())
		self.tabPicInActive[3]:setPositionX(self.tabPicInActive[2]:getPositionX())
		if self.activityParticle then
			self.activityParticle:removeFromParentAndCleanup(true)
			self.activityParticle = nil
		end
	end
end

function GachaScene:refreshBroadcast()
	local function GetBroadcastSucceed()
		local msg = EventManager:sharedManager():getThreeGachaBroadcast()
		for i=1,3 do
			if self.textBroadcast[i] and not self.textBroadcast[i].isDisposed and msg[i] then
				self.textBroadcast[i]:setString(msg[i])
			end
		end
		Set_ShareData("GachaBroadcast_Request_Running", 0)
	end
	local function GetBroadcastFailed()
		Set_ShareData("GachaBroadcast_Request_Running", 0)
	end
	Set_ShareData("GachaBroadcast_Request_Running", 1)
	local request = GetGachaBroadcastRequest.new(nil, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.GetGachaBroadcastSucceed, GetBroadcastSucceed)
	request:addEventListener(RequestNotifyEnum.GetGachaBroadcastFailed, GetBroadcastFailed)
	request:start()
end

function GachaScene:refreshButton()
	if not self.mainUI[self.currentTab] then
		return
	end
	local function refreshSingleButton(childName, text)
		local txt = self.mainUI[self.currentTab]:getChildByName(childName):getChildByName("txt_money_cost")
		txt:getChildByName("txt"):setString(text)
	end
	if self.currentTab == 1 then
		refreshSingleButton("btn_high_run_1", self:getGachaCost(3) .. "  " .. getTextByKey("gacha_times_1"))
		refreshSingleButton("btn_high_run_10", Localization:getInstance():getText("gacha_tenPlusOne", {goldNum = self:getGachaCost(3)*10}))
		refreshSingleButton("btn_mid_run_1", self:getGachaCost(2) .. "  " .. getTextByKey("gacha_times_1"), "Pic_High_Run_1_txt_money_cost")
		refreshSingleButton("btn_mid_run_10", Localization:getInstance():getText("gacha_tenPlusOne", {goldNum = self:getGachaCost(2)*10}), "gacha_times_1")
		local tenTimes = DataManager.getGameInitData().sharkUserExtend.seniorGachaTenTimes or 0
		self.mainUI[self.currentTab]:getChildByName("txt_first_ten_info"):setVisible(tenTimes < 1)

		local rpValue = 0
		local rpTimes = 0
		local rpInfo = DataManager.getGameInitData().sharkGachaInfo
		if rpInfo then
			rpValue = rpInfo.rpValue
			rpTimes = rpInfo.rpGachaTimes
		end
		local nextRp = 0
		if MetaManager.rp_gacha then
			for i,v in ipairs(MetaManager.rp_gacha) do
				if v.rpGachaTimesMin <= rpTimes and (v.rpGachaTimesMax >= rpTimes or v.rpGachaTimesMax < 0) then
					nextRp = v.rpPointsNeeded
					break
				end
			end
		end
		local light = self.mainUI[self.currentTab]:getChildByName("new_gacha_bar_cb"):getChildByName("btn_light")
		if rpValue >= nextRp then
			self.mainUI[self.currentTab]:getChildByName("txt_new_gacha1"):getChildByName("txt"):setString(getTextByKey("gacha_rpFull_text"))

			light:setVisible(true)
			light:setOpacity(0)
			local fadein = CCFadeIn:create(0.6)
			light:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(fadein, fadein:reverse())))
		else
			self.mainUI[self.currentTab]:getChildByName("txt_new_gacha1"):getChildByName("txt"):setString(getTextByKey("gacha_rpNotFull_text"))
			light:setVisible(false)
		end
		self.mainUI[self.currentTab]:getChildByName("txt_new_gacha2"):getChildByName("txt"):setString(rpValue .. "/" .. nextRp)
		self.progressRp:setPercentage(math.min(100, 100 * rpValue / nextRp))
	elseif self.currentTab == 2 then
		-- refreshSingleButton("btn_activity_run_1", self:getGachaCost(4) .. "  " .. getTextByKey("gacha_times_1"))
		-- refreshSingleButton("btn_activity_run_10", self:getGachaCost(4)*10 .. "  " .. getTextByKey("gacha_times_10"))
	elseif self.currentTab == 3 then
		refreshSingleButton("btn_friend_run_1", self:getGachaCost(1) .. "  " .. getTextByKey("gacha_times_1"))
		local friendPoint = DataManager.getGameInitData().sharkUserExtend.friendPoint or 0
		local maxCount = math.max(0, math.min(10, math.floor(friendPoint / self:getGachaCost(1))))
		self.mainUI[self.currentTab]:getChildByName("txt_Not_Enough_Friends_Points"):getChildByName( "txt" ):setString(getTextByKey("gacha_friendshipPointInsufficient"))
		self.mainUI[self.currentTab]:getChildByName("txt_friend_point"):getChildByName( "txt" ):setString(getTextByKey("gacha_friendPointNum") .. friendPoint) --"您当前拥有的友情点："
		self.mainUI[self.currentTab]:getChildByName("txt_howtogetpoint"):getChildByName( "txt" ):setString(getTextByKey("gacha_friend_txt1") .. "\n" .. getTextByKey("gacha_friend_txt3"))--萌阳:去掉一段文字(gacha_friend_txt2) modified by zheng.che @ 2014-12-10
		self.mainUI[self.currentTab]:getChildByName("btn_friend_run_1"):setVisible(maxCount > 0 and self.showButton)
		self.mainUI[self.currentTab]:getChildByName("btn_friend_run_1"):setPositionX(maxCount > 1 and self.btnFriend1X or 235)
		self.mainUI[self.currentTab]:getChildByName("btn_friend_run_10"):setVisible(maxCount > 1 and self.showButton)
		self.mainUI[self.currentTab]:getChildByName("txt_Not_Enough_Friends_Points"):setVisible(maxCount <= 0)
		if maxCount > 1 then
			self.mainUI[self.currentTab]:getChildByName("btn_friend_run_1"):setVisible(self.showButton)
			self.mainUI[self.currentTab]:getChildByName("btn_friend_run_1"):setPositionX(self.btnFriend1X)
			self.mainUI[self.currentTab]:getChildByName("btn_friend_run_10"):setVisible(self.showButton)
			self.mainUI[self.currentTab]:getChildByName("txt_Not_Enough_Friends_Points"):setVisible(false)
			local textKey = {"gacha_times_1", "gacha_times_2", "gacha_times_3", "gacha_times_4", "gacha_times_5", "gacha_times_6", "gacha_times_7", "gacha_times_8", "gacha_times_9", "gacha_times_10"}
			refreshSingleButton("btn_friend_run_10", self:getGachaCost(1)*maxCount .. "  " .. getTextByKey(textKey[maxCount]))
		end
	end
end

function GachaScene:refreshFreeGachaTime()
	if self.isDisposed or not self.mainUI[self.currentTab] then
		return
	end
	local function refreshType(gachaType, txtName, btnName)
		self.freeGacha[gachaType] = false
		self.mainUI[self.currentTab]:getChildByName(txtName):getChildByName("txt"):setString("")
		local lastTime = self:getLastFreeGachaTime(gachaType) or 0;
		if lastTime then
			local btn = self.mainUI[self.currentTab]:getChildByName(btnName)
			local leftTime = lastTime + self.gachaConfig[gachaType].countdownDuration - TimeUtil.getServerTimeSeconds()
			if leftTime <= 0 then
				self.freeGacha[gachaType] = true
				self.mainUI[self.currentTab]:getChildByName(txtName):getChildByName("txt"):setString(getTextByKey("gacha_freeTip"))
				if btn.picBtnFree == nil then
					btn.picBtnFree = self.uiBuilder:build("btn/btn_free_of_charge")
					btn.picBtnFree:getChildByName("txt_free_of_charge"):getChildByName("txt"):setString(getTextByKey("gacha_freeBtn"))
					btn:addChild(btn.picBtnFree)
				end
			else
				leftTime = math.floor(leftTime)
				local timeString = string.format("%02d:%02d:%02d", math.floor(leftTime/3600), math.floor(leftTime/60)%60, leftTime%60)
				self.mainUI[self.currentTab]:getChildByName(txtName):getChildByName("txt"):setString(Localization:getInstance():getText("gacha_countdown", { timeNum = timeString}))
				if btn.picBtnFree then
					btn:removeChild(btn.picBtnFree)
					btn.picBtnFree = nil
				end
			end
		end
	end
	if self.currentTab == 1 then
		refreshType(3, "txt_Show_Time_Info_High", "btn_high_run_1")
		refreshType(2, "txt_Show_Time_Info_Mid", "btn_mid_run_1")
		Set_ShareData("HighGacha_Whether_Can_Free", self.freeGacha[3] and 1 or 0)
	elseif self.currentTab == 2 then
		if self:selectActivity() == GachaActivityEnum.Niu_Dan then
			refreshType(4, "txt_Show_Time_Info_High", "btn_mid_run_1")
		end
	elseif self.currentTab == 3 then
		-- 友情现在没有倒计时了
		-- refreshType(1, "txt_Show_Time_Info_Friend", "btn_friend_run_1")
	end
end

function GachaScene:refreshMaxGachaNum()
	if not self.mainUI[self.currentTab] then
		return
	end
	local function setAdMaxGachaNum(pic, pos, num)
		if pic.labelMaxGacha then
			pic.labelMaxGacha:setString(tostring(num))
		else
			local newLabel = ArtLabelTTF:create(tostring(num))
			newLabel:setCenterColor(ccc3(255,255,255))
			newLabel:setAroundColor(ccc3(0,0,0))
			newLabel:setSize(40)
			newLabel:setTextAnchorPoint(ccp(0.5,0.5))
			newLabel:setPosition(pos)
			newLabel:construct()
			pic:addChild(CocosObject.new(newLabel))
		end
	end
	if self.currentTab == 1 then
		-- local gems = CalculationManager.calcComplex_getGemsNow()
		-- if self.AdSprite[1][1] then
			-- local num = self:getGachaCost(3) > 0 and math.max(0, math.min(9999, math.floor(gems / self:getGachaCost(3)))) or 0
			-- setAdMaxGachaNum(self.AdSprite[1][1], ccp(629, 29), num)
		-- end
		-- if self.AdSprite[1][2] then
			-- local num = self:getGachaCost(2) > 0 and math.max(0, math.min(9999, math.floor(gems / self:getGachaCost(2)))) or 0
			-- setAdMaxGachaNum(self.AdSprite[1][2], ccp(629, 29), num)
		-- end
	elseif self.currentTab == 2 then
		local function yellowCrystalFunc()
			--当前拥有积分数量
			local point = 0
			--活动时间不符 说明此时后端已经清零
			local actNode = self:getActivityConfigNode()
			if actNode then
				local gachaBeginTime = MaintenanceManager:getStartAndEndTime(actNode.activityName)[1].activityBeginTimeStamp
				local gameInitData = DataManager.getGameInitData()
				if gameInitData.sharkActivity and gameInitData.sharkActivity.activityGachaInfo and gameInitData.sharkActivity.activityGachaInfo.featureBeginSeconds == gachaBeginTime then
					point = gameInitData.sharkActivity.activityGachaInfo.point
				end
			end
			self.mainUI[self.currentTab]:getChildByName("txt_activity_2"):getChildByName( "txt" ):setString(tostring(point))
			--当前次数
			local costAmount = self:getGachaCost(5)
			local num = costAmount > 0 and math.max(0, math.min(9999, math.floor(point / costAmount))) or 0
			self.maxActivityTimes = num
			if self.AdSprite[2][1] then
				setAdMaxGachaNum(self.AdSprite[2][1], ccp(629, 35), num)
			end
			self.mainUI[self.currentTab]:getChildByName("txt_activity_v"):getChildByName( "txt" ):setString(tostring(num))
			if num == 0 then
				--没有剩余次数了 禁用按钮
				self.mainUI[self.currentTab]:getChildByName("btn_activity_gacha"):getChildByName( "btn" ):setVisible(false)
				self.mainUI[self.currentTab]:getChildByName("btn_activity_gacha"):getChildByName( "btn_inactive" ):setVisible(self.showButton)
				self.boomButton:setEnable(false)
			else
				--还可以求将
				self.mainUI[self.currentTab]:getChildByName("btn_activity_gacha"):getChildByName( "btn" ):setVisible(self.showButton)
				self.mainUI[self.currentTab]:getChildByName("btn_activity_gacha"):getChildByName( "btn_inactive" ):setVisible(false)
				self.boomButton:setEnable(true)
			end
		end

		if self:selectActivity() == GachaActivityEnum.YELLOW_CRYSTAL then
			yellowCrystalFunc()
		elseif self:selectActivity() == GachaActivityEnum.GACHA_BOX then

		elseif self:selectActivity() == GachaActivityEnum.Niu_Dan then

		end
		
	elseif self.currentTab == 3 then
		local friendpoint = DataManager.getGameInitData().sharkUserExtend.friendPoint or 0
		local num = self:getGachaCost(1) > 0 and math.max(0, math.min(9999, math.floor(friendpoint / self:getGachaCost(1)))) or 0
		self.maxFriendTimes = math.min(10, num)
		if self.AdSprite[3][1] then
			setAdMaxGachaNum(self.AdSprite[3][1], ccp(629, 35), num)
		end
	end
end

function GachaScene:refreshAd()
	if not self.mainUI[self.currentTab] then
		return
	end
	local function loadAd(id, index, posY,tabIndex)
		local function LoadAdCallback(event, data, param)
			if not self or not self.refCocosObj or not self.mainUI or not self.mainUI[param] then
				return;
			end

			if event == ResCallbackEvent.onSuccess and self.mainUI[param] and self.AdSprite[param] then
				if self.AdSprite[param][index] then
					self.mainUI[param]:removeChild(self.AdSprite[param][index])
					self.AdSprite[param][index] = nil
				end
				local AdSprite = Sprite:create(data.realPath)
				AdSprite:setAnchorPoint(ccp(0.5,1))
				AdSprite:setPosition(ccp(visibleSize.width/2, posY))
				self.mainUI[param]:addChild(AdSprite)
				self.AdSprite[param][index] = AdSprite
				self:refreshMaxGachaNum()
			end
		end
		ResourceLoader.loadThirdPartyRes({MetaManager.getAdPictureById(id).url}, LoadAdCallback, tabIndex)
	end
	if self.currentTab == 1 then
		local gachaTimes = DataManager.getGameInitData().sharkUserExtend.seniorGachaTenTimes or 0
		if gachaTimes > 0 then
			loadAd("advacedGacha_1", 1, 946, 1)
		else
			loadAd("advacedGacha_2", 1, 946, 1)
		end
		loadAd("normalGacha_1", 2, 585 , 1)
	elseif self.currentTab == 2 then
		if self:selectActivity() == GachaActivityEnum.YELLOW_CRYSTAL then
			loadAd("activityGacha_1", 1, 946, 2)
		elseif self:selectActivity() == GachaActivityEnum.GACHA_BOX then
			loadAd("boxGacha", 1, 946, 2)
		elseif self:selectActivity() == GachaActivityEnum.Niu_Dan then
			loadAd("activityGacha_2", 1, 946, 2)
		end
	elseif self.currentTab == 3 then
		loadAd("friendGacha_1", 1, 946, 3)
	end
end

function GachaScene.preloadAd() -- static
	if GachaScene.preloadedAd then
		return
	end
	GachaScene.preloadedAd = true
	local AdId = {"advacedGacha_1", "advacedGacha_2", "normalGacha_1", "activityGacha_1", "friendGacha_1" , "boxGacha" , "activityGacha_2"}
	for i = 1, #AdId do
		ResourceLoader.loadThirdPartyRes({MetaManager.getAdPictureById(AdId[i]).url}, function() end)
	end
end

function GachaScene:getGachaCost(gachaType)
	if gachaType == 5 then
		local actNode = self:getActivityConfigNode()
		if actNode then
			return tonumber(actNode.requisites[1].amount), ResourceEnum.GACHA_POINT
		end
		return 0
	end

	if not self.gachaConfig[gachaType] then
		return
	end
	local costType = nil
	if gachaType == 2 or gachaType == 3 or gachaType == 4 then
		costType = ResourceEnum.GEMS
	elseif gachaType == 1 then
		costType = ResourceEnum.FRIENDPOINT
	end
	return self.gachaConfig[gachaType].requisites.requisite.amount, costType
end

function GachaScene:getActivityConfigNode()
	if DataManager.GameMetaData.gachaCardConfig == nil then
		return nil
	end
	local gachaNodes = DataManager.GameMetaData.gachaCardConfig.gachaNodes
	for _, gachaNode in ipairs(gachaNodes) do
		if gachaNode.id == 5 then
			return gachaNode
		end
	end
end

function GachaScene:getLastFreeGachaTime(gachaType)
	if self.gachaConfig[gachaType] and self.gachaConfig[gachaType].countdownFree then
		local info = DataManager.getGameInitData().sharkUserExtend.countdownFreeGachaInfos
		if info then
			for k,v in pairs(info) do
				if tonumber(v.gachaNodeId) == gachaType then
					return tonumber(v.latestFreeGachaTime)
				end
			end
		end
		return 0
    end
	return nil
end

function GachaScene:runGacha(gachaType, gachaTimes)
	if gachaType == 1 and gachaTimes == -1 then
		gachaTimes = self.maxFriendTimes
	end
	local freeGacha = gachaTimes == 1 and self.freeGacha[gachaType]
	--十连抽，判断是否是VIP用户
	if gachaTimes == 10 and (gachaType == 3 or gachaType == 2) then
		local unlockType = gachaType == 3 and 2 or 1
		local minLevel = 999999
		for k,vsetting in pairs(MetaManager.vip_setting) do
			local unlockList = vsetting.unlockContents:split(",")
			for k,vtype in pairs(unlockList) do
				if(tonumber(vtype) == unlockType) and vsetting.level < minLevel then
					minLevel = vsetting.level
				end
			end
		end
		if DataManager.getGameInitData().sharkUser.vipLevel < minLevel then
			local panel = VipWarningPanel:create(self, minLevel)
			PopoutManager:sharedManager():popout(panel, kPopoutDir.kScale, true, false, self)
			return
		end
	end
	-- 检查消耗
	local costAmount, costType = self:getGachaCost(gachaType)
	if costType == ResourceEnum.GEMS then -- 消耗金币
		local gems = CalculationManager.calcComplex_getGemsNow()
		if gachaTimes <= 0 or (not(freeGacha) and costAmount * gachaTimes > gems) then
			local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
			self:addChild(aPanel)
			aPanel:scaleIn()
			return
		end
	elseif costType == ResourceEnum.FRIENDPOINT then -- 消耗友情点
		local friendPoint = DataManager.getGameInitData().sharkUserExtend.friendPoint or 0
		if gachaTimes <= 0 or (not(freeGacha) and costAmount * gachaTimes > friendPoint) then
			CanonMessageBox:Show(getTextByKey("gacha_friendshipPointInsufficient"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40)
			return
		end
	end
	--判断背包是否已满
	if BagCalcManager.isFull() then
		NewPackageFullPanel:show()
		-- CanonMessageBox:Show(getTextByKey("gacha_inventoryFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40)
		return
	end

	local function onGachaSucceed(e)
		if Get_ShareData( "New_User_Guide_Running" ) == 1 then --如果正在运行新手引导
			if Get_ShareData( "Gacha_One_Finished" ) == 0 then --如果新手引导正在等待播放动画
				Set_ShareData( "Guide_Save_State", 0 )
				GlobalScene_globalUpdate() --保存“已运行过求将新手引导”的状态
			end
		end
		freeGacha = freeGacha and e.data.free
		if freeGacha then --如果是免费求将，则用服务器给的数据更新当前时间信息
			local InitData = DataManager.getGameInitData()
			InitData.sharkUserExtend.countdownFreeGachaInfos = e.data.countdownFreeGachaInfos
			DataManager.setGameInitData(InitData)
			self:refreshFreeGachaTime()
		end
		if gachaType == 3 and #e.data.rewards >= 10 then --高级求将十连抽
			local InitData = DataManager.getGameInitData()
			local times = InitData.sharkUserExtend.seniorGachaTenTimes or 0
			InitData.sharkUserExtend.seniorGachaTenTimes = times + 1
			DataManager.setGameInitData(InitData)
		end
		RewardManager:getReward(e.data.rewards)
		if not freeGacha then
		 	--版署 由于增加了非卡牌的奖励 计算扣金币次数要改(过滤掉卡牌以外的数量)
			local costTimes = 0
			for i, v in ipairs(e.data.rewards) do
				if v.itemType == ResourceEnum.CARD then
					costTimes = costTimes + 1
				end
			end
			RewardManager:getReward({{itemType = costType, amount = -costAmount*math.min(10, costTimes)}})
		end

		local gachaNode = nil
		if DataManager.GameMetaData.gachaCardConfig then
			for i,v in ipairs(DataManager.GameMetaData.gachaCardConfig.gachaNodes) do
				if v.id == gachaType then
					gachaNode = v
					break
				end
			end
		end
		local gachaPointAdd = 0
		if gachaType ~= 5 and gachaNode and self.gachaConfig[5] and MaintenanceManager.isActivityOpen(self.gachaConfig[5].activityName) then
			gachaPointAdd = #e.data.rewards * gachaNode.pointReward
		end
		-- 人品值
		local gachaRpAdd = 0
		if gachaType == 3 then
			if gachaNode then
				local rewardsNum = 0
				for k,v in pairs(e.data.rewards) do
					if v.itemType == ResourceEnum.CARD then
						rewardsNum = rewardsNum + 1
					end
				end
				gachaRpAdd = rewardsNum * gachaNode.rpReward
			end
			local InitData = DataManager.getGameInitData()
			local rpInfo = InitData.sharkGachaInfo or {rpValue=0, rpGachaTimes=0}
			local nextRp = 0
			if MetaManager.rp_gacha then
				for i,v in ipairs(MetaManager.rp_gacha) do
					if v.rpGachaTimesMin <= rpInfo.rpGachaTimes and (v.rpGachaTimesMax >= rpInfo.rpGachaTimes or v.rpGachaTimesMax < 0) then
						nextRp = v.rpPointsNeeded
						break
					end
				end
			end
			if rpInfo.rpValue >= nextRp then
				for i,v in ipairs(e.data.rewards) do
					if v.itemType == ResourceEnum.CARD then
						if not MetaManager.card_meta[v.metaId] then
							print("card_meta nil! v = " .. tostringRich(v))
						end
						if MetaManager.card_meta[v.metaId].rare == 5 then
							if i > 1 then
								e.data.rewards[1], e.data.rewards[i] = e.data.rewards[i], e.data.rewards[1]
							end
							break
						end
					end
				end
				rpInfo.rpValue = rpInfo.rpValue - nextRp
				rpInfo.rpGachaTimes = rpInfo.rpGachaTimes + 1
			end
			rpInfo.rpValue = rpInfo.rpValue + gachaRpAdd
			InitData.sharkGachaInfo = rpInfo
			DataManager.setGameInitData(InitData)
		end
		local function onShowCardFinish()
			if gachaPointAdd ~= 0 then
				RewardManager:getReward({{itemType = ResourceEnum.GACHA_POINT, amount = gachaPointAdd}})
			end
			if #e.data.rewards > 0 then
				local nextTime = gachaTimes
				if gachaType == 1 and gachaTimes > 1 then
					nextTime = self.maxFriendTimes
				elseif gachaType == 5 and nextTime > self.maxActivityTimes then
					nextTime = self.maxActivityTimes
				end
				local function gachaFunc(gachaType, gachaTimes)
					self:runGacha(gachaType, gachaTimes)
				end
				local panel = GachaResultPanel:create(self, e.data.rewards, costAmount, costType, gachaType, gachaTimes, gachaFunc, nextTime, gachaPointAdd, gachaRpAdd)
				PopoutManager:sharedManager():popout(panel, nil, true, false, self)
			end
			self.showButton = true
			self:refreshButton()
			self:refreshAd()
			if ( not (tonumber(Get_ShareData( "New_User_Guide_Running" ))==1) ) then
				self:refreshBroadcast()
			else
				Set_ShareData( "GachaBroadcast_Request_Running", 0 )
			end
			Set_ShareData( "Run_Gacha_Animation", 1 )
		end
    	--版署 由于增加了非卡牌的奖励 显示武将的时候需要过滤
		local showCardRewards = {}
		for i, v in ipairs(e.data.rewards) do
			if v.itemType == ResourceEnum.CARD then
				table.insert(showCardRewards, v)
			end
		end
		if #showCardRewards > 0 then
			local panel = GachaShowCardPanel:create(self, showCardRewards, 1, onShowCardFinish, gachaType)
			PopoutManager:sharedManager():popout(panel, nil, true, false, self)
		else
			onShowCardFinish()
		end
		self.showButton = false
		self:refreshButton()
		self:refreshMaxGachaNum()
		self.gachaRequesting = false
	end
	local function onGachaFailed(e)
		if e.data == 710513 then
			local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
			self:addChild(aPanel)
			aPanel:scaleIn()
		elseif e.data == 712901 or e.data == 712902 then --在前端已作判断，此处仅作为错误预防
			CanonMessageBox:Show( getTextByKey("gacha_vipLevelInsufficient")
				, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
		elseif e.data == 710516 then --在前端已作判断，此处仅作为错误预防
			NewPackageFullPanel:show()
			-- CanonMessageBox:Show( getTextByKey("gacha_inventoryFull")
			-- 	, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
		elseif e.data == 712203 then --在前端已作判断，此处仅作为错误预防
			CanonMessageBox:Show( getTextByKey("gacha_friendshipPointInsufficient")
				, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
		elseif e.data == 712201 then --在前端已作判断，此处仅作为错误预防
			CanonMessageBox:showCommUnHandleErrorBox( e.data )
		elseif e.data == 712202 then --在前端已作判断，此处仅作为错误预防
			CanonMessageBox:showCommUnHandleErrorBox( e.data )
		elseif e.data == 712204 then
			CanonMessageBox:Show( getTextByKey("gacha_activityDisabled") --在前端已作判断，此处仅作为错误预防
				, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
		elseif freeGacha then --免费求将还有其它的
			if e.data == 712205 then
				CanonMessageBox:Show( "不能免费！" --在前端已作判断，此处仅作为错误预防
					, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
			elseif e.data == 712206 then
				CanonMessageBox:Show( "还没到免费的时间！" --在前端已作判断，此处仅作为错误预防
					, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
			end
		end
		self.gachaRequesting = false
	end

	if self.gachaRequesting then
		return
	end
	self.gachaRequesting = true
	if freeGacha then
		local params = {gachaId = gachaType}
		local request = GachaCardFreeRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(RequestNotifyEnum.GachaCardFreeSucceed, onGachaSucceed)
		request:addEventListener(RequestNotifyEnum.GachaCardFreeFailed, onGachaFailed)
		request:start()
	else
		local params = {gachaId = gachaType, time = gachaTimes}
		local request = GachaCardRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(RequestNotifyEnum.GachaCardSucceed, onGachaSucceed)
		request:addEventListener(RequestNotifyEnum.GachaCardFailed, onGachaFailed)
		request:start()
	end
end
