require "hecore.display.Director"
require "hecore.display.TextField"

Button = class(EventDispatcher)
local isTouchMovingInButton = false
local ifShieldingTouchMoving = false
function resetTouchMovingPara()
    isTouchMovingInButton = false
    ifShieldingTouchMoving = false
end
local function onButtonTouchBegin( evt )
    isTouchMovingInButton = false
	local button = evt.context
	if not button.enable then return end
	
	if button.selected then
		do return end
	end
	
	if button and button:hasEventListenerByName(Events.kStartClickBegin) then
		button:dispatchEvent(Event.new(Events.kStartClickBegin, nil, button))
	end
	
	local animationObject = button.getColorAnimationFunc(button)
  
  local function grayDisplay(aObject)
    if (not aObject) or (type(aObject) ~= "table") then
      return
    end
    if aObject.setColor then
      if type(aObject.refCocosObj.setString) == "function" then
		if not aObject.originalColor then
			aObject.originalColor = aObject:getColor()
		end
        aObject:setColor(ccc3(aObject.originalColor.r * 0.8, aObject.originalColor.g * 0.8, aObject.originalColor.b * 0.8))
      else
      	if aObject.blackLayerColor then
      		aObject:setColor(aObject.blackLayerColor)
      	else
	        aObject:setColor(button.colorOverlay)
	    end
      end
      return
    end
    if (not aObject.list) or (#aObject.list == 0) then
      return
    end
    for _, aChild in pairs(aObject.list) do
      grayDisplay(aChild)
    end
  end
	if not button.noTouchEffect then
		grayDisplay(animationObject)
		--[[
		if  animationObject and animationObject.setColor then
			animationObject:setColor(button.colorOverlay)
		end]]
		if button.display and button.display.refCocosObj then
			button.positionX = button.display:getPositionX()
			button.positionY = button.display:getPositionY()
			button.display:setPosition(ccp(button.positionX+1, button.positionY-1))
		end
	end
	button.selected = true
	button:setButtonState(1)
end

local function onButtonTouchEnd( evt )
	local button = evt.context
	if not button.enable then return end
	local animationObject = button.getColorAnimationFunc(button)
  if not button.selected then
	do return end
  end
  button.selected = false;
  local function brightDisplay(aObject)
    if not aObject then
      return
    end
    if not aObject.refCocosObj then
      return
    end    
    if aObject.setColor then
      if type(aObject.refCocosObj.setString) == "function" then
        if aObject.originalColor then
          aObject:setColor(aObject.originalColor)
        end
      else
      	if aObject.originalColor then
          aObject:setColor(aObject.originalColor)
	    else
	      aObject:setColor(ccc3(255,255,255))
        end
        
      end
      return
    end
    if (not aObject.list) or (#aObject.list == 0) then
      return
    end
    for _, aChild in pairs(aObject.list) do
      brightDisplay(aChild)
    end
  end
	if not button.noTouchEffect then
		brightDisplay(animationObject)
		--[[
		if animationObject and animationObject.setColor then
			animationObject:setColor(ccc3(255,255,255))
		end]]
		if button.display and button.display.refCocosObj then
			button.positionX = button.display:getPositionX() - 1
			button.positionY = button.display:getPositionY() + 1
			button.display:setPosition(ccp(button.positionX, button.positionY))
		end
	end
	button:setButtonState(0)
	CanonPlayEffect("music/sfx_button_confirm.wav")
end

local function onButtonTouchTap( evt )
	local button = evt.context
	if not button.enable then return end
	if button and button:hasEventListenerByName(Events.kStart) then
		button:dispatchEvent(Event.new(Events.kStart, nil, button))
		if FireClickEvent then
			FireClickEvent() -- 新手引导
		end
	end
end

local function onButtonTouchMove( evt )
	isTouchMovingInButton = true
end

local function getButtonColorAnimationObject( button )
	return button.display
end

function Button:ctor( display, useLayerFrame )
	self.display = display
	self.scaleX = 1
	self.scaleY = 1

	self.enable = true
	self.colorOverlay = ccc3(200,200,200)
	self.getColorAnimationFunc = getButtonColorAnimationObject
	self.useLayerFrame = useLayerFrame
	if useLayerFrame and display and #display.list > 1 then
		self.normalBackground = display:getChildByName("normal")
		self.overBackground = display:getChildByName("over")
		self.disabledBackground = display:getChildByName("disabled")

		if not self.overBackground then self.overBackground = self.normalBackground end
		if not self.disabledBackground then self.disabledBackground = self.normalBackground end

		if not self.normalBackground then useLayerFrame = false end

		self:setButtonState(0)
	else
		useLayerFrame = false
	end
		
	isTouchMovingInButton = false
end
function Button:initButton()
	local  display = self.display
	if display then
		self.positionX = display:getPositionX()
		self.positionY = display:getPositionY()

		display:addEventListener(DisplayEvents.kTouchBegin, onButtonTouchBegin, self)
		display:addEventListener(DisplayEvents.kTouchEnd, onButtonTouchEnd, self)
		display:addEventListener(DisplayEvents.kTouchTap, onButtonTouchTap, self)
		display:addEventListener(DisplayEvents.kTouchMove, onButtonTouchMove, self)
	else print("no display assign to button") end
end

function Button:setButtonState( state )
	if not self.useLayerFrame then return end

	state = state or 0
	self.normalBackground:setVisible(false)
	self.disabledBackground:setVisible(false)
	self.overBackground:setVisible(false)

	if state == 0 then
		self.normalBackground:setVisible(true)
	elseif state == 1 then
		self.overBackground:setVisible(true)
	else
		self.disabledBackground:setVisible(true)
	end
end

function Button:dispose()
	local  display = self.display
	if display then
		display:removeAllEventListeners()
		self.display = nil
	end
	self.getColorAnimationFunc = nil
	self.colorOverlay = nil
end

function Button:setEnable( v )
	self.enable = v
	if self.enable then self:setButtonState(0)
	else self:setButtonState(2) end
end

function Button:setVisible( v )
	local  display = self.display
	if display then display:setVisible(v) end
end

function Button:create(display, useLayerFrame, shieldingTouchMoving)
	local button = Button.new(display, useLayerFrame)
	if shieldingTouchMoving then
	    ifShieldingTouchMoving = shieldingTouchMoving
	else
	    ifShieldingTouchMoving = false
    end
	button:initButton()
	return button
end

-------------------------------------------------
-- 是否闪烁
-------------------------------------------------

function Button:getShined()
	return self.shined or false
end

-------------------------------------------------
-- 闪烁效果
-- v 是否闪烁
-- shineDisplay 自定义闪烁资源 可以为nil或不传
-------------------------------------------------
function Button:setShined(v, defaultShineDisplay)
	if self.shined and v then
		--已经闪烁 并且还要闪烁 不处理
		return
	end

	self.shined = v
	local shineDisplay = defaultShineDisplay
	if not shineDisplay then
		if self.display.refCocosObj then
			shineDisplay = self.display:getChildByName("btn_light")
		else
			shineDisplay = self.display:getChildByTag(TagConstans.BTN_LAYER_SHINE_TAG)
		end
	end

	if shineDisplay then
        shineDisplay:setVisible(v)
        shineDisplay:stopAllActions()

        if v then
	        local array = CCArray:create()
	        array:addObject(CCFadeOut:create(0.5))
	        array:addObject(CCFadeIn:create(0.5))
	        shineDisplay:runAction(CCRepeatForever:create(CCSequence:create(array)))
		end
	end
end