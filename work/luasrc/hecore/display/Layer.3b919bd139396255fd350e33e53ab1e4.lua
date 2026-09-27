-------------------------------------------------------------------------
--  Class include: Layer, MultiTouchLayer, RootLayer, LayerColor, LayerGradient
-------------------------------------------------------------------------

require "hecore.display.Sprite"

--
-- Layer ---------------------------------------------------------
--
-- NOTICE! DO remember call initLayer after ctor;
-- because sub-class need to override layer initialization but we can not call member functions in ctor.

kTouchesMode = {kCCTouchesAllAtOnce, kCCTouchesOneByOne}
kKeypadMSGType = {kTypeBackClicked, kTypeMenuClicked}

Layer = class(CocosObject);
function Layer:ctor()
	self.nodeType = kCocosObjectType.kLayer;
	self.isLayerInitialized = false;
	self.refCocosObj = nil;
end

function Layer:initLayer()
    if not self.isLayerInitialized then
        self.isLayerInitialized = true;
		self:setRefCocosObj(CCLayer:create());
        
        if self.refCocosObj then
            self.refCocosObj:setAnchorPoint(CCPointMake(0,0));
            self.refCocosObj:setContentSize(CCSizeMake(1,1));
        end
    end
end

function Layer:toString()
	return string.format("Layer [%s]", self.name and self.name or "nil");
end

function Layer:changeWidthAndHeight(w, h) 
	self:setContentSize(CCSizeMake(w, h)) 
end

function Layer:isTouchEnabled() 
    return self.refCocosObj:isTouchEnabled() 
end

function Layer:setTouchEnabled(v) 
    self.touchEnabled = v;
    self.touchChildren = v;
    self.refCocosObj:setTouchEnabled(v) 
end

--kTouchesMode
function Layer:getTouchMode() return self.refCocosObj:getTouchMode() end;
function Layer:setTouchMode(v) self.refCocosObj:setTouchMode(v) end;

function Layer:isAccelerometerEnabled() return self.refCocosObj:isAccelerometerEnabled() end;
function Layer:setAccelerometerEnabled(v) self.refCocosObj:setAccelerometerEnabled(v) end;

function Layer:registerScriptAccelerateHandler(func) self.refCocosObj:registerScriptAccelerateHandler(func) end;
function Layer:unregisterScriptAccelerateHandler() self.refCocosObj:unregisterScriptAccelerateHandler() end;

function Layer:isKeypadEnabled() return self.refCocosObj:isKeypadEnabled() end;
function Layer:setKeypadEnabled(v) self.refCocosObj:setKeypadEnabled(v) end;

function Layer:registerScriptKeypadHandler(func) self.refCocosObj:registerScriptKeypadHandler(func) end;
function Layer:unregisterScriptKeypadHandler() self.refCocosObj:unregisterScriptKeypadHandler() end;
	
--[[
func(eventType, x, y) where eventType = 
    CCTOUCHBEGAN,
    CCTOUCHMOVED,
    CCTOUCHENDED,
    CCTOUCHCANCELLED,
]]
-- WARNING: use touch events by scene 1st. use unregisterScriptTouchHandler/registerScriptTouchHandler carefully.
function Layer:unregisterScriptTouchHandler() return self.refCocosObj:unregisterScriptTouchHandler() end;
function Layer:registerScriptTouchHandler(func, bIsMultiTouches, nPriority, bSwallowsTouches)
    local isMultiTouches = false;
    local priority = nPriority or 0;
    local swallowsTouches = false;
    if bIsMultiTouches ~= nil then isMultiTouches = bIsMultiTouches end;
    if bSwallowsTouches ~= nil then swallowsTouches = bSwallowsTouches end;
    self.refCocosObj:registerScriptTouchHandler(func, isMultiTouches, priority, swallowsTouches) 
end

--static create function
function Layer:create()
  local layer = Layer.new()
  layer:initLayer()
  return layer
end


--
-- MultiTouchLayer ---------------------------------------------------------
--

MultiTouchLayer = class(Layer)
function MultiTouchLayer:ctor()
    --when multi touch began, all other single-touch will be disabled.
    --this is very useful for disable UI touch event while drag/scale the current scene
    self.disableSceneTouchAfterTouches = true
end
--static create function
function MultiTouchLayer:create(width, height)
    local winSize = CCDirector:sharedDirector():getWinSize()
    width = width or winSize.width
    height = height or winSize.height

    local layer = MultiTouchLayer.new()
    layer:initLayer()
    layer:setContentSize(CCSizeMake(width, height))
    layer:setTouchEnabled(true)
    return layer
end

--
--all children added into this layer will not have normal-touch events dispatched by root layer.
--
function MultiTouchLayer:setTouchEnabled(v) 
    self.touchEnabled = false
    self.touchChildren = false

    self.refCocosObj:setTouchEnabled(v) 

    local  context = self
    local function onMultiTouchRootLayer(eventType, touches)
        local touchset = {}
        for i=1, #touches, 3 do
            local x, y, touchID = touches[i], touches[i+1], touches[i+2]
            table.insert(touchset, {x=x, y=y,id=touchID})
        end
        if eventType == "began" then
            context:onTouchesBegin(touchset)
        elseif eventType == "moved" then
            context:onTouchesMoved(touchset)
        elseif eventType == "ended" then
            context:onTouchesEnded(touchset)
        elseif eventType == "cancelled" then
            context:onTouchesCancelled(touchset)
        end    
        
    end
    self:registerScriptTouchHandler(onMultiTouchRootLayer, true)
end

function MultiTouchLayer:onTouchesBegin( touches )
    local scene = Director.sharedDirector():getRunningScene()
    if scene and self.disableSceneTouchAfterTouches then
        scene.touchEnabled = false
    end
    --print("onTouchesBegin", touches, #touches)
end

function MultiTouchLayer:onTouchesMoved( touches )
    print("onTouchesMoved", table.tostring(touches), #touches)
end

function MultiTouchLayer:onTouchesEnded( touches )
    local scene = Director.sharedDirector():getRunningScene()
    if scene and self.disableSceneTouchAfterTouches then
        scene.touchEnabled = true
    end
    --print("onTouchesEnded", touches, #touches)
end

function MultiTouchLayer:onTouchesCancelled( touches )
    local scene = Director.sharedDirector():getRunningScene()
    if scene and self.disableSceneTouchAfterTouches then
        scene.touchEnabled = true
    end
    --print("onTouchesCancelled", touches, #touches)
end
--
-- LayerColor ---------------------------------------------------------
--

LayerColor = class(Layer);
function LayerColor:initLayer()
    if not self.isLayerInitialized then
        self.isLayerInitialized = true;
        self:setRefCocosObj(CCLayerColor:create(ccc4(0,0,0,255))); --black

        if self.refCocosObj then
            self.refCocosObj:setAnchorPoint(CCPointMake(0,0));
            self.refCocosObj:setContentSize(CCSizeMake(1,1));
        end
    end
end

--ccColor3B
function LayerColor:getColor() return self.refCocosObj:getColor() end
function LayerColor:setColor(v) self.refCocosObj:setColor(v) end
--ccBlendFunc
function LayerColor:getBlendFunc() return self.refCocosObj:getBlendFunc() end;
function LayerColor:setBlendFunc(v) self.refCocosObj:setBlendFunc(v) end;

function LayerColor:isOpacityModifyRGB() return self.refCocosObj:isOpacityModifyRGB() end;
function LayerColor:setOpacityModifyRGB(v) self.refCocosObj:setOpacityModifyRGB(v) end;

function LayerColor:changeWidth(v) self.refCocosObj:changeWidth(v) end
function LayerColor:changeHeight(v) self.refCocosObj:changeHeight(v) end
function LayerColor:changeWidthAndHeight(w, h) self.refCocosObj:changeWidthAndHeight(w, h) end

--static create function
function LayerColor:create()
  local layer = LayerColor.new()
  layer:initLayer()
  return layer
end
--
-- LayerGradient ---------------------------------------------------------
--

LayerGradient = class(LayerColor);
function LayerGradient:initLayer()
    if not self.isLayerInitialized then
        self.isLayerInitialized = true;
        self:setRefCocosObj(CCLayerGradient:create(ccc4(0,0,0,0),ccc4(0,0,0,0)));

        if self.refCocosObj then
            self.refCocosObj:setAnchorPoint(CCPointMake(0,0));
            self.refCocosObj:setContentSize(CCSizeMake(1,1));
        end
    end
end
--ccColor3B
function LayerGradient:getStartColor() return self.refCocosObj:getStartColor() end;
function LayerGradient:setStartColor(v) self.refCocosObj:setStartColor(v) end;
--ccColor3B
function LayerGradient:getEndColor() return self.refCocosObj:getEndColor() end;
function LayerGradient:setEndColor(v) self.refCocosObj:setEndColor(v) end;
--GLubyte
function LayerGradient:getStartOpacity() return self.refCocosObj:getStartOpacity() end;
function LayerGradient:setStartOpacity(v) self.refCocosObj:setStartOpacity(v) end;
--GLubyte
function LayerGradient:getEndOpacity() return self.refCocosObj:getEndOpacity() end;
function LayerGradient:setEndOpacity(v) self.refCocosObj:setEndOpacity(v) end;
--CCPoint
function LayerGradient:getVector() return self.refCocosObj:getVector() end;
function LayerGradient:setVector(v) self.refCocosObj:setVector(v) end;

function LayerGradient:isCompressedInterpolation() return self.refCocosObj:isCompressedInterpolation() end;
function LayerGradient:setCompressedInterpolation(v) self.refCocosObj:setCompressedInterpolation(v) end;

--static create function
function LayerGradient:create()
  local layer = LayerGradient.new()
  layer:initLayer()
  return layer
end

--
-- RootLayer ---------------------------------------------------------
--

RootLayer = class(Layer);
function RootLayer:ctor()
	self.name = "root";
end

--static create function
function RootLayer:create()
  local layer = RootLayer.new()
  layer:initLayer()
  return layer
end

local function sortOnComputedIndex(a, b) return a.computeIndex < b.computeIndex end
local function sortOnDepth(a, b) return a.depth < b.depth end

local function removeAncestorObject(parentRemovedObject)
    local haveLinkedItems = false;
    for i, v in ipairs(parentRemovedObject) do
        for j, k in ipairs(parentRemovedObject) do
            if v ~= k and v:isAncestor(k) then v.__linked = true; haveLinkedItems = true; end;
        end
    end
    if haveLinkedItems then
        local ret = {};
            for i, v in ipairs(parentRemovedObject) do
                if not v.__linked then table.insert(ret, v) end;
            end
        return ret;
    else
        return parentRemovedObject;
    end
end

local function computeTouchedObject(parentRemovedObject, rootLayer)
    -- trick of Lowest Common Ancestor probles. we do not use any of LCA algorithms 
    -- more discuss at http://en.wikipedia.org/wiki/Lowest_common_ancestor
    -- also: http://community.topcoder.com/tc?module=Static&d1=tutorials&d2=lowestCommonAncestor
    
    if table.getn(parentRemovedObject) > 1 then
        local commonRoot = parentRemovedObject[1].root;
        local haveSameRoot = true;
        for i, v in ipairs(parentRemovedObject) do
            if v.root ~= commonRoot then 
                haveSameRoot = false;
                break;
            end;
        end
        
        --have same root, need compute root again.
        if haveSameRoot then
            for i, v in ipairs(parentRemovedObject) do v:computeRoot(commonRoot,rootLayer) end;
        end
    end
    
    local ret = {};
    
    local maxIndex = -1;
    for i, v in ipairs(parentRemovedObject) do
        if v.root and v.root.index > maxIndex and not v.root.notAffectTouchEvent then maxIndex = v.root.index end;
    end
    if maxIndex ~= -1 then
        for i, v in ipairs(parentRemovedObject) do
            if v.root and v.root.index == maxIndex then table.insert(ret, v) end;
        end
    end
    
    return ret;
end

--height if display tree(parent level): max 10 (1 for scene, 1 for root layer)
function RootLayer:getObjectUnderPointForTouch(worldPosition, eventType)

    local allHitObject = {};
    local parentRemovedObject = {};
     
    self:__getObjectUnderPointForTouch(worldPosition, allHitObject, {0});
    table.sort(allHitObject, sortOnComputedIndex);
    
    for i, v in ipairs(allHitObject) do
		--print(v:toString())
        if v.refCocosObj:hitTestPoint(worldPosition, false, false) then
            table.insert(parentRemovedObject, v);
            v:computeRoot(self, self);
            v.__linked = false;
        end
    end
    
    local length = 0;
    length = table.getn(parentRemovedObject);
    if length > 1 then
        --remove object that heve linked by child-parent.
        parentRemovedObject = removeAncestorObject(parentRemovedObject);
    end
    
    parentRemovedObject = computeTouchedObject(parentRemovedObject, self);
    local times = 0;
    length = table.getn(parentRemovedObject);
    while length > 1 and times < 12 do
        parentRemovedObject = computeTouchedObject(parentRemovedObject, self);
        length = table.getn(parentRemovedObject);
        times = times + 1;
    end 
    
    local ret = {};
    length = table.getn(parentRemovedObject);
    if length > 0 then
        local finalObj = parentRemovedObject[1];
        table.insert(ret, finalObj.refCocosObj);
        --local  gbs = finalObj.refCocosObj:getGroupBounds(nil);
        --print(eventType.."-"..tostring(finalObj.refCocosObj.name).."-"..gbs.origin.x.."-"..gbs.origin.y.."-"..gbs.size.width.."-"..gbs.size.height);
        local parent_ = finalObj.refCocosObj:getParent();
        while parent_ and parent_ ~= self do
            if parent_ ~= self then table.insert(ret, parent_) end;
            parent_ = parent_:getParent();
        end    
    end
        
    return ret;
end