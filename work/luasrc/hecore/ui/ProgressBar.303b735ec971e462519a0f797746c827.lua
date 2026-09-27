require "hecore.display.Director"

ProgressBar = class(EventDispatcher)

function ProgressBar:ctor( display, direction )
	self.display = display
	self.progress = 100
	self.direction = direction or 0

	local bounds = display:getContentSize()
	self.originalWidth = bounds.width
	self.originalHeight = bounds.height
end
function ProgressBar:initProgressBar()
	local  display = self.display
	if display then
		
	else print("no display assign to ProgressBar") end
end

function ProgressBar:dispose()
	
end

local  function clamp( value, min, max )
	local  min = min or 0
	local  max = max or 100
	if min > max then min, max = max, min end

	if value < min then value = min end
	if value > max then value = max end
	return value
end

function ProgressBar:setPercentage( percent )
	self.progress = clamp(percent)
	self:updateProgress()
end
function ProgressBar:getPercentage( )
	return self.progress
end

function ProgressBar:updateProgress( )
	local display = self.display
	if display then
		local textureRect = display:getTextureRect()
		if self.direction == 0 then
			local transformedWidth = self.progress * self.originalWidth * 0.01
			textureRect.size.width = transformedWidth
		else
			local transformedHeight = self.progress * self.originalHeight * 0.01
			textureRect.size.height = transformedHeight
		end
		local rotated = false;
		if display.refCocosObj and type(display.refCocosObj.isTextureRectRotated) == "function" then
			rotated = display.refCocosObj:isTextureRectRotated()
		end
		display:setTextureRect2(textureRect, rotated, textureRect.size);
	end
end

function ProgressBar:setVisible( v )
	local  display = self.display
	if display then display:setVisible(v) end
end

function ProgressBar:create(display, direction)
	local ret = ProgressBar.new(display, direction)
	ret:initProgressBar()
	return ret
end

function ProgressBar:progressTo(percent, duration)
  if percent == self.progress then
    return
  end
  
  local flag = true
  if percent < self.progress then
    flag = false
  end
  local aStep = (percent - self.progress) / duration
  local function updateProgress(dt)
    local next_progress = self.progress + aStep * dt
    if (flag and (next_progress >= percent)) or ((not flag) and (next_progress <= percent)) then
      self:setPercentage(percent)
      CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.progressEntry)
      self.progressEntry = nil
    else
      self:setPercentage(next_progress)
    end
  end
  if self.progressEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.progressEntry)
  end
  self.progressEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(updateProgress, 0, false)
end

function ProgressBar:stopProgress()
  if self.progressEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.progressEntry)
    self.progressEntry = nil
  end
end