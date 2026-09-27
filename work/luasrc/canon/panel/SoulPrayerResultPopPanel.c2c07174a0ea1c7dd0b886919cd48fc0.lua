--
-- SoulPrayerResultPopPanel 碎片祈祷结果UI
-- Author: czh
-- Date: 2014-02-19 16:27:47
--
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

SoulPrayerResultPopPanel = class(Layer)

function SoulPrayerResultPopPanel:ctor()
	self.container = nil
	self.content = nil
end

function SoulPrayerResultPopPanel:create( container, content, dropInfo, completeCallBack )
	local s = SoulPrayerResultPopPanel.new()
	s:initLayer(container, content, dropInfo, completeCallBack)
	return s
end

function SoulPrayerResultPopPanel:initLayer(container, content, dropInfo, completeCallBack)
	SoulPrayerResultPopPanel.super.initLayer(self)

	--点击确认
	local function onConfirm(evt)
		self:dismiss()
	end
	--点击返回列表
	local function onBackList(evt)
		self:dismiss()
		self.container:replaceScene(FragmentScene)
	end

	--三级框关闭
	local function onInfoClosed()
		--还不让滚动
		self.container:setTableViewsEnabledInner(false)
	end

	--点击碎片
	local function onItemClick()
		--弹出物品详情二级 改为通用接口 原先的容易出错 modified by zheng.che @ 2014-11-20
		CanonGoodIcon.popoutGoodPanel(ResourceEnum.CARD_FRAGMENT, self.dropInfo.metaId)
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

	local builder = LayoutBuilder:createWithContentsOfFile("scene/soulprayer.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("soulprayer_result") 
	self.tempLayer:addChild(self.panelUI)

	self.panelUI:getChildByName("txt_up"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_pray_result_title"))

	--确认按钮
	local gainButton = Button:create(self.panelUI:getChildByName("btn_sure"))
	self.panelUI:getChildByName("btn_sure"):getChildByName("txt"):setString(Localization:getInstance():getText("yes"))--确定
	gainButton:addEventListener(Events.kStart,onConfirm, self)

	--返回列表按钮
	local backListButton = Button:create(self.panelUI:getChildByName("btn_backlist"))
	self.panelUI:getChildByName("btn_backlist"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_pray_result_listBtn"))--将魂列表
	backListButton:addEventListener(Events.kStart,onBackList, self)

	--显示碎片图片
    local cardMetaId = MetaManager.card_fragment_meta[dropInfo.metaId].cardId
	local aCardDisplay =  self.panelUI:getChildByName("frame_card")
	aCardDisplay:setVisible(false)
    local fragmentIcon = getHeadIconNoStarCanonCardByMetaId(cardMetaId)
    fragmentIcon:setPosition(ccp(aCardDisplay:getPositionX(), aCardDisplay:getPositionY()))
    --fragmentIcon:setScale(0.9)
    self.tempLayer:addChild(fragmentIcon, 10)
    --显示碎片角标
    aSmallIcon = Sprite:create("Item/Picture/Prop_soul.png")
	aSmallIcon:setPosition( ccp(37, 47) )
    fragmentIcon:addChild(aSmallIcon, 20)

	--图片添加点击事件
	local btn_dropItem = Button:create( fragmentIcon )
	btn_dropItem:addEventListener( Events.kStart, onItemClick, self ) 

	--显示装备名称
	self.panelUI:getChildByName("txt_soulprayer_result_name"):getChildByName("txt"):setString(CanonGoodIcon.getGoodName(ResourceEnum.CARD_FRAGMENT, dropInfo.metaId, 1, {withoutAmount = true}))

	self.tempLayer:setScale(0.1)
end

function SoulPrayerResultPopPanel:scaleIn()
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
end

function SoulPrayerResultPopPanel:dismiss()
	self:removeFromParentAndCleanup(true)

	if self.completeCallBack then
		self.completeCallBack()
	end
end