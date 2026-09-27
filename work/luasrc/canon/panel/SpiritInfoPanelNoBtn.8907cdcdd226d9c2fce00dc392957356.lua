--------------------------------------------------------------------------------
-- SpiritInfoPanelNoBtn.lua - 道具详情面板
-- author: fanzhou.long
-- date: 2013-08-27
--------------------------------------------------------------------------------
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.panel.ItemSellMessageBoxPanel"
require "canon.request.UsePropRequest"
require "canon.scene.PropConfig"
require "canon.panel.GetRewardInfoPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

SpiritInfoPanelNoBtn = class(Layer)

function SpiritInfoPanelNoBtn:ctor()
	self.container = nil
end

function SpiritInfoPanelNoBtn:create( container )
	self.container = container
	self.prop = self.container._data
	local s = SpiritInfoPanelNoBtn.new()
	s:initLayer()
	return s
end

function SpiritInfoPanelNoBtn:refreshData()
	local aProp =  MetaManager.prop_meta[self.prop.metaId]
	
	--刷新描述标签
	self.panelUI:getChildByName("common_txt_propInfo_title"):getChildByName("txt_propInfo_title"):setString(Localization:getInstance():getText("propInfo_title"))
	
	--刷新动态标签
	--这两个暂时写死
	self.panelUI:getChildByName("common_popup_propInfo_upper"):getChildByName("txt_propInfo_desc_txt"):getChildByName("txt_propInfo_desc_txt"):setString(Localization:getInstance():getText("activity_dailyCharge_spriteInfo"))
	self.panelUI:getChildByName("common_popup_propInfo_upper"):getChildByName("txt_equipName"):getChildByName("txt_equipName"):setString(Localization:getInstance():getText("activity_dailyCharge_spriteName"))

	
	self.panelUI:getChildByName("common_btn_propInfo_useBtn"):setVisible(false)
	self.panelUI:getChildByName("common_btn_equip_SellBtn_usable"):setVisible(false)
	self.panelUI:getChildByName("btn_l"):setVisible(false)
	self.panelUI:getChildByName("btn_r"):setVisible(false)

	self.panelUI:getChildByName("common_btn_equip_SellBtn"):setVisible(false)
end

function SpiritInfoPanelNoBtn:initLayer()
	self.container:setTableViewsEnabled(false)
	SpiritInfoPanelNoBtn.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
	self.panelUI = builder:build("common_popup_propInfo")
	self.panelUI:getChildByName("common_txt_propInfo_title"):getChildByName("txt_propInfo_title"):setString(Localization:getInstance():getText("propInfo_title"))
	
	self.panelUI:getChildByName("common_popup_propInfo_upper"):getChildByName("shuliang"):setVisible(false)

	self:refreshData() 
	
	--关闭
	local function onClosePanel(evt)
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end	 
	local bt_panel_close = Button:create(self.panelUI:getChildByName("common_btn_close"))
	bt_panel_close:addEventListener(Events.kStart, onClosePanel)

    self.panelUI:getChildByName("common_popup_propInfo_upper"):getChildByName("normal_card_small"):setVisible(false)
    --物品信息
	local propObject = CanonItem:create()
    propObject:loadByMetaId(self.prop.metaId)
	local position = self.panelUI:getChildByName("common_popup_propInfo_upper"):getChildByName("normal_card_small"):getPosition()
	propObject:setPosition(ccp(position.x,position.y))
	self.panelUI:getChildByName("common_popup_propInfo_upper"):addChild(propObject)  
    --显示品质
    self.propMetaData = MetaManager.prop_meta[tonumber(self.prop.metaId, 10)]   
	self:addChild(self.panelUI)
end

function SpiritInfoPanelNoBtn:initData()

end

function SpiritInfoPanelNoBtn:updata()

end