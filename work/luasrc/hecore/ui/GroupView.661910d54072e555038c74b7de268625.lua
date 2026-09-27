-------------------------------------------------------------------------
--  Class include: DisplayBounds, GroupView
-------------------------------------------------------------------------

require "hecore.display.Director"
require "hecore.display.TextField"

--
-- GroupView ---------------------------------------------------------
--
kGroupViewDirection = {horizontal=0, vertical=1, cross=2}
GroupView = class()

function GroupView:ctor(w, h, direction)
	self.width = w
 	self.height = h
  	self.direction = direction or 1 --by default, it's vertical
  
  	local layer = ClippingNode:create(CCRectMake(0,0,w,h))
	self.layer = layer

  	local container = Layer:create()
  	container:setTouchEnabled(false)
	self.container = container
  
	local hitArea = Layer:create()
	hitArea.name = kHitAreaObjectName
	hitArea:setContentSize(CCSizeMake(w,h))
	layer:addChild(hitArea)
  	
  	layer:addChild(container)
  
  	local context = self
  	local function onTouchEvent( evt )
  		if evt.name == DisplayEvents.kTouchBegin then context:onScrollViewBegin(evt)
  		elseif evt.name == DisplayEvents.kTouchEnd then context:onScrollViewEnd(evt)
  		elseif evt.name == DisplayEvents.kTouchMove then context:onScrollViewMove(evt) end
  	end 
  
	layer:addEventListener(DisplayEvents.kTouchBegin, onTouchEvent)
	layer:addEventListener(DisplayEvents.kTouchEnd, onTouchEvent)
	layer:addEventListener(DisplayEvents.kTouchMove, onTouchEvent)
end

function GroupView:create( w, h, direction )
	return GroupView.new(w, h, direction)
end

function GroupView:dispose()
	if self.layer then
      self.layer:removeAllEventListeners()
      self.layer = nil
  	end
  	CocosObject:dispose()
end

function GroupView:onScrollViewBegin(evt)
  	local currX = evt.globalPosition.x or 0
  	local currY = evt.globalPosition.y or 0
  	self.helper = {
  		startX = currX,
  		startY = currY,
  		deltaX = 0,
  		deltaY = 0,
  		startTime = os.clock(),
  		sample = {},
  		containerSize = self.container:getGroupBounds(self.layer).size;
  	}
end

function GroupView:updateHelperData( evt )
	local currX = evt.globalPosition.x or 0
  	local currY = evt.globalPosition.y or 0
  	local currentTime = os.clock()

  	if not self.helper then
	  	self.helper = {
	  		startX = currX, 
	  		startY = currY, 
	  		deltaX = 0, 
	  		deltaY = 0,
	  		startTime = currentTime, 
	  		sample = {}, 
	  		containerSize = self.container:getGroupBounds(self.layer).size;
	  	}
	  	return false
  	end
  	local helper = self.helper
  	
    local deltaX = currX - helper.startX
    local deltaY = currY - helper.startY
    local deltaT = (currentTime - helper.startTime) 

    if deltaT < 0.01 then return false end

    local distance = deltaX
    if self.direction == 1 then distance = deltaY 
    elseif self.direction == 3 then distance = math.sqrt(deltaX*deltaX + deltaY*deltaY) end

    local velocity = distance/deltaT
    local acceleration = velocity/deltaT

    helper.deltaX = deltaX
    helper.deltaY = deltaY
    helper.startTime = currentTime
    helper.startX = currX
	helper.startY = currY

	if #helper.sample > 40 then
		table.remove(helper.sample, 1)
	end
	table.insert(helper.sample, {acceleration, velocity})

    return true
end

function GroupView:onScrollViewMove(evt)
	local valid = self:updateHelperData(evt)
  	local helper = self.helper

  	if valid and helper then
	    local deltaX = helper.deltaX
	    local deltaY = helper.deltaY
    
	    local containerSize = helper.containerSize
	    local containerPosition = self.container:getPosition()
	    local layerPosition = self.layer:getPosition()

	    if containerSize.width < self.width then containerSize.width = self.width end
	    if containerSize.height < self.height then containerSize.height = self.height end

    	local topLeft = self.width - containerSize.width
    	local bottomLeft = self.height - containerSize.height
    	if self.direction == 0 or self.direction == 2 then
	   		containerPosition.x = containerPosition.x + deltaX
	      	if containerPosition.x > 0 then containerPosition.x = 0 end
	      	if containerPosition.x < topLeft then containerPosition.x = topLeft end
    	end
    	if self.direction == 1 or self.direction == 2 then
      		containerPosition.y = containerPosition.y + deltaY
      		if containerPosition.y > 0 then containerPosition.y = 0 end
      		if containerPosition.y < bottomLeft then containerPosition.y = bottomLeft end
      	end
    
    	self.container:setPositionXY(containerPosition.x, containerPosition.y)
  	end
end


function GroupView:onScrollViewEnd(evt)
  	local valid = self:updateHelperData(evt)
  	local helper = self.helper

  	if valid and helper then
  		local sample = helper.sample
  		local acceleration = 0
  		local velocity = 0
  		local animationTime = 0.3

  		for i,v in ipairs(sample) do
  			acceleration = acceleration + v[1]
  			velocity = velocity + v[2]
  		end
  		acceleration = acceleration / #sample
  		velocity = velocity/ #sample
  		local distance = velocity * animationTime * 0.5
  		print("acceleration, velocity:", acceleration, velocity, distance)

  		local containerSize = helper.containerSize
	    local containerPosition = self.container:getPosition()
	    local layerPosition = self.layer:getPosition()
    
    	if containerSize.width < self.width then containerSize.width = self.width end
    	if containerSize.height < self.height then containerSize.height = self.height end
    	local topLeft = self.width - containerSize.width
    	local bottomLeft = self.height - containerSize.height

    	self.container:stopAllActions()

    	local finalX, finalY = containerPosition.x, containerPosition.y
    	if self.direction == 0 or self.direction == 2 then
    		finalX = containerPosition.x + distance
    		if finalX > 0 then finalX = 0 end
	      	if finalX < topLeft then finalX = topLeft end
    	end
    	if self.direction == 1 or self.direction == 2 then
    		finalY = containerPosition.y + distance
      		if finalY > 0 then finalY = 0 end
      		if finalY < bottomLeft then finalY = bottomLeft end
    	end
    	self.container:runAction(CCEaseSineOut:create(CCMoveTo:create(animationTime, ccp(finalX, finalY))))
  	end
end

function GroupView:addChild(child)
  self.container:addChild(child);
end

function GroupView:addChildAt(child, index)
  self.container:addChildAt(child, index);
end

function GroupView:getChildByName(childName)
	return self.container:getChildByName(childName);
end

function GroupView:getChildAt(index)
	return self.container:getChildAt(index);
end

function GroupView:getChildIndex(child)
	return self.container:getChildIndex(child);
end

function GroupView:removeChild(child, cleanup)
	self.container:removeChild(child, cleanup);
end

function GroupView:removeChildAt(index, cleanup)
	self.container:removeChildAt(index, cleanup);
end