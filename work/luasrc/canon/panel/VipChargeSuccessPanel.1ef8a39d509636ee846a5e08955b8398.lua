require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

VipChargeSuccessPanel = class(Layer)

function VipChargeSuccessPanel:ctor()
	self.container = nil
end

function VipChargeSuccessPanel:create( container , vipInfo)
	self.container = container
	self.vipInfo = vipInfo
	local s = VipChargeSuccessPanel.new()
	s:initLayer()
	return s
end

function VipChargeSuccessPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	VipChargeSuccessPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/shop_new.json")
	self.panelUI = builder:build("shop_popup_recharge_complete")
	
	self.panelUI:getChildByName("btn_buy_moneyver"):getChildByName("txt_sure"):setString(getTextByKey("yes"))
	self.panelUI:getChildByName("shop_btn_info"):getChildByName("txt_sure"):setString(getTextByKey("shop_charge_vipPrivilegeBtn"))
	self.panelUI:getChildByName("txt_exp_font"):getChildByName("txt"):setString(tostring(self.vipInfo.levelupCurGold) .. "/" .. tostring(self.vipInfo.levelupTotalGold))
	local progressBar = ProgressBar:create(self.panelUI:getChildByName("vip_boost"):getChildByName("vip_boost_sb"))
	local percentage = 0
	if self.vipInfo.levelupTotalGold > 0 then
		percentage = self.vipInfo.levelupCurGold / self.vipInfo.levelupTotalGold * 100
	end
	if percentage > 100 then
		percentage = 100
	end
	progressBar:setPercentage(percentage)
	
	local vipText = ""
	local vipPrivilegeText = ""
	local showLevel = self.vipInfo.level
	
	if self.vipInfo.isLevelup then
		vipText = Localization:getInstance():getText("shop_charge_vipLevelRaised", {num1 = self.vipInfo.chargeAmount, viplevel = "VIP" .. showLevel})
	elseif self.vipInfo.isMaxLevel then
		vipText = Localization:getInstance():getText("shop_charge_vipLevelMax", {num = self.vipInfo.chargeAmount})
	else
		showLevel = showLevel + 1
		vipText = Localization:getInstance():getText("shop_charge_vipLevelUnchanged", {num1 = self.vipInfo.chargeAmount, num2 = self.vipInfo.levelupTotalGold - self.vipInfo.levelupCurGold, viplevel = "VIP" .. showLevel})	
	end
	
	local privilegeTextTable = VipPrivilegeManager.getVipPrivilegeTextTable(showLevel)
	vipPrivilegeText = Localization:getInstance():getText("shop_charge_vipPrivilege", {viplevel = "VIP" .. showLevel})
	vipPrivilegeText = vipPrivilegeText .. "\n"
	
	for k,v in ipairs(privilegeTextTable) do
		vipPrivilegeText = vipPrivilegeText .. k .. "." .. v
		if k ~= #privilegeTextTable then
			vipPrivilegeText = vipPrivilegeText .. "\n"
		end
	end
	
	self.panelUI:getChildByName("shop_txt_message3"):getChildByName("txt"):setString(vipText)
	self.panelUI:getChildByName("txt_message3"):getChildByName("txt"):setString(vipPrivilegeText)
	self.panelUI:getChildByName("txt_message3"):getChildByName("txt"):setVerticalAlignment(kCCVerticalTextAlignmentCenter)
	
	local function onKnowMoreAboutVip(evt)
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		
		self.container.vipPrivilegePanel:refreshPanel(self.vipInfo, true)
		self.container.targetInfoPanel = self.container.vipPrivilegePanel
		PopoutManager:sharedManager():popout(self.container.targetInfoPanel, kPopoutDir.kScale, true, false ,self.container)
	end
	
	local bt_panel_knowMore = Button:create(self.panelUI:getChildByName("shop_btn_info"))
	bt_panel_knowMore:addEventListener(Events.kStart, onKnowMoreAboutVip)
	
	local function onClosePanel(evt)
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end	 
	local bt_panel_close = Button:create(self.panelUI:getChildByName("btn_buy_moneyver"))
	bt_panel_close:addEventListener(Events.kStart, onClosePanel)
	local bt_shop_close = Button:create(self.panelUI:getChildByName("shop_btn_close"))
	bt_shop_close:addEventListener(Events.kStart, onClosePanel)

	self:addChild(self.panelUI)
end
