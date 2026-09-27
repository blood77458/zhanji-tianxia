--------------------------------------------------------------------------------
-- TreasureGachaScene.lua - 宝宝扭蛋
-- author: l1ghtsaber
-- date: 2015-8-3
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

TreasureGachaScene = class(BaseUIScene)

function TreasureGachaScene:ctor()
	self.title = getTextByKey("Treasure_titel_1")
	self.isfree = false
	self.textBroadcast = {}
end

function TreasureGachaScene:dispose()
	if self.scheduledRefreshHandle then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.scheduledRefreshHandle)
		self.scheduledRefreshHandle = nil
	end
	TreasureGachaScene.super.dispose(self)
end

function TreasureGachaScene:create( argv )
    if argv then 
        self.argv = argv 
    else
        self.argv = {enterScene=nil,returnScene=nil,params={}}
    end
    local scene = TreasureGachaScene.new()
    scene:initScene()
    return scene
end

function TreasureGachaScene:onInit()
	BaseUIScene.initBackGround(self)

	self.uiBuilder = LayoutBuilder:createWithContentsOfFile("scene/treasure.json")
	self.uiBuilder.useArtLabelTTF = true
	self.mainUI = self.uiBuilder:build("popup_treasure_bg_1")
	self:addChild(self.mainUI)

	self.mainUI:getChildByName("txt_shuoming_1"):getChildByName("txt"):setString(getTextByKey("Treasure_text_1"))
	self.mainUI:getChildByName("txt_mss"):getChildByName("txt"):setString(getTextByKey("Treasure_gacha_9"))
	
	self.cost = tonumber(DataManager.GameMetaData.treasureGachaConfig.gachaNode.requisites[1].amount)
	self:refreshFreeGachaTime()
	local exCost = self.cost * 10
	self.mainUI:getChildByName("btn_select_chapter_1"):getChildByName("txt"):setString(exCost..getTextByKey("Treasure_titel_3"))
	local btnFree = Button:create(self.mainUI:getChildByName("btn_blue_short_1"))
	local function onClickFreeBtn( evt )
		if self.isfree then 
			self:runGacha(0,1)
		else
			self:runGacha(tonumber(DataManager.GameMetaData.treasureGachaConfig.gachaNode.requisites[1].amount),1)
		end
	end
	btnFree:addEventListener(Events.kStart, onClickFreeBtn)

	local btnTen = Button:create(self.mainUI:getChildByName("btn_select_chapter_1"))
	local function onClickTenBtn( evt )
		self:runGacha(tonumber(DataManager.GameMetaData.treasureGachaConfig.gachaNode.requisites[1].amount) * 10,10)
	end
	btnTen:addEventListener(Events.kStart, onClickTenBtn)

	local btnToBat = Button:create(self.mainUI:getChildByName("icon_therefined"))
	local function onClickBatBtn( evt )
		if DataManager.getCurrUser().level < MetaManager.getGameSettingConfig().sacrificeUnlockLevel then
			SuspensionLabel:showContent(self, Localization:getInstance():getText("module_needLevel", {num = MetaManager.getGameSettingConfig().sacrificeUnlockLevel}))
		else
			local self = evt.context
			self:replaceScene(CardRebirthScene)
		end
	end
	btnToBat:addEventListener(Events.kStart, onClickBatBtn, self)

	for i = 1,7 do 
		self.textBroadcast[i] = self.mainUI:getChildByName("txt_shuomingzong"..i):getChildByName("txt")
	end
	self:refreshBroadcast()
	self:refreshBroadcast()

	BaseUIScene.onInit(self)
end

function TreasureGachaScene:back()
	self:replaceScene(MainMenuScene)
end

function TreasureGachaScene:runGacha(cost, time)
	--计算消耗
	local gems = CalculationManager.calcComplex_getGemsNow()
	local freeGacha = self.isfree and cost == 0
	if  (not freeGacha and cost > gems) then
		local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
		self:addChild(aPanel)
		aPanel:scaleIn()
		return
	end

	--计算背包
	if (TreasureManager.isTreasurePoolFull()) then 
		TreasurePackageFullPanel:show()
		return
	end

 	local function afterGachaTreasure( evt )
 		self.mainUI:getChildByName("cangjinniang"):setVisible(false)

		local LightFilePath = "EVO2/changbaoge"  --标记线 加特技
		local LightFlash = FlashSprite:create(LightFilePath)
		LightFlash:changeAnimation(0)
		LightFlash:setLoop(false)

		local GirlFilePath = "EVO2/changbaoge_0"  --标记线 加特技
		local GirlFlash = FlashSprite:create(GirlFilePath)
		GirlFlash:changeAnimation(0)
		GirlFlash:setLoop(false)		

		local function onLightFinish( anim )
			LightFlash:unregisterEndAnimationScriptHandler()
			self:removeChild(self.LightFlash_co)
			self.tempLayer:removeFromParentAndCleanup(true)
			self.mainUI:getChildByName("cangjinniang"):setVisible(true)
	 		if freeGacha then 
	 			local gameData = DataManager.getGameInitData()
	 			if not gameData.sharkGachaInfo then gameData.sharkGachaInfo = {} end
	 			gameData.sharkGachaInfo.lastFreeTreasureGachaSeconds = TimeUtil.getServerTimeSeconds()
	 			DataManager.setGameInitData( gameData )
	 		end
	 		if cost ~= 0 then
		 		local requisite = {
					amount = tostring(-cost),
					metaId = 0,
					itemType = 2,
					id = 0
				}
				RewardManager:getReward({requisite})
			end
	 		self:refreshFreeGachaTime()
	 		local function gachaFunc(cost, time)
	 			self:runGacha(cost, time)
	 		end
			if time == 1 then 
				local showPanel = TreasureGachaOnePanel:create( self, evt.data.rewards ,gachaFunc)
				PopoutManager:sharedManager():popout(showPanel, nil, true, false, self)
			elseif time == 10 then
				local showPanel = TreasureGachaTenPanel:create( self, evt.data.rewards ,gachaFunc)
				PopoutManager:sharedManager():popout(showPanel, nil, true, false, self)
			end
		end
		LightFlash:registerEndAnimationScriptHandler(onLightFinish)
		self.LightFlash_co = CocosObject.new(LightFlash)
		self:addChild(self.LightFlash_co)

		local function onGirlFinish( anim )
			self.mainUI:removeChild(self.GirlFlash_co)
			GirlFlash:unregisterEndAnimationScriptHandler()
		end
		GirlFlash:registerEndAnimationScriptHandler(onGirlFinish)
		self.GirlFlash_co = CocosObject.new(GirlFlash)
		self.mainUI:addChildAt(self.GirlFlash_co,self.mainUI:getChildByName("bg_treasure_01"):getZOrder() + 1)

		self.tempLayer = Layer:create()
		self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
		local function onTouch(event, x, y)
			if event == CCTOUCHBEGAN then
				return true
			else
				return
			end
		end
		self.tempLayer:registerScriptTouchHandler(onTouch, false, -100, true)
		self.tempLayer:setTouchEnabled(true)
		self:addChild(self.tempLayer)
		self:refreshBroadcast()
 	end
  	GachaTreasureRequest.sendRequestDefalut(time, freeGacha, afterGachaTreasure)
end

function TreasureGachaScene:getLastFreeGachaTime()
	local info = DataManager.getGameInitData().sharkGachaInfo
	if info then
		return tonumber(info.lastFreeTreasureGachaSeconds or 0)
	end
	return nil
end

function TreasureGachaScene:refreshFreeGachaTime()
	self.isfree = false
	local lastTime = self:getLastFreeGachaTime() or 0
	local leftTime = lastTime + DataManager.GameMetaData.treasureGachaConfig.gachaNode.countdownDuration - TimeUtil.getServerTimeSeconds()
	if (leftTime <= 0 or lastTime == 0) then 
		self.isfree = true
		self.mainUI:getChildByName("btn_blue_short_1"):getChildByName("txt"):setString(getTextByKey("Treasure_titel_2"))
		self.mainUI:getChildByName("txt_djs"):setVisible(false)
		self.mainUI:getChildByName("txt_mss"):setVisible(false)
	else
		self.mainUI:getChildByName("btn_blue_short_1"):getChildByName("txt"):setString(getTextByKey("Treasure_gacha_8",{num = self.cost}))
		self.mainUI:getChildByName("txt_djs"):setVisible(true)
		local timeString = string.format("%02d:%02d:%02d", math.floor(leftTime/3600), math.floor(leftTime/60)%60, leftTime%60)
		self.mainUI:getChildByName("txt_djs"):getChildByName("txt"):setString(timeString)
		self.mainUI:getChildByName("txt_mss"):setVisible(true)
	end
end

function TreasureGachaScene:refreshBroadcast()
	local function GetBroadcastSucceed()
		local msg = EventManager:sharedManager():getTreasureGachaBroadcast()
		for i=1,7 do
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

function TreasureGachaScene:doEnterAnimation()
	self:preEnterAnimation()
	self:startEnterAnimation()
end

function TreasureGachaScene:startEnterAnimation()
	BaseUIScene.startEnterAnimation(self)
	local function nodeActionFinished()
		self:nodeAnimationFinished()
	end

	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(0.2, ccp(visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(nodeActionFinished))
	self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
	self.mainUI:runAction(CCSequence:create(arr))

	local function refresh()
		self:refreshFreeGachaTime()
	end
	self.scheduledRefreshHandle = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(refresh, 1, false)
end

function TreasureGachaScene:doExitAnimation()
	self:preExitAnimation()
	self:startExitAnimation()
end

function TreasureGachaScene:startExitAnimation()
	BaseUIScene.startExitAnimation(self)

	local function nodeActionFinished()
		self:nodeAnimationFinished()
	end

	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(0.2, ccp(-visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(nodeActionFinished))
	self.mainUI:runAction(CCSequence:create(arr))

	if self.scheduledRefreshHandle then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.scheduledRefreshHandle)
		self.scheduledRefreshHandle = nil
	end
end