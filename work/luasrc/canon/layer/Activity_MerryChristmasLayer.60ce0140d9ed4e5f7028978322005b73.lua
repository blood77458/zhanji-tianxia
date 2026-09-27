require "hecore.display.Layer"
require "canon.panel.MerryChristmasInfoPanel"
require "canon.scene.MerryChristmasScene"
--
-- Activity_MerryChristmasLayer
--

--跨天事件
local function onPassDay(evt)
    local self = evt.context
    local featureName = DataManager.GameMetaData.activityEventChristmasConfig.featureName
    self.activityOutData = not MaintenanceManager.isActivityOpen(featureName)
end

Activity_MerryChristmasLayer = class(Layer)
function Activity_MerryChristmasLayer:ctor()
    self.container = nil
end

function Activity_MerryChristmasLayer:create(container , extraArgs)
    local s = Activity_MerryChristmasLayer.new()
    s.container = container
    s.extraArgs = extraArgs
    s:initLayer()
    return s
end

function Activity_MerryChristmasLayer:initLayer()
    Activity_MerryChristmasLayer.super.initLayer(self)
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/Christmas.json")
    self.builder.useArtLabelTTF = true
    --创建圣诞节界面
    self.mainUI = self.builder:build("Christmas_01")
    self:addChild(self.mainUI)

    local activityTimeKey = DataManager.GameMetaData.activityEventChristmasConfig.featureName
    local activityTimeInfo = MaintenanceManager:getStartAndEndTime(activityTimeKey)

    -- 帮助界面
    local function infoButtonSelected(evt)
        self.container:setTableViewsEnabled(false)

        local content = getTextByKey("eventChristmas_help1",{month1 = activityTimeInfo[1].month ,day1 = activityTimeInfo[1].day , month2 = activityTimeInfo[2].month , day2 = activityTimeInfo[2].day})
        local aInfoPanel = MerryChristmasInfoPanel:create(self.container,content)
        self.container:addChild(aInfoPanel)
        aInfoPanel:scaleIn()
    end
    local infoButton = Button:create(self.mainUI:getChildByName("sky_btn_qa"))
    infoButton:addEventListener(Events.kStart, infoButtonSelected, self)

    self.mainUI:getChildByName("txt_01"):getChildByName("txt"):setString(getTextByKey("activity-sworn-title1"))
    self.mainUI:getChildByName("txt_02"):getChildByName("txt"):setString(getTextByKey("activity-sworn-title3",{num1 = activityTimeInfo[1].month ,num2 = activityTimeInfo[1].day , num3 = activityTimeInfo[2].month , num4 = activityTimeInfo[2].day}))

    --确认分配文字
    self.mainUI:getChildByName("btn"):getChildByName("txt_guild_66"):getChildByName("txt"):setString(getTextByKey("wanted_button2"))
    --确认分配按钮事件处理
    local function enterMerryChristmasScene(tagType)
        local argv = {enterScene="ActivityPanelScene",returnScene="ActivityPanelScene",params={}}
        self.container:replaceScene(MerryChristmasScene, argv)
    end

    local function EnterChristmasButtonSelectedHandler(evt)
        if self.activityOutData then
            local function callback()
                Director:sharedDirector():replaceScene(MainMenuScene:create())
            end
            CanonMessageBox:Show( getTextByKey("activity-treasurebox-over"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 ,callback)
            return
        end

        enterMerryChristmasScene()
    end
    local EnterChristmasButton = Button:create(self.mainUI:getChildByName("btn"))
    EnterChristmasButton:addEventListener(Events.kStart, EnterChristmasButtonSelectedHandler, self)
    
    local function showCardDetailBtn(evt)
        CanonGoodIcon.popoutGoodPanel(ResourceEnum.CARD, MetaManager.getMerryChristmasConfig().specialReward)
    end
    local cardDetailBtn = Button:create(self.mainUI:getChildByName("icon_Christmas_card_caoren"))
    cardDetailBtn:addEventListener(Events.kStart, showCardDetailBtn, self)

    cardDetailBtn.display:setAnchorPoint(ccp(0.5,0.5))

    local actionArray = CCArray:create()
    actionArray:addObject(CCScaleTo:create(1,1.2))
    actionArray:addObject(CCScaleTo:create(1,1))
    cardDetailBtn.display:runAction(CCRepeatForever:create(CCSequence:create(actionArray)))

    NotificationManager:addEventListener(PassDayManager.PASS_DAY, onPassDay, self)
end


function Activity_MerryChristmasLayer:setData()
    
end

--判断活动是否开启
function Activity_MerryChristmasLayer:enable()
    local featureName = DataManager.GameMetaData.activityEventChristmasConfig.featureName
    local isEnable = MaintenanceManager.isActivityOpen(featureName)
    return isEnable
end

function Activity_MerryChristmasLayer:dispose()
    NotificationManager:removeEventListener(PassDayManager.PASS_DAY, onPassDay, self)
    Activity_MerryChristmasLayer.super.dispose(self)
end

function Activity_MerryChristmasLayer.getTipNum()
    return 0
end