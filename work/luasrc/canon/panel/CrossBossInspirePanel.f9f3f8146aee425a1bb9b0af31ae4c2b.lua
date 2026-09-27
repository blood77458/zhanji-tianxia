--------------------------------------------------------------------------------
-- CrossBossInspirePanel.lua - 鼓舞信息面板
--------------------------------------------------------------------------------

require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.data.MetaManager"
require "canon.models.CommonManager"
require "canon.request.InspireCrossBossTeamRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

CrossBossInspirePanel = class(Layer)

function CrossBossInspirePanel:ctor()
    self.container = nil
    self.propInspireCount = 0
    self.goldInspireCount = 0
end

function CrossBossInspirePanel:create( container )
    self.container = container
    local s = CrossBossInspirePanel.new()
    s:initLayer()
    return s
end

function CrossBossInspirePanel:initLayer()
	CrossBossInspirePanel.super.initLayer(self)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/Siren.json")
    self.panelUI = builder:build("popup_Siren_03")
	self:addChild(self.panelUI)

	local gameInitData = DataManager.getGameInitData()

	local crossBossSettingConfig = CrossWorldBossManager.getCrossBossSettingConfig()

	self.panelUI:getChildByName("txt_8"):getChildByName("txt"):setString(getTextByKey("crossBoss_inspireTitle"))
	self.panelUI:getChildByName("txt_02"):getChildByName("txt"):setString(getTextByKey("crossBoss_inspireBuff"))
	self.panelUI:getChildByName("txt_03"):getChildByName("txt"):setString(CrossWorldBossManager.getInsprieValue())
	self.panelUI:getChildByName("txt_01"):getChildByName("txt"):setString(getTextByKey("crossBoss_inspireLimit")..crossBossSettingConfig.inspireLimit)

	self.panelUI:getChildByName("txt_11"):getChildByName("txt"):setString(getTextByKey("crossBoss_itemInspireExplain"))
	self.panelUI:getChildByName("txt_06"):getChildByName("txt"):setString(getTextByKey("crossBoss_inspireNum"))
	self.panelUI:getChildByName("txt_05"):getChildByName("txt"):setString(crossBossSettingConfig.inspirePropBuff.."%")

	self.panelUI:getChildByName("txt_10"):getChildByName("txt"):setString("VIP"..crossBossSettingConfig.inspireGoldVipLevel)
	self.panelUI:getChildByName("txt_09"):getChildByName("txt"):setString(getTextByKey("crossBoss_goldInspireExplain"))
	self.panelUI:getChildByName("txt_07"):getChildByName("txt"):setString(getTextByKey("crossBoss_inspireNum"))
	self.panelUI:getChildByName("txt_04"):getChildByName("txt"):setString(crossBossSettingConfig.inspireGoldBuff.."%")


	local function getCurInspirePropAmount()
		for k, v in pairs(gameInitData.sharkProps.sharkProps) do
			if v.metaId == crossBossSettingConfig.inspirePropId then
				return v.amount
			end
		end
		return 0
	end

	local function getExpectInspireValue()
	      local addInspire = self.propInspireCount * crossBossSettingConfig.inspirePropBuff
		addInspire = addInspire + self.goldInspireCount * crossBossSettingConfig.inspireGoldBuff
		addInspire = addInspire + CrossWorldBossManager.getInsprieValue()
		-- addInspire = addInspire + 0.0001
		if (addInspire + 0.0001) > crossBossSettingConfig.inspireLimit then
			addInspire = crossBossSettingConfig.inspireLimit
		end
		return addInspire
	end

	self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("worldBoss_propNum"))

	local function updateCurrentInspireValue()
		self.expectInspire = getExpectInspireValue()
		local stringInspire = math.floor( self.expectInspire )
		self.panelUI:getChildByName("txt_03"):getChildByName("txt"):setString("" .. stringInspire .. "%")  --当前伤害加成

		local curprop = getCurInspirePropAmount() - self.propInspireCount
		self.panelUI:getChildByName("txt_08"):getChildByName("txt"):setString(curprop)  --当前拥有的军令

		local curGams = CalculationManager.calcComplex_getGemsNow() - self.goldInspireCount*crossBossSettingConfig.inspireGoldCost
		self.panelUI:getChildByName("txt11"):getChildByName("txt"):setString(curGams)  --当前的金币值
	end

	updateCurrentInspireValue()

	local function onInspire( evt )
		print("onInspire in InspirePanel")
		--判断当前是否有足够的鼓舞道具
		local function isEnoughProp()
			local curAmount = getCurInspirePropAmount()
			if curAmount > self.propInspireCount then
				return true
			end
			return false
		end
            local addInspire = getExpectInspireValue()
		if addInspire >= crossBossSettingConfig.inspireLimit then
			SuspensionLabel:showContent(self, Localization:getInstance():getText("worldBoss_boostLimit"))
		elseif not isEnoughProp() then
			SuspensionLabel:showContent(self, Localization:getInstance():getText("worldBoss_propInsufficient"))
		else
			self.propInspireCount = self.propInspireCount + 1
			updateCurrentInspireValue()
		end
	end

	local inspireBtn = Button:create(self.panelUI:getChildByName("icon_token_inspire"))
	inspireBtn:addEventListener(Events.kStart, onInspire)


    local function onGoldInspire(evt)
    	local nowGems = CalculationManager.calcComplex_getGemsNow()
    	local addInspire = getExpectInspireValue()

    	local vipLevel = DataManager.getGameInitData().sharkUser.vipLevel
    	if vipLevel < crossBossSettingConfig.inspireGoldVipLevel then
				local requireVipLevel = crossBossSettingConfig.inspireGoldVipLevel
				self.container.targetInfoPanel = VipWarningPanel:create( self.container, crossBossSettingConfig.inspireGoldVipLevel)
				-- self.container.targetInfoPanel:setZOrder(10000)
		        PopoutManager:sharedManager():popout(self.container.targetInfoPanel, kPopoutDir.kScale, true, false , self)
		elseif addInspire >= crossBossSettingConfig.inspireLimit then
			SuspensionLabel:showContent(self, Localization:getInstance():getText("worldBoss_boostLimit"))
		elseif nowGems <  (self.goldInspireCount+1)*crossBossSettingConfig.inspireGoldCost then
			--SuspensionLabel:showContent(self, Localization:getInstance():getText("没有足够的金币了"))
			local function onReplaceScene()
                -- self.container:setTableViewsEnabled(true)
                -- self.container.targetInfoPanel = nil
                -- PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
			end
			local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene})
			self:addChild(aPanel)
			aPanel:scaleIn()
		else
			self.goldInspireCount = self.goldInspireCount + 1
			updateCurrentInspireValue()
		end
    end

    local goldInspireBtn = Button:create(self.panelUI:getChildByName("icon_gold_inspire"))
	goldInspireBtn:addEventListener(Events.kStart, onGoldInspire)


	local function onConfirmPanel(evt)
		if self.container.curretnStage ~= 1 then
			local aContent = getTextByKey("crossBoss_errorCodeBattleEnd")
			SuspensionLabel:showContent(Director:mgr():run(), aContent)
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
			self.container.targetCrossBossInspirePanel = nil
			do return end
		end
		if self.propInspireCount <= 0 and self.goldInspireCount <= 0 then
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
			self.container.targetCrossBossInspirePanel = nil
			do return end
		end	


		local function onInspireInWorldBossSuccess(response)
			local gameInitData = DataManager.getGameInitData()
			print( "onInspireInWorldBossSuccess" )
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
			CrossWorldBossManager.setInsprieValue(self.expectInspire)
			for k, v in pairs(gameInitData.sharkProps.sharkProps) do
				if v.metaId == crossBossSettingConfig.inspirePropId then
					if v.amount >= self.propInspireCount then
						v.amount = v.amount - self.propInspireCount
						break
					end
				end
			end
			DataManager.setGameInitData(gameInitData)
			
			local gemsCost = self.goldInspireCount * crossBossSettingConfig.inspireGoldCost
			RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -gemsCost})

			self.container:refreshInspireBtn()
			self.container.targetCrossBossInspirePanel = nil
		end
		
		local function onInspireInWorldBossFailed(response)
			print( "onInspireInWorldBossFailed" )
		end

		local params = {props = self.propInspireCount , gems = self.goldInspireCount}
		
		InspireCrossBossTeamRequest.sendRequest(params ,onInspireInWorldBossSuccess , onInspireInWorldBossFailed)
	end

	self.panelUI:getChildByName("btn_01"):getChildByName("txt_guild_66"):getChildByName("txt"):setString(getTextByKey("yes"))
	local bt_panel_close = Button:create(self.panelUI:getChildByName("btn_01"))
    bt_panel_close:addEventListener(Events.kStart, onConfirmPanel)
	
   
    local function onCancelPanel(evt)
        PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		self.container.targetCrossBossInspirePanel = nil
    end 
	self.panelUI:getChildByName("btn_02"):getChildByName("txt_guild_66"):getChildByName("txt"):setString(getTextByKey("cancel"))
    local bt_panel_close = Button:create(self.panelUI:getChildByName("btn_02"))
    bt_panel_close:addEventListener(Events.kStart, onCancelPanel)   
   
	
end