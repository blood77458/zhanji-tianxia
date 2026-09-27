--
-- WantedActivityInfoPanel
--

WantedActivityInfoPanel = class(Layer)

function WantedActivityInfoPanel:ctor()
    self.container = nil
end

function WantedActivityInfoPanel:create(container)
    local s = WantedActivityInfoPanel.new()
    s:initLayer(container)
    return s
end

function WantedActivityInfoPanel:initLayer(container)
    WantedActivityInfoPanel.super.initLayer(self)
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
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_wanted_activity_rules")
    self.tempLayer:setScale(0.1)
    self.tempLayer:addChild(self.panelUI)
    
    local function closeAction(evt)
      self:dismiss()
    end
    
    local closeButton = Button:create(self.panelUI:getChildByName("common_btn_close"))
    closeButton:addEventListener(Events.kStart, closeAction, self)

    self.panelUI:getChildByName("common_txt_playerInfo_title"):getChildByName("txt_playerInfo_title"):setString(getTextByKey("wanted_ruleTitle1"))
    self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("wanted_ruleTitle2"))
    self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("wanted_ruleReward1"))

    local ruleStr = getTextByKey("wanted_rule" , {num = DataManager.GameMetaData.activityWantedConfig.completeNum})
    local ruleStrTable = ruleStr:split("\\n")
    local finalString = ""
    for i, aString in ipairs(ruleStrTable) do
        if i > 1 then
            finalString = finalString.."\n"
        end
        finalString = finalString..aString
    end
    self.panelUI:getChildByName("txt_3"):getChildByName("txt_sellItem_equip"):setString(finalString)

    local rewardDetail = {}
    for i=1,5 do
        local rewardsInfo = DataManager.GameMetaData.activityWantedConfig.questRewards[i]

        local goldOrSilver = nil
        if rewardsInfo.contentID1 == 400217 then -- 400217 金
            goldOrSilver = true
        elseif rewardsInfo.contentID1 == 400216 then -- 400216 银
            goldOrSilver = false
        else
            print("操,配置有问题")
        end

        table.insert(rewardDetail, {goldOrSilver = goldOrSilver , count = rewardsInfo.contentNum1 , money = rewardsInfo.contentNum2})
    end

    for i=1,5 do
        local display = self.panelUI:getChildByName("table_wanted_activity_rules_list"..i)
        display:getChildByName("txt_6"):getChildByName("txt"):setString(i)
        display:getChildByName("txt_7"):getChildByName("txt"):setString(getTextByKey("wanted_ruleReward2"))
        display:getChildByName("icon_medal_gold"):setVisible(rewardDetail[i].goldOrSilver)
        display:getChildByName("icon_medal_silver"):setVisible(not rewardDetail[i].goldOrSilver)
        display:getChildByName("txt_5"):getChildByName("txt"):setString(rewardDetail[i].count)
        display:getChildByName("txt_4"):getChildByName("font"):setString(rewardDetail[i].money)
    end
end

function WantedActivityInfoPanel:scaleIn()
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

function WantedActivityInfoPanel:dismiss()
    self.container.targetInfoPanel = nil
    self:removeFromParentAndCleanup(true)
    self.container:setTableViewsEnabled(true)
end

