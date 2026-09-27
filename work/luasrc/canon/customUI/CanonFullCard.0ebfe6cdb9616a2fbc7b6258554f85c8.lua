-- CanonFullCard.lua
-- 2014-11-11
-- zheng.che
-- 卡牌大图组件

require "hecore.display.CocosObject"
require "hecore.display.Layer"

CanonFullCard = class(Layer)

-- 创建一个卡牌大图组件
-- display 美术摆的默认图片 用来获得位置 最终居中显示
function CanonFullCard:create(display)
	local fullCard = CanonFullCard.new()
	fullCard:initLayer()
	fullCard:init(display)
	return fullCard
end

function CanonFullCard:ctor()
	self.name = "CanonFullCard"
end

function CanonFullCard:init(display)
	self.display = display

	--默认图片自动隐藏
	self.display:setVisible(false)
	--默认图片不能被点击 也不影响其他点击
	self.display.touchEnabled = false

	--悄悄替换成另一个图片
	local parent = self.display:getParent()
	self:setPositionXY(self.display:getPositionX(), self.display:getPositionY())
	self.display:getParent():addChildAt(self, self.display:getZOrder())
end

function CanonFullCard:dispose()
	if self.display then
		self.display:removeAllEventListeners()
		self.display = nil
	end
end

-- 替换显示的卡牌
-- cardMetaId 要显示卡牌的配置编号
function CanonFullCard:setCard(cardMetaId)
	if not cardMetaId then
		return 
	end

	--清空容器
	self:removeChildren(true)

	local bigCardSpriteFrame = getFullCardSpriteFrame(cardMetaId)
	local cardSprite = CCSprite:createWithSpriteFrame(bigCardSpriteFrame)
	cardDisplay = CocosObject.new(cardSprite)
	cardDisplay:setAnchorPoint(ccp(0.5, 0.5))
	self:addChild(cardDisplay)
end