require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

require "canon.request.ResetClimbTowerRequest"
-- require "canon.request.GetSkyTowerInfoRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

NewBabelRestartAfterDiePanel = class(Layer)

function NewBabelRestartAfterDiePanel:ctor()
	self.container = nil
end

function NewBabelRestartAfterDiePanel:create( container, sharkSkyTowerData, callback1 , callback2)
	self.container = container
	-- self.preTargetInfoPanel = self.container.targetInfoPanel
	self.sharkSkyTowerData = sharkSkyTowerData
	self.callback1 = callback1
	self.callback2 = callback2
	
	local s = NewBabelRestartAfterDiePanel.new()
	s:initLayer()
	return s
end

function NewBabelRestartAfterDiePanel:sendGetSkyTowerInfoRequest()--重新拉取通天塔信息
print("11111")
	local function onGetSkyTowerInfoSucceed(evt)
		print("2222")
		self.waitRequest = false
		self.container.sharkSkyTowerData = evt.data
		self.container:refreshUI(true)

		self.container:setTableViewsEnabled(true)
		-- self.container.targetInfoPanel = self.preTargetInfoPanel
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end
	
	local function onGetSkyTowerInfoFailed(evt)
		self.waitRequest = false
	end
	
	if self.waitRequest then
		do return end
	end
	
	self.waitRequest = true
	generalSendGetSkyTowerInfoRequest(onGetSkyTowerInfoSucceed, nil, onGetSkyTowerInfoFailed)
end

function NewBabelRestartAfterDiePanel:initLayer()
	self.container:setTableViewsEnabled(false)
	NewBabelRestartAfterDiePanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/towerBabel.json")
	self.panelUI = builder:build("popup_buff3")

	local function getMaxClimbTimes()
      	return MetaManager.getNewBabelSettings().challengeChance
    end
	
	self.panelUI:getChildByName("txt_buff1"):getChildByName("txt"):setString(getTextByKey("skyTower_battleChooseTitle"))
	self.panelUI:getChildByName("txt_towerBabel_lose1"):getChildByName("txt"):setString(getTextByKey("skyTower_highFloor"))
	self.panelUI:getChildByName("txt_towerBabel_lose_value1"):getChildByName("txt"):setString(Localization:getInstance():getText("babel_floor", {num = self.sharkSkyTowerData.currStatus.maxFloor}))
	self.panelUI:getChildByName("txt_towerBabel_lose2"):getChildByName("txt"):setString(getTextByKey("skyTower_battleResult_starSum"))
	self.panelUI:getChildByName("txt_towerBabel_lose_value2"):getChildByName("txt"):setString(tostring(self.sharkSkyTowerData.currStatus.currTotalStars))
	self.panelUI:getChildByName("txt_failed_info"):getChildByName("txt"):setString(getTextByKey("skyTower_battleChooseRule"))
	self.panelUI:getChildByName("txt_towerBabel_9_1"):getChildByName("txt"):setString(getTextByKey("skyTower_remainingChances"))
	self.panelUI:getChildByName("txt_towerBabel_buff"):getChildByName("txt"):setString(tostring(getMaxClimbTimes() - self.sharkSkyTowerData.currStatus.climbTimes))
	-- self.panelUI:getChildByName("txt_buff8"):getChildByName("txt"):setString(getTextByKey("skyTower_remainingStars"))
	-- self.panelUI:getChildByName("txt_towerBabel_buff7_1"):getChildByName("txt"):setString(tostring(self.sharkSkyTowerData.currStatus.currTotalStars))
	-- self.panelUI:getChildByName("txt_towerBabel_buff7_2"):getChildByName("txt"):setString(tostring(self.sharkSkyTowerData.currStatus.currTotalStars - self.sharkSkyTowerData.currStatus.currUsedStars))
	self.panelUI:getChildByName("txt_towerBabel_buff_a2"):getChildByName("txt"):setString(tostring(-self.sharkSkyTowerData.currStatus.enemyAtkDebuff))
	self.panelUI:getChildByName("txt_towerBabel_buff_a1"):getChildByName("txt"):setString(tostring(-self.sharkSkyTowerData.currStatus.enemyDefDebuff))
	self.panelUI:getChildByName("txt_towerBabel_buff_d2"):getChildByName("txt"):setString("+" .. math.floor(getFloatNumber(self.sharkSkyTowerData.currStatus.selfAtkBuff) * 100) .. "%")
	self.panelUI:getChildByName("txt_towerBabel_buff_d1"):getChildByName("txt"):setString("+" .. math.floor(getFloatNumber(self.sharkSkyTowerData.currStatus.selfDefBuff) * 100) .. "%")
	self.panelUI:getChildByName("txt_towerBabel_buff_d0"):getChildByName("txt"):setString("+" .. math.floor(getFloatNumber(self.sharkSkyTowerData.currStatus.selfHpBuff) * 100) .. "%")
	self.panelUI:getChildByName("txt_towerBabel_14"):getChildByName("txt"):setString(getTextByKey("skyTower_opponent"))
	self.panelUI:getChildByName("txt_towerBabel_13"):getChildByName("txt"):setString(getTextByKey("skyTower_self"))
	-- self.panelUI:getChildByName("txt_buff6"):getChildByName("txt"):setString(getTextByKey("skyTower_buyBuff"))
	-- self.panelUI:getChildByName("txt_towerBabel_buff"):getChildByName("txt"):setString("剩余册数")
	
	-- local function onClosePanel(evt)
	-- 	self.container:setTableViewsEnabled(true)
	-- 	self.container.targetInfoPanel = self.preTargetInfoPanel
	-- 	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	-- 	if self.callback then
	-- 		self.callback()
	-- 	end
	-- end	 

	local function onToBottom( evt )
		-- body
		local function onToBottomSucceed( data )
			-- body
			print("法神了神马")
			self:sendGetSkyTowerInfoRequest()
			-- if self.callback1 then
			-- 	self.callback1()
			-- end
		end

		local function onToBottomFailed( data )
			-- body
		end

		local request = ResetClimbTowerRequest.new( {type = 0}, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.ResetClimbTowerSucceed, onToBottomSucceed )
		request:addEventListener( RequestNotifyEnum.ResetClimbTowerFailed, onToBottomFailed )
		request:start()

	end

	local function continueClimb( evt )
		-- body
		local function onContinueClimbSucceed( data )
			-- body
			self:sendGetSkyTowerInfoRequest()
			-- if self.callback2 then
			-- 	self.callback2()
			-- end
		end

		local function onContinueClimbFailed( data )
			-- body
		end

		local request = ResetClimbTowerRequest.new( {type = 1}, rpc.SendingPriority.kHigh )
		request:addEventListener( RequestNotifyEnum.ResetClimbTowerSucceed, onContinueClimbSucceed )
		request:addEventListener( RequestNotifyEnum.ResetClimbTowerFailed, onContinueClimbFailed )
		request:start()
	end

	self.panelUI:getChildByName("btn_buff_chose1"):getChildByName("txt"):setString(getTextByKey("skyTower_battleChoose1"))
	local toBottomButton = Button:create(self.panelUI:getChildByName("btn_buff_chose1"))
	toBottomButton:addEventListener( Events.kStart, onToBottom, self )
	
	self.panelUI:getChildByName("btn_buff_chose2"):getChildByName("txt"):setString(getTextByKey("skyTower_battleChoose2"))
	local continueButton = Button:create(self.panelUI:getChildByName("btn_buff_chose2"))
	continueButton:addEventListener( Events.kStart, continueClimb, self )
	
	self:addChild(self.panelUI)
	
end


