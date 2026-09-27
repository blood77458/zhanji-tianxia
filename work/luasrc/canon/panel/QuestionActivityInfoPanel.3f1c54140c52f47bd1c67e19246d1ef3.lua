require "hecore.ui.TableView"
--
-- QuestionActivityInfoPanel
--

QuestionActivityInfoPanel = class(Layer)

function QuestionActivityInfoPanel:ctor()
    self.container = nil
end

function QuestionActivityInfoPanel:create(container,thisWeekNum)
    local s = QuestionActivityInfoPanel.new()
    s.thisWeekNum = thisWeekNum
    s:initLayer(container)
    return s
end

function QuestionActivityInfoPanel:initLayer(container)
    QuestionActivityInfoPanel.super.initLayer(self)
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
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/question_activity.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_question_activity_01")
    self.tempLayer:setScale(0.1)
    self.tempLayer:addChild(self.panelUI)
    
    local function closeAction(evt)
      self:dismiss()
    end
    
    local closeButton = Button:create(self.panelUI:getChildByName("btn_close"))
    closeButton:addEventListener(Events.kStart, closeAction, self)

    self.panelUI:getChildByName("common_txt_playerInfo_title"):getChildByName("txt_playerInfo_title"):setString(getTextByKey("activity_question_rewardPreview"))
    self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(getTextByKey("activity_question_rewardTip"))
    self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(getTextByKey("activity_question_currCorrect"))
    self.panelUI:getChildByName("txt_3"):getChildByName("txt"):setString(self.thisWeekNum)
    self.panelUI:getChildByName("txt_4"):getChildByName("txt"):setString(getTextByKey("activity_question_answerNum"))
    
    self.panelUI:getChildByName("table_question_activity_list"):setVisible(false)

    local rewardDataList = DataManager.GameMetaData.activityQuestionSettingConfig or {questionWeekRewards = {}}
    self:createTableView(rewardDataList.questionWeekRewards)
end

function QuestionActivityInfoPanel:createTableView(listData)
    local cellTag = 1024

    local QuestionActivityInfoRenderer = class(TableViewRenderer)
    function QuestionActivityInfoRenderer:ctor(width , height , data , creater)
        self.width = width
        self.height = height
        self.list = data or {}
        self.creater = creater
    end

    function QuestionActivityInfoRenderer:buildCell(container)
        local builder = LayoutBuilder:createWithContentsOfFile("scene/question_activity.json")
        local aCell = builder:build("list_activity_question")
        container:addChild(aCell)
        aCell:setTag(cellTag)

        aCell:getChildByName("txt_reward_rank"):setTag(-11)
        aCell:getChildByName("txt_reward_rank"):getChildByName("txt"):setTag(-11)

        for i=1,4 do
            aCell:getChildByName("normal_card_small"..i):setTag(-20-i)
            aCell:getChildByName("normal_card_small"..i):getChildByName("txt"):setTag(-30-i)
            aCell:getChildByName("normal_card_small"..i):getChildByName("txt"):getChildByName("txt"):setTag(-30-i)
            aCell:getChildByName("normal_card_small"..i):getChildByName("normal_card_small"):setVisible(false)
            aCell:getChildByName("normal_card_small"..i):getChildByName("normal_card_small"):setTag(-40-i)
        end
    end

    function QuestionActivityInfoRenderer:setData(rawCocosObj, index)
        local aCell = self:getChildByTag(rawCocosObj, cellTag)
        local data = self.list[index + 1]

        setNodeText(aCell:getChildByTag(-11):getChildByTag(-11), getTextByKey("activity_question_rewardTitle",{num1 = data.correctMin , num2 = data.correctMax}))

        local rewardPackageIds = MetaManager.getRewardInfoByID(data.rewardPackageId)
        for i=1,4 do
            aCell:getChildByTag(-20-i):removeChildByTag(-50-i, true)

            if rewardPackageIds[i] then
                local itemIcon = CanonGoodIcon.createGoodIcon(rewardPackageIds[i].itemType, rewardPackageIds[i].metaId, rewardPackageIds[i].amount, {sourceDisplay = aCell:getChildByTag(-20-i):getChildByTag(-40-i) , showInCenter = true})
                itemIcon:setTag(-50-i)
                aCell:getChildByTag(-20-i):addChild(itemIcon.refCocosObj)
                setNodeText(aCell:getChildByTag(-20-i):getChildByTag(-30-i):getChildByTag(-30-i), CanonGoodIcon.getGoodName(rewardPackageIds[i].itemType, rewardPackageIds[i].metaId, rewardPackageIds[i].amount, {withoutAmount = false}))

                aCell:getChildByTag(-20-i):setVisible(true)
            else
                aCell:getChildByTag(-20-i):setVisible(false)
            end
        end
    end

    local tableViewSizes = getTableViewSizes(self.panelUI:getChildByName("table_question_activity_list"))

    local renderer = QuestionActivityInfoRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height , listData , self)
    local aTableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, {}, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
    aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))

    self.panelUI:addChild(aTableView)
end

function QuestionActivityInfoPanel:scaleIn()
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

function QuestionActivityInfoPanel:dismiss()
    self.container.targetInfoPanel = nil
    self:removeFromParentAndCleanup(true)
    self.container:setTableViewsEnabled(true)
end