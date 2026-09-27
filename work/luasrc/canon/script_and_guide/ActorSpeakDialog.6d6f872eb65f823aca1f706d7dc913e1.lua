--------------------------------------------------------------------------------
-- ActorSpeakDialog.lua - ½ÇÉ«¶Ô»°½çÃæ
-- author: litong.sun
-- date: 2014-04-14
--------------------------------------------------------------------------------

local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local currentDialog = nil
local showSkip = false
local skipStory = false
local mask_height = 140
local bg_extra_height = 277
local role_extra_height = 30
local animation_speed = 2000
local bottom_scale = 1.3
local top_scale = 1.5
local expression_dic = {
	[1] = 4,
	[2] = 1,
	[3] = 2,
	[4] = 0,
	[5] = 3,
}

ActorSpeakDialog = class(LayerColor)

function ActorSpeakDialog:ctor()
end

function ActorSpeakDialog:create(params)
	local dialog = ActorSpeakDialog.new()
	dialog.text = params.ShowText
	dialog.eventConfig = params.One_Event
	if tonumber(dialog.eventConfig.figureId) == 0 then
	    dialog.personName = dialog.eventConfig.ActorName
	else
	    local OneData = MetaManager.card_meta[tonumber(dialog.eventConfig.figureId)]
	    if OneData == nil then
	      	dialog.personName = ""
	    else
	      	dialog.personName = Localization_getText( OneData.name )
	    end
	end
	dialog.personId = dialog.eventConfig.figureId
	dialog.personSide = dialog.eventConfig.talker
	dialog.textType = dialog.eventConfig.dialogType
	dialog.background = string.gsub(dialog.eventConfig.background, " ", "")
	dialog.enterAnimation = dialog.eventConfig.enterAnimation
	dialog.expression = dialog.eventConfig.expression

	dialog.animationFinishFlag = false
	dialog.selectSprite1 = nil
	dialog.selectSprite2 = nil
	dialog.skipSprite = nil
	dialog:initLayer()
	return dialog
end

--[[local musicEntry
local function stopScheduler()
	if musicEntry then
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(musicEntry)
      	musicEntry = nil
      	SimpleAudioEngine:sharedEngine():setBackgroundMusicVolume(1.0)
	end
end
local function switchMusic(aMusicName)
	if (not musicEntry) and (aMusicName ~= current_music_name) then
	    local function delayCallback( dt )
	    	local currentVolume = SimpleAudioEngine:sharedEngine():getBackgroundMusicVolume()
	    	currentVolume = currentVolume - 0.2
	    	SimpleAudioEngine:sharedEngine():setBackgroundMusicVolume(currentVolume)
	    	if (currentVolume <= 0) and musicEntry then
		      	CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(musicEntry)
		      	musicEntry = nil
		      	CanonPlayBackgroundMusic(aMusicName, true)
		      	SimpleAudioEngine:sharedEngine():setBackgroundMusicVolume(1.0)
		    end
	    end
	    musicEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(delayCallback, 0.1, false)
	end
end]]

function ActorSpeakDialog:initLayer()
	ActorSpeakDialog.super.initLayer(self)
	local curScene = Director:sharedDirector():getRunningScene()
	--switchMusic("music/" .. self.eventConfig.bgm .. ".mp3")
	CanonPlayBackgroundMusic("music/" .. self.eventConfig.bgm .. ".mp3", true)

	self:changeWidthAndHeight(visibleSize.width, visibleSize.height)
	function onTouch(eventType, x, y)
		if not self.animationFinishFlag then
			return 1
		end
		if eventType == "began" then
			--add touch effect begin by dc
			if addTouchEffect then
				addTouchEffect(curScene,x,y)
			end
			--add touch effect end--]]
		end
		if self.selectSprite1 and self.selectSprite1.refCocosObj and self.selectSprite1:hitTestPoint(ccp(x, y), true) then
			if eventType == "began" then
				local evt = DisplayEvent.new(DisplayEvents.kTouchBegin, self.selectSprite1, ccp(x, y))
				self.selectSprite1:dispatchEvent(evt)
			elseif eventType == "moved" then
				local evt = DisplayEvent.new(DisplayEvents.kTouchMove, self.selectSprite1, worldPosition);
				self.selectSprite1:dispatchEvent(evt)
			elseif eventType == "ended" then
				local evt = DisplayEvent.new(DisplayEvents.kTouchEnd, self.selectSprite1, worldPosition);
				self.selectSprite1:dispatchEvent(evt)
				local evt = DisplayEvent.new(DisplayEvents.kTouchTap, self.selectSprite1, worldPosition);
				self.selectSprite1:dispatchEvent(evt)
			elseif eventType == "cancelled" then
				local evt = DisplayEvent.new(DisplayEvents.kTouchEnd, self.selectSprite1, worldPosition);
				self.selectSprite1:dispatchEvent(evt)
			end
		end

		if self.selectSprite2 and self.selectSprite2.refCocosObj and self.selectSprite2:hitTestPoint(ccp(x, y), true) then
			if eventType == "began" then
				local evt = DisplayEvent.new(DisplayEvents.kTouchBegin, self.selectSprite2, ccp(x, y))
				self.selectSprite2:dispatchEvent(evt)
			elseif eventType == "moved" then
				local evt = DisplayEvent.new(DisplayEvents.kTouchMove, self.selectSprite2, worldPosition);
				self.selectSprite2:dispatchEvent(evt)
			elseif eventType == "ended" then
				local evt = DisplayEvent.new(DisplayEvents.kTouchEnd, self.selectSprite2, worldPosition);
				self.selectSprite2:dispatchEvent(evt)
				local evt = DisplayEvent.new(DisplayEvents.kTouchTap, self.selectSprite2, worldPosition);
				self.selectSprite2:dispatchEvent(evt)
			elseif eventType == "cancelled" then
				local evt = DisplayEvent.new(DisplayEvents.kTouchEnd, self.selectSprite2, worldPosition);
				self.selectSprite2:dispatchEvent(evt)
			end
		end

		if self.skipSprite and self.skipSprite.refCocosObj and self.skipSprite:hitTestPoint(ccp(x, y), true) then
			if eventType == "began" then
				local evt = DisplayEvent.new(DisplayEvents.kTouchBegin, self.skipSprite, ccp(x, y))
				self.skipSprite:dispatchEvent(evt)
			elseif eventType == "moved" then
				local evt = DisplayEvent.new(DisplayEvents.kTouchMove, self.skipSprite, worldPosition);
				self.skipSprite:dispatchEvent(evt)
			elseif eventType == "ended" then
				local evt = DisplayEvent.new(DisplayEvents.kTouchEnd, self.skipSprite, worldPosition);
				self.skipSprite:dispatchEvent(evt)
				local evt = DisplayEvent.new(DisplayEvents.kTouchTap, self.skipSprite, worldPosition);
				self.skipSprite:dispatchEvent(evt);
			elseif eventType == "cancelled" then
				local evt = DisplayEvent.new(DisplayEvents.kTouchEnd, self.skipSprite, worldPosition);
				self.skipSprite:dispatchEvent(evt)
			end
		end

		if eventType == "ended" and (not self.selectSprite1) and (not self.selectSprite2) then
			FireClickEvent()
			--stopScheduler()
		end
		return 1
	end
	self:registerScriptTouchHandler(onTouch, false, -32768, true)
	self:setTouchEnabled(true)

	local z_order_index = 0
	local function addZorderIndex()
		z_order_index = z_order_index + 1
	end

	local bg = Sprite:create("textbox_comm/GuideBg/" .. self.background .. ".png")
	bg:setScale(1.5)
	bg:setAnchorPoint(ccp(0.5, z_order_index))
	bg:setPosition(ccp(visibleSize.width / 2.0, mask_height + bg_extra_height))
	self:addChildAt(bg, 0)
	addZorderIndex()

	local function addTalkerSprite(aPersonId, aTalkerSide, aScale, aZorder)
		local aCardMeta = MetaManager.card_meta[aPersonId]
		if aCardMeta then
			local personSprite = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(aPersonId))
			personSprite:setScale(aScale)
			personSprite:setAnchorPoint(ccp(0.5, 0))
			if aTalkerSide == 1 then
				personSprite.refCocosObj:setFlipX(not personSprite.refCocosObj:isFlipX())
			end
			if aCardMeta.face == 1 then
				personSprite.refCocosObj:setFlipX(not personSprite.refCocosObj:isFlipX())
			end
			personSprite:setPosition(ccp(aTalkerSide == 1 and visibleSize.width/4 or visibleSize.width*3/4, mask_height + bg_extra_height - 20))
			self:addChildAt(personSprite, aZorder)
			return personSprite
		end
	end

	local function calculateExitAnimationParams(aSprite, aType)
		local moveDistance = ccp(0, 0)
		if aType == 1 then
			moveDistance.x = -aSprite:getContentSize().width / 2.0 - aSprite:getPositionX()
			moveDistance.y = 0
		elseif aType == 2 then
			moveDistance.x = visibleSize.width + aSprite:getContentSize().width / 2.0 - aSprite:getPositionX()
			moveDistance.y = 0
		elseif aType == 3 then
			moveDistance.x = 0
			moveDistance.y = -aSprite:getContentSize().height / 2.0 - aSprite:getPositionY()
		else
			print("This exit animation type not exit")
		end
		return moveDistance
	end

	local function calculateEnterAnimationParams(aSprite, aType, aPersonSide)
		local originalPos = ccp(aSprite:getPositionX(), aSprite:getPositionY())
		local moveDistance = ccp(0, 0)
		if aType == 1 then
			originalPos.x = -aSprite:getContentSize().width / 2.0
			originalPos.y = aSprite:getPositionY()
		elseif aType == 2 then
			originalPos.x = visibleSize.width + aSprite:getContentSize().width / 2.0
			originalPos.y = aSprite:getPositionY()
		elseif aType == 3 then
			originalPos.x = aSprite:getPositionX()
			originalPos.y = -aSprite:getContentSize().height / 2.0
		else
			print("This enter animation type not exit")
		end
		moveDistance.x = aSprite:getPositionX() - originalPos.x
		moveDistance.y = aSprite:getPositionY() - originalPos.y
		return originalPos, moveDistance
	end

	local function addMaskLayer(aZorder)
		self.maskLayer = LayerColor:create()
		self.maskLayer:changeWidthAndHeight(visibleSize.width, visibleSize.height)
		--self.maskLayer:setColor(ccc3(255, 0, 0))
		self.maskLayer:setOpacity(100)
		self:addChildAt(self.maskLayer, aZorder)
	end

	local function removeMaskLayer()
		self.maskLayer:removeFromParentAndCleanup(true)
		self.maskLayer = nil
	end

	local function addTextBox(aTalkerSide, aName, aContent, aZorder)
		self.textbox = Sprite:create("textbox_comm/TextBox_Comm_New_1.png")
		self:addChildAt(self.textbox, aZorder)
		if aTalkerSide == 2 then
			self.textbox.refCocosObj:setFlipX(true)
		end
		local personText = BitmapText:create(aName, "common/card_name.fnt", 0, kCCTextAlignmentLeft)
		if aTalkerSide == 2 then
			personText:setAnchorPoint(ccp(0.5, 0.5))
			personText:setPosition(ccp(visibleSize.width-190, 305))
		else
			personText:setAnchorPoint(ccp(0.5, 0.5))
			personText:setPosition(ccp(190, 305))
		end
		personText.name = "personText"
		self.textbox:addChild(personText)
		local text = TextField:create(aContent, nil, 36, CCSizeMake(30*22, 0))
		text:setAnchorPoint(ccp(0, 1.0))
		text:setPosition(ccp(40, 175))
		text.name = "text"
		self.textbox:addChild(text)
		self.textbox:setAnchorPoint(ccp(0.5, 0))
		self.textbox:setPosition(ccp(visibleSize.width/2, mask_height))
	end

	local function removeTextBox()
		self.textbox:removeFromParentAndCleanup(true)
		self.textbox = nil
	end

	local function addTBMaskLayer(aZorder)
		self.topMaskLayer = LayerColor:create()
		self.topMaskLayer:changeWidthAndHeight(visibleSize.width, mask_height)
		self.topMaskLayer:setOpacity(255)
		self.topMaskLayer:setPosition(ccp(0, visibleSize.height - mask_height))
		self:addChildAt(self.topMaskLayer, aZorder)
		self.bottomMaskLayer = LayerColor:create()
		self.bottomMaskLayer:changeWidthAndHeight(visibleSize.width, mask_height)
		self.bottomMaskLayer:setOpacity(255)
		self.bottomMaskLayer:setPosition(ccp(0, 0))
		self:addChildAt(self.bottomMaskLayer, aZorder)
	end

	local function removeTBMaskLayer()
		self.topMaskLayer:removeFromParentAndCleanup(true)
		self.topMaskLayer = nil
		self.bottomMaskLayer:removeFromParentAndCleanup(true)
		self.bottomMaskLayer = nil
	end

	local previousTalkerSide = Get_ShareData("Previsou_Talker_Side")

	local bottomTalkerSide = (previousTalkerSide == 1) and 2 or 1
	local bottomPersonId = Get_ShareData("Person_Id_Talker_" .. bottomTalkerSide)
	local bottomSprite = addTalkerSprite(bottomPersonId, bottomTalkerSide, bottom_scale, z_order_index)
	addZorderIndex()
	
	addMaskLayer(z_order_index)
	addZorderIndex()

	local topTalkerSide = previousTalkerSide
	local topPersonId = Get_ShareData("Person_Id_Talker_" .. topTalkerSide)
	local topSprite = addTalkerSprite(topPersonId, topTalkerSide, top_scale, z_order_index)
	addZorderIndex()

	addTBMaskLayer(z_order_index)
	addZorderIndex()

	local function addSpriteExpression(aSprite, aPersonId, aPersonSide, aExpression)
		if aExpression == 0 then
			return
		end
		
	    local bubble = Sprite:create("textbox_comm/biaoqingpaopao.png")
	    local aCardMeta = MetaManager.card_meta[aPersonId]
	    local posList = aCardMeta.expression:split(",")
	    if aPersonSide == 1 then
	    	posList[1] = aSprite:getContentSize().width - posList[1]
	    	bubble.refCocosObj:setFlipX(not bubble.refCocosObj:isFlipX())
	    end
	    posList[2] = aSprite:getContentSize().height - posList[2]
	    bubble:setPositionX(posList[1])
	    bubble:setPositionY(posList[2])
		aSprite:addChild(bubble)

		local fspt = FlashSprite:create("EVO2/conversation_expression")
	    fspt:changeAnimation(expression_dic[aExpression])
	    fspt:setLoop(true)
	    local fspt_co = CocosObject.new(fspt)
	    fspt_co:setPositionX(posList[1])
	    fspt_co:setPositionY(posList[2])
	    aSprite:addChild(fspt_co)
	end

	local function addButton(aSpriteName1, aSpriteName2, aPos, callback)
		local aButtonSprite = CocosObject:create()
		local normal = Sprite:create(aSpriteName1)
		normal.name = "normal"
		aButtonSprite:addChild(normal)
		local press = Sprite:create(aSpriteName2)
		press.name = "over"
		aButtonSprite:addChild(press)
		aButtonSprite:setPosition(aPos)
		self:addChild(aButtonSprite)
		local button = Button:create(aButtonSprite, true)
		-- button.noTouchEffect = true
		button:addEventListener(Events.kStart, callback)
		return aButtonSprite
	end

	local enterSprite
	local function enterAnimationFinished()
		addSpriteExpression(enterSprite, self.personId, self.personSide, self.expression)
		self.animationFinishFlag = true
	end

	local function switchTalker()
		local oldSprite
		local staySprite
		if self.personSide == previousTalkerSide then
			oldSprite = topSprite
			staySprite = bottomSprite
		else
			oldSprite = bottomSprite
			staySprite = topSprite
		end
		if oldSprite then
			oldSprite:removeFromParentAndCleanup(true)
			oldSprite = nil
		end
		if staySprite and staySprite.refCocosObj then
			staySprite:setScale(bottom_scale)
		end
		addMaskLayer(z_order_index)
		addZorderIndex()

		enterSprite = addTalkerSprite(self.personId, self.personSide, top_scale, z_order_index)
		addZorderIndex()

		addTBMaskLayer(z_order_index)
		addZorderIndex()

		addTextBox(self.personSide, self.personName, self.text, z_order_index)
		addZorderIndex()
		if enterSprite then
			if self.enterAnimation == 0 then
				addSpriteExpression(enterSprite, self.personId, self.personSide, self.expression)
				self.animationFinishFlag = true
			else
				local aContentSize = enterSprite:getContentSize()
				local originalPos
				local moveDistance
				originalPos, moveDistance = calculateEnterAnimationParams(enterSprite, self.enterAnimation, self.personSide)
				enterSprite:setPositionX(originalPos.x)
				enterSprite:setPositionY(originalPos.y)
				local arr = CCArray:create()
				arr:addObject(CCMoveBy:create(math.sqrt(math.pow(moveDistance.x, 2) + math.pow(moveDistance.y, 2)) / animation_speed, moveDistance))
			    arr:addObject(CCCallFunc:create(enterAnimationFinished))
			    enterSprite:runAction(CCSequence:create(arr))
			end
		else
			self.animationFinishFlag = true
		end
		if self.eventConfig.dialogContent2 and type(self.eventConfig.dialogContent2) == "string" then
	    	local previousDialogContent = Get_ShareData("Previous_Dialog_Content")
	    	local text = self.textbox:getChildByName("text")
	    	local personText = self.textbox:getChildByName("personText")
	    	text:setString(previousDialogContent)
	    	if previousTalkerSide == 2 then
				self.textbox.refCocosObj:setFlipX(true)
				personText:setAnchorPoint(ccp(0.5, 0.5))
				personText:setPosition(ccp(visibleSize.width-190, 305))
			else
				self.textbox.refCocosObj:setFlipX(false)
				personText:setAnchorPoint(ccp(0.5, 0.5))
				personText:setPosition(ccp(190, 305))
			end
	    	local previousDialogPerson = Get_ShareData("Previous_Dialog_Person")
	    	personText:setString(previousDialogPerson)
	    	local function onSelectButton1()
				Set_ShareData("Next_Order_Id", self.eventConfig.nextDialogID)
			end
	    	self.selectSprite1 = addButton("textbox_comm/bg_review_plot.png", "textbox_comm/bg_review_plot.png", ccp(360, 896), onSelectButton1)
	    	local aText = TextField:create(Localization_getText(self.eventConfig.dialogContent), nil, 26, CCSizeMake(268, 0))
			aText:setAnchorPoint(ccp(0, 1.0))
			aText:setColor(ccc3(0,0,0))
			aText:setPosition(ccp(39 - 268, 120 - 80))
			self.selectSprite1:addChild(aText)
	    	local function onSelectButton2()
				Set_ShareData("Next_Order_Id", self.eventConfig.nextDialogID2)
			end
	    	self.selectSprite2 = addButton("textbox_comm/bg_review_plot.png", "textbox_comm/bg_review_plot.png", ccp(360, 670), onSelectButton2)
	    	local aText = TextField:create(Localization_getText(self.eventConfig.dialogContent2), nil, 26, CCSizeMake(268, 0))
			aText:setAnchorPoint(ccp(0, 1.0))
			aText:setColor(ccc3(0,0,0))
			aText:setPosition(ccp(39 - 268, 120 - 80))
			self.selectSprite2:addChild(aText)
			
	    end

	    if showSkip then
			local function onSkipClicked()
				skipStory = true
				Set_ShareData("Skip_Story", 1)
			end
			self.skipSprite = addButton("battle/pic/skip_active.png", "battle/pic/skip_active.png", ccp(614, 1074), onSkipClicked)
			--[[local aText = ArtTextField:create(Localization_getText("storyReview_skipButton"), nil, 42, CCSizeMake(0, 0), kCCTextAlignmentCenter)
			aText:setAnchorPoint(ccp(0.5, 0.5))
			aText:setPosition(ccp(0, 4))
			aText:setColor(ccc3(255, 255, 255))
			aText:setAroundColor(ccc3(0, 0, 0))
			self.skipSprite:addChild(aText)]]
		end
	end

	local function exitAnimationFinished()
		removeMaskLayer()
		removeTBMaskLayer()
		topSprite:removeFromParentAndCleanup(true)
		topSprite = nil
		removeTextBox()
		switchTalker()
	end

	local previousTalkerExitType = Get_ShareData("Previsou_Talker_Exit_Type")
	if (previousTalkerSide == 0) or (previousTalkerExitType == 0) or (not topSprite) then
		removeMaskLayer()
		removeTBMaskLayer()
		switchTalker()
	else
		Set_ShareData("Person_Id_Talker_" .. previousTalkerSide, -1)
		addTextBox(previousTalkerSide, Get_ShareData("Previous_Dialog_Person"), Get_ShareData("Previous_Dialog_Content"), z_order_index)
		addZorderIndex()
		local aContentSize = topSprite:getContentSize()
		local moveDistance = calculateExitAnimationParams(topSprite, previousTalkerExitType)
		local arr = CCArray:create()
		arr:addObject(CCMoveBy:create(math.sqrt(math.pow(moveDistance.x, 2) + math.pow(moveDistance.y, 2)) / animation_speed, moveDistance))
	    arr:addObject(CCCallFunc:create(exitAnimationFinished))
	    topSprite:runAction(CCSequence:create(arr))
	end

end

local blockLayer = nil
function disableUserInteraction()
	local scene = Director:sharedDirector():getRunningScene()
	enableUserInteraction()
	blockLayer = Layer:create()
	function onTouch(eventType, x, y)
		return 1
	end
	blockLayer:registerScriptTouchHandler(onTouch, false, -32767, true)
	blockLayer:setTouchEnabled(true)
	scene:addChild(blockLayer)
end

function enableUserInteraction()
	if blockLayer then
		if not blockLayer.isDisposed then
			blockLayer:removeFromParentAndCleanup(true)
		end
		blockLayer = nil
	end
end

-- local dialogTimeout = nil
-- local dialogEnableClick = nil
function Replace_Clicking_With_Timer(timeout, enableClick)
	-- dialogTimeout = timeout
	-- dialogEnableClick = enableClick
end

function Clicking_Only()
	dialogTimeout = nil
	dialogEnableClick = nil
end

local currentDialogBox = nil
function All_DialogBoxes_Hide()
	if currentDialogBox then
		if not currentDialogBox.isDisposed then
			currentDialogBox:removeFromParentAndCleanup(true)
		end
		currentDialogBox = nil
	end
end

function setIsShowDialogSkipButton(show)
	showSkip = show
	skipStory = false
end

local delay_flag = "Delay_Flag"
function ShowDialogBox(params)
	if skipStory then
		return
	end
	currentDialogBox = ActorSpeakDialog:create(params)
	currentDialogBox:setZOrder(9999)
	local scene = Director:sharedDirector():getRunningScene()
	scene:addChild(currentDialogBox)
	--[[
	WaitForClick()
	All_DialogBoxes_Hide()
	]]
	
	local aScheduler
	local function callback()
		CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(aScheduler)
		Set_ShareData(delay_flag, 1)
	end
	aScheduler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(callback, 0.03, false)

	
	Set_ShareData(delay_flag, 0)
	Wait_For_ShareData(delay_flag, 1)
	WaitForClick()
	All_DialogBoxes_Hide()
end
