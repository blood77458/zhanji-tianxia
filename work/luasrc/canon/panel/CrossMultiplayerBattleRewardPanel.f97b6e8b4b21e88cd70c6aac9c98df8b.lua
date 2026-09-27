--
-- CrossMultiplayerBattleRewardPanel
--

CrossMultiplayerBattleRewardPanel = class(Layer)

function CrossMultiplayerBattleRewardPanel:ctor()
    self.container = nil
end

function CrossMultiplayerBattleRewardPanel:create(container,data)
    local s = CrossMultiplayerBattleRewardPanel.new()
    s.win = data.win or false
    s.damage = data.damage or 0
    s.score = data.score or 0
    s.rewards = data.rewards or {}
    
    s.targetType = data.type or 0
    s:initLayer(container)
    return s
end

function CrossMultiplayerBattleRewardPanel:initLayer(container)
    CrossMultiplayerBattleRewardPanel.super.initLayer(self)
    local visibleSize = CCDirector:sharedDirector():getVisibleSize()

    self.container = container
    
    self.container.targetInfoPanel = self
    
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)
    
    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/Siren.json")
    builder.useArtLabelTTF = true

    local iconNum = 0
    local coinNum = 0
    for i,v in ipairs(self.rewards) do
        if v.itemType ~= ResourceEnum.COIN then
            iconNum = iconNum + 1
        else
            coinNum = tonumber(v.amount)
        end
    end

    if iconNum > 0 then
        self.panelUI = builder:build("popup_Siren_01")
        self.panelUI:getChildByName("txt_07"):getChildByName("txt"):setString(getTextByKey("crossBoss_attackReward"))

        for i=1,3 do
            local iconDisplay = self.panelUI:getChildByName("normal_card_small_name_godWill"..i)
            local iconBackground = iconDisplay:getChildByName("normal_card_small")
            iconBackground:setVisible(false)
        end

        local IconIndex = 1

        for i=1,4 do
            if self.rewards[i] and self.rewards[i].itemType ~= ResourceEnum.COIN and IconIndex < 4 then
                local iconDisplay = self.panelUI:getChildByName("normal_card_small_name_godWill"..IconIndex)
                local iconBackground = iconDisplay:getChildByName("normal_card_small")
                    
                if self.rewards[i] then
                    local itemIcon = CanonGoodIcon.createGoodIcon(self.rewards[i].itemType, self.rewards[i].metaId, self.rewards[i].amount, {sourceDisplay = iconBackground , showInCenter = true})
                    iconDisplay:addChild(itemIcon)

                    local itemName = CanonGoodIcon.getGoodName(self.rewards[i].itemType, self.rewards[i].metaId, self.rewards[i].amount, {withoutAmount = false})
                    iconDisplay:getChildByName("txt_Siren_34"):getChildByName("txt"):setString(itemName)
                end

                IconIndex = IconIndex + 1
            end
        end

        -- RewardManager:getReward(self.rewards)
    else
        self.panelUI = builder:build("popup_Siren_07")
    end

    if coinNum > 0 then
        self.panelUI:getChildByName("txt_03"):getChildByName("txt"):setString(getTextByKey("resource_silverCoin").."：")
        self.panelUI:getChildByName("txt_02"):getChildByName("txt"):setString(coinNum)
    end
    
    self.tempLayer:setScale(0.1)
    self.tempLayer:addChild(self.panelUI)
    
    local function closeAction(evt)
      -- self:dismiss()
      Director:sharedDirector():replaceScene(ActivityPanelScene:create("Activity_CrossBoss"))
    end

    local sureBtn = Button:create(self.panelUI:getChildByName("btn"))
    sureBtn.display:getChildByName("txt_guild_66"):getChildByName("txt"):setString(getTextByKey("yes"))
    sureBtn:addEventListener(Events.kStart, closeAction, self)

    if self.win then
    	local targetName = nil
    		
    	if self.targetType == 2 then
    		targetName = getTextByKey("crossBoss_awakenBoss")
    	elseif self.targetType == 3 then
    		targetName = getTextByKey("crossBoss_rampageBoss")
    	else -- 这是 1
    		targetName = getTextByKey("crossBoss_normalBoss")
    	end
    	self.panelUI:getChildByName("txt_06"):getChildByName("txt"):setString(getTextByKey("crossBoss_attackWin")..targetName)

        self.panelUI:getChildByName("lbl_victory"):setVisible(true)
        self.panelUI:getChildByName("lbl_failure"):setVisible(false)
    else
        self.panelUI:getChildByName("lbl_victory"):setVisible(false)
        self.panelUI:getChildByName("lbl_failure"):setVisible(true)
    end

	self.panelUI:getChildByName("txt_01"):getChildByName("txt"):setString(getTextByKey("crossBoss_attackDamage",{num1 = self.damage}))

	self.panelUI:getChildByName("txt_05"):getChildByName("txt"):setString(getTextByKey("crossBoss_score"))
	self.panelUI:getChildByName("txt_04"):getChildByName("txt"):setString(self.score)
end

function CrossMultiplayerBattleRewardPanel:scaleIn()
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
end

function CrossMultiplayerBattleRewardPanel:dismiss()
    self.container.targetInfoPanel = nil
    self:removeFromParentAndCleanup(true)
    self.container:setTableViewsEnabled(true)
end