-------------------------------------------------------------------------
--  Class include: ControlBase, ControlButton, ControlSlider, ControlSwitch, ControlStepper
-------------------------------------------------------------------------

require "hecore.display.Director"

kControlState = 
{
    CCControlStateNormal,
    CCControlStateHighlighted,
    CCControlStateDisabled,
    CCControlStateSelected,
}

kControlEvent = 
{
	kControlEventTouchDown = "ControlEventTouchDown",
	kControlEventTouchDragInside  = "ControlEventTouchDragInside",
	kControlEventTouchDragOutside = "ControlEventTouchDragOutside",
	kControlEventTouchDragEnter = "ControlEventTouchDragEnter",
	kControlEventTouchDragExit = "ControlEventTouchDragExit",
	kControlEventTouchUpInside = "ControlEventTouchUpInside",
	kControlEventTouchUpOutside = "ControlEventTouchUpOutside",
	kControlEventTouchCancel = "ControlEventTouchCancel",
	kControlEventValueChanged = "ControlEventValueChanged",
}

local kControlEventList = {
	kControlEvent.kControlEventTouchDown,
	kControlEvent.kControlEventTouchDragInside,
	kControlEvent.kControlEventTouchDragOutside,
	kControlEvent.kControlEventTouchDragEnter,
	kControlEvent.kControlEventTouchDragExit,
	kControlEvent.kControlEventTouchUpInside,
	kControlEvent.kControlEventTouchUpOutside,
	kControlEvent.kControlEventTouchCancel,
	kControlEvent.kControlEventValueChanged,
}
local kControlEventTotalNumber = 8
local kControlEventMapping = {}
for i=0,kControlEventTotalNumber do kControlEventMapping[tostring(math.pow(2, i))] = kControlEventList[i+1] end

kControlEventList = nil
kZeroRect = CCRectMake(0,0,0,0)

--
-- ControlBase ---------------------------------------------------------
--
ControlBase = class(CocosObject)

function ControlBase:dispose()
	CocosObject.dispose(self)
end

function ControlBase:isEnabled() return self.refCocosObj:isEnabled() end
function ControlBase:setEnabled(v) self.refCocosObj:setEnabled(v) end

function ControlBase:isSelected() return self.refCocosObj:isSelected() end
function ControlBase:setSelected(v) self.refCocosObj:setSelected(v) end

function ControlBase:isHighlighted() return self.refCocosObj:isHighlighted() end
function ControlBase:setHighlighted(v) self.refCocosObj:setHighlighted(v) end

function ControlBase:getState() return self.refCocosObj:getState() end

--
-- ControlButton ---------------------------------------------------------
--

ControlButton = class(ControlBase)

function ControlButton:dispose()
	CocosObject.dispose(self)
end

function ControlButton:create(title, fontName, fontSize)
	fontName = fontName or "Helvetica"
	fontSize = fontSize or 12
	local node = CCControlButton:create(title, fontName, fontSize)
	local button = ControlButton.new(node)
	button:setAdjustBackgroundImage(true)
	button:setBackgroundSpriteForState(CCScale9Sprite:create("extensions/button.png", kZeroRect), CCControlStateNormal)
	button:setBackgroundSpriteForState(CCScale9Sprite:create("extensions/buttonHighlighted.png", kZeroRect), CCControlStateHighlighted)
	local function onButtonEvent( eventType )
		local eventName = kControlEventMapping[eventType]
		if eventName and button:hn(eventName) then
			button:dp(Event.new(eventName, nil, button))
		end
	end 
	button.refCocosObj:registerScriptHandler(onButtonEvent)
	return button
end


function ControlButton:doesAdjustBackgroundImage() return self.refCocosObj:doesAdjustBackgroundImage() end
function ControlButton:setAdjustBackgroundImage(v) self.refCocosObj:setAdjustBackgroundImage(v) end

--CCSize
function ControlButton:getPreferredSize() return self.refCocosObj:getPreferredSize() end
function ControlButton:setPreferredSize(v) self.refCocosObj:setPreferredSize(v) end
--bool
function ControlButton:getZoomOnTouchDown() return self.refCocosObj:getZoomOnTouchDown() end
function ControlButton:setZoomOnTouchDown(v) self.refCocosObj:setZoomOnTouchDown(v) end
--CCPoint
function ControlButton:getLabelAnchorPoint() return self.refCocosObj:getLabelAnchorPoint() end
function ControlButton:setLabelAnchorPoint(v) self.refCocosObj:setLabelAnchorPoint(v) end

function ControlButton:isPushed() return self.refCocosObj:isPushed() end
function ControlButton:getVerticalMargin() return self.refCocosObj:getVerticalMargin() end
function ControlButton:getHorizontalOrigin() return self.refCocosObj:getHorizontalOrigin() end
function ControlButton:setMargins(marginH, marginV) self.refCocosObj:setMargins(marginH, marginV) end

function ControlButton:getTitleForState(state)   
	local ret = self.refCocosObj:getTitleForState(state)
	if ret then return ret:getCString() end
	return ""
end
function ControlButton:setTitleForState(title, state) 
	self.refCocosObj:setTitleForState(CCString:create(title), state) 
end
--ccColor3B
function ControlButton:getTitleColorForState(state) return self.refCocosObj:getTitleColorForState(state) end
function ControlButton:setTitleColorForState(color, state) self.refCocosObj:setTitleColorForState(color, state) end

--CCNode
function ControlButton:getTitleLabelForState(state) return self.refCocosObj:getTitleLabelForState(state) end
function ControlButton:setTitleLabelForState(label, state) self.refCocosObj:setTitleLabelForState(label, state) end

function ControlButton:getTitleTTFForState(state) return self.refCocosObj:getTitleTTFForState(state) end
function ControlButton:setTitleTTFForState(fntFile, state) self.refCocosObj:setTitleTTFForState(fntFile, state) end

function ControlButton:getTitleTTFSizeForState(state) return self.refCocosObj:getTitleTTFSizeForState(state) end
function ControlButton:setTitleTTFSizeForState(size, state) self.refCocosObj:setTitleTTFSizeForState(size, state) end

function ControlButton:getTitleBMFontForState(state) return self.refCocosObj:getTitleBMFontForState(state) end
function ControlButton:setTitleBMFontForState(fntFile, state) self.refCocosObj:setTitleBMFontForState(fntFile, state) end

--CCScale9Sprite
function ControlButton:getBackgroundSpriteForState(state) return self.refCocosObj:getBackgroundSpriteForState(state) end
function ControlButton:setBackgroundSpriteForState(sprite, state) self.refCocosObj:setBackgroundSpriteForState(sprite, state) end
function ControlButton:setBackgroundSpriteFrameForState(spriteFrame, state) self.refCocosObj:setBackgroundSpriteFrameForState(spriteFrame, state) end

--
-- ControlSlider ---------------------------------------------------------
--

ControlSlider = class(ControlBase)

function ControlSlider:dispose()
	CocosObject.dispose(self)
end

function ControlSlider:create(backgroundSprite, pogressSprite, thumbSprite)
	local bgFile = "extensions/sliderTrack.png"
	local progressFile = "extensions/sliderProgress.png" 
	local thumbFile = "extensions/sliderThumb.png"
	if not backgroundSprite then backgroundSprite = CCSprite:create(bgFile) end
	if not pogressSprite then pogressSprite = CCSprite:create(progressFile) end
	if not thumbSprite then thumbSprite = CCSprite:create(thumbFile) end

	local node = CCControlSlider:create(backgroundSprite, pogressSprite, thumbSprite)
	local button = ControlSlider.new(node)

	local function onButtonEvent( eventType )
		local eventName = kControlEventMapping[eventType]
		if eventName and button:hn(eventName) then
			button:dp(Event.new(eventName, button:getValue(), button))
		end
	end 

	button.refCocosObj:registerScriptHandler(onButtonEvent)
	return button
end

function ControlSlider:getValue() return self.refCocosObj:getValue() end
function ControlSlider:setValue(v) self.refCocosObj:setValue(v) end

function ControlSlider:getMinimumValue() return self.refCocosObj:getMinimumValue() end
function ControlSlider:setMinimumValue(v) self.refCocosObj:setMinimumValue(v) end

function ControlSlider:getMaximumValue() return self.refCocosObj:getMaximumValue() end
function ControlSlider:setMaximumValue(v) self.refCocosObj:setMaximumValue(v) end

function ControlSlider:getMinimumAllowedValue() return self.refCocosObj:getMinimumAllowedValue() end
function ControlSlider:setMinimumAllowedValue(v) self.refCocosObj:setMinimumAllowedValue(v) end

function ControlSlider:getMaximumAllowedValue() return self.refCocosObj:getMaximumAllowedValue() end
function ControlSlider:setMaximumAllowedValue(v) self.refCocosObj:setMaximumAllowedValue(v) end


--
-- ControlSwitch ---------------------------------------------------------
--

ControlSwitch = class(ControlBase)

function ControlSwitch:dispose()
	CocosObject.dispose(self)
end

function ControlSwitch:create(maskSprite, onSprite, offSprite, thumbSprite)
	if not maskSprite then maskSprite = CCSprite:create("extensions/switch-mask.png") end
	if not onSprite then onSprite = CCSprite:create("extensions/switch-on.png") end
	if not offSprite then offSprite = CCSprite:create("extensions/switch-off.png") end
	if not thumbSprite then thumbSprite = CCSprite:create("extensions/switch-thumb.png") end

	local node = CCControlSwitch:create(maskSprite, onSprite, offSprite, thumbSprite)
	local button = ControlSwitch.new(node)

	local function onButtonEvent( eventType )
		local eventName = kControlEventMapping[eventType]
		if eventName and button:hn(eventName) then
			button:dp(Event.new(eventName, button:isOn(), button))
		end
	end 

	button.refCocosObj:registerScriptHandler(onButtonEvent)
	return button
end

function ControlSwitch:isOn() return self.refCocosObj:isOn() end
function ControlSwitch:setOn(isOn, animated) self.refCocosObj:setOn(isOn, animated) end

function ControlSwitch:hasMoved() return self.refCocosObj:hasMoved() end


--
-- ControlStepper ---------------------------------------------------------
--

ControlStepper = class(ControlBase)

function ControlStepper:dispose()
	CocosObject.dispose(self)
end

function ControlStepper:create(minusSprite, plusSprite)
	if not minusSprite then minusSprite = CCSprite:create("extensions/stepper-minus.png") end
	if not plusSprite then plusSprite = CCSprite:create("extensions/stepper-plus.png") end

	local node = CCControlStepper:create(minusSprite, plusSprite)
	local button = ControlStepper.new(node)

	local function onButtonEvent( eventType )
		local eventName = kControlEventMapping[eventType]
		if eventName and button:hn(eventName) then
			button:dp(Event.new(eventName, button:getValue(), button))
		end
	end 

	button.refCocosObj:registerScriptHandler(onButtonEvent)
	return button
end
--bool
function ControlStepper:isContinuous() return self.refCocosObj:isContinuous() end
function ControlStepper:setWraps(v) self.refCocosObj:setWraps(v) end

function ControlStepper:setMinimumValue(v) self.refCocosObj:setMinimumValue(v) end
function ControlStepper:setMaximumValue(v) self.refCocosObj:setMaximumValue(v) end
function ControlStepper:setValue(v) self.refCocosObj:setValue(v) end
function ControlStepper:setStepValue(v) self.refCocosObj:setStepValue(v) end
function ControlStepper:setValueWithSendingEvent(value, send) self.refCocosObj:setValueWithSendingEvent(value, send) end

function ControlStepper:getValue() return self.refCocosObj:getValue() end
