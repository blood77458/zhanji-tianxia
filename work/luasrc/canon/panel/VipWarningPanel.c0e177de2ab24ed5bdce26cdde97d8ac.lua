require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

VipWarningPanel = class(Layer)

function VipWarningPanel:ctor()
	self.container = nil
end

function VipWarningPanel:create( container , needVipLevel, extraParams)
	self.container = container
	self.needVipLevel = needVipLevel
  self.extraParams = extraParams
	local s = VipWarningPanel.new()
	s:initLayer()
	return s
end

function VipWarningPanel:initLayer()
	if self.container.setTableViewsEnabled and type(self.container.setTableViewsEnabled) == "function" then
		self.container:setTableViewsEnabled(false)
	end
	
	VipWarningPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
	local highLight
	local closeButtonDisplayTable = {}
	local becomeVipButtonDisplay
	if (tonumber(DataManager.getCurrUser().rechargeGems) <= 0) then
		self.panelUI = builder:build("common_popup_vipCharge")
		local titleText
    if self.extraParams and self.extraParams.title then
      titleText = self.extraParams.title
    else
      titleText = Localization:getInstance():getText("popup_vipRequired_title", {viplevel = "VIP"})
    end
		self.panelUI:getChildByName("common_txt_popup_addCoin_common1_needtitle2"):getChildByName("txt_popup_addCoin_common1_needtitle"):setString(titleText)
		self.panelUI:getChildByName("common_btn_cancel_2"):getChildByName("txt_cancel"):setString(getTextByKey("yes"))
		self.panelUI:getChildByName("common_btn_bevip"):getChildByName("txt"):setString(getTextByKey("chargeMoney_not_vip_button"))
		self.panelUI:getChildByName("common_txt_popup_addCoin_common1_needconent2"):getChildByName("txt_popup_addCoin_common1_needcontent"):setString(getTextByKey("chargeMoney_not_vip_dec_part1"))
		self.panelUI:getChildByName("txt_redo1"):getChildByName("txt"):setString(getTextByKey("chargeMoney_not_vip_dec_part2"))
		self.panelUI:getChildByName("txt_redo2"):getChildByName("txt"):setString(getTextByKey("chargeMoney_not_vip_dec_part3"))
		self.panelUI:getChildByName("txt_jiazhi"):getChildByName("txt"):setString(getTextByKey("chargeMoney_not_vip_dec_part4"))
		self.panelUI:getChildByName("txt_charge_4"):getChildByName("txt"):setString(getTextByKey("chargeMoney_not_vip_dec_part5"))
		
		self.panelUI:getChildByName("charge_reward_item"):setVisible(false)
		
		self.chargeLevel = Activity_ChargeRewardLayer.getEnableChargeLevel()		
		local rewardMeta = MetaManager.charge_money_reward[self.chargeLevel + 1]
		self.panelUI:getChildByName("txt_jiazhi_font"):getChildByName("txt"):setString(tostring(rewardMeta.worthGold))
		self.panelUI:getChildByName("txt_charge_5"):getChildByName("txt"):setString(getTextByKey(rewardMeta.describe))
		local rewardsLayer = Activity_ChargeRewardLayer.createRewardLayer(self.chargeLevel, ccc3(255, 255, 255))
		rewardsLayer:setPositionXY(self.panelUI:getChildByName("charge_reward_item"):getPositionX() + 88, self.panelUI:getChildByName("charge_reward_item"):getPositionY() - 60)
		self.panelUI:addChild(rewardsLayer)
		
		highLight = self.panelUI:getChildByName("common_btn_bevip"):getChildByName("common_btn_light")
		
		table.insert(closeButtonDisplayTable, self.panelUI:getChildByName("common_btn_cancel_2"))
		table.insert(closeButtonDisplayTable, self.panelUI:getChildByName("common_btn_close_sb"))
	
		becomeVipButtonDisplay = self.panelUI:getChildByName("common_btn_bevip")
	else
		self.panelUI = builder:build("common_popup_getvip")
		
		local titleText = Localization:getInstance():getText("popup_vipRequired_title", {viplevel = "VIP" .. self.needVipLevel})
		self.panelUI:getChildByName("common_txt_getvip"):getChildByName("txt"):setString(titleText)
		self.panelUI:getChildByName("common_txt_getvip_info"):getChildByName("txt"):setString(getTextByKey("popup_vipRequired_content"))
		self.panelUI:getChildByName("common_btn_cancel_y"):getChildByName("txt_cancel"):setString(getTextByKey("yes"))
		self.panelUI:getChildByName("common_btn_becomevip"):getChildByName("txt"):setString(getTextByKey("popup_vipRequired_btn"))
		
		highLight = self.panelUI:getChildByName("common_btn_becomevip"):getChildByName("common_btn_light")
		
		becomeVipButtonDisplay = self.panelUI:getChildByName("common_btn_becomevip")

		table.insert(closeButtonDisplayTable, self.panelUI:getChildByName("common_btn_cancel_y"))
		table.insert(closeButtonDisplayTable, self.panelUI:getChildByName("btn_close"))
	end
	
	local function onClickBecomeVip(evt)
		if self.container.setTableViewsEnabled and type(self.container.setTableViewsEnabled) == "function" then
			self.container:setTableViewsEnabled(true)
		end
		-- self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
    if self.BecomeVIP_CallBack ~= nil then
      self.BecomeVIP_CallBack()
    end
    	Director:sharedDirector():replaceScene(ShopScene:create({params = {tabIndex = TABLEVIEW_TAB_INDEX.CHARGE}}))
		-- self.container:replaceScene(ShopScene, {params = {tabIndex = TABLEVIEW_TAB_INDEX.CHARGE}})
	end
		
	local bt_panel_becomeVip = Button:create(becomeVipButtonDisplay)
	bt_panel_becomeVip:addEventListener(Events.kStart, onClickBecomeVip)
		
	local function onClosePanel(evt)
		if self.container.setTableViewsEnabled and type(self.container.setTableViewsEnabled) == "function" then
			self.container:setTableViewsEnabled(true)
		end
		-- self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
    if self.Close_CallBack ~= nil then
      self.Close_CallBack()
    end
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
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
