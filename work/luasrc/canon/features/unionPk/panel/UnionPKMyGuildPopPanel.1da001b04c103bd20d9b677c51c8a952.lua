-- UnionPKMyGuildPopPanel.lua
-- zhehua.ou
-- 2014-9-3
-- 军团战 我的军团

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

------------------------------------------------------------------------------------------------------

UnionPKMyGuildPopPanel = class(Layer)

function UnionPKMyGuildPopPanel:ctor()
	self.container = nil
	self.content = nil
end

function UnionPKMyGuildPopPanel:create( container , uiData )
	local s = UnionPKMyGuildPopPanel.new()
	s.container = container
	s._uiData = uiData
	s:initLayer()
	return s
end

function UnionPKMyGuildPopPanel:initLayer()
	UnionPKMyGuildPopPanel.super.initLayer(self)

	self.pre_container_targetInfoPanel = self.container.targetInfoPanel
	self.container.targetInfoPanel = self
    
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)

    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/guild_pk.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_guildpk_myguild")
    self.tempLayer:addChild(self.panelUI)

    local function closeBtnAction(evt)
      	self:dismissSelf()
    end
    local closeBtnDisplay = self.panelUI:getChildByName("login_btn_close")
    local closeBtn = Button:create(closeBtnDisplay)
    closeBtn:addEventListener( Events.kStart, closeBtnAction, self )
    
    local function onGoToCityBtn(evt)
    	local index = evt.target.index
    	local data = evt.context._uiData
 
   	    local function onAfterSucceed(evt)
   	    	self:dismissSelf()

			local scene = Director:mgr():run()
			scene.targetInfoPanel = UnionPkCityInfoPopPanel:create(scene, evt.data)
		    PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)
		end
		UnionPkGetCityInfoRequest.sendRequestDefalut(data[index], onAfterSucceed)
    end

    for i=1,2 do
    	local myGuildDisplay = self.panelUI:getChildByName("myguild_list"..i)

    	local goToCityBtn = Button:create(myGuildDisplay:getChildByName("btn"))
    	goToCityBtn.display:getChildByName("txt"):setString(getTextByKey("UnionWar_battle_go"))
    	goToCityBtn.index = i
    	goToCityBtn:addEventListener(Events.kStart, onGoToCityBtn, self)

		local textContainer = myGuildDisplay:getChildByName("txt_myguild_1")
		textContainer:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("UnionWar_battle_explain"))
		textContainer:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("UnionWar_battle_explain1"))
    end

	-- self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("UnionWar_sign_text1"))
	self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("UnionWar_ready_mine"))
	self.panelUI:getChildByName("myguild_blank"):getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("UnionWar_attend_lose"))

	self.tempLayer:setScale(0.1)

	self:refreshUI()
end

function UnionPKMyGuildPopPanel:refreshUI()
	self:setData(self._uiData)
end

function UnionPKMyGuildPopPanel:setData(cityList)
	if #cityList == 0 then
		self.panelUI:getChildByName("myguild_blank"):setVisible(true)
	else
		self.panelUI:getChildByName("myguild_blank"):setVisible(false)
	end

	for i=1,2 do
		local myguild = self.panelUI:getChildByName("myguild_list"..i)

		if cityList[i] == nil then
			myguild:setVisible(false)
		else
			myguild:setVisible(true)
			myguild:getChildByName("txt_myguild_1"):getChildByName("txt_2"):getChildByName("txt"):setString(UnionPkUtils.getCityNameById(cityList[i]))
		end
	end
end

function UnionPKMyGuildPopPanel:dispose()
	UnionPKMyGuildPopPanel.super.dispose(self)
end

function UnionPKMyGuildPopPanel:scaleIn()
	self.tempLayer.touchEnabled = false
	self.tempLayer.touchChildren = false
	local function scaleInFinished()
	  self.tempLayer.touchEnabled = true
	  self.tempLayer.touchChildren = true
	end
	local arr = CCArray:create()
	arr:addObject(CCEaseSineOut:create(CCScaleTo:create(0.3, 1.0)))
	arr:addObject(CCCallFunc:create(scaleInFinished))
	self.tempLayer:runAction(CCSequence:create(arr))

	UiStackManager.push(self)
end

function UnionPKMyGuildPopPanel:dismissSelf()
	UiStackManager.remove(self)

	self.container.targetInfoPanel = self.pre_container_targetInfoPanel
	self:removeFromParentAndCleanup(true)
end