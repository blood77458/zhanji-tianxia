require "hecore.display.Director"
require "canon.manager.UiStackManager"
kPopoutDir = {
	kFromTopToTop = 1,
	kScale = 2,
}

kDarkOpacity = 150

PopoutManager = {}
PopoutManager.popouts = {}

PopoutEvents = {kPopoutExitFinish = "PopoutExitFinish"}

local instance = nil
function PopoutManager:sharedManager()
	if not instance then
		instance = PopoutManager
		--initialize
	end
	return instance
end

--dark: optional, false by default.
--parent: optional, running scene by default.
--enableTouchBehind: optional, false by default.
function PopoutManager:add(child, dark, enableTouchBehind, parent)
	local scene = Director:mgr():run()
	if not parent then parent = scene end
	if not scene or not parent or not child then return false end
	
	--check if child is already inserted.
	if self:indexOf(child) ~= -1 then return false end

	--disable parent touch
	--[[child.pre_container_targetInfoPanel = scene.targetInfoPanel
	scene.targetInfoPanel = child
	scene:setTableViewsEnabled(false)]]

	local winSize = CCDirector:sharedDirector():getWinSize()

	local container = CocosObject:create()
	container.name = "popout container"
	container:setContentSize(CCSizeMake(winSize.width, winSize.height))
	if enableTouchBehind then
		container.touchEnabled = false
		container.touchChildren = false
	end

	local layer = LayerColor:create()
	if dark then layer:setOpacity(kDarkOpacity)
	else layer:setOpacity(0) end

	layer.name = "popout layer"
	layer:changeWidthAndHeight(winSize.width, winSize.height)
	layer:setAnchorPoint(ccp(0,0))
	layer:addChild(child)
	container:addChild(layer)
	
	parent:addChild(container)
	local function onLayerRemoved( evt )
		self:remove(child, true)
	end
	container:ad(Events.kRemoveFromStage, onLayerRemoved)
	table.insert(self.popouts, {child, container})

	return true
end

function PopoutManager:indexOf( child )
	for i,v in ipairs(self.popouts) do
		if v[1] == child then return i end
	end
	return -1
end

function PopoutManager:remove( child, deleteFromTable )
	if not child then return end
	local idx = self:indexOf(child)
	if idx ~= -1 then
		local map = self.popouts[idx]
		if map then
			local container = map[2]
			if container and container:getParent() then container:removeFromParentAndCleanup(true) end
			if container then container:rma() end
		end
		if deleteFromTable then table.remove(self.popouts, idx) end
	end
end

function PopoutManager:clear()
	for i,v in ipairs(self.popouts) do
		self:remove(v[1])
	end
	self.popouts = {}
end

function PopoutManager:bringToFront( child )
	if not child then return end
	local idx = self:indexOf(child)
	local map = self.popouts[idx]
	if map then
		local container = map[2]
		if container then 
			local parent = container:getParent()
			parent:setChildIndex(container, parent:getNumOfChildren()-1)
		end
	end
end

function PopoutManager:bringAllToFront( parent )
	local scene = Director:mgr():run()
	if not parent then parent = scene end
	if not scene or not parent then return end

	local list = {}
	for i,v in ipairs(self.popouts) do
		local child = v[1]
		if child and child:getParent() == parent then
			table.insert(list, child)
		end
	end
	for i,v in ipairs(list) do
		self:bringToFront(v)
	end
end

local parentList = {}

function PopoutManager:popout(child, dir, dark, enableTouchBehind, parent, zorder, callback)
	local scene = Director:mgr():run()
	if not parent then parent = scene end
	if not scene or not parent or not child then return false end
	if not zorder then zorder = 1 end
	
	--check if child is already inserted.
	if self:indexOf(child) ~= -1 then return false end
	
	--disable parent touch
	if (parent.targetInfoPanel == child) then
		child.pre_container_targetInfoPanel = nil --todo for jet
	else
		child.pre_container_targetInfoPanel = parent.targetInfoPanel
	end
	parent.targetInfoPanel = child
	if (parent.setTableViewsEnabled) then
		if (parent.setTableViewsEnabled) then
			parent:setTableViewsEnabled(false)
		end
	end

	local winSize = CCDirector:sharedDirector():getWinSize()

	local container = CocosObject:create()
	container.name = "popout container"
	container:setContentSize(CCSizeMake(winSize.width, winSize.height))
	if enableTouchBehind then
		container.touchEnabled = false
		container.touchChildren = false
	end

	local layer = LayerColor:create()
	if dark then layer:setOpacity(kDarkOpacity)
	else layer:setOpacity(0) end

	layer.name = "popout layer"
	layer:changeWidthAndHeight(winSize.width, winSize.height)
	layer:setAnchorPoint(ccp(0,0))
  layer:setZOrder(2000)
    local aGroupBounds = child:getGroupBounds()
    child:setPosition(ccp(0,0))

	container:addChild(layer)
	
	parent:addChild(container, zorder)
	table.insert(self.popouts, {child, container})
  
  parentList[child] = parent

  UiStackManager.push(child)
  
  local function onPopoutEnterAnimationFinished()
  	local function judgeCallback()
  		if callback then
  			callback()
  		end
  	end
    if not child then 
    	judgeCallback()
    	return 
    end
    child.touchEnabled = true
    child.touchChildren = true
    judgeCallback()
  end
  
  child.touchEnabled = false
  child.touchChildren = false
  if dir == kPopoutDir.kFromTopToTop then
    layer:addChild(child)
    local pos = child:getPosition()
    local moveTo = CCMoveTo:create(0.4, ccp(pos.x, pos.y))
    local ease = CCEaseBackOut:create(moveTo)
    child:setPositionXY(pos.x, pos.y + winSize.height)
    child:stopAllActions()
    child:runAction(CCSequence:createWithTwoActions(ease, CCCallFunc:create(onPopoutEnterAnimationFinished)))
  elseif dir == kPopoutDir.kScale then
    local bgLayer = Layer:create()
    bgLayer:setContentSize(CCSizeMake(winSize.width, winSize.height))
	bgLayer:setAnchorPoint(ccp(0.5, 0.5))
	bgLayer:setScale(0.1)
    layer:addChild(bgLayer)
	bgLayer:addChild(child)
	child:stopAllActions()
	local arr = CCArray:create()
    arr:addObject(CCEaseSineOut:create(CCScaleTo:create(0.3, 1)))
    arr:addObject(CCCallFunc:create(onPopoutEnterAnimationFinished))
    bgLayer:runAction(CCSequence:create(arr))
 else
 	layer:addChild(child)
 	onPopoutEnterAnimationFinished()
  end
  
	return true
end

function PopoutManager:pullin( child, dir )
  local function onPopoutExitAnimationFinished()
    if not child then return end
    parentList[child]:dispatchEvent(Event.new(PopoutEvents.kPopoutExitFinish, nil, parentList[child]))
	
	parentList[child] = nil
    local aPopoutManager = PopoutManager:sharedManager()
    local idx = aPopoutManager:indexOf(child)
    if idx ~= -1 then
      local map = aPopoutManager.popouts[idx]
      if map then
        local container = map[2]
        if container and container:getParent() then 
          container:removeFromParentAndCleanup(true) 
        end
        if container then container:rma() end
      end
      table.remove(aPopoutManager.popouts, idx)
    end
  end

  local winSize = CCDirector:sharedDirector():getWinSize()
  child.touchEnabled = false
  child.touchChildren = false
  --in case there's a replaceScene after pullin
  parentList[child].targetInfoPanel = child.pre_container_targetInfoPanel
  
  --enable parent touch

	if (parentList[child]) then
		if (parentList[child].setTableViewsEnabled) and (not parentList[child].targetInfoPanel) then
			parentList[child]:setTableViewsEnabled(true)
		end
	end
  
  if dir == kPopoutDir.kFromTopToTop then
    local pos = child:getPosition()
    local moveTo = CCMoveTo:create(0.6, ccp(pos.x, pos.y + winSize.height))
    local ease = CCEaseBackOut:create(moveTo)
    child:stopAllActions()
    child:runAction(CCSequence:createWithTwoActions(ease, CCCallFunc:create(onPopoutExitAnimationFinished)))
  elseif dir == kPopoutDir.kScale then
	child:stopAllActions()
	onPopoutExitAnimationFinished()
  end

  UiStackManager.remove(child)
  
end