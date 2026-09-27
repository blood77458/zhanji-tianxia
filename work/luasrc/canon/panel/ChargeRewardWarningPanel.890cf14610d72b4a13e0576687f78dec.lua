require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

ChargeRewardWarningPanel = class(Layer)

function ChargeRewardWarningPanel:ctor()
	self.container = nil
end

function ChargeRewardWarningPanel:create( container )
	self.container = container
	local s = ChargeRewardWarningPanel.new()
	s:initLayer()
	return s
end

function ChargeRewardWarningPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	ChargeRewardWarningPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
	local highLight
	local closeButtonDisplayTable = {}
	local becomeVipButtonDisplay
	-- if (tonumber(DataManager.getCurrUser().rechargeGems) <= 0) then
		self.panelUI = builder:build("common_popup_vipCharge2")
		
		local titleText = Localization:getInstance():getText("popup_vipRequired_title", {viplevel = "VIP"})
		self.panelUI:getChildByName("common_txt_popup_addCoin_common1_needtitle2"):getChildByName("txt"):setString(getTextByKey("chargeMoney_dec15"))
		-- self.panelUI:getChildByName("common_btn_cancel_2"):getChildByName("txt_cancel"):setString(getTextByKey("yes"))
		self.panelUI:getChildByName("txt_vipCharge_title"):getChildByName("txt"):setString(getTextByKey("chargeMoney_dec16"))
		self.panelUI:getChildByName("common_btn_bevip"):getChildByName("txt"):setString(getTextByKey("chargeMoney_dec17"))
		
		self.panelUI:getChildByName("charge_reward_item"):setVisible(false)
		self.panelUI:getChildByName("common_btn_cancel_2"):setVisible(false)
		
		self.chargeLevel = Activity_ChargeRewardLayer.getCurrentChargeLevel()		
		self.panelUI:getChildByName("txt_charge_5"):getChildByName("txt"):setString(getTextByKey(MetaManager.charge_money_reward[self.chargeLevel + 1].describe))
		-- local rewardMeta = MetaManager.charge_money_reward[self.chargeLevel + 1]
		-- self.panelUI:getChildByName("txt_jiazhi_font"):getChildByName("txt"):setString(tostring(rewardMeta.worthGold))
		-- self.panelUI:getChildByName("txt_charge_5"):getChildByName("txt"):setString(getTextByKey(rewardMeta.describe))
		local rewardsLayer = Activity_ChargeRewardLayer.createRewardLayer(self.chargeLevel, ccc3(255, 255, 255))
		rewardsLayer:setPositionXY(self.panelUI:getChildByName("charge_reward_item"):getPositionX() + 88, self.panelUI:getChildByName("charge_reward_item"):getPositionY() - 60)
		self.panelUI:addChild(rewardsLayer)
		
		highLight = self.panelUI:getChildByName("common_btn_bevip"):getChildByName("common_btn_light")
		
		-- table.insert(closeButtonDisplayTable, self.panelUI:getChildByName("common_btn_cancel_2"))
		table.insert(closeButtonDisplayTable, self.panelUI:getChildByName("common_btn_close_sb"))
	
		becomeVipButtonDisplay = self.panelUI:getChildByName("common_btn_bevip")
	
	local function onClickBecomeVip(evt)
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		self.container:replaceScene(ActivityPanelScene, {selectPanelName = "Activity_ChargeReward"})
		-- self.container:replaceScene(ShopScene, {params = {tabIndex = TABLEVIEW_TAB_INDEX.CHARGE}})
	end
		
	local bt_panel_becomeVip = Button:create(becomeVipButtonDisplay)
	bt_panel_becomeVip:addEventListener(Events.kStart, onClickBecomeVip)
		
	local function onClosePanel(evt)
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		PopoutManager:sharedManager():popout(self.container.vipWarningPanel, kPopoutDir.kScale, true, false ,self.container)

	end
		
	for k, data in pairs(closeButtonDisplayTable) do
		local bt_panel_close = Button:create(data)
		bt_panel_close:addEventListener(Events.kStart, onClosePanel)
	end
	
	local actionArray = CCArray:create()
	actionArray:addObject(CCFadeOut:create(0.5))
	actionArray:addObject(CCFadeIn:create(0.5))
	highLight:runAction(CCRepeatForever:create(CCSequence:create(actionArray)))
	
	self:addChild(self.panelUI)
end
