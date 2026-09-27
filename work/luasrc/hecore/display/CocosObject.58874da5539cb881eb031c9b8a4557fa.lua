-------------------------------------------------------------------------
--  Class include: DisplayBounds, CocosObject, ClippingNode, TouchResult[internal use only]
-------------------------------------------------------------------------

require "hecore.class"
require "hecore.EventDispatcher"

kCocosObjectType = {kLayer = 1, kScene = 2, kRootLayer = 3, kOthers = 4}
kHitAreaObjectName = "hit_area";
kHitAreaObjectTag = -100;
--
-- DisplayBounds ---------------------------------------------------------
--
DisplayBounds = class();

function DisplayBounds:ctor(x,y,w,h)
    self.x = x or 0;
    self.y = y or 0;
    self.width = w or 0;
    self.height = h or 0;    
    
    self.origin = {x= x, y=y}
    self.size = {width=w,height=h}
end

function DisplayBounds:getPosition()
  return ccp(self.x, self.y)
end

function DisplayBounds:getSize()
  return CCSizeMake(self.width, self.height);
end

function DisplayBounds:toRect()
    return CCRectMake(self.x,self.y, self.width, self.height);
end

function DisplayBounds:toString()
	return string.format("DisplayBounds [x=%d,y=%d,w=%d,h=%d]", self.x, self.y, self.width, self.height);
end

function DisplayBounds:mergeBound(b)
	local minX, minY, maxX, maxY = self.x, self.y, self.x + self.width, self.y + self.height;
    local vx, vy, vw, vh = b.x, b.y, b.x + b.width, b.y + b.height;           
    if vx < minX then minX = vx end;
    if vy < minY then minY = vy end;
    if vw > maxX then maxX = vw end;
    if vh > maxY then maxY = vh end;
    self.x, self.y, self.width, self.height = minX, minY, maxX - minX, maxY - minY;
end

function DisplayBounds:mergeBounds(list)
	local minX, minY, maxX, maxY = self.x, self.y, self.x + self.width, self.y + self.height;
    for i, v in ipairs(list) do
        local vx, vy, vw, vh = v.x, v.y, v.x + v.width, v.y + v.height;       
        if vx < minX then minX = vx end;
        if vy < minY then minY = vy end;
        if vw > maxX then maxX = vw end;
        if vh > maxY then maxY = vh end;
    end
    self.x, self.y, self.width, self.height = minX, minY, maxX - minX, maxY - minY;
end

--
-- kZeroDisplayBound ---------------------------------------------------------
--
kZeroDisplayBound = DisplayBounds.new(0,0,1,1);

--
-- CocosObject ---------------------------------------------------------
--

CocosObject = class(EventDispatcher);
function CocosObject:ctor(refCocosObj)
    self.parent = nil;
	self.nodeType = kCocosObjectType.kOthers; --for faster compare then class:is();

    self.anchorX = 0;
	self.anchorY = 0;
	
    self.touchEnabled = true;
    self.touchChildren = true;
    
	self.index = 0; -- [0 - getNumOfChildren]
	self.list = {};
	self.name = nil;
	
    self:setRefCocosObj(refCocosObj)
    self.isDisposed = false;
end

function CocosObject:toString()
	return string.format("CocosObject [%s]", self.name and self.name or "nil");
end

function CocosObject:retain()
	self.toRetain = true;
end

function CocosObject:unretain()
	self.toRetain = false;
end

function CocosObject:dispose()
	if self.toRetain then
		do return end
	end
  --print("dispose", self:toString());
	if self.refCocosObj then
        self.refCocosObj:stopAllActions(); -- stop all actions? nor sure if it needed.
        self.refCocosObj:release();
        self.refCocosObj = nil;
    end
	if self.list then for k, v in pairs(self.list) do v:dispose() end end;
	self.list = nil;
	self.refCocosObj = nil;
	self.name = nil;
	self.parent = nil;
	
	self.isDisposed = true;
end

-- static object creation
function CocosObject:create()
  return CocosObject.new(CCNode:create())
end

function CocosObject:updatePivot()
    if self.refCocosObj then self.refCocosObj:setAnchorPoint(ccp(self.anchorX,self.anchorY)) end;
end

function CocosObject:setRefCocosObj(refCocosObj)
    if self.refCocosObj == refCocosObj then return end;

    if self.refCocosObj then
        self.refCocosObj:release();
        self.refCocosObj = nil;
    end
    self.refCocosObj = refCocosObj;

    local context = self
    local function sceneEventHandler( eventType )
        if eventType == "enter" then 
            if self:hn(Events.kAddToStage) then self:dp(Event.new(Events.kAddToStage, nil, self)) end
            context:onAddToStage()
        elseif eventType == "exit" then 
            if self:hn(Events.kRemoveFromStage) then self:dp(Event.new(Events.kRemoveFromStage, nil, self)) end
            context:onRemoveFromStage()
        elseif eventType == "cleanup" then 
            if self:hn(Events.kDispose) then self:dp(Event.new(Events.kDispose, nil, self)) end
            context:onCocosDispose() 
        end
    end 

    if self.refCocosObj then
        self.refCocosObj:registerScriptHandler(sceneEventHandler) 
        self.refCocosObj:retain();
    end
end

function CocosObject:onAddToStage() end
function CocosObject:onRemoveFromStage() end
function CocosObject:onCocosDispose() end

--
-- public props ---------------------------------------------------------
--
function CocosObject:getParent() return self.parent end
function CocosObject:getCocosRefParent() 
	if self.refCocosObj then
		return self.refCocosObj:getParent()
	end
end

function CocosObject:isRunning() 
	if self.refCocosObj then
		return self.refCocosObj:isRunning() 
	end
end
function CocosObject:getZOrder() 
	if self.refCocosObj then
		return self.refCocosObj:getZOrder() 
	end
end
function CocosObject:setZOrder(v) 
	if self.refCocosObj then
		return self.refCocosObj:setZOrder(v)
	end
end
function CocosObject:getNumOfChildren() return table.getn(self.list) end --self.refCocosObj:getChildrenCount() end

function CocosObject:getRotation() 
	if self.refCocosObj then
		return self.refCocosObj:getRotation() 
	end
end
function CocosObject:setRotation(v) 
	if self.refCocosObj then
		self.refCocosObj:setRotation(v) 
	end
end

function CocosObject:getRotationX() return HeDisplayUtil:getRotationX(self.refCocosObj) end
function CocosObject:setRotationX(v) HeDisplayUtil:setRotationX(self.refCocosObj,v) end

function CocosObject:getRotationY() return HeDisplayUtil:getRotationY(self.refCocosObj) end
function CocosObject:setRotationY(v) HeDisplayUtil:setRotationY(self.refCocosObj,v) end

function CocosObject:getScale() 
	if self.refCocosObj then
		return self.refCocosObj:getScale() 
	end
end
function CocosObject:setScale(v) 
	if self.refCocosObj then
		self.refCocosObj:setScale(v) 
	end
end

function CocosObject:getScaleX() 
	if self.refCocosObj then
		return self.refCocosObj:getScaleX() 
	end
end
function CocosObject:setScaleX(v) 
	if self.refCocosObj then
		self.refCocosObj:setScaleX(v) 
	end
end

function CocosObject:getScaleY() 
	if self.refCocosObj then
		return self.refCocosObj:getScaleY() 
	end
end
function CocosObject:setScaleY(v) 
	if self.refCocosObj then
		self.refCocosObj:setScaleY(v) 
	end
end

--CCPoint
function CocosObject:getPosition() return HeDisplayUtil:getNodePosition(self.refCocosObj) end
function CocosObject:setPosition(v) 
	if self.refCocosObj then
		self.refCocosObj:setPosition(v) 
	end
end
function CocosObject:setPositionXY(x, y) 
	if self.refCocosObj then
		self.refCocosObj:setPosition(x, y) 
	end
end

function CocosObject:getPositionX() 
	if self.refCocosObj then
		return self.refCocosObj:getPositionX() 
	end
end
function CocosObject:setPositionX(v) 
	if self.refCocosObj then
		self.refCocosObj:setPositionX(v)
	end
end

function CocosObject:getPositionY()
	if self.refCocosObj then
		return self.refCocosObj:getPositionY()
	end
end
function CocosObject:setPositionY(v) 
	if self.refCocosObj then
		self.refCocosObj:setPositionY(v)
	end
end

function CocosObject:getSkewX() 
	if self.refCocosObj then
		return self.refCocosObj:getSkewX()
	end
end
function CocosObject:setSkewX(v) 
	if self.refCocosObj then
		self.refCocosObj:setSkewX(v) 
	end
end

function CocosObject:getSkewY() 
	if self.refCocosObj then
		return self.refCocosObj:getSkewY()
	end
end
function CocosObject:setSkewY(v) 
	if self.refCocosObj then
		self.refCocosObj:setSkewY(v) 
	end
end

function CocosObject:getOpacity() 
	if self.refCocosObj then
		return self.refCocosObj:getOpacity() 
	end
end
function CocosObject:setOpacity(v) 
	if self.refCocosObj then
		self.refCocosObj:setOpacity(v) 
	end
end

function CocosObject:getAlpha() 
	if self.refCocosObj then
		return self.refCocosObj:getOpacity()/255 
	end
end
function CocosObject:setAlpha(v)  
	if self.refCocosObj then
		local v_ = math.floor(v * 255 + 0.5); --round
		self.refCocosObj:setOpacity(v_);
	end
end

function CocosObject:isVisible() 
	if self.refCocosObj then
		return self.refCocosObj:isVisible() 
	end
end
function CocosObject:setVisible(v) 
	if self.refCocosObj then
		self.refCocosObj:setVisible(v) 
	end
end

--void*
function CocosObject:getUserData() 
	if self.refCocosObj then
		return self.refCocosObj:getUserData() 
	end
end
function CocosObject:setUserData(v) 
	if self.refCocosObj then
		self.refCocosObj:setUserData(v) 
	end
end

--CCPoint
function CocosObject:getAnchorPoint() 
	if self.refCocosObj then
		return self.refCocosObj:getAnchorPoint() 
	end
end
function CocosObject:setAnchorPoint(v) 
	if self.refCocosObj then
		self.refCocosObj:setAnchorPoint(v) 
	end
end

function CocosObject:isIgnoreAnchorPointForPosition() 
	if self.refCocosObj then
		return self.refCocosObj:isIgnoreAnchorPointForPosition() 
	end
end
function CocosObject:ignoreAnchorPointForPosition(v) 
	if self.refCocosObj then
		self.refCocosObj:ignoreAnchorPointForPosition(v) 
	end
end

-- [CCSize]The untransformed size of the node.
-- The contentSize remains the same no matter the node is scaled or rotated.
-- All nodes has a size. Layer and Scene has the same size of the screen.
function CocosObject:getContentSize() 
	if self.refCocosObj then
		return self.refCocosObj:getContentSize() 
	end
end
function CocosObject:setContentSize(v) 
	if self.refCocosObj then
		self.refCocosObj:setContentSize(v) 
	end
end

--int
function CocosObject:getTag() 
	if self.refCocosObj then
		return self.refCocosObj:getTag() 
	end
end
function CocosObject:setTag(v) 
	if self.refCocosObj then
		self.refCocosObj:setTag(v) 
	end
end

--return a raw c++ cocos object by tag
--[[
function CocosObject:getChildByTag(tag)
    return self.refCocosObj:getChildByTag(v)
end
]]
--CCRect
function CocosObject:boundingBox() 
	if self.refCocosObj then
		return self.refCocosObj:boundingBox() 
	end
end

--
-- public methods of actions ---------------------------------------------------------
--

function CocosObject:cleanup() 
	if self.refCocosObj then
		self.refCocosObj:cleanup() 
	end
end
function CocosObject:draw() 
	if self.refCocosObj then
		self.refCocosObj:draw() 
	end
end
function CocosObject:visit() 
	if self.refCocosObj then
		self.refCocosObj:visit() 
	end
end
function CocosObject:transform() 
	if self.refCocosObj then
		self.refCocosObj:transform() 
	end
end
function CocosObject:scheduleUpdate() 
	if self.refCocosObj then
		self.refCocosObj:scheduleUpdate() 
	end
end
function CocosObject:unscheduleUpdate() 
	if self.refCocosObj then
		self.refCocosObj:unscheduleUpdate() 
	end
end

--CCAction
function CocosObject:runAction(v) 
	if self.refCocosObj then
		return self.refCocosObj:runAction(v) 
	end
end
function CocosObject:stopAllActions() 
	if self.refCocosObj then
		self.refCocosObj:stopAllActions() 
	end
end
function CocosObject:stopAction(v) 
	if self.refCocosObj then
		self.refCocosObj:stopAction(v) 
	end
end
function CocosObject:stopActionByTag(v) 
	if self.refCocosObj then
		self.refCocosObj:stopActionByTag(v) 
	end
end
function CocosObject:getActionByTag(v) 
	if self.refCocosObj then
		return self.refCocosObj:getActionByTag(v) 
	end
end
function CocosObject:numberOfRunningActions() 
	if self.refCocosObj then
		return self.refCocosObj:numberOfRunningActions() 
	end
end

--CCGridBase
function CocosObject:setGrid(v) 
	if self.refCocosObj then
		self.refCocosObj:setGrid(v) 
	end
end

--CCAffineTransform
function CocosObject:nodeToParentTransform() 
	if self.refCocosObj then
		return self.refCocosObj:nodeToParentTransform() 
	end
end
function CocosObject:parentToNodeTransform() 
	if self.refCocosObj then
		return self.refCocosObj:parentToNodeTransform() 
	end
end
function CocosObject:nodeToWorldTransform() 
	if self.refCocosObj then
		return self.refCocosObj:nodeToWorldTransform() 
	end
end
function CocosObject:worldToNodeTransform() 
	if self.refCocosObj then
		return self.refCocosObj:worldToNodeTransform() 
	end
end

--CCPoint
function CocosObject:convertToNodeSpace(v) 
	if self.refCocosObj then
		return self.refCocosObj:convertToNodeSpace(v) 
	end
end
function CocosObject:convertToWorldSpace(v) 
	if self.refCocosObj then
		return self.refCocosObj:convertToWorldSpace(v) 
	end
end
function CocosObject:convertToNodeSpaceAR(v) 
	if self.refCocosObj then
		return self.refCocosObj:convertToNodeSpaceAR(v) 
	end
end
function CocosObject:convertToWorldSpaceAR(v) 
	if self.refCocosObj then
		return self.refCocosObj:convertToWorldSpaceAR(v) 
	end
end
function CocosObject:convertTouchToNodeSpace(v) 
	if self.refCocosObj then
		return self.refCocosObj:convertTouchToNodeSpace(v) 
	end
end
function CocosObject:convertTouchToNodeSpaceAR(v) 
	if self.refCocosObj then
		return self.refCocosObj:convertTouchToNodeSpaceAR(v) 
	end
end

--
-- public methods of display ---------------------------------------------------------
--
function CocosObject:refreshIndex()
	local dp = self.refCocosObj;
	for i, v in ipairs(self.list) do
		--this is a very ligng function call, just setup it's globalOrderOfArrival and zOrder.
		if v.refCocosObj then dp:reorderChild(v.refCocosObj, v.index) end; 
	end
end

function CocosObject:contains(child)
    if not child then return false end;
	for k, v in pairs(self.list) do if v == child then return true end end;
	return false;
end
function CocosObject:addChild(child)
	self:addChildAt(child, #self.list);
end
-- index: [0 - getNumOfChildren]
function CocosObject:addChildAt(child, index)
    if not child or not child.refCocosObj then return end;
	local added = self:contains(child);
	if added then return end;

	local compare = child.refCocosObj;
	
	if kHitAreaObjectName == child.name then 
        self.refCocosObj:addChild(compare, index, kHitAreaObjectTag);
    else
        self.refCocosObj:addChild(compare, index);
    end
		
    local oldIndex = table.getn(self.list);
	table.insert(self.list, index+1, child);
	child.parent = self;

	--update index
	for i, v in ipairs(self.list) do v.index = i-1 end;
    if index ~= oldIndex then self:refreshIndex() end;
end

function CocosObject:getChildByName(childName)
	for i, v in ipairs(self.list) do
		if childName == v.name then return v end;
	end
	return nil;
end

-- index: [0 - getNumOfChildren]
function CocosObject:getChildAt(index)
	if index < 0 or index >= #self.list then return nil end;
	return self.list[index+1];
end
-- index: [0 - getNumOfChildren], -1 means not found.
function CocosObject:getChildIndex(child)
	if not child then return -1 end;

	for i, v in ipairs(self.list) do
		if v == child then return i - 1 end;
	end

	return -1;
end

function CocosObject:removeFromParentAndCleanup(cleanup)
  if self.parent then
    self.parent:removeChild(self, cleanup);
  end
end

-- default: cleanup = true;
function CocosObject:removeChild(child, cleanup, __not_remove_cocos_child__)
	if not child then return end;
	local isCleanup = true;
	if cleanup ~= nil then isCleanup = cleanup end;

	--clean cocos2d
	local compare = child.refCocosObj;
	if not compare then return end;
	if not __not_remove_cocos_child__ then self.refCocosObj:removeChild(compare, isCleanup) end;
	
	local cd = 0;
	for i, v in ipairs(self.list) do
		if v == child then cd = i end;
	end

	--clean self list
	if cd > 0 then
		table.remove(self.list, cd);
		child.parent = nil;
		for i, v in ipairs(self.list) do v.index = i-1 end;
	end

	if(isCleanup) then child:dispose() end;
end

-- index: [0 - getNumOfChildren]
function CocosObject:removeChildAt(index, cleanup)
	local child = self:getChildAt(index);
	local isCleanup = true;
	if cleanup ~= nil then isCleanup = cleanup end;

	if child then self:removeChild(child, isCleanup) end;
end

function CocosObject:removeChildren(cleanup)
    local isCleanup = true;
	if cleanup ~= nil then isCleanup = cleanup end;

	self.refCocosObj:removeAllChildrenWithCleanup(isCleanup);
    if isCleanup then
        for k, v in pairs(self.list) do v:dispose() end;
    end
    self.list = {};
end

local function sortOnIndex(a, b) return a.index < b.index end
function CocosObject:setChildIndex(child, index)
	local added = self:contains(child);
	if (not added) or (child.index == index) then return end;

	for i, v in ipairs(self.list) do
		local cd = i - 1;
		if (cd >= index) and (v ~= child) then
			v.index = v.index + 1;
		end
	end
	child.index = index;

	table.sort(self.list, sortOnIndex)
	self:refreshIndex();
end

function CocosObject:swapChildren(child1, child2)
	local child1Index = self:getChildIndex(child1);
	local child2Index = self:getChildIndex(child2);
	if child1Index >= 0 and child2Index >= 0 then
		child1.index = child2Index;
		child2.index = child1Index;

		local sp = self.refCocosObj;
		if child1.refCocosObj then sp:reorderChild(child1.refCocosObj, child1.index) end;
		if child2.refCocosObj then sp:reorderChild(child2.refCocosObj, child2.index) end;
	end
end

function CocosObject:swapChildrenAt(child1, child2)
	local c1 = self:getChildAt(child1);
	local c2 = self:getChildAt(child2);
	if c1 and c2 then self:swapChildren(c1, c2) end;
end

--
-- public methods of display ---------------------------------------------------------
--

--Returns a rectangle that defines the area of the display object relative to the coordinate system of the targetCoordinateSpace object. 
function CocosObject:getBounds(targetCoordinateSpace)
    local targetSpace = nil;
    if targetCoordinateSpace then targetSpace = targetCoordinateSpace.refCocosObj end
    return HeDisplayUtil:getNodeBounds(self.refCocosObj, targetSpace);
end

--Returns a rectangle that defines the area of the display object relative to the coordinate system of the targetCoordinateSpace object.  
--Including all it's children.
function CocosObject:getGroupBounds(targetCoordinateSpace)
    local targetSpace = nil;
    if targetCoordinateSpace then targetSpace = targetCoordinateSpace.refCocosObj end
    return HeDisplayUtil:getNodeGroupBounds(self.refCocosObj, targetSpace, kHitAreaObjectTag);
end
--Evaluates the display object to see if it overlaps or intersects with the point specified by the worldPosition parameters.
--if useGroupTest, we will check all it's children's bounds.
function CocosObject:hitTestPoint(worldPosition, useGroupTest)
    local isUseGroupTest = false;
    if useGroupTest ~= nil then isUseGroupTest = useGroupTest end;
    return HeDisplayUtil:hitTestPoint(self.refCocosObj, worldPosition, isUseGroupTest, kHitAreaObjectTag);
end

--private
function CocosObject:__getObjectUnderPointForTouch(worldPosition, objectList, depth)
    if not objectList then return end;
    
    local numberOfChildren = self:getNumOfChildren();
    local invalid = (not self.touchChildren) or (numberOfChildren <= 0);
    if invalid then return end;
    
    local currentDepth = 0;
    if not depth then 
        depth = {0};
    else
        currentDepth = depth[1];
        currentDepth = currentDepth + 1;
        depth[1] = currentDepth;
    end
    
    for i = numberOfChildren, 1, -1 do
        local v = self.list[i];
        if v and (not v.isDisposed) then
	        local ignoredItem = (v.nodeType == 1 and not v:isVisible());
	        local isHit = false;
	        if not ignoredItem then 
	             isHit = v:hitTestPoint(worldPosition, true);
			--else print("ignored", v.name)
	        end

	        if isHit then  --use group hit test
	            if v.touchEnabled then 
	                table.insert(objectList, TouchResult.new(v, currentDepth));
	            end
	            if v.touchChildren then
	               v:__getObjectUnderPointForTouch(worldPosition, objectList, depth);
	            end
	        end
	    end
    end
end


--
-- ClippingNode ---------------------------------------------------------
--
ClippingNode = class(CocosObject)

--CCNode
function ClippingNode:getStencil() 
	if self.refCocosObj then
		return self.refCocosObj:getStencil() 
	end
end
function ClippingNode:setStencil(v) 
	if self.refCocosObj then
		self.refCocosObj:setStencil(v) 
	end
end

--GLfloat, 1.0f by default
function ClippingNode:getAlphaThreshold() 
	if self.refCocosObj then
		return self.refCocosObj:getAlphaThreshold() 
	end
end
function ClippingNode:setAlphaThreshold(v) 
	if self.refCocosObj then
		self.refCocosObj:setAlphaThreshold(v) 
	end
end

function ClippingNode:isInverted() 
	if self.refCocosObj then
		return self.refCocosObj:isInverted() 
	end
end
function ClippingNode:setInverted(v) 
	if self.refCocosObj then
		self.refCocosObj:setInverted(v) 
	end
end

--static creation function
function ClippingNode:create (clipRect, target)
  if not clipRect then
    print("invalid params for buildClippingNode")
    return 
  end
  local stencilNode = CCLayerColor:create(ccc4(255,255,255,255), clipRect.size.width, clipRect.size.height)
  local node = ClippingNode.new(CCClippingNode:create(stencilNode))
  if target then node:addChild(target) end
  return node
end

--
-- TouchResult ---------------------------------------------------------
--
TouchResult = class();
function TouchResult:ctor(refCocosObj, depth)
    self.refCocosObj = refCocosObj;
    self.root = nil;
    self.depth = depth or 0;
    self.computeIndex = self.depth * 1000 + self.refCocosObj.index;
    
    self.__linked = false;
end

function TouchResult:computeRoot(rootLayer, stopParent)    
    self.root = self.refCocosObj;
    
    local parent = self.refCocosObj:getParent();
    while parent and parent ~= rootLayer and parent ~= stopParent do
        if parent ~= rootLayer and parent ~= stopParent then self.root = parent end;
        parent = parent:getParent();
    end    
end

function TouchResult:isAncestor(compare)
    if not compare then return false end;
    
    local parent = compare.refCocosObj:getParent();
    while parent do
        if parent == self.refCocosObj then return true end;
        parent = parent:getParent();
    end 
    
    return false;  
end


function TouchResult:toString()
	if self.refCocosObj then
		return "["..self.refCocosObj.name.."] "..self.depth.."/"..self.computeIndex;
	end
end