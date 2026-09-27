--------------------------------------------------------------------------------
-- NewUserGuideDialog.lua - 新手引导界面
-- author: litong.sun
-- date: 2014-04-09
--------------------------------------------------------------------------------

require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

NewUserGuideDialog = class(Layer)

function NewUserGuideDialog:ctor()
end

function NewUserGuideDialog:create(x, y, width, height, text, guiderX, guiderY, stepNumber)
	local dialog = NewUserGuideDialog.new()
	dialog.x = x
	dialog.y = y
	dialog.width = width
	dialog.height = height
	dialog.text = text
	dialog.guiderX = guiderX
	dialog.guiderY = guiderY
	dialog.stepNumber = stepNumber
	dialog:initLayer()
	return dialog
end

function NewUserGuideDialog:initLayer()
	NewUserGuideDialog.super.initLayer(self)
	self:changeWidthAndHeight(visibleSize.width, visibleSize.height)
	if self.width <= 0 or self.height <= 0 then -- 全屏点击
		local subLayer = LayerColor:create()
		subLayer:setOpacity(150)
		subLayer:changeWidthAndHeight(visibleSize.width, visibleSize.height)
		subLayer.hitTestPoint = function (self, worldPosition, useGroupTest)
			return false
		end
		self:addChild(subLayer)

		function onTouch(eventType, x, y)
			if eventType == "ended" then
				FireClickEvent()
			end
			return 1
		end
		self:registerScriptTouchHandler(onTouch, false, -32768, true)
		self:setTouchEnabled(true)
	else -- 区域点击
		local subLayerPos = {{0,0}, {0, self.y}, {self.x+self.width, self.y}, {0, self.y+self.height}}
		local subLayerSize = {{visibleSize.width, self.y}, {self.x, self.height}, {visibleSize.width-self.x-self.width, self.height}, {visibleSize.width, visibleSize.height-self.y-self.height}}
		for i=1,4 do
			if subLayerSize[i][1] > 0 and subLayerSize[i][2] > 0 then
				local subLayer = LayerColor:create()
				subLayer:setOpacity(150)
				subLayer:changeWidthAndHeight(subLayerSize[i][1], subLayerSize[i][2])
				subLayer:setAnchorPoint(ccp(0, 0))
				subLayer:setPosition(ccp(subLayerPos[i][1], subLayerPos[i][2]))
				self:addChild(subLayer)
			end
		end
		local function onTouch(eventType, x, y)
			if eventType == CCTOUCHBEGAN then
				--add touch effect begin by dc
				if addTouchEffect then
					addTouchEffect(self,x,y)
				end
				--add touch effect end--]]
			end
			if (x > self.x and x < self.x+self.width and y > self.y and y < self.y+self.height) then
				return 0
			else
				return 1
			end
		end
		self:registerScriptTouchHandler(onTouch, false, -32768, true)
		self:setTouchEnabled(true)
	end

	if self.text ~= "" then
		local guide = Sprite:create("textbox_comm/mysweetlittleguide.png")
		self:addChild(guide)
		local textbox = Sprite:create("textbox_comm/NewUserGuide_TextBox.png")
		self:addChild(textbox)
		local text = TextField:create(self.text, nil, 30, CCSizeMake(30*16, 0))
		text:setAnchorPoint(ccp(0.5, 1))
		text:setPosition(ccp(textbox:getContentSize().width/2, textbox:getContentSize().height-16))
		textbox:addChild(text)
		if self.width <= 0 or self.height <= 0 then -- 全屏点击
			local ellipse = Sprite:create("textbox_comm/UsingPics/ellipse.png")
			ellipse:setPosition(ccp(480, 33))
			textbox:addChild(ellipse)
			local triangle = Sprite:create("textbox_comm/UsingPics/triangle.png")
			triangle:setPosition(ccp(482, 53))
			textbox:addChild(triangle)
			local moveTo = CCMoveTo:create(0.8, ccp(482, 43))
			local easeIn = CCEaseInOut:create(moveTo, 1.6)
			local moveBack = CCMoveTo:create(0.5, ccp(482, 53))
			triangle:runAction(CCRepeatForever:create(CCSequence:createWithTwoActions(easeIn, moveBack)))
			local label = TextField:create(getTextByKey("newGuideRemindClick"), nil, 13, CCSizeMake(13*5, 0), kCCTextAlignmentRight)
			label:setAnchorPoint(ccp(1, 0.5))
			label:setPosition(ccp(460, 33))
			textbox:addChild(label)
		end
		if self.stepNumber then
			local stepPic = Sprite:create("textbox_comm/UsingPics/aquire_card.png")
			stepPic:setAnchorPoint(ccp(0, 0.1))
			stepPic:setPosition(ccp(0, 150))
			textbox:addChild(stepPic)
			local label = TextField:create(tostring(self.stepNumber), nil, 60, CCSizeMake(60*3, 0), kCCTextAlignmentCenter)
			label:setAnchorPoint(ccp(0.5, 0.5))
			label:setPosition(ccp(83, 53))
			stepPic:addChild(label)
		end

		local guideW = guide:getContentSize().width
		local guideH = guide:getContentSize().height
		local textW = textbox:getContentSize().width
		local textH = textbox:getContentSize().height
		local width = math.max(guideW/2 - 120, textW/2) + math.max(guideW/2 + 120, textW/2)
		local height = guideH*1.2 - textH*0.2
		local guiderX = self.guiderX + width/2
		local guiderY = self.guiderY - height/2
		if guiderX < 0 or guiderY < 0 then
			if self.y < visibleSize.height/2 then
				guide:setAnchorPoint(ccp(0.5, 0))
				guide:setPosition(ccp(visibleSize.width/2 + 120, guide:getContentSize().height*0.2 + visibleSize.height/2 + 65))
				textbox:setAnchorPoint(ccp(0.5, 0))
				textbox:setPosition(ccp(visibleSize.width/2, textbox:getContentSize().height*0.2 + visibleSize.height/2 + 65))
			else
				guide:setAnchorPoint(ccp(0.5, 0))
				guide:setPosition(ccp(visibleSize.width/2 + 120, guide:getContentSize().height*0.2 + 145))
				textbox:setAnchorPoint(ccp(0.5, 0))
				textbox:setPosition(ccp(visibleSize.width/2, textbox:getContentSize().height*0.2 + 145))
			end
		else
			guide:setAnchorPoint(ccp(0.5, 0.5))
			guide:setPosition(ccp(guiderX - width/2 + textW/2 + 120, guiderY - height/2 + guideH*0.7- textH*0.2))
			textbox:setAnchorPoint(ccp(0, 0))
			textbox:setPosition(ccp(guiderX - width/2, guiderY - height/2))
		end
	end
	local circle0 = Sprite:create("textbox_comm/UsingPics/big_circle.png")
	circle0:setPosition(ccp(self.x + self.width/2, self.y + self.height/2))
	self:addChild(circle0)
	local arr0 = CCArray:create()
	arr0:addObject(CCScaleTo:create(0.5, 2))
	arr0:addObject(CCFadeOut:create(0.5))
	arr0:addObject(CCScaleTo:create(0.1, 1))
	arr0:addObject(CCDelayTime:create(1))
	arr0:addObject(CCFadeIn:create(0.1))
	circle0:runAction(CCRepeatForever:create(CCSequence:create(arr0)))
	local circle1 = Sprite:create("textbox_comm/UsingPics/big_circle.png")
	circle1:setPosition(ccp(self.x + self.width/2, self.y + self.height/2))
	circle1:setOpacity(0)
	self:addChild(circle1)
	local arr1 = CCArray:create()
	arr1:addObject(CCDelayTime:create(0.6))
	arr1:addObject(CCFadeIn:create(0.1))
	arr1:addObject(CCScaleTo:create(0.5, 2))
	arr1:addObject(CCFadeOut:create(0.5))
	arr1:addObject(CCScaleTo:create(0.1, 1))
	arr1:addObject(CCDelayTime:create(0.4))
	circle1:runAction(CCRepeatForever:create(CCSequence:create(arr1)))
end

function NewUserGuideDialog:hitTestPoint(worldPosition, useGroupTest)
	return false
end
