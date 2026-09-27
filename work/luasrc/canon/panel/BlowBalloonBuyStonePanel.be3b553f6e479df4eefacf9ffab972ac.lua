require "hecore.ui.TableView"
--
-- BlowBalloonBuyStonePanel
--

BlowBalloonBuyStonePanel = class(Layer)

function BlowBalloonBuyStonePanel:ctor()
    self.container = nil
end

function BlowBalloonBuyStonePanel:create(container,father)
    local s = BlowBalloonBuyStonePanel.new()
    s.father = father
    s:initLayer(container)
    return s
end

function BlowBalloonBuyStonePanel:initLayer(container)
    BlowBalloonBuyStonePanel.super.initLayer(self)
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
    self.panelUI = builder:build("common_popup_Blowing Balloons_Billboard_01")
    self.tempLayer:setScale(0.1)
    self.tempLayer:addChild(self.panelUI)
    
    local function closeAction(evt)
        if self.needRefreshFather then
            self.father:setData()
        end
        self:dismiss()
    end
    
    local closeButton = Button:create(self.panelUI:getChildByName("common_btn_close"))
    closeButton:addEventListener(Events.kStart, closeAction, self)

    self.panelUI:getChildByName("txt_5"):getChildByName("txt"):setString(getTextByKey("balloon_buyStone"))
    self.panelUI:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("wanted_price"))
    self.panelUI:getChildByName("txt_4"):getChildByName("txt"):setString(getTextByKey("wanted_price"))

    self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(DataManager.GameMetaData.activityBalloonConfig.propCost)
    self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString((DataManager.GameMetaData.activityBalloonConfig.propCost * 10))

    local function onClickBuyStone(evt)
        if self.father.activityOutData then
            local function callback()
                Director:sharedDirector():replaceScene(MainMenuScene:create())
            end
            CanonMessageBox:Show( getTextByKey("activity-treasurebox-over"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 ,callback)
            return
        end

        -- 判断背包是否满
        if BagCalcManager.isFull() then
            self.container.targetInfoPanel = NewPackageFullPanel:show()
            return
        end

        -- 先算钱
        local gems = CalculationManager.calcComplex_getGemsNow()
        if evt.target.price > gems then
            local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin )
            self.container:addChild(aPanel)
            aPanel:scaleIn()
            return
        end

        local function successCallback(e)
            -- 扣钱
            RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -evt.target.price})
            RewardManager:getReward(e.data.rewards)
            self.needRefreshFather = true

            SuspensionLabel:showContent(self.container, getTextByKey("shop_buySuccess"))
            closeAction(nil)
        end

        local function failedCallback(e)
            local errorCode = tonumber(e.data)
            if errorCode == 710516 then  --背包已满
                NewPackageFullPanel:show()
            elseif errorCode == 714720 then
                CanonMessageBox:Show( getTextByKey("activity-treasurebox-over"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40)
            else
                CanonMessageBox:showCommUnHandleErrorBox(errorCode)
            end
        end

        local request = BlowBalloonActBuyEnegyRequest.new({num = evt.target.count}, rpc.SendingPriority.kHigh)
        request:addEventListener(RequestNotifyEnum.BlowBalloonActBuyEnegyRequestSucceed, successCallback)
        request:addEventListener(RequestNotifyEnum.BlowBalloonActBuyEnegyRequestFailed, failedCallback)
        request:start()
    end

    local buyOneBtn = Button:create(self.panelUI:getChildByName("common_btn_sellItem_yes"))
    buyOneBtn.count = 1
    buyOneBtn.price = DataManager.GameMetaData.activityBalloonConfig.propCost
    buyOneBtn.display:getChildByName("txt_yes"):setString(getTextByKey("balloon_buy1"))
    buyOneBtn:addEventListener(Events.kStart, onClickBuyStone, self)

    local buyTenBtn = Button:create(self.panelUI:getChildByName("common_btn_sellItem_no"))
    buyTenBtn.count = 10
    buyTenBtn.price = DataManager.GameMetaData.activityBalloonConfig.propCost * 10
    buyTenBtn.display:getChildByName("txt_yes"):setString(getTextByKey("balloon_buy2"))
    buyTenBtn:addEventListener(Events.kStart, onClickBuyStone, self)
end

function BlowBalloonBuyStonePanel:scaleIn()
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

function BlowBalloonBuyStonePanel:dismiss()
    self.container.targetInfoPanel = nil
    self:removeFromParentAndCleanup(true)
    self.container:setTableViewsEnabled(true)
end