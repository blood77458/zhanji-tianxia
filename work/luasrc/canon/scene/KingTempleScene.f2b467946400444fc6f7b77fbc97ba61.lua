require "canon.scene.BaseUIScene"
require "canon.request.SpiritConcentrateRequest"
require "canon.panel.GetEleSoulPanel"
require "canon.panel.GetTenEleSoulPanel"

KingTempleScene = class(BaseUIScene)
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

function KingTempleScene:ctor()
  self.title = getTextByKey("hallOfChampion_title")
  self.argv = nil
  
  self.mainUI = nil
  self.contentLayer = nil
  self.waitForGetElesoulAnimEnd = false
end

function KingTempleScene:create(argv)
  local scene = KingTempleScene.new()
  
  if(argv) then
    scene.argv = argv
  else 
    scene.argv = {enterScene = nil, returnScene = nil, params = {}}
  end

  scene.ignoreAction = scene.argv.params.ignoreAction
    
  scene:initScene()
  return scene
end

function KingTempleScene:back()
	if self.waitForGetElesoulAnimEnd then
		return
	end

	if self.argv.returnScene and self.argv.returnScene == "DestinyFightChallengeScene" then
		self:replaceScene(DestinyFightChallengeScene)
	else
		self:replaceScene(ChallengeEntersScene, {params = {showPanelName = "destiny"}})
	end
end


function KingTempleScene:refreshUI(destinyData)
	self.destinyData = destinyData
	self.mainUI:getChildByName("txt_destiny_fight2"):getChildByName("txt"):setString(getTextByKey("hallOfChampion_level") .. destinyData.spiritConcentrateLevel)--王者殿堂等级
	
	--记录王者殿堂等级
	local gameInitData = DataManager.getGameInitData()
	local destinyLocalInfo = gameInitData.sharkDestinyInfo
	destinyLocalInfo.spiritConcentrateLevel = destinyData.spiritConcentrateLevel
	DataManager.setGameInitData(gameInitData)
	
	if self.bossCard == nil then
		local guide_other = self.mainUI:getChildByName("full")
		guide_other:setVisible(false)
		self.bossCard = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(destinyData.bossId))
		self.bossCard:setScale(1.3)
		self.bossCard:setPosition(ccp(guide_other:getPositionX() + guide_other:getContentSize().width / 2.0 +70, guide_other:getPositionY() - guide_other:getContentSize().height / 2.0 -50))
		self.mainUI:addChildAt(self.bossCard, 10)
	end
	
	local function buttonLayerSwitch(bool)
		self.spiritBtn:setVisible(bool)
		self.onceSpiritBtn:setVisible(not bool)
		self.tenTimeSpiritBtn:setVisible(not bool)
	end
	local function refreshButtonCostNum()
		local curSpiritTime = destinyData.spiritConcentrateVipNum + 1
		local costList = MetaManager.game_meta.spiritConcentrateCostConfig.spiritConcentrateCostList

		local function countNumByTimes(times)
			local value = 0
			for k,v in pairs (costList) do
				if times >= v.concentrateMin and times <= v.concentrateMax then
					value = v.cost
					break
				elseif v.concentrateMax == -1 then
					--最高等级金币凝神
					value = v.cost
					break
				end
			end
			return value
		end
		self.goldSpiritCost = countNumByTimes(curSpiritTime)
		self.onceSpiritBtn.display:getChildByName("txt"):setString(self.goldSpiritCost .. getTextByKey("hallOfChampion_concentrateBtn"))

		self.tenTimeGoldCost = 0
		for i=1,10 do
			self.tenTimeGoldCost = self.tenTimeGoldCost + countNumByTimes(destinyData.spiritConcentrateVipNum + i)
		end
		self.tenTimeSpiritBtn.display:getChildByName("txt"):setString(self.tenTimeGoldCost .. getTextByKey("spirit_unload_txt3"))
	end
	
	if destinyData.spiritConcentrateTotalNum > destinyData.spiritConcentrateNum then
		--还有免费凝神次数
		self.spiritInfoLabel:setString(getTextByKey("hallOfChampion_freeConcentrateTimes",{ num = (destinyData.spiritConcentrateTotalNum - destinyData.spiritConcentrateNum)}))
		buttonLayerSwitch(true)
	elseif DataManager.getCurrUser().vipLevel >= MetaManager.getGoldSpiritVipLimit() then
		--vip 
		if destinyData.spiritConcentrateVipTotalNum > destinyData.spiritConcentrateVipNum then
			--还有金币凝神次数
			self.spiritInfoLabel:setString(getTextByKey("hallOfChampion_goldConcentrateTimes",{ num = (destinyData.spiritConcentrateVipTotalNum - destinyData.spiritConcentrateVipNum)}))
			
			buttonLayerSwitch(false)
			refreshButtonCostNum()
			if destinyData.spiritConcentrateVipTotalNum < destinyData.spiritConcentrateVipNum + 10 then
				self.unableToTenTime = true
				self.tenTimeSpiritBtn:setEnable(false)
				self.tenTimeSpiritBtn.display:getChildByName("btn"):setVisible(false)
			end
		else
			--今日已无凝神次数
			self.spiritInfoLabel:setString(getTextByKey("spiritConcentrate_used"))
			buttonLayerSwitch(false)
			refreshButtonCostNum()
			self.onceSpiritBtn:setEnable(false)
			self.onceSpiritBtn.display:getChildByName("btn"):setVisible(false)

			self.unableToTenTime = true
			self.tenTimeSpiritBtn:setEnable(false)
			self.tenTimeSpiritBtn.display:getChildByName("btn"):setVisible(false)
		end
	else
		--非vip，已无凝神次数
		self.spiritInfoLabel:setString(getTextByKey("hallOfChampion_goldConcentrateTips",{num = MetaManager.getGoldSpiritVipLimit()}))
		buttonLayerSwitch(false)
		refreshButtonCostNum()
		self.onceSpiritBtn:setEnable(false)
		self.onceSpiritBtn.display:getChildByName("btn"):setVisible(false)

		self.unableToTenTime = true
		self.tenTimeSpiritBtn:setEnable(false)
		self.tenTimeSpiritBtn.display:getChildByName("btn"):setVisible(false)
	end
	
	--facebook share king temple info
	FacebookShareManager.facebookShareKingTemple(destinyLocalInfo.spiritConcentrateLevel)	
end

function KingTempleScene:onInit()
	BaseUIScene.initBackGround(self)
	local builder = LayoutBuilder:createWithContentsOfFile( "scene/destiny_fight.json" )
	builder.useArtLabelTTF = true
	self.mainUI = builder:build("bosshall")
	self:addChild(self.mainUI)
	
	self.spiritInfoLabel = self.mainUI:getChildByName("txt_destiny_fight1"):getChildByName("txt")
	local guide_other = self.mainUI:getChildByName("full")
	guide_other:setVisible(false)
	
	local function onClickSpiritBtn(evt)
		local function runSpirit(isFree)
			local function requestSpirit()
				local function spiritSuccess(e)
					local getElesoulFilePath = "EVO2/getelesoul"
					local getElesoulFlash = FlashSprite:create(getElesoulFilePath)
					getElesoulFlash:changeAnimation(0)
					getElesoulFlash:setLoop(false)
					--openGateFlash:setIsRun(true)
					local function onOpenGateFlashFinish( anim )
						getElesoulFlash:unregisterEndAnimationScriptHandler()
						self:removeChild(self.getElesoulFlash_co)
						self.tempLayer:removeFromParentAndCleanup(true)
						if isFree then
							self.destinyData.spiritConcentrateNum = self.destinyData.spiritConcentrateNum + 1
							local spiritConcentrateNum = DailyDataManager.getDailyDataSpiritConcentrateNum()
							DailyDataManager.setDailyDataSpiritConcentrateNum(spiritConcentrateNum + 1)
						else
							self.destinyData.spiritConcentrateVipNum = self.destinyData.spiritConcentrateVipNum + 1
							RewardManager:getReward({{itemType = ResourceEnum.GEMS, amount = -self.goldSpiritCost}})
							local spiritConcentrateVipNum = DailyDataManager.getDailyDataSpiritConcentrateVipNum()
							DailyDataManager.setDailyDataSpiritConcentrateVipNum(spiritConcentrateVipNum + 1)
						end
						self:refreshUI(self.destinyData)
						--弹出元神面板
						self.targetInfoPanel = GetEleSoulPanel:create( self, e.data.sharkSpirits)
						PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
						--更新前端元神数据
						local spiritData = DataManager.getSpiritsData()
						for k,v in pairs(e.data.sharkSpirits) do
							table.insert(spiritData,v)
						end
						DataManager.setSpiritsData(spiritData)

						self:setTouchEnable(false)
					end
					getElesoulFlash:registerEndAnimationScriptHandler(onOpenGateFlashFinish)

					self.getElesoulFlash_co = CocosObject.new(getElesoulFlash)
					self:addChild(self.getElesoulFlash_co)

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
					
				end
			
				local function spiritFail(e)
					CanonMessageBox:showCommUnHandleErrorBox( e.data )
					self:setTouchEnable(false)
				end
				local params = {type = 1}
				local spiritConcentrateRequest = SpiritConcentrateRequest.new(params, rpc.SendingPriority.kHigh)
				spiritConcentrateRequest:addEventListener(RequestNotifyEnum.SpiritConcentrateSucceed, spiritSuccess)
				spiritConcentrateRequest:addEventListener(RequestNotifyEnum.SpiritConcentrateFailed, spiritFail)
				spiritConcentrateRequest:start()
				self:setTouchEnable(true)
			end
			
			if SpiritManager:isSpiritPoolFull() then
				SpiritPackageFullPanel:show()
				return
			else
				if isFree then
					if not self.waitForGetElesoulAnimEnd then
						requestSpirit()
					end		
				else
					if CalculationManager.calcComplex_getGemsNow() < self.goldSpiritCost then
						local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
						self:addChild(aPanel)
						aPanel:scaleIn()
					else
						if not self.waitForGetElesoulAnimEnd then
							requestSpirit()
						end	
					end
				end
			end
		end
		
		if self.destinyData.spiritConcentrateTotalNum > self.destinyData.spiritConcentrateNum then
			--还有免费凝神次数
				runSpirit(true)
		elseif DataManager.getCurrUser().vipLevel > 0 then
			--vip 
			if self.destinyData.spiritConcentrateVipTotalNum > self.destinyData.spiritConcentrateVipNum then
				--还有金币凝神次数
				runSpirit(false)
			else
				--今日已无凝神次数
				--不做处理，按钮置灰
			end
		else
			--非vip，已无凝神次数
			CanonMessageBox:Show( getTextByKey("spiritConcentrate_used"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
		end
	end
	--凝神按钮
	self.spiritBtn = Button:create(self.mainUI:getChildByName("btn_goup2"))
	self.spiritBtn.display:getChildByName("txt"):setString(getTextByKey("hallOfChampion_concentrateBtn"))
	self.spiritBtn:addEventListener( Events.kStart, onClickSpiritBtn, self ) 
	
	self.onceSpiritBtn = Button:create(self.mainUI:getChildByName("btn_goup"))
	self.onceSpiritBtn:addEventListener( Events.kStart, onClickSpiritBtn, self )

	local function onClickTenSpiritBtn(evt)
		if self.waitForGetElesoulAnimEnd then
			return
		elseif SpiritManager:isSpiritPoolFull() then
			SpiritPackageFullPanel:show()
			return
		elseif CalculationManager.calcComplex_getGemsNow() < self.tenTimeGoldCost then
			local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
			self:addChild(aPanel)
			aPanel:scaleIn()
			return
		end

		local function spiritSuccess(e)
			local getElesoulFilePath = "EVO2/getelesoul"
			local getElesoulFlash = FlashSprite:create(getElesoulFilePath)
			getElesoulFlash:changeAnimation(0)
			getElesoulFlash:setLoop(false)
			local function onOpenGateFlashFinish( anim )
				getElesoulFlash:unregisterEndAnimationScriptHandler()
				self:removeChild(self.getElesoulFlash_co)

				self.destinyData.spiritConcentrateVipNum = self.destinyData.spiritConcentrateVipNum + 10
				RewardManager:getReward({{itemType = ResourceEnum.GEMS, amount = -self.tenTimeGoldCost}})
				local spiritConcentrateVipNum = DailyDataManager.getDailyDataSpiritConcentrateVipNum()
				DailyDataManager.setDailyDataSpiritConcentrateVipNum(spiritConcentrateVipNum + 10)

				self:refreshUI(self.destinyData)

				local onceAgainBtnData = {text = self.tenTimeGoldCost .. getTextByKey("spirit_unload_txt3") , unable = self.unableToTenTime}
				self.targetInfoPanel = GetTenEleSoulPanel:create( self , e.data.sharkSpirits , onceAgainBtnData , onClickTenSpiritBtn)
				PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false ,self)
				--更新前端元神数据
				local spiritData = DataManager.getSpiritsData()
				for k,v in pairs(e.data.sharkSpirits) do
					table.insert(spiritData,v)
				end
				DataManager.setSpiritsData(spiritData)
				self:setTouchEnable(false)
			end
			getElesoulFlash:registerEndAnimationScriptHandler(onOpenGateFlashFinish)
			self.getElesoulFlash_co = CocosObject.new(getElesoulFlash)
			self:addChild(self.getElesoulFlash_co)
		end

		local function spiritFail(e)
			CanonMessageBox:showCommUnHandleErrorBox( e.data )
			self:setTouchEnable(false)
		end

		local params = {type = 2}
		local spiritConcentrateRequest = SpiritConcentrateRequest.new(params, rpc.SendingPriority.kHigh)
		spiritConcentrateRequest:addEventListener(RequestNotifyEnum.SpiritConcentrateSucceed, spiritSuccess)
		spiritConcentrateRequest:addEventListener(RequestNotifyEnum.SpiritConcentrateFailed, spiritFail)
		spiritConcentrateRequest:start()
		self:setTouchEnable(true)
	end

	self.tenTimeSpiritBtn = Button:create(self.mainUI:getChildByName("btn_goup1"))
	self.tenTimeSpiritBtn:addEventListener( Events.kStart, onClickTenSpiritBtn, self )
	
	self.spiritBtn:setVisible(false)
	self.onceSpiritBtn:setVisible(false)
	self.tenTimeSpiritBtn:setVisible(false)
	
	--跳转到宿命对决
	local function onClickGotoDestinyFight(evt)
		self:replaceScene(DestinyFightChallengeScene)
	end
	self.challengeButton = Button:create(self.mainUI:getChildByName("icon_goon"))
	self.challengeButton:addEventListener( Events.kStart, onClickGotoDestinyFight, self ) 
	
	local function onSpiritBackPackBtn(evt)
		local argv = {
			enterScene="KingTempleScene",
			returnScene="KingTempleScene",
			params={}
		}
		self:replaceScene(SpiritBackPackScene , argv)
	end
	local spiritBackPackBtn = Button:create(self.mainUI:getChildByName("icon_elesoul"))
	spiritBackPackBtn:addEventListener( Events.kStart, onSpiritBackPackBtn, self )

	BaseUIScene.onInit(self)
	
	local function onEnter(evt)
		local function getInfoSuccess(e)
			if self.ignoreAction then
		
				local openGatefilePath = "EVO2/opentime"
				local openGateFlash = FlashSprite:create(openGatefilePath)
				openGateFlash:changeAnimation(0)
				openGateFlash:setLoop(false)
				local function onOpenGateFlashFinish( anim )
					openGateFlash:unregisterEndAnimationScriptHandler()
					self:removeChild(self.openGateFlash_co)
					
					self:refreshUI(e.data)
				end
				openGateFlash:registerEndAnimationScriptHandler(onOpenGateFlashFinish)

				self.openGateFlash_co = CocosObject.new(openGateFlash)
				self:addChild(self.openGateFlash_co)
			else
				self:refreshUI(e.data)
			end
			
		end
		
		local function getInfoFail(e)
			CanonMessageBox:showCommUnHandleErrorBox( e.data )
		end
		local params = nil
		local getDestinyInfoRequest = GetDestinyInfoRequest.new(params, rpc.SendingPriority.kHigh)
		getDestinyInfoRequest:addEventListener(RequestNotifyEnum.GetDestinyInfoSucceed, getInfoSuccess)
		getDestinyInfoRequest:addEventListener(RequestNotifyEnum.GetDestinyInfoFailed, getInfoFail)
		getDestinyInfoRequest:start()
		
	end
	self:addEventListener(Events.kAddToStage, onEnter)
end

function KingTempleScene:dispose()
  KingTempleScene.super.dispose(self)
end

function KingTempleScene:doEnterAnimation()
	self:preEnterAnimation()
	--[[
	if self.ignoreAction then
		
		local openGatefilePath = "EVO2/opentime"
		local openGateFlash = FlashSprite:create(openGatefilePath)
		openGateFlash:changeAnimation(0)
		openGateFlash:setLoop(false)
		local function onOpenGateFlashFinish( anim )
			openGateFlash:unregisterEndAnimationScriptHandler()
			self:removeChild(self.openGateFlash_co)
			
			self:startEnterAnimation()
		end
		openGateFlash:registerEndAnimationScriptHandler(onOpenGateFlashFinish)

		self.openGateFlash_co = CocosObject.new(openGateFlash)
		self:addChild(self.openGateFlash_co)
	else
		self:startEnterAnimation()
	end
	-]]
	self:startEnterAnimation()
end

function KingTempleScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
end

function KingTempleScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  if self.ignoreAction then
   --self.ignoreAction = false
   local arr = CCArray:create()
   arr:addObject(CCCallFunc:create(enterActionFinished))
   self.mainUI:runAction(CCSequence:create(arr))
  else
  	 self.mainUI:setPositionX(self.mainUI:getPositionX() + visibleSize.width)
   local arr = CCArray:create()
   arr:addObject(CCMoveBy:create(0.5, ccp(-visibleSize.width, 0)))
   arr:addObject(CCCallFunc:create(enterActionFinished))
   self.mainUI:runAction(CCSequence:create(arr))
  end
end

function KingTempleScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
end

function KingTempleScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function KingTempleScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function KingTempleScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(0.5, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.mainUI:runAction(CCSequence:create(arr))
end

function KingTempleScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function KingTempleScene:setTouchEnable(bool)
	self.waitForGetElesoulAnimEnd = bool
	self.touchEnabled = not bool
  	self.touchChildren = not bool
end