UpdateNotifyBox = class(Layer)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function UpdateNotifyBox:ctor()
	self.tempLayer = nil
	self.container = nil
end

function UpdateNotifyBox:dispose()
	self.tempLayer = nil
	self.container = nil
end

function UpdateNotifyBox:initLayer(size, onConfirm, onCancel)
	UpdateNotifyBox.super.initLayer(self)

	self.tempLayer = Layer:create()
	self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
	self:addChild(self.tempLayer)
	self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))

	local bg = Sprite:create("loading/box_bg.png")
	bg:setPosition(ccp(visibleSize.width/2, 700))
	self.tempLayer:addChild(bg)

	local noticeStr = Localization:getInstance():getText("updateDialog", {num = string.format("%.2f", size/1000000)})

	if isXiaomiAndroid() then
		--[[
		require "hecore.luaJavaConvert"
		require "canon.data.ThirdPlatformLogin"
		local javaClass = luajava.bindClass("com.happyelements.arda.MainActivity")
		local isWifiAvailable = javaClass:isWifiAvailable()

		if not isWifiAvailable then
			noticeStr = Localization:getInstance():getText("updateWifiConfirm")
		end
		--]]
	end

	local text = TextField:create(noticeStr,
		"Helvetica",
		28,
		CCSizeMake(480, 0),
		kCCTextAlignmentLeft)
	text:setPosition(ccp(visibleSize.width/2, 740))
	self.tempLayer:addChild(text)

	local function onConfirmClicked()
      	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
      	CanonPlayEffect(MusicPathConstants.ButtonOK)
		if onConfirm and type(onConfirm) == "function" then
			onConfirm()
		end
	end

	local arr = CCArray:create()

	local buttonSprite = CCSprite:create("loading/btn_sure.png")
	local buttonSelected = CCSprite:create("loading/btn_sure.png")
	local button = CCMenuItemSprite:create(buttonSprite, buttonSelected)
	button:setPosition(ccp(visibleSize.width/2 - 120, 640))
	button:registerScriptTapHandler(onConfirmClicked)
	arr:addObject(button)

	local function onCancelClicked()
      	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
      	CanonPlayEffect(MusicPathConstants.ButtonOK)
		if onCancel and type(onCancel) == "function" then
			onCancel()
		end
	end

	local cancelSprite = CCSprite:create("loading/btn_cancel.png")
	local cancelSelected = CCSprite:create("loading/btn_cancel.png")
	local cancelButton = CCMenuItemSprite:create(cancelSprite, cancelSelected)
	cancelButton:setPosition(ccp(visibleSize.width/2 + 120, 640))
	cancelButton:registerScriptTapHandler(onCancelClicked)
	arr:addObject(cancelButton)

	local menu = PandoraMenuEx:createWithArray(arr, -128)
	menu = tolua.cast(menu, "CCNode")
	menu:setPosition(0,0)
	local menuLayer = CCLayer:create()

	local function onTouch(event, x, y)
		if event == CCTOUCHBEGAN then
			return true
		else
			return
		end
	end
	--menuLayer:registerScriptTouchHandler(onTouch, false, -39000, true)
	--menuLayer:setTouchEnabled(true)

	menuLayer:addChild(menu, 20)
	self.tempLayer:addChild(CocosObject.new(menuLayer))

  	PopoutManager:sharedManager():popout(self, kPopoutDir.kScale, true, false ,self.container, 200)
end

function UpdateNotifyBox.showBox(size, onConfirm, onCancel)
	local errorBox = UpdateNotifyBox.new()
	errorBox.container = Director:sharedDirector():getRunningScene()
	errorBox:initLayer(size, onConfirm, onCancel)
end
