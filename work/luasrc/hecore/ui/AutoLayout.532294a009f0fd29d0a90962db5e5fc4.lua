require "hecore.display.Director"
require "hecore.display.TextField"
require "hecore.ui.ControlButton"

local configCached = {}
local cjson = require "cjson"
local string = require "string"
local algorithms = require "hecore.ui.LayoutAlgorithms"

kFontPercentRatio = 1/320 --by default, we use font in 320/480 as 100%
kSupportedLayoutComponent = {kContainer = "Container", kControlButton = "ControlButton"}

local instanceID = 1

AutoLayout = class()
function AutoLayout:ctor(config, filePath)
  self.config = config
  self.filePath = filePath or ""
end

function AutoLayout:createWithContentsOfFile(filePath)
  local config = configCached[filePath]
  if not config then
    local path = CCFileUtils:sharedFileUtils():fullPathForFilename(filePath)    
    local file = io.open(path, "r")
    if not file then
      print("AutoLayout fail, file not exist: "..filePath)
      return;
    end
    local t = file:read("*all")
    io.close(file)
    
    config = cjson.decode(t)
    configCached[filePath] = config
  end
  
  local layout = AutoLayout.new(config)
  return layout:layout()
end

--get the formated number, 2 number returend: 1st is the size that to number, 2nd will be the percent of 0-100 if it's percent fromated.
--example: src=100%, return 100, true ; src=10, return 10, false; src=nil, return 0, false
local function getFormatedPercentage( src )
	if type(src) == "string" then
		local length = string.len(src)
		if length <= 0 then return 0, false
		else
			local ended = string.byte(src, length)
			--char code of 37 is '%'
			if ended == 37 then
				local sub = string.sub(src, 1, -2)
				return tonumber(sub), true
			else return tonumber(src), false end
		end
	end
	if type(src) == "number" then return src, false end
	return 0, false
end

--size in config: direct 234 or percent 100%
local function computeSizeByParent( parentWidth, parentHeight, configWidth, configHeight )
	local width, percentWidth = getFormatedPercentage(configWidth)
	local height, percentHeight = getFormatedPercentage(configHeight)

	local computedWidth = width
	local computedHeight = height
	if percentWidth then computedWidth = parentWidth * width * 0.01 end
	if percentHeight then computedHeight = parentHeight * height * 0.01 end
	return computedWidth, computedHeight
end 

--colos in config: #RRGGBB of hex or 16777215 of int.
local function parseCocosColor( color, defaultColor )
	if type(color) == "string" then
		local first = string.byte(color, 1)
		local length = #color
		local integer = 0
		if first == 35 then
			-- char code of 35 is '#'
			if length > 6 then color = string.sub(color, 2, 7) end
			integer = tonumber(color, 16)
		else
			if length > 5 then color = string.sub(color, 1, 6) end
			integer = tonumber(color)
		end
    	return HeDisplayUtil:ccc3FromUInt(integer)
	end
	defaultColor = defaultColor or 0
	return HeDisplayUtil:ccc3FromUInt(defaultColor)
end 

--alpha in config: 0-100
local function parseCocosOpacity(alpha)
	local alpha, percent = getFormatedPercentage(alpha)
	alpha = alpha or 100
	return alpha * 255 * 0.01
end

--same define as HTML's Padding and Margin
--define border to it's parent. 4 component as top, right, bottom, left.
--percent is support as input margin can be 1%,1%,1%,2%
--direct number is supported: input margin can be 1,2,1,1
--The number of property can have from one to four values:
--input:25 50 75 100 = top right bottom left
--input:25 50 75 = top left&right bottom 
--input:25 50 = top&bottom left&right
--input:25 = top&right&bottom&left
local function parseObjectMargin( parentWidth, parentHeight, margin )
	if type(margin) == "string" then
		local components = margin:split(",")
		local length = #components
		if length == 4 then
			local top, topPercent = getFormatedPercentage(components[1])
			if topPercent then top = parentHeight * top * 0.01 end
			local right, rightPercent = getFormatedPercentage(components[2])
			if rightPercent then right = parentWidth * right * 0.01 end
			local bottom, bottomPercent = getFormatedPercentage(components[3])
			if bottomPercent then bottom = parentHeight * bottom * 0.01 end
			local left, leftPercent = getFormatedPercentage(components[4])
			if leftPercent then left = parentWidth * left * 0.01 end
			return top, right, bottom, left
		elseif length == 3 then
			local top, topPercent = getFormatedPercentage(components[1])
			if topPercent then top = parentHeight * top * 0.01 end
			local bottom, bottomPercent = getFormatedPercentage(components[3])
			if bottomPercent then bottom = parentHeight * bottom * 0.01 end

			local right, rightPercent = getFormatedPercentage(components[2])
			if rightPercent then right = parentWidth * right * 0.01 end

			return top, right, bottom, right
		elseif length == 2 then
			local top, topPercent = getFormatedPercentage(components[1])
			if topPercent then top = parentHeight * top * 0.01 end
			local right, rightPercent = getFormatedPercentage(components[2])
			if rightPercent then right = parentWidth * right * 0.01 end
			return top, right, top, right
		elseif length == 1 then
			local width, percent = getFormatedPercentage(margin)
			local sameWidth, sameHeight = width, width
			if percent then 
				sameWidth = parentWidth * width * 0.01 
				sameHeight = parentHeight * width * 0.01
			end
			return sameWidth, sameHeight, sameWidth, sameHeight
		end
	end
	if type(margin) == "number" then return margin, margin, margin, margin end
	return 0,0,0,0
end 

local function parseCocosAnchorPoint( anchor )
	if type(anchor) == "string" then
		local components = anchor:split(",")
		if #components == 2 then
			local x = tonumber(components[1])
			local y = tonumber(components[2])
			return ccp(x, y)
		end
	end
	return ccp(0.5, 0.5)
end 

local function parseInstanceID( configID )
	if type(configID) == "string" and #configID > 0 then return configID end
	instanceID = instanceID + 1
	return "instance"..instanceID
end

local function parseFontSize( fontSize )
	local size, percent = 12, true --default font size:12
	local winSize = CCDirector:sharedDirector():getWinSize()
	if fontSize then
		local size, percent = getFormatedPercentage(fontSize)
	end
	if percent then
		size = size * kFontPercentRatio * winSize.width
	end
	return size
end

local function parseBoolean( value, defaultValue )
	if value then 
		local typeValue = type(value)
		return (typeValue == "string" and value:lower() == "true") or (typeValue == "number" and value ~= 0) or (typeValue == "boolean" and value) 
	end
	return defaultValue
end 

function AutoLayout:buildBargoundImage( image )
	local result = nil
	if type(image) == "string" then
		-- start with "#", we use sprite frame instead image
		if string.byte(image) == 35 then result = CCScale9Sprite:createWithSpriteFrameName(string.sub(image, 2), kZeroRect)
  		else result = CCScale9Sprite:create(image, kZeroRect) end
  	end
	return result
end

function AutoLayout:buildControlButton(config, parentWidth, parentHeight, parent)
	local x, y = computeSizeByParent(parentWidth, parentHeight, config.x, config.y)
	local anchor = parseCocosAnchorPoint(config.anchor)
	local label = config.label or "Button"
	local autoSize = parseBoolean(config.autoSize, true)
	local zoomOnTouchDown = parseBoolean(config.zoomOnTouchDown, true)

	local normalBackground = self:buildBargoundImage(config.normalBackground)
	local highlightedBackground = self:buildBargoundImage(config.highlightedBackground)
	local disabledBackground = self:buildBargoundImage(config.disabledBackground)
	local selectedBackground = self:buildBargoundImage(config.selectedBackground)

	local normalColor = parseCocosColor(config.normalColor, 0xffffff)
	local highlightedColor = parseCocosColor(config.highlightedColor, 0xffffff)
	local disabledColor = parseCocosColor(config.disabledColor, 0xffffff)
	local selectedColor = parseCocosColor(config.selectedColor, 0xffffff)

	local normalLabel = config.normalLabel
	local highlightedLabel = config.highlightedLabel
	local disabledLabel = config.disabledLabel
	local selectedLabel = config.selectedLabel

	local fontSize = parseFontSize(config.fontSize)
	local button = ControlButton:create(label, nil, fontSize)
	button.name = parseInstanceID(config.id)
	button:setPosition(ccp(x,y))
	button:setAnchorPoint(anchor)
	button:setAdjustBackgroundImage(autoSize)
	button:setZoomOnTouchDown(zoomOnTouchDown)

	button:setTitleColorForState(normalColor, CCControlStateNormal)
	button:setTitleColorForState(highlightedColor, CCControlStateHighlighted)
	button:setTitleColorForState(disabledColor, CCControlStateDisabled)
	button:setTitleColorForState(selectedColor, CCControlStateSelected)

	if normalBackground then button:setBackgroundSpriteForState(normalBackground, CCControlStateNormal) end
	if highlightedBackground then button:setBackgroundSpriteForState(highlightedBackground, CCControlStateHighlighted) end
	if disabledBackground then button:setBackgroundSpriteForState(disabledBackground, CCControlStateDisabled) end
	if selectedBackground then button:setBackgroundSpriteForState(selectedBackground, CCControlStateSelected) end

	if normalLabel then button:setTitleForState(normalLabel, CCControlStateNormal) end
	if highlightedLabel then button:setTitleForState(highlightedLabel, CCControlStateHighlighted) end
	if disabledLabel then button:setTitleForState(disabledLabel, CCControlStateDisabled) end
	if selectedLabel then button:setTitleForState(selectedLabel, CCControlStateSelected) end

	if not autoSize then
	end

	if parent then parent:addChild(button) end
	return button
end

--Margin
--	The margin clears an area around an element (outside the border). The margin does not have a background color, and is completely transparent.
--	The percent of an elements margin is related to it's parent content size.
--
-- param: parent <opt>
function AutoLayout:buildContainer( config, parentWidth, parentHeight, parent )
	local computedWidth, computedHeight = computeSizeByParent(parentWidth, parentHeight, config.width, config.height)
	local topMargin, rightMargin, bottomMargin, leftMargin = parseObjectMargin(parentWidth, parentHeight, config.margin)
	local color = parseCocosColor(config.backgroundColor)
	local opacity = parseCocosOpacity(config.backgroundAlpha)
	local x = leftMargin
	local y = topMargin
	computedWidth = computedWidth - leftMargin - rightMargin
	computedHeight = computedHeight - topMargin - bottomMargin

	local layerID = parseInstanceID(config.id)
	print(layerID, computedWidth, computedHeight, parentWidth, parentHeight, color, opacity, topMargin, rightMargin, bottomMargin, leftMargin)

	local layer = LayerColor:create()
	layer.name = layerID
    layer:setColor(color)
    layer:setOpacity(opacity)
    layer:setContentSize(CCSizeMake(computedWidth, computedHeight))
    layer:setPosition(ccp(x, y))
    layer:setAnchorPoint(ccp(0,0))
    layer.padding = {topPadding, rightPadding, bottomPadding, leftPadding}

    local children = config.children
    if children and #children > 0 then
	    for i,v in ipairs(children) do self:buildComponent(v, computedWidth, computedHeight, layer) end
    end

    algorithms.layout(layer, config.layout)
    if parent then parent:addChild(layer) end

	return layer
end

function AutoLayout:buildComponent( config, parentWidth, parentHeight, parent )
	local component = config.component or ""
	local result = nil
	if component == kSupportedLayoutComponent.kControlButton then result = self:buildControlButton(config, parentWidth, parentHeight, parent)
	elseif component == kSupportedLayoutComponent.kContainer then result = self:buildContainer(config, parentWidth, parentHeight, parent)
	else
		local external = string.sub(component, -5, -1)
		if external == ".json" then
			local customComponent = AutoLayout:createWithContentsOfFile(component)
			if customComponent then
				if parent then parent:addChild(customComponent) end
			end
			return customComponent
		end
	end
	return result
end 
function AutoLayout:layout()
	local config = self.config
	local version = config.version or "1.0"
	local textures = config.textures
	if type(textures) == "table" and #textures > 0 then
		for i,v in ipairs(textures) do
			SpriteUtil:addSpriteFramesWithFile(v..".plist", v..".png")
		end
	end
	local winSize = CCDirector:sharedDirector():getWinSize()
	return self:buildComponent(config, winSize.width, winSize.height)
end