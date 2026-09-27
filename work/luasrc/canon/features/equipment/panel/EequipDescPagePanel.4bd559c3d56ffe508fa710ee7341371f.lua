-- EequipDescPagePanel.lua
-- 2014-12-4
-- zheng.che
-- 装备详情 -> 简介页签

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

EequipDescPagePanel = class(Layer)

--------------------------------------------------------------------------------------------------------

function EequipDescPagePanel:ctor()
	self.container = nil
	self.dataList = nil
end

function EequipDescPagePanel:create(container, equipData )
	local s = EequipDescPagePanel.new()
	s:initLayer(container, equipData)
	return s
end

function EequipDescPagePanel:initLayer(container, equipData)
	local function refreshSelf()
	end
	self.refreshSelf = refreshSelf

	EequipDescPagePanel.super.initLayer(self)
	self.container = container
	self.equipData = equipData

	--显示卡牌说明
	local aDescArea = self.container:getChildByName("txt_1")
	self.descInnerPanel = CardDescPanel:create(
		self.equipData.metaId,
		{height=255, width=572},
		ccc3(255,255,255),
		self.equipData.cardId
	)
	self.descInnerPanel:setViewPosition(aDescArea:getPosition().x,aDescArea:getPosition().y)
	self.container:addChild(self.descInnerPanel)
	aDescArea:setVisible(false)
	self.container:getChildByName("pattern_cardInfor_line"):setVisible(false)

	self.refreshSelf()
end

function EequipDescPagePanel:dispose()
	if self.descInnerPanel then
		self.descInnerPanel:removeFromParentAndCleanup(true)
	end

	EequipDescPagePanel.super.dispose(self)
end

--设置触摸是否开启
function EequipDescPagePanel:setTableViewTouched(enabled)
	if self.descInnerPanel then
		print("EequipDescPagePanel:setTableViewTouched! enabled = " .. tostringRich(enabled))
		self.descInnerPanel:setScrollViewTouchEnable(enabled)
	end
end