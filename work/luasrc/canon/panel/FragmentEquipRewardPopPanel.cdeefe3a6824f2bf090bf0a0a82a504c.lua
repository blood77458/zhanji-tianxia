--
-- FragmentEquipRewardPopPanel
-- Author: czh
-- Date: 2014-02-18 14:20:40
--
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

FragmentEquipRewardPopPanel = class(Layer)

function FragmentEquipRewardPopPanel:ctor()
	self.container = nil
	self.content = nil
end

function FragmentEquipRewardPopPanel:create( container, content, dropInfo, completeCallBack )
	local s = FragmentEquipRewardPopPanel.new()
	s:initLayer(container, content, dropInfo, completeCallBack)
	return s
end

function FragmentEquipRewardPopPanel:initLayer(container, content, dropInfo, completeCallBack)
	FragmentEquipRewardPopPanel.super.initLayer(self)

	--点击确认
	local function onConfirm(evt)
		self:dismiss()
	end

	--三级框关闭
	local function onInfoClosed()
		--还不让滚动
		self.container:setTableViewsEnabled(false)
	end

	--点击装备
	local function onItemClick()
		self.container._data = FragmentScene.Get_Equip_Whole_Information( self.dropInfo.id )
		self.container.targetInfoPanel = EquipInfoPanelNoBtn:create( self.container , "BackpackScene", onInfoClosed)
		PopoutManager:sharedManager():popout(self.container.targetInfoPanel, kPopoutDir.kScale, false, false ,self.container) 
		self.container.targetInfoPanel = nil
	end

	self.container = container
	self.content = content
	self.dropInfo = dropInfo
	self.completeCallBack = completeCallBack

	self.container.targetInfoPanel = self

	self.colorLayer = LayerColor:create()
	self.colorLayer:setOpacity(kDarkOpacity)
	self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
	self:addChild(self.colorLayer)

	self.tempLayer = Layer:create()
	self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
	self:addChild(self.tempLayer)
	self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))

	local builder = LayoutBuilder:createWithContentsOfFile("scene/soulcombine.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("soulcombine_result_item") 
	self.tempLayer:addChild(self.panelUI)

	self.panelUI:getChildByName("txt_up"):getChildByName("txt"):setString(Localization:getInstance():getText("fragment_equipCombine_title"))
	self.panelUI:getChildByName("txt_buttom"):getChildByName("txt"):setString(Localization:getInstance():getText("fragment_equipCombine_text"))

	--确认按钮
	local gainButton = Button:create(self.panelUI:getChildByName("btn_sure"))
	self.panelUI:getChildByName("btn_sure"):getChildByName("txt"):setString(Localization:getInstance():getText("yes"))--确定

	gainButton:addEventListener(Events.kStart,onConfirm, self)

	--显示装备图片
	local aCardDisplay =  self.panelUI:getChildByName("frame_card")
	aCardDisplay:setVisible(false)
	self.equipIcon = CanonItem:create()
	self.equipIcon:loadByMetaId(self.dropInfo.metaId)
	self.equipIcon:setPosition(ccp(aCardDisplay:getPositionX(), aCardDisplay:getPositionY()))
	self.equipIcon:setScale(0.8)
	self.panelUI:addChild(self.equipIcon, 10)

	--图片添加点击事件
	local Btn_dropItem = Button:create( self.equipIcon )
	Btn_dropItem:addEventListener( Events.kStart, onItemClick, self ) 

	--显示装备名称
	self.panelUI:getChildByName("txt_soulcombine_info2"):getChildByName("txt"):setString(Localization:getInstance():getText(MetaManager.equip_meta[self.dropInfo.metaId].name))

	self.tempLayer:setScale(0.1)
end

function FragmentEquipRewardPopPanel:scaleIn()
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

  	UiStackManager.push(self)
end

function FragmentEquipRewardPopPanel:dismiss()
  	UiStackManager.remove(self)
	self:removeFromParentAndCleanup(true)

	if self.completeCallBack then
		self.completeCallBack()
	end
end