

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

------------------------------------------------------------------------------------------------------

MesteriousChanllengePanel = class(Layer)

function MesteriousChanllengePanel:ctor()
end

function MesteriousChanllengePanel:create(container)
	local s = MesteriousChanllengePanel.new()
	s.container = container
	s:initLayer()
	return s
end

function MesteriousChanllengePanel:initLayer()
	MesteriousChanllengePanel.super.initLayer(self)
	MesteriousManager.setDefaultDiffculty(2)

	self.container:setTableViewsEnabled(false)

	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_mysteriousTraining_01") 
	self:addChild(self.panelUI)

	local function onClose( evt )
		self:close()
	end

	local closeBtn = Button:create(self.panelUI:getChildByName("common_btn_close"))
	closeBtn:addEventListener( Events.kStart, onClose, self )

	local tempTable = {
		"btn_orinary",
		"btn_torture",
		"btn_theDeep",
	}

	local function onRefreshChooseState()
		for k,v in pairs(tempTable) do
			if k == MesteriousManager.getDefaultDiffculty() then
				self.panelUI:getChildByName(v .. "0"):getChildByName(v.."_h"):setVisible(true)
				self.panelUI:getChildByName(v .. "0"):getChildByName(v):setVisible(false)
			else
				self.panelUI:getChildByName(v .. "0"):getChildByName(v.."_h"):setVisible(false)
				self.panelUI:getChildByName(v .. "0"):getChildByName(v):setVisible(true)
			end
		end
	end

	onRefreshChooseState()

	local chooseCountry = MesteriousManager.getChanllengeCountry()
	local function onChooseDiffculty( evt )
		print("onChanllenge"..evt.context)
		MesteriousManager.setDefaultDiffculty(evt.context)

		onRefreshChooseState()
		
	end
	for k,v in pairs(tempTable) do
		local chooseBtn = Button:create(self.panelUI:getChildByName(v .. "0"))
		chooseBtn:addEventListener( Events.kStart, onChooseDiffculty, k )
	end

	local function onChanllenge( evt )
		print("onChanllenge")
		if BagCalcManager.isFull() then
          NewPackageFullPanel:show()
          return
        end
		if CalculationManager.calcComplex_getEPNow() < MesteriousManager.getMysteriousConfig().energyCost - 0.01 then
			
			self.container:showNotEnoughEventPointPanel()
	      
			return
	    end
		local function afterSucceedCallback( e )
			RewardManager:getReward({{itemType = ResourceEnum.EVENTPOINT, amount = -MesteriousManager.getMysteriousConfig().energyCost}})
			MesteriousManager.changeMysteriousChallengeTimes()
			Director:sharedDirector():replaceScene(BattleScene:create(e.data,BattleBackType.kMysteriousBattle, BattleEnterEnum.kMysteriousBattle))
		end
		ChallengeMysteriousRequest.sendRequestDefalut(chooseCountry ,MesteriousManager.getDefaultDiffculty() , afterSucceedCallback)
	end

	local chanllengeBtn = Button:create(self.panelUI:getChildByName("btn_mysteriousTraining_01"))
	chanllengeBtn:addEventListener( Events.kStart, onChanllenge, self )

	self.panelUI:getChildByName("txt_01"):getChildByName("txt_sellItem_equip"):setString(getTextByKey("Mysterious_tips8"))
	self.panelUI:getChildByName("txt_02"):getChildByName("txt_sellItem_equip"):setString(getTextByKey("Mysterious_tips6"))
	self.panelUI:getChildByName("btn_mysteriousTraining_01"):getChildByName("txt"):setString(MesteriousManager.getMysteriousConfig().energyCost)
	self.panelUI:getChildByName("common_txt_equipInfo"):getChildByName("txt_equipInfo"):setString(getTextByKey("Mysterious_titel6"))
end


function MesteriousChanllengePanel:dispose()
	MesteriousChanllengePanel.super.dispose(self)
end

--关闭对话框
function MesteriousChanllengePanel:close()
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	self.container:setTableViewsEnabled(true)
end

-------------------------------------------------------------------------------------------------------------
