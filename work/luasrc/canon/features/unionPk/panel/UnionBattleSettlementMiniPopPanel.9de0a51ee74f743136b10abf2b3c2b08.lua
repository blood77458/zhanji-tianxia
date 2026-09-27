-- UnionBattleSettlementMiniPopPanel.lua
-- zhehua.ou
-- 2014-10-17
-- 军团战 战斗结算 小

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

------------------------------------------------------------------------------------------------------

UnionBattleSettlementMiniPopPanel = class(Layer)

function UnionBattleSettlementMiniPopPanel:ctor()
	self.container = nil
	self.content = nil
end

function UnionBattleSettlementMiniPopPanel:create(container , data)
	local s = UnionBattleSettlementMiniPopPanel.new()
	s.container = container
	s.data = data
	s:initLayer()
	return s
end

function UnionBattleSettlementMiniPopPanel:initLayer()
	UnionBattleSettlementMiniPopPanel.super.initLayer(self)

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
    self.panelUI = builder:build("popup_settlement_2")
    self.tempLayer:addChild(self.panelUI)

    local function closeBtnAction(evt)
    	local cityId = self.data.cityId

      	self:dismissSelf()
      	UnionPK.battleBackToUnionPkScene(cityId)
    end
    local closeBtnDisplay = self.panelUI:getChildByName("login_btn_close")
    local closeBtn = Button:create(closeBtnDisplay)
    closeBtn:addEventListener( Events.kStart, closeBtnAction, self )
    
    self.panelUI:getChildByName("txt_4"):getChildByName("txt"):setString(UnionPkUtils.getCityNameById(self.data.cityId))

    self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(self.data.left_name)
    self.panelUI:getChildByName("signInIcon_victory_f_1"):setVisible(self.data.left_winOrlose)
    self.panelUI:getChildByName("signInIcon_negative_f_2"):setVisible(not self.data.left_winOrlose)

	self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(self.data.right_name)
	self.panelUI:getChildByName("signInIcon_victory_f_2"):setVisible(self.data.right_winOrlose)
	self.panelUI:getChildByName("signInIcon_negative_f_1"):setVisible(not self.data.right_winOrlose)

	self.panelUI:getChildByName("btn_1"):getChildByName("txt_guild_66"):getChildByName("txt"):setString(getTextByKey("yes"))

	local yesBtn = Button:create(self.panelUI:getChildByName("btn_1"))
	yesBtn:addEventListener(Events.kStart, closeBtnAction, self)
	
	self.tempLayer:setScale(0.1)
end

function UnionBattleSettlementMiniPopPanel:dispose()
	UnionBattleSettlementMiniPopPanel.super.dispose(self)
end

function UnionBattleSettlementMiniPopPanel:scaleIn()
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

function UnionBattleSettlementMiniPopPanel:dismissSelf()
	UiStackManager.remove(self)

	self.container.targetInfoPanel = self.pre_container_targetInfoPanel
	self:removeFromParentAndCleanup(true)
end