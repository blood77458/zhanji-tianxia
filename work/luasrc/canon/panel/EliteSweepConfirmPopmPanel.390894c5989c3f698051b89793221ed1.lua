-- EliteSweepConfirmPopmPanel.lua
-- 2015-3-26
-- zheng.che
-- 精英关卡扫荡确认窗口

require "canon.request.EliteSweepRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local selectedText = ""
------------------------------------------------------------------------------------------------------

EliteSweepConfirmPopmPanel = class(Layer)

-- 弹出窗口
-- missionConfig 	当前精英任务的配置信息
-- missionInfo 		当前精英任务数据 nil表示默认数据
-- fightCallback 	玩家选择手动挑战的回调
-- completeCallback 扫荡完毕后的回调
function EliteSweepConfirmPopmPanel.pop(missionConfig, missionInfo, fightCallback, completeCallback)
	local scene = Director:mgr():run()
	local panel = EliteSweepConfirmPopmPanel:create(missionConfig, missionInfo, fightCallback, completeCallback)
	PopoutManager:sharedManager():popout(panel, kPopoutDir.kScale, true, false , scene)
end

function EliteSweepConfirmPopmPanel:ctor()
	self.container = nil
	self.content = nil
end

function EliteSweepConfirmPopmPanel:create(missionConfig, missionInfo, fightCallback, completeCallback)
	if not missionInfo then
		--无数据情况
		missionInfo = {}
		missionInfo.challengeNum = 0
	end
	local s = EliteSweepConfirmPopmPanel.new()
	s:initLayer(missionConfig, missionInfo, fightCallback, completeCallback)
	return s
end

function EliteSweepConfirmPopmPanel:initLayer(missionConfig, missionInfo, fightCallback, completeCallback)
	EliteSweepConfirmPopmPanel.super.initLayer(self)

	self.missionConfig = missionConfig
	self.missionInfo = missionInfo
	self.fightCallback = fightCallback
	self.completeCallback = completeCallback
    
	local builder = LayoutBuilder:createWithContentsOfFile("scene/chapterSelect_new.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_chapterSelect") 
	self:addChild(self.panelUI)

	--每轮消耗体力
	local eliteConsumeEnergy = EliteManager.getEliteSetting().eliteConsumeEnergy

	self.panelUI:getChildByName("txt_chs"):getChildByName("txt"):setString(Localization:getInstance():getText("stage_times", {challengeNum = string.format("%d/%d", self.missionInfo.challengeNum, self.missionConfig.maxChallengesPerDay)}))

	--检查一下文案的内容
	local str1 = Localization:getInstance():getText("elite_stageClear1", {num = eliteConsumeEnergy})--一轮扫荡要消耗{num}点体力
	local str2 = Localization:getInstance():getText("elite_stageClear2", {num = DataManager.GameMetaData.battleSettingConfig.clearMissionConfig.maxRounds})--最多一次扫荡{num}次
	local str3 = Localization:getInstance():getText("stage_stageClearTips3")--
	self.panelUI:getChildByName("txt_popup_chapterSelect"):getChildByName("txt"):setString(string.format("%s\n%s\n%s", str1, str2, str3))

	--关闭按钮
	local function onCloseButtonClicked(evt)
		self:close()
	end
	local closeButtonDisplay = self.panelUI:getChildByName("btn_close")
	local closeButton = Button:create(closeButtonDisplay)
	closeButton:addEventListener( Events.kStart, onCloseButtonClicked, self )

	--闯关按钮
	local function onGoButtonClicked(evt)
		self:close()
		if self.fightCallback then
			self.fightCallback()
		end
	end
	local goButtonDisplay = self.panelUI:getChildByName("btn_go_stage")
	goButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("elite_challengeBtn"))--挑战
	local goButton = Button:create(goButtonDisplay)
	goButton:addEventListener( Events.kStart, onGoButtonClicked, self )

	--挑战消耗
	local strFightCost = Localization:getInstance():getText("elite_stageClear3", {num = eliteConsumeEnergy})--每次挑战消耗{num}点体力
	self.panelUI:getChildByName("txt_cutstamina"):getChildByName("txt"):setString(strFightCost)

	--扫荡总共消耗
	-- print("self.missionConfig = " .. tostringRich(self.missionConfig))
	-- print("CalculationManager.calcComplex_getEnergyNow() = " .. tostringRich(CalculationManager.calcComplex_getEnergyNow()))
	-- print("eliteConsumeEnergy = " .. tostringRich(eliteConsumeEnergy))
	-- print("self.missionInfo = " .. tostringRich(self.missionInfo))
	local roundForEnergy = math.modf((CalculationManager.calcComplex_getEnergyNow() / eliteConsumeEnergy))
	local sweepRound = math.min(DataManager.GameMetaData.battleSettingConfig.clearMissionConfig.maxRounds, self.missionConfig.maxChallengesPerDay - self.missionInfo.challengeNum, roundForEnergy)
	--print("roundForEnergy = " .. tostringRich(roundForEnergy))
	local sweepTipsLabel = self.panelUI:getChildByName("txt_rushstamina")
	sweepTipsLabel:getChildByName("txt"):setString(Localization:getInstance():getText("stage_stageClearConsumeTip", {num = sweepRound * eliteConsumeEnergy}))
	

	--扫荡按钮资源
	local coolDownLabel = self.panelUI:getChildByName("txt_chapterSelect_time")
	local coolDownLabel2 = coolDownLabel:getChildByName("txt")
	local sweepButtonDisplay = self.panelUI:getChildByName("btn_sweep")
	local sweepButton = Button:create(sweepButtonDisplay)
	local sweepLabel1 = sweepButtonDisplay:getChildByName("txt")
	local sweepLabel2 = sweepButtonDisplay:getChildByName("txt2")
	local sweepLabel3 = sweepButtonDisplay:getChildByName("txt3")
	local sweepGemIcon = sweepButtonDisplay:getChildByName("icon_manycoin")

	--扫荡按钮状态
	coolDownLabel:setVisible(false)
	sweepButtonDisplay:getChildByName("btn_disadble"):setVisible(false)
	sweepButtonDisplay:getChildByName("btn_long_blue"):setVisible(true)
	--扫荡按钮文字
	if sweepRound > 0 then
		sweepLabel1:setVisible(true)
		sweepLabel1:setString(Localization:getInstance():getText("stage_stageClearRoundsBtn", {num = sweepRound}))--扫荡{num}轮
		sweepLabel2:setVisible(false)
		sweepLabel3:setVisible(false)
		sweepGemIcon:setVisible(false)
	else
		sweepLabel1:setString(Localization:getInstance():getText("stage_stageClear"))
		sweepLabel2:setVisible(false)
		sweepLabel3:setVisible(false)
		sweepGemIcon:setVisible(false)
	end

	--扫荡按钮
	local function onSweepButtonClicked(evt)
		if BagCalcManager.isFull() then
			local aContent = Localization:getInstance():getText("bagFull_challenge")
			NewPackageFullPanel:show()
			return
		end

		--扫荡
		local function onAfterSuccessed(requestEvent)
			--成功后的处理
			if self.completeCallback then
				self.completeCallback()
			end
		end
		EliteSweepRequest.sendRequestDefalut(self.missionConfig.id, sweepRound, self.missionInfo, onAfterSuccessed)
		self:close()
	end
	sweepButton:addEventListener( Events.kStart, onSweepButtonClicked, self )
end

function EliteSweepConfirmPopmPanel:close()
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
end

function EliteSweepConfirmPopmPanel:dispose()
	EliteSweepConfirmPopmPanel.super.dispose(self)
end

function EliteSweepConfirmPopmPanel:setTableViewsEnabled(v)
	self.editInputLabel:setEnabled(v)
end