NetworkErrorBox = class(Layer)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();

function NetworkErrorBox:ctor()
	self.tempLayer = nil
	self.container = nil
end

function NetworkErrorBox:dispose()
	self.tempLayer = nil
	self.container = nil
end

function NetworkErrorBox:initLayer(callback)
	NetworkErrorBox.super.initLayer(self)

	self.tempLayer = Layer:create()
	self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
	self:addChild(self.tempLayer)
	self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))

	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
	self.panelUI = builder:build("common_popup1") 
	self.tempLayer:addChild(self.panelUI)

	local aMessageLabelOne = self.panelUI:getChildByName("common_txt_popup1"):getChildByName("txt_popup1")
	local aMessageLabelTwo = self.panelUI:getChildByName("common_txt_sellItem_equip"):getChildByName("txt_sellItem_equip")
	aMessageLabelTwo:setDimensions(CCSizeMake(aMessageLabelTwo:getDimensions().width, 0))

	aMessageLabelOne:setVisible(false)
	aMessageLabelTwo:setString(getTextByKey("popup_networkError"))

	local leftBtn = self.panelUI:getChildByName("common_btn_continue")
	local txtLeftBtn = leftBtn:getChildByName("txt_continue")
	leftBtn:setVisible(false)
	local rightBtn = self.panelUI:getChildByName("common_btn_cancel")
	local txtRightBtn = rightBtn:getChildByName("txt_cancel")
	rightBtn:setVisible(false)
	local centerBtn = self.panelUI:getChildByName("common_btn_center")
	local txtCenterBtn = centerBtn:getChildByName("txt_center")
	centerBtn:setVisible(false)

	local function onButtonClicked()
        self:pullin()
      	CanonPlayEffect(MusicPathConstants.ButtonOK)
		if callback and type(callback) == "function" then
			callback()
		end
	end

	local arr = CCArray:create()

	local buttonSprite = CCSprite:create(UI_RES_PATH.."/common_new/common_btn_common_short_blue_sb.png")
	local buttonSelected = CCSprite:create(UI_RES_PATH.."/common_new/common_btn_common_short_blue_sb.png")
	buttonSelected:setColor(ccc3(100,100,100))
	local button = CCMenuItemSprite:create(buttonSprite, buttonSelected)
	button:setPosition(ccp(visibleSize.width/2, 640))
	button:registerScriptTapHandler(onButtonClicked)
	local label = ArtLabelTTF:create(getTextByKey("retry"), "Arial", 36)
	label:setPosition(button:getContentSize().width/2, button:getContentSize().height/2)
	button:addChild(label)
	arr:addObject(button)

	local menu = PandoraMenuEx:createWithArray(arr, -40000)
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
	menuLayer:registerScriptTouchHandler(onTouch, false, -39000, true)
	menuLayer:setTouchEnabled(true)

	menuLayer:addChild(menu, 20)
	self.tempLayer:addChild(CocosObject.new(menuLayer))
  
  self:popout( 99999 )  --位于屏幕最顶层的弹出框
end

function NetworkErrorBox.showErrorBox(callback)
	local errorBox = NetworkErrorBox.new()
	errorBox.container = Director:sharedDirector():getRunningScene()
	errorBox:initLayer(callback)
end

function NetworkErrorBox:popout( ZOrder ) --位于屏幕最顶层的弹出框
  local curScene = CCDirector:sharedDirector():getRunningScene()
  
  local TouchLayer = CCLayerColor:create(ccc4( 0, 0, 0, 0 ))--截获触摸的层
  self:addChild( TouchLayer )
  
	self.BackLayer = CCLayerColor:create(ccc4( 0, 0, 0, 255 ))--黑色背景
	self.BackLayer:setOpacity( 150 )
  self.BackLayer:setZOrder( ZOrder )
  self.BackLayer:setContentSize(CCSizeMake( visibleSize.width, visibleSize.height ))
	self.BackLayer:setAnchorPoint(ccp( 0.5, 0.5 ))
  curScene:addChild( self.BackLayer )
  
  local bgLayer = CCLayerColor:create(ccc4( 0, 0, 0, 0 ))--显示对话框
  bgLayer:setScale( 0.1 )
  bgLayer:addChild( self.refCocosObj )
  self.BackLayer:addChild( bgLayer )

  local function onPopoutEnterAnimationFinished()
  end

	local arr = CCArray:create()
    arr:addObject(CCEaseSineOut:create(CCScaleTo:create( 0.3, 1 )))
    arr:addObject(CCCallFunc:create( onPopoutEnterAnimationFinished ))
    bgLayer:runAction(CCSequence:create( arr ))
end

function NetworkErrorBox:pullin()
  local curScene = CCDirector:sharedDirector():getRunningScene()
  if self.BackLayer ~= nil then
    curScene:removeChild( self.BackLayer, true )
  end
end

