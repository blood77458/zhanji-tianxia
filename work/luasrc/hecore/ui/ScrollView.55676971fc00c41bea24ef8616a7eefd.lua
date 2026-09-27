require "hecore.display.Director"

kScrollViewDirection = {kCCScrollViewDirectionNone, 
				kCCScrollViewDirectionHorizontal, 
				kCCScrollViewDirectionVertical, 
				kCCScrollViewDirectionBoth}

ScrollView = class(CocosObject)

function ScrollView:dispose()
	CocosObject.dispose(self)
end

function ScrollView:create(width, height)
	local size = CCSizeMake(width, height)
	local view = ScrollView.new(CCScrollView:create()) 
	
	--hitarea
	local node = CocosObject:create()
	node.name = kHitAreaObjectName
	node.touchEnabled = false
	node.touchChildren = false

	view:addChild(node)

	view.hitArea = node
	view:addChild(node)
	view:setViewSize(size)
	return view
end

function ScrollView:setTouchEnabled(v) 
	self.touchEnabled = true
    self.touchChildren = true
	self.refCocosObj:setTouchEnabled(v)
end

function ScrollView:isBounceable() return self.refCocosObj:isBounceable() end
function ScrollView:setBounceable(v) self.refCocosObj:setBounceable(v) end

function ScrollView:isClippingToBounds() return self.refCocosObj:isClippingToBounds() end
function ScrollView:setClippingToBounds(v) self.refCocosObj:setClippingToBounds(v) end

--CCNode
function ScrollView:getContainer() return self.refCocosObj:getContainer() end
function ScrollView:setContainer(v) self.refCocosObj:setContainer(v) end

--Sets a new content offset. It ignores max/min offset. It just sets what's given. (just like UIKit's UIScrollView)
--void setContentOffset(CCPoint offset, bool animated = false);
function ScrollView:getContentOffset() return self.refCocosObj:getContentOffset() end
function ScrollView:setContentOffset(offset, animated) self.refCocosObj:setContentOffset(offset) end

function ScrollView:setContentOffsetInDuration(offset, dt) self.refCocosObj:setContentOffsetInDuration(offset, dt) end
function ScrollView:setScrollViewAnimationParemeter(scrollDeaccelRate, 
													scrollDeaccelDist, 
													bounceDuration, 
													insetRatio, 
													moveInch) 
	self.refCocosObj:setScrollViewAnimationParemeter(scrollDeaccelRate, 
													scrollDeaccelDist, 
													bounceDuration, 
													insetRatio, 
													moveInch) 
end

--CCScrollViewDirection
function ScrollView:getDirection() return self.refCocosObj:getDirection() end
function ScrollView:setDirection(v) self.refCocosObj:setDirection(v) end

function ScrollView:isDragging() return self.refCocosObj:isDragging() end
--Determines if a given node's bounding box is in visible bounds
function ScrollView:isNodeVisible(node) return self.refCocosObj:isNodeVisible(node) end
function ScrollView:isTouchMoved() return self.refCocosObj:isTouchMoved() end

--CCSize
--size to clip. CCNode boundingBox uses contentSize directly.
function ScrollView:getViewSize() return self.refCocosObj:getViewSize() end
function ScrollView:setViewSize(v) 
	self.refCocosObj:setViewSize(v) 
	if self.hitArea then self.hitArea:setContentSize(CCSizeMake(v.width, v.height)) end
end

function ScrollView:adjustHitArea()
  local aSize = self:getContentSize()
  if self.hitArea then self.hitArea:setContentSize(CCSizeMake(aSize.width, aSize.height))
  end
end

function ScrollView:getZoomScale() return self.refCocosObj:getZoomScale() end
function ScrollView:setZoomScale(v) self.refCocosObj:setZoomScale(v) end
function ScrollView:setZoomScaleInDuration(v) self.refCocosObj:setZoomScaleInDuration(v) end