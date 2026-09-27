require "hecore.display.CocosObject"
require "hecore.display.Director"

AttributeChangePanel = class(Layer)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

local number_pixiel_x = 54
local number_pixiel_y = 63

PanelShowStep = {
	INIT = 0,
	STARTSHOW = 1,
	FINISHSHOW = 2,
}

local g_attributeChangePanel = nil;

function AttributeChangePanel:ctor()
	g_attributeChangePanel = self
	self.panelShowStep = PanelShowStep.INIT
end

function AttributeChangePanel:show(fromNumber, toNumber, container)	
	fromNumber = math.floor(fromNumber)
	toNumber = math.floor(toNumber)
	recordScore(toNumber)
	if fromNumber == toNumber then
		do return end
	end
	
	if not container then
		container = Director:sharedDirector():getRunningScene()
	end
	
	local function changeNumberToTable(number, numbertable)
		while number > 0 do
			table.insert(numbertable, math.floor(number % 10))
			number = math.floor(number / 10)
		end
		if table.getn(numbertable) == 0 then
			table.insert(numbertable, 0)
		end
	end

	
	local fromNumberTable = {}
	local toNumberTable = {}
	
	changeNumberToTable(fromNumber, fromNumberTable)
	changeNumberToTable(toNumber, toNumberTable)
	
	local numberAmount = 0
	if table.getn(fromNumberTable) > numberAmount then
		numberAmount = table.getn(fromNumberTable)
	end
	if table.getn(toNumberTable) > numberAmount then
		numberAmount = table.getn(toNumberTable)
	end
	
	local immediateShow = false;
	
	if g_attributeChangePanel and g_attributeChangePanel.container == container then
		if g_attributeChangePanel.panelShowStep == PanelShowStep.INIT or g_attributeChangePanel.panelShowStep == PanelShowStep.STARTSHOW then
			g_attributeChangePanel:removeFromParentAndCleanup(true)
			immediateShow = true
		end
	end
	
	self.container = container
	self.fromNumberTable = fromNumberTable
	self.toNumberTable = toNumberTable
	self.numberAmount = numberAmount + 1
	self.isBattleCountUp = (fromNumber < toNumber)
	
	local s = AttributeChangePanel.new()
	s:initLayer(immediateShow)
	self.container:addChild(s)
	return s
end

local FIRST_NUMBER_TAG = 1000
local EXTRA_RUN_ROUNDS = 1
local TOTALAMOUNT = 1
local ONE_ROUND_DURATION = 0.4
local NUMBER_TOP_POSITION_Y = number_pixiel_y--visibleSize.height - 65
local ABSOLUTE_NUMBER_TOP_POSITION_Y = visibleSize.height - 65

function AttributeChangePanel:initLayer(immediateShow)
	AttributeChangePanel.super.initLayer(self)
	
	local bgL = Sprite:create("pic/1.png")
	bgL:setAnchorPoint(ccp(1, 1))
	bgL:setPosition(ccp(visibleSize.width  / 2, visibleSize.height - 35))
	self:addChild(bgL)
	
	local bgR = Sprite:create("pic/1.png")
	bgR:setAnchorPoint(ccp(1, 1))
	bgR:setScaleX(-1)
	bgR:setPosition(ccp(visibleSize.width  / 2, visibleSize.height - 35))
	self:addChild(bgR)
	
	local totalpixielX = -(self.numberAmount - 3) * number_pixiel_x / 2 + 60
	
	local textSprite
	local textPosX, textPosY = visibleSize.width  / 2 - 50 + totalpixielX, visibleSize.height - 100
	if self.isBattleCountUp then
		textSprite = Sprite:create("pic/battlecountup.png")
	else
		textSprite = Sprite:create("pic/battlecountdown.png")
	end
	textSprite:setAnchorPoint(ccp(1, 0.5))
	textSprite:setPosition(ccp(textPosX, textPosY))
	self:addChild(textSprite)
	
	local battleTextSprite = Sprite:create("pic/battlecount.png")
	battleTextSprite:setAnchorPoint(ccp(1, 0.5))
	battleTextSprite:setPosition(ccp(textPosX - textSprite:getContentSize().width, textPosY))
	self:addChild(battleTextSprite)
	--.refCocosObj:getTexture():setAliasTexParameters()
	
	local numberClipLayer = CCClippingNode:create();
	local numberClipLayer_co = CocosObject.new(numberClipLayer)
	numberClipLayer:setContentSize(CCSizeMake(visibleSize.width * 2, visibleSize.height - ABSOLUTE_NUMBER_TOP_POSITION_Y + number_pixiel_y))
	numberClipLayer:setAnchorPoint(ccp(0, 1))
	numberClipLayer:setPosition(ccp(totalpixielX, visibleSize.height))
	self:addChild(numberClipLayer_co)
	
	local stencil = CCSprite:create("pic/1.png")
	stencil:setScaleX(visibleSize.width * 2 / stencil:getContentSize().width)
	stencil:setScaleY(number_pixiel_y / stencil:getContentSize().height)
	stencil:setAnchorPoint(ccp(0, 0))
	stencil:setPosition(ccp(0, 0))
	numberClipLayer:setStencil(stencil)
	
	local zOrder = numberClipLayer_co:getZOrder()
	
	self.showNumberSpriteTable = {}--old
	self.showNumberSpriteBackTable = {}--new
	self.specialStatusBgTable = {}
	self.hightLightTable = {}
	
	local function addSpriteToLayer(layer, spriteName, num)
		for i = 1, num do
			local sprite = Sprite:create(spriteName)
			sprite:setPositionXY(sprite:getContentSize().width / 2, -5 - (sprite:getContentSize().height / 2 + 5) * (i - 1))
			layer:addChild(sprite)
		end
	end
	
	for i = 1, self.numberAmount do
		if i == self.numberAmount then
			if self.isBattleCountUp then
				self.showNumberSpriteTable[i] = Sprite:create("pic/lvjiantou3.png")
				self.showNumberSpriteBackTable[i] = Sprite:create("pic/lvjiantou3.png")
				addSpriteToLayer(self.showNumberSpriteTable[i], "pic/lvjiantou3.png", 2)
				addSpriteToLayer(self.showNumberSpriteBackTable[i], "pic/lvjiantou3.png", 2)
			else
				self.showNumberSpriteTable[i] = Sprite:create("pic/hongjiantou3.png")
				self.showNumberSpriteBackTable[i] = Sprite:create("pic/hongjiantou3.png")
				addSpriteToLayer(self.showNumberSpriteTable[i], "pic/hongjiantou3.png", 2)
				addSpriteToLayer(self.showNumberSpriteBackTable[i], "pic/hongjiantou3.png", 2)
			end
			self.showNumberSpriteTable[i]:setAnchorPoint(ccp(0, 0.6))
			self.showNumberSpriteBackTable[i]:setAnchorPoint(ccp(0, 0.6))
		else
			local showNumber = self.fromNumberTable[self.numberAmount - i]
			if not showNumber then
				showNumber = 0
			end
			
			local toNumber = self.toNumberTable[self.numberAmount - i]
			if not toNumber then
				toNumber = 0
			end
			
			self.showNumberSpriteTable[i] = Sprite:create("pic/NO" .. showNumber .. ".png")
			self.showNumberSpriteBackTable[i] = Sprite:create("pic/NO" .. toNumber .. ".png")
			self.showNumberSpriteTable[i]:setAnchorPoint(ccp(0, 1))
			self.showNumberSpriteBackTable[i]:setAnchorPoint(ccp(0, 1))
		end
		self.showNumberSpriteTable[i]:setTag(FIRST_NUMBER_TAG + i)
		
		self.showNumberSpriteTable[i]:setPosition(ccp(visibleSize.width / 2 + (i - 1) * number_pixiel_x, NUMBER_TOP_POSITION_Y))
		
		if self.isBattleCountUp then
			self.showNumberSpriteBackTable[i]:setPosition(ccp(self.showNumberSpriteTable[i]:getPositionX(), self.showNumberSpriteTable[i]:getPositionY() - number_pixiel_y))
		else
			self.showNumberSpriteBackTable[i]:setPosition(ccp(self.showNumberSpriteTable[i]:getPositionX(), self.showNumberSpriteTable[i]:getPositionY() + number_pixiel_y))
		end
		numberClipLayer_co:addChild(self.showNumberSpriteBackTable[i])
		numberClipLayer_co:addChild(self.showNumberSpriteTable[i])
		
		local bgSprite = Sprite:create("pic/4.png")
		bgSprite:setAnchorPoint(ccp(0, 1))
		bgSprite:setPosition(ccp(visibleSize.width / 2 + (i - 1) * number_pixiel_x - 2 + totalpixielX, ABSOLUTE_NUMBER_TOP_POSITION_Y + (71- number_pixiel_y) / 2))
		self:addChildAt(bgSprite, zOrder)
		
		local bgCover, specialStatusBg;
		local pixielX = 0
		local specialPixielX = 0
		if i == 1 then
			bgCover = Sprite:create("pic/2.png")
			bgCover:setScaleX(-1)
			bgCover:setAnchorPoint(ccp(1, 1))
			pixielX = -8
			if self.isBattleCountUp then
				specialStatusBg = Sprite:create("pic/languang1.png")
			else
				specialStatusBg = Sprite:create("pic/hongguang1.png")
			end
			specialStatusBg:setAnchorPoint(ccp(0, 1))
			specialPixielX = -16
		elseif i == self.numberAmount then
			bgCover = Sprite:create("pic/2.png")
			bgCover:setAnchorPoint(ccp(0, 1))
			pixielX = -2
			if self.isBattleCountUp then
				specialStatusBg = Sprite:create("pic/languang1.png")
			else
				specialStatusBg = Sprite:create("pic/hongguang1.png")
			end
			specialStatusBg:setAnchorPoint(ccp(1, 1))
			specialStatusBg:setScaleX(-1)
			specialPixielX = -2
		else
			bgCover = Sprite:create("pic/3.png")
			bgCover:setAnchorPoint(ccp(0, 1))
			pixielX = -2
			if self.isBattleCountUp then
				specialStatusBg = Sprite:create("pic/languang2.png")
			else
				specialStatusBg = Sprite:create("pic/hongguang2.png")
			end
			specialStatusBg:setAnchorPoint(ccp(0, 1))
			specialPixielX = -2
		end
		
		self.specialStatusBgTable[i] = specialStatusBg
		bgCover:setPosition(ccp(visibleSize.width / 2 + (i - 1) * number_pixiel_x + pixielX + totalpixielX, ABSOLUTE_NUMBER_TOP_POSITION_Y + (83- number_pixiel_y) / 2))
		self:addChild(bgCover)
		specialStatusBg:setPosition(ccp(visibleSize.width / 2 + (i - 1) * number_pixiel_x + specialPixielX + totalpixielX, ABSOLUTE_NUMBER_TOP_POSITION_Y + (99- number_pixiel_y) / 2))
		self:addChild(specialStatusBg)
		self.specialStatusBgTable[i]:setVisible(false)
		
		self.hightLightTable[i] = Sprite:create("pic/baiguang.png")
		self.hightLightTable[i]:setAnchorPoint(ccp(0, 1))
		if self.isBattleCountUp then
			self.hightLightTable[i]:setPosition(ccp(visibleSize.width / 2 + (i - 1) * number_pixiel_x - 2 + totalpixielX, ABSOLUTE_NUMBER_TOP_POSITION_Y + (83- number_pixiel_y) / 2 - 40))
		else
			self.hightLightTable[i]:setPosition(ccp(visibleSize.width / 2 + (i - 1) * number_pixiel_x - 2 + totalpixielX, ABSOLUTE_NUMBER_TOP_POSITION_Y + (83- number_pixiel_y) / 2 - 0))
		end
		self:addChild(self.hightLightTable[i])
		self.hightLightTable[i]:setVisible(false)
	end
	
	local function runRemovePanel()
		self:removeFromParentAndCleanup(true)
	end
	
	local function runPanelMoveAction()
		if self.flashFinish_co then
			self.flashFinish_co:removeFromParentAndCleanup(true)
		end
		if self.panelShowStep ~= PanelShowStep.FINISHSHOW then
			self.panelShowStep = PanelShowStep.FINISHSHOW
			g_attributeChangePanel = nil;
		end
		local actionArray = CCArray:create() 
		actionArray:addObject(CCMoveBy:create(0.3, ccp(0, 400)))
		actionArray:addObject(CCCallFuncN:create(runRemovePanel))
		self:runAction(CCSequence:create(actionArray))
	end
	
	local function runHighLightFun()
		for i = 1, self.numberAmount do
			self.specialStatusBgTable[i]:setVisible(false)
			if i == self.numberAmount then
				self.showNumberSpriteTable[i]:setVisible(false)
			end
		end

		if self.isBattleCountUp then
			local flashFinish = FlashSprite:create("EVO2/zhandouliup")   
			flashFinish:setLoop(false)
			flashFinish:changeAnimation(0)
			flashFinish:registerEndAnimationScriptHandler(runPanelMoveAction)
			self.flashFinish_co = CocosObject.new(flashFinish)
			self:addChild(self.flashFinish_co)
		else
			local actionArray = CCArray:create()
			actionArray:addObject(CCDelayTime:create(0.5))
			actionArray:addObject(CCCallFuncN:create(runPanelMoveAction))
			self:runAction(CCSequence:create(actionArray))
		end
	end
	
	local function onNodeRunFinish(obj)
		obj:setVisible(false)
	end
	
	local function runChangeAction(node, isHighLight)
		local actionArray = CCArray:create()
		local isUp = 1
		if not self.isBattleCountUp then
			isUp = -1
		end
		if isHighLight then
			actionArray:addObject(CCMoveBy:create(0.1, ccp(0, -10 * isUp)))
			actionArray:addObject(CCMoveBy:create(0.4, ccp(0, (0 + number_pixiel_y) * isUp)))
			actionArray:addObject(CCCallFuncN:create(onNodeRunFinish))
		else
			actionArray:addObject(CCMoveBy:create(0.1, ccp(0, -10 * isUp)))
			actionArray:addObject(CCDelayTime:create(0.05))
			actionArray:addObject(CCMoveBy:create(0.35, ccp(0, (10 + number_pixiel_y) * isUp)))
		end
		node:runAction(CCSequence:create(actionArray))
	end
	
	local function runNumberAction()
		local startRotation = false
		for i = 1, self.numberAmount do
			self.specialStatusBgTable[i]:setVisible(true)
			if not startRotation then
				local showNumber = self.fromNumberTable[self.numberAmount - i]
				if not showNumber then
					showNumber = 0
				end
				
				local toNumber = self.toNumberTable[self.numberAmount - i]
				if not toNumber then
					toNumber = 0
				end
				
				if showNumber ~= toNumber then
					startRotation = true
				end
			end
			
			if startRotation then
				self.hightLightTable[i]:setVisible(true)
				runChangeAction(self.showNumberSpriteTable[i])
				runChangeAction(self.showNumberSpriteBackTable[i])
				runChangeAction(self.hightLightTable[i], true)
			end
		end
		local actionArray = CCArray:create()
		actionArray:addObject(CCDelayTime:create(0.6))
		actionArray:addObject(CCCallFuncN:create(runHighLightFun))
		self:runAction(CCSequence:create(actionArray))
	end	
	
	if immediateShow then
		runNumberAction()
	else
		local actionArray = CCArray:create()
		self:setPosition(ccp(0, 400))
		actionArray:addObject(CCMoveTo:create(0.3, ccp(0, 0)))
		actionArray:addObject(CCCallFuncN:create(runNumberAction))
		self:runAction(CCSequence:create(actionArray))
	end
	
	local function setNotAffectTouchEvent(obj)
		obj.notAffectTouchEvent = true
		if type(obj.list) == "table" then
			for k,v in pairs(obj.list) do
				setNotAffectTouchEvent(v)
			end
		end
	end
	setNotAffectTouchEvent(self)
end

function AttributeChangePanel:dispose()
	if self.panelShowStep ~= PanelShowStep.FINISHSHOW then
		self.panelShowStep = PanelShowStep.FINISHSHOW
		g_attributeChangePanel = nil;
	end
	AttributeChangePanel.super.dispose(self)
end
