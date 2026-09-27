require "hecore.display.Layer"

--
-- Scene ---------------------------------------------------------
--

local debugTouchEvent = false;

-- NOTICE! DO remember call initScene after ctor;
-- because we can not call member functions in ctor.

Scene = class(CocosObject);
function Scene:ctor()
	self.nodeType = kCocosObjectType.kScene;

	--only CClayer can handle touch via registerScriptTouchHandler. we add all display object to this layer instead of scene self.
	self.rootLayer = nil;
	self.isSceneInitialized = false;
	self.touchEnabled = false;
	
	local winSize = CCDirector:sharedDirector():getWinSize();
	self.screenWidth = winSize.width;
	self.screenHeight = winSize.height;
	
	self:setRefCocosObj(CCScene:create());
	
	if self.refCocosObj then
		self.refCocosObj:setAnchorPoint(CCPointMake(0,0));
		self.refCocosObj:ignoreAnchorPointForPosition(true);
	end
	self:sceneFitDevice()
end

local extra_border_width = 120

local TAG_LEFT_BOARD = 123456
local TAG_RIGHT_BOARD = 123457

function Scene:sceneFitDevice(resPath)
	if not resPath then
		resPath = "pic/shipei.png"
	end
	local screenWidth = MetaInfo:getInstance():getResolutionWidth()
	local screenHeight = MetaInfo:getInstance():getResolutionHeight()
	if __ANDROID and screenWidth > screenHeight then
		local temp = screenWidth
		screenWidth = screenHeight
		screenHeight = temp
	end
	local curVisibleSize = CCDirector:sharedDirector():getVisibleSize()
	if screenWidth / screenHeight > curVisibleSize.width / curVisibleSize.height then
		local endWidth = screenWidth / screenHeight * curVisibleSize.height
		local setRectWidth
		--[[if endWidth >= curVisibleSize.width + extra_border_width * 2 then
		else
			setRectWidth = (endWidth - curVisibleSize.width) / 2
		end--]]
		
		local function createBorderSprite()
			local borderSprite = Sprite:create(resPath)
			borderSprite:setAnchorPoint(ccp(1, 0))
			borderSprite:setScaleX(extra_border_width / borderSprite:getContentSize().width)
			borderSprite:setScaleY(curVisibleSize.height / borderSprite:getContentSize().height)
			if setRectWidth then
				borderSprite:setTextureRect(CCRectMake((1 - setRectWidth / extra_border_width) * borderSprite:getContentSize().width, 0, setRectWidth / extra_border_width * borderSprite:getContentSize().width, borderSprite:getContentSize().height))
			end
			return borderSprite
		end
		
		if self.refCocosObj:getChildByTag(TAG_LEFT_BOARD) then
			self.refCocosObj:removeChildByTag(TAG_LEFT_BOARD, true)
		end
		
		local leftSprite = createBorderSprite()
		leftSprite:setPositionXY(0, 0)
		--leftSprite:setScaleX(-leftSprite:getScaleX())
		leftSprite:setTag(TAG_LEFT_BOARD)
		self.refCocosObj:addChild(leftSprite.refCocosObj, 100000)
		leftSprite:dispose()
		
		if self.refCocosObj:getChildByTag(TAG_RIGHT_BOARD) then
			self.refCocosObj:removeChildByTag(TAG_RIGHT_BOARD, true)
		end
		local rightSprite = createBorderSprite()
		rightSprite:setPositionXY(curVisibleSize.width, 0)
		rightSprite:setScaleX(-rightSprite:getScaleX())
		rightSprite:setTag(TAG_RIGHT_BOARD)
		self.refCocosObj:addChild(rightSprite.refCocosObj, 100000)
		rightSprite:dispose()
	end
end

function Scene:initScene()
  if not self.isSceneInitialized then
    self.isSceneInitialized = true;
    self.rootLayer = RootLayer.new(); --scene's root layer is a RootLayer class
    self.rootLayer:initLayer();
    self:superAddChild(self.rootLayer);
  end
  
  self:setTouchEnabled(true);
  self:onInit();
end

--static create function
function Scene:create()
  local s = Scene.new()
  s:initScene()
  return s
end

function Scene:onInit()end
function Scene:onEnter(params)end
function Scene:onExit()end
function Scene:onKeyBackClicked() end
function Scene:onUpdate(dt)
end

function Scene:toString()
	return string.format("Scene [%s]", self.name and self.name or "nil");
end
function Scene:dispose()
	if self.rootLayer then self.rootLayer:dispose() end;
    self.rootLayer = nil;
	CocosObject.dispose(self);
end

local function indexOf(tb, item)
    local idx = -1;
    if tb and item then
        for i, v in ipairs(tb) do
            if v == item then 
                idx= i;
                break;
            end
        end
    end
    return idx;
end

--
-- public control -------------------
--

function Scene:refreshSuperIndex()
	local dp = self.refCocosObj;
	for i, v in ipairs(self.list) do
		--this is a very ligng function call, just setup it's globalOrderOfArrival and zOrder.
		if v.refCocosObj then dp:reorderChild(v.refCocosObj, v.index) end; 
	end
end
function Scene:superAddChild(child)
	self:superAddChildAt(child, #self.list);
end
function Scene:superAddChildAt(child, index)
    if not child or not child.refCocosObj then return end;
	local i = indexOf(self.list, child);
	if i == -1 then
	    local compare = child.refCocosObj;
        self.refCocosObj:addChild(compare, index); --ccScene

        table.insert(self.list, index+1, child);
        child.parent = self;

        --update index
        for i, v in ipairs(self.list) do v.index = i-1 end;
		self:refreshSuperIndex();
	end
end

function Scene:superRemoveChild(child, cleanup)
	if not child then return end;
	local isCleanup = true;
	if cleanup ~= nil then isCleanup = cleanup end;

	--clean cocos2d
	local compare = child.refCocosObj;
	if not compare then return end;
	self.refCocosObj:removeChild(compare, isCleanup);

	local cd = 0;
	for i, v in ipairs(self.list) do if v == child then cd = i end end

	--clean self list
	if cd > 0 then
		table.remove(self.list, cd);
		child.parent = nil;
		for i, v in ipairs(self.list) do v.index = i-1 end;
	end
	if(isCleanup) then child:dispose() end;
end

function Scene:getNumOfChildren() return self.rootLayer:getNumOfChildren() end
function Scene:addChild(child) self.rootLayer:addChild(child) end
function Scene:addChildAt(child, index) self.rootLayer:addChildAt(child, index) end
function Scene:contains(child) return self.rootLayer:contains(child) end  
function Scene:getChildAt(index) return self.rootLayer:getChildAt(index) end
function Scene:getChildIndex(child) return self.rootLayer:getChildIndex(child) end
function Scene:removeFromParentAndCleanup(cleanup) end
function Scene:removeChild(child, cleanup) self.rootLayer:removeChild(child, cleanup) end
function Scene:removeChildren(cleanup) self.rootLayer:removeChildren(cleanup) end
function Scene:refreshIndex() self.rootLayer:refreshIndex() end
function Scene:setChildIndex(child, index) self.rootLayer:setChildIndex(child, index) end
function Scene:swapChildren(child1, child2) end
function Scene:swapChildrenAt(child1, child2) end
function Scene:isTouchEnabled() return self.touchEnabled end
   

--
-- touch control -------------------
--
local touchBeginObject = nil;
local lastTouchMovedObject = nil;

--in latest cocos2d-x, eventType is hard-coded in CCLuaEngine::executeLayerTouchesEvent

CCTOUCHBEGAN = "began"
CCTOUCHMOVED = "moved"
CCTOUCHENDED = "ended"
CCTOUCHCANCELLED = "cancelled"

local mTouchFlag = false;
local sceneBeginPosition = {x=-9999,y=-9999};

--在ios上，有可能出现touchBegan和touchEnd坐标不同，但是没有调用touchMoved的情况，这样就会出现按钮被按下去却没收到kTouchEnd，没有弹起来的情况
--增加isTouchMoved字段，假如touchMove没有被调用，则直接调用touchBeginObject的kTouchEnd事件
local isTouchMoved = false

TouchType = {
				default = "normalTouch",
				systemBackTouch = "systemBackTouch",
			}
local FLAG_TOUCHEFFECT_DEFAULT = 0
local FLAG_TOUCHEFFECT_ON = 1
local FLAG_TOUCHEFFECT_OFF = 2
local KEY_OPTION_TOUCHEFFECT = "toucheffect_option"

function addTouchEffect(parent,x,y)
	local touchEffectFlag = CCUserDefault:sharedUserDefault():getIntegerForKey(KEY_OPTION_TOUCHEFFECT)
	if touchEffectFlag == FLAG_TOUCHEFFECT_ON then --toucheffect on
		local effect = FlashSprite:create("EVO2/touchEffect")
		local effect_co = CocosObject.new(effect)
		effect:changeAnimation(0)
		effect:setLoop(false)
		local function touchEffectAnimationEnd(anim)
			effect:unregisterEndAnimationScriptHandler()
			if parent.refCocosObj then
				parent:removeChild(effect_co)
			end
		end
		effect:registerEndAnimationScriptHandler(touchEffectAnimationEnd)
		effect_co:setPositionXY(x,y)
		parent:addChildAt(effect_co,10000)
	end
end

local function onTouchRootBegin(rootLayer, objectList, worldPosition, touchType)
    for i, v in ipairs(objectList) do 
        --debug print
        if debugTouchEvent then print(" [debug touch begin]", worldPosition.x, worldPosition.y, v:toString()) end;
        
        if v:hasEventListenerByName(DisplayEvents.kTouchBegin) then
            local evt = DisplayEvent.new(DisplayEvents.kTouchBegin, v, worldPosition);
            v:dispatchEvent(evt);
            if not evt.propagation then break end;
        end
    end
	
	--add touch effect begin by dc
	if addTouchEffect then
		if touchType == nil then
			touchType = TouchType.default
		end
		if touchType ~= TouchType.systemBackTouch then
			addTouchEffect(rootLayer,worldPosition.x,worldPosition.y)
		end
	end
	--add touch effect end--]]
end
local function onTouchRootMoved(rootLayer, objectList, worldPosition)  
    if debugTouchEvent then print(" [debug touch move]") end;
    for i, v in ipairs(touchBeginObject) do v.__touchHelper = 0 end;
  
    for i, v in ipairs(objectList) do 
        local evt = nil;
        local idx = indexOf(touchBeginObject, v);
        if idx == -1 then
            --debug print, new object
            if debugTouchEvent then print(" [debug touch over]", worldPosition.x, worldPosition.y, v:toString()) end;
            evt = DisplayEvent.new(DisplayEvents.kTouchOver, v, worldPosition);            
        else
            --debug print, object already insert when touch begin
            if debugTouchEvent then print(" [debug touch moved]", worldPosition.x, worldPosition.y, v:toString()) end;
            evt = DisplayEvent.new(DisplayEvents.kTouchMove, v, worldPosition);
            v.__touchHelper = 1;
        end
        
        if v:hasEventListenerByName(evt.name) then            
            v:dispatchEvent(evt);
            if not evt.propagation then break end;
        end        
    end
    
    local objectAfterMove = {};
    for i, v in ipairs(touchBeginObject) do
		
		local exist = false;
		if not lastTouchMovedObject then
			lastTouchMovedObject = touchBeginObject
		end
		for lastk,lastv in pairs(lastTouchMovedObject)
		do
			if lastv == v then
				exist = true;
				break;
			end
		end
        if v.__touchHelper == 1 then
            table.insert(objectAfterMove, v);
			if not exist then
				 if v:hasEventListenerByName(DisplayEvents.kTouchBegin) then
					local evt = DisplayEvent.new(DisplayEvents.kTouchBegin, v, worldPosition);
					v:dispatchEvent(evt);
					if not evt.propagation then break end;
				end
			end
        else
			
            --end of the touch event
			if not exist then
				if debugTouchEvent then print(" [debug touch out]", worldPosition.x, worldPosition.y, v:toString()) end;
				local evtTouchOut = DisplayEvent.new(DisplayEvents.kTouchOut, v, worldPosition);
				if v:hasEventListenerByName(evtTouchOut.name) then            
					v:dispatchEvent(evtTouchOut);
					if not evtTouchOut.propagation then break end;
				end   
				
				if debugTouchEvent then print(" [debug touch end]", worldPosition.x, worldPosition.y, v:toString()) end;
				local evtTouchEnd = DisplayEvent.new(DisplayEvents.kTouchEnd, v, worldPosition);
				if v:hasEventListenerByName(evtTouchEnd.name) then            
					v:dispatchEvent(evtTouchEnd);
					if not evtTouchEnd.propagation then break end;
				end 
			end
        end
    end
    lastTouchMovedObject = objectAfterMove;
end
local function onTouchRootEnd(rootLayer, objectList, worldPosition, filterObject)
    for i, v in ipairs(touchBeginObject) do v.__touchHelper = 0 end;
    
    for i, v in ipairs(objectList) do         
        local idx = indexOf(touchBeginObject, v);
        if idx ~= -1 then v.__touchHelper = 1 end;
        
        --debu print.
        if debugTouchEvent then print(" [debug touch end]"..worldPosition.x..worldPosition.y..v:toString()) end;

        local evtTouchEnd = DisplayEvent.new(DisplayEvents.kTouchEnd, v, worldPosition);
        if v:hasEventListenerByName(evtTouchEnd.name) then            
            if debugTouchEvent then print(" v get touch event!!!") end;
            v:dispatchEvent(evtTouchEnd);
            if not evtTouchEnd.propagation then break end;
        end
    end

    if not isTouchMoved then
        for i,v in ipairs(touchBeginObject) do
            if v.__touchHelper == 0 then
                local evtTouchEnd = DisplayEvent.new(DisplayEvents.kTouchEnd, v, worldPosition);
                if v:hasEventListenerByName(evtTouchEnd.name) then            
                    if debugTouchEvent then print(" v get touch event!!!") end;
                    v:dispatchEvent(evtTouchEnd);
                    if not evtTouchEnd.propagation then break end;
                end
            end
        end
    end
    
    --local dx = sceneBeginPosition.x - worldPosition.x
    --local dy = sceneBeginPosition.y - worldPosition.y
    --local distance = dx * dx + dy * dy
    if true--[[distance < 64--]] then
        for i, v in ipairs(touchBeginObject) do 
					if filterObject then
						local evtTouchEnd = DisplayEvent.new(DisplayEvents.kTouchEnd, v, worldPosition);
						if v:hasEventListenerByName(evtTouchEnd.name) then            
							v:dispatchEvent(evtTouchEnd);
							if not evtTouchEnd.propagation then break end;
						end 
					end
            if v.__touchHelper == 1 or (v.__touchHelper == 0 and not isTouchMoved) then
                --debug print.
                if debugTouchEvent then print(" [debug touch tap]", worldPosition.x, worldPosition.y, v:toString()) end;
                local evtTouchTap = DisplayEvent.new(DisplayEvents.kTouchTap, v, worldPosition);
                if v:hasEventListenerByName(evtTouchTap.name) then            
                    v:dispatchEvent(evtTouchTap);
                    if not evtTouchTap.propagation then break end;
                end
            end 
        end
    end
    
    touchBeginObject = nil;
	lastTouchMovedObject = nil;
end
local function onTouchRootCancelled(rootLayer, objectList, worldPosition)
    for i, v in ipairs(touchBeginObject) do  
        --debu print.
        if debugTouchEvent then print(" [debug touch end]", worldPosition.x, worldPosition.y, v:toString()) end;
        local evtTouchEnd = DisplayEvent.new(DisplayEvents.kTouchEnd, v, worldPosition);
        if v:hasEventListenerByName(evtTouchEnd.name) then            
            v:dispatchEvent(evtTouchEnd);
            if not evtTouchEnd.propagation then break end;
        end
    end
    
    touchBeginObject = nil;
	lastTouchMovedObject = nil;
end

function onTouchRootLayer(eventType, x, y, touchType)
    local scene = Director.sharedDirector():getRunningScene();
    local winSize = CCDirector:sharedDirector():getWinSize();
	
    
    if scene and scene.touchEnabled then
        local disableMultiTouch = true;
      
        local rootLayer_ = scene.rootLayer;
        if rootLayer_ then
            --transform touch position to CCPoint, x, y are global position.
            --local worldPosition = ccp(x, scene.screenHeight - y);
			local worldPosition = ccp(x, y);
            local objectList = nil;
			--print(disableMultiTouch, mTouchFlag)
            if eventType == CCTOUCHBEGAN then
              --print("____CCTOUCHBEGAN")

                if not __IOS then
                    if disableMultiTouch and mTouchFlag then return false end; --disable multi touch.
                    mTouchFlag = true;
                end

                sceneBeginPosition.x = worldPosition.x;
                sceneBeginPosition.y = worldPosition.y;
                
                if scene:hasEventListenerByName(DisplayEvents.kTouchBegin) then
                    local evt = DisplayEvent.new(DisplayEvents.kTouchBegin, scene, worldPosition);
                    scene:dispatchEvent(evt);
                end
              
                objectList = rootLayer_:getObjectUnderPointForTouch(worldPosition, eventType);

                if table.getn(objectList) > 0 then
                    touchBeginObject = objectList;
                    onTouchRootBegin(rootLayer_, objectList, worldPosition, touchType);                    
                    return true;
                else 
					mTouchFlag = false;
                    touchBeginObject = nil;
                    return false;
                end
            else
                
                if touchBeginObject and table.getn(touchBeginObject) > 0 and (not scene.filterObject or eventType ~= CCTOUCHMOVED) then
                    objectList = rootLayer_:getObjectUnderPointForTouch(worldPosition, eventType);
                    if eventType == CCTOUCHMOVED then 
                        onTouchRootMoved(rootLayer_, objectList, worldPosition);
                        isTouchMoved = true
                    elseif eventType == CCTOUCHENDED then 
                        if debugTouchEvent then print("onTouchEnded is called!!") end
                        onTouchRootEnd(rootLayer_, objectList, worldPosition, scene.filterObject);
                        isTouchMoved = false
                    elseif eventType == CCTOUCHCANCELLED then 
                        onTouchRootCancelled(rootLayer_, objectList, worldPosition) 
                        isTouchMoved = false
                    end;
                end
                
                if eventType == CCTOUCHENDED then 
                  if scene:hasEventListenerByName(DisplayEvents.kTouchEnd) then
                    local evt = DisplayEvent.new(DisplayEvents.kTouchEnd, scene, worldPosition);
                    scene:dispatchEvent(evt);
                  end
                  
                  if sceneBeginPosition.x ~= worldPosition.x and sceneBeginPosition.y ~= worldPosition.y then
                    if scene:hasEventListenerByName(DisplayEvents.kTouchTap) then
                      local evt = DisplayEvent.new(DisplayEvents.kTouchTap, scene, worldPosition);
                      scene:dispatchEvent(evt);
                    end
                  end
                end
                
            end
        end
    end
    if eventType == CCTOUCHENDED or eventType == CCTOUCHCANCELLED then 
      --print("____CCTOUCHENDED")
      mTouchFlag = false;
      sceneBeginPosition.x = -9999;
      sceneBeginPosition.y = -9999;
    end
end

function Scene:resetTouchFlag()
  mTouchFlag = false;
  sceneBeginPosition.x = -9999;
  sceneBeginPosition.y = -9999;
end
   
function Scene:setTouchEnabled(v)
    if self.touchEnabled ~= v then
        if self.touchEnabled then self.rootLayer:unregisterScriptTouchHandler() end;
        self.touchEnabled = v;

        if self.touchEnabled then 
          self.rootLayer:registerScriptTouchHandler(onTouchRootLayer, false, 0, false)
          mTouchFlag = false;
        end
		self.rootLayer:setTouchEnabled(v);
    end
end