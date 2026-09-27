-- NewBabelSkipPanel.lua
-- zhehua.ou
-- 2014-8-26
-- 通天塔 跳过面板
require "canon.request.SkyTowerSkipBattleRequest"
require "canon.request.SkyTowerSkipGainRewardsRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

------------------------------------------------------------------------------------------------------

NewBabelSkipPanel = class(Layer)

function NewBabelSkipPanel:ctor()
	self.container = nil
	self.content = nil
end

-- style : 1.开始跳过  2.跳过结束领奖
function NewBabelSkipPanel:create( container , style , callbackFunc)
	local s = NewBabelSkipPanel.new()
	s.container = container
	s.style = style
	s.callbackFunc = callbackFunc
	s:initLayer()
	return s
end

function NewBabelSkipPanel:initLayer()
	NewBabelSkipPanel.super.initLayer(self)

	self.pre_container_targetInfoPanel = self.container.targetInfoPanel
	self.container.targetInfoPanel = self
    
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)

    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))

    local builder = LayoutBuilder:createWithContentsOfFile("scene/towerBabel.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_canskip") 
    self.tempLayer:addChild(self.panelUI)

    local function closeBtnAction(evt)
      	self:dismissSelf()
    end
    local closeBtnDisplay = self.panelUI:getChildByName("btn_close_sb")
    local closeBtn = Button:create(closeBtnDisplay)
    closeBtn:addEventListener( Events.kStart, closeBtnAction, self )
    
    local btnDisplay = self.panelUI:getChildByName("btn_buff_chose1")
    local btnInstance = Button:create(btnDisplay)
    if self.style == 1 then
    	closeBtnDisplay:setVisible(true)

    	self.panelUI:getChildByName("txt_towerBabel_rule_title"):getChildByName("txt"):setString(getTextByKey("storyReview_skipButton"))
    	self.panelUI:getChildByName("txt_towerBabel_canskip"):getChildByName("txt"):setString("\n"..getTextByKey("skyTower_passRule1").."\n"..getTextByKey("skyTower_passRule2").."\n"..getTextByKey("skyTower_passRule3"))
    	
    	btnDisplay:getChildByName("txt"):setString(getTextByKey("yes"))
    	local function BeginSkip(evt)
    		self:confirmSkipFunc()
    	end
    	btnInstance:addEventListener(Events.kStart,BeginSkip, self)
    elseif self.style == 2 then
    	closeBtnDisplay:setVisible(false)

    	self.panelUI:getChildByName("txt_towerBabel_rule_title"):getChildByName("txt"):setString(getTextByKey("skyTower_passOver"))
    	local sharkSkyTowerData = DataManager.getSharkSkyTowerData()
    	self.panelUI:getChildByName("txt_towerBabel_canskip"):getChildByName("txt"):setString("\n"..getTextByKey("skyTower_passoverTxt1",{num = sharkSkyTowerData.currStatus.currFloor}).. "\n" .. getTextByKey("skyTower_passoverTxt2"))
    	
    	btnDisplay:getChildByName("txt"):setString(getTextByKey("achieve_task_get"))
    	local function EndSkip(evt)
    		self:getSkipRewards()
    	end
    	btnInstance:addEventListener(Events.kStart,EndSkip, self)
	else
		print("bug")
    end

    self.tempLayer:setScale(0.1)
end

-- 跳过
function NewBabelSkipPanel:confirmSkipFunc()
	local function onSkipSucceed(evt)
		local sharkSkyTowerData = DataManager.getSharkSkyTowerData()
		local targetFloor = DataManager.getSharkSkyTowerNeedAddFloor()
		if targetFloor == 0 then
			targetFloor = sharkSkyTowerData.sharkSkyTower.maxBigWinFloor
		end

		local skipFloorNum = targetFloor - sharkSkyTowerData.currStatus.currFloor
		-- 3 代表最高难度 和 不掉血过关
		local starGained = 3 * 3 * skipFloorNum

		sharkSkyTowerData.currStatus.currTotalStars  = sharkSkyTowerData.currStatus.currTotalStars + starGained
		sharkSkyTowerData.currStatus.beginSkipFloor = sharkSkyTowerData.currStatus.currFloor
		sharkSkyTowerData.currStatus.currFloor = targetFloor
		sharkSkyTowerData.currStatus.skipBattle = true

		DataManager.setSharkSkyTowerData(sharkSkyTowerData)

		local callbackFunc = self.callbackFunc
		self:dismissSelf()
			
		if callbackFunc then 
			callbackFunc()
		end
    end

	local function onSkipFailed(evt)
		local errorCode = tonumber(evt.data)
		if errorCode == 713513 then
          self.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("skyTower_cannotChallenge"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        elseif errorCode == 713521 then
          self.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("skyTower_error_pass1"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        elseif errorCode == 713522 then
          self.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("skyTower_error_pass2"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        else
          CanonMessageBox:showCommUnHandleErrorBox(errorCode)
        end
    end

    local request = SkyTowerSkipBattleRequest.new({}, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.SkyTowerSkipBattleSucceed, onSkipSucceed)
	request:addEventListener(RequestNotifyEnum.SkyTowerSkipBattleFailed, onSkipFailed)
	request:start()
end

-- 领奖
function NewBabelSkipPanel:getSkipRewards()
	local function onGetRewardsSucceed(evt)
		local sharkSkyTowerData = DataManager.getSharkSkyTowerData()
		sharkSkyTowerData.currStatus.skipBattle = false
		DataManager.setSharkSkyTowerData(sharkSkyTowerData)

		if evt.data.rewards and table.getn(evt.data.rewards) > 0 then
			self.container.targetInfoPanel = NewBabelFloorRewardPanel:create(self.container, sharkSkyTowerData, evt.data.rewards, self.callbackFunc)
			PopoutManager:sharedManager():popout(self.container.targetInfoPanel, kPopoutDir.kScale, true, false ,self.container)

			self:removeFromParentAndCleanup(true)
		else
			local callbackFunc = self.callbackFunc
			self:dismissSelf()

			if callbackFunc then 
				callbackFunc()
			end
		end
	end

	local function onGetRewardsFailed(evt)
		local errorCode = tonumber(evt.data)
		if errorCode == 713523 then
			self.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("skyTower_error_reward"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		elseif errorCode == 713524 then
			self.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("skyTower_error_pass3"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
		else
			CanonMessageBox:showCommUnHandleErrorBox(evt.data)
		end
	end

	local request = SkyTowerSkipGainRewardsRequest.new({}, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.SkyTowerSkipGainRewardsSucceed, onGetRewardsSucceed, self)
	request:addEventListener(RequestNotifyEnum.SkyTowerSkipGainRewardsFailed, onGetRewardsFailed, self)
	request:start()
end

function NewBabelSkipPanel:dispose()
	NewBabelSkipPanel.super.dispose(self)
end

function NewBabelSkipPanel:scaleIn()
	self.tempLayer.touchEnabled = false
	self.tempLayer.touchChildren = false
	local function scaleInFinished()
	  self.tempLayer.touchEnabled = true
	  self.tempLayer.touchChildren = true
	end
	local arr = CCArray:create()
	arr:addObject(CCEaseSineOut:create(CCScaleTo:create(0.3, 1.0)))
	arr:addObject(CCCallFunc:create(scaleInFinished))
	self.tempLayer:runAction(CCSequence:create(arr))

	--添加到二级堆栈
	UiStackManager.push(self)
end

function NewBabelSkipPanel:dismissSelf()
	self.container.targetInfoPanel = self.pre_container_targetInfoPanel
	self:removeFromParentAndCleanup(true)
end