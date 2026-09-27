-- 圣诞节挑战界面
-- 
-- MerryChristmasChallengePanel
--
--挑战请求
require "canon.scene.StoryReviewScene"
require "canon.request.MerryChristmasChallengeRequest"
require "canon.request.MerryChristmasResetRequest"

--跨天事件
local function onPassDay(evt)
    local self = evt.context
    local featureName = DataManager.GameMetaData.activityEventChristmasConfig.featureName
    local isEnable = MaintenanceManager.isActivityOpen(featureName)
    self.activityOutData = not isEnable

    if isEnable then
        for i,v in ipairs(self.TempChristInfo.listSharkChristInfo) do
            v.challengeNum = 0
            v.resetNum = 0
        end
        DataManager.setSharkChristInfo(self.TempChristInfo)
        self.TableView:reloadData()
    end
end

MerryChristmasChallengePanel = class(Layer)

function MerryChristmasChallengePanel:ctor()
    self.container = nil
end

function MerryChristmasChallengePanel:create(container)
    local s = MerryChristmasChallengePanel.new()
    s:initLayer(container)
    return s
end

function MerryChristmasChallengePanel:initLayer(container)
    MerryChristmasChallengePanel.super.initLayer(self)
    local visibleSize = CCDirector:sharedDirector():getVisibleSize()

    self.container = container
    
    --targetInfoPanel 暂时不知知道干什么用
    --self.container.targetInfoPanel = self
    
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)
    
    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/Christmas.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("Christmas_03")
    self.tempLayer:addChild(self.panelUI)

    --隐藏UI模型
    self.panelUI:getChildByName("table_Christmas_list"):setVisible(false)

    local function onActivityStoryReviewBtn(evt)
      local RunningScene = Director:sharedDirector():getRunningScene()
      RunningScene:replaceScene(StoryReviewScene,{enterScene = "MerryChristmasScene", returnScene = "MerryChristmasScene", beginPanelIndex = 2 , params = {}})
    end
    
    local activityStoryReviewBtn = Button:create(self.panelUI:getChildByName("btn_chapterSelect_review_plot"))
    self.panelUI:getChildByName("btn_chapterSelect_review_plot"):getChildByName("txt"):setString(getTextByKey("storyReview_title"))
    activityStoryReviewBtn:addEventListener(Events.kStart, onActivityStoryReviewBtn, self)
    
    if CityMainScene.CheckActivityStoryReviewBtnEnable() then
        activityStoryReviewBtn:setEnable(true)
        activityStoryReviewBtn.display:getChildByName("normal"):setVisible(true)
    else
        activityStoryReviewBtn:setEnable(false)
        activityStoryReviewBtn.display:getChildByName("normal"):setVisible(false)
    end

    self.TempChristInfo = DataManager.getSharkChristInfo()
    --创建TableView
    self.TableView = self:createTableView(self.panelUI:getChildByName("table_Christmas_list"))

    NotificationManager:addEventListener(PassDayManager.PASS_DAY, onPassDay, self)

    -- 加容错
    local featureName = DataManager.GameMetaData.activityEventChristmasConfig.featureName
    local isEnable = MaintenanceManager.isActivityOpen(featureName)
    self.activityOutData = not isEnable
end

function MerryChristmasChallengePanel:getSharkChristInfoById(id)
    local info = nil
    for i,v in ipairs(self.TempChristInfo.listSharkChristInfo) do
        if id == v.christId then
            info = v
            break
        end
    end
    if not info then
        local tempTable = {christId = id , challengeNum = 0 , resetNum = 0}
        table.insert(self.TempChristInfo.listSharkChristInfo, tempTable)
        DataManager.setSharkChristInfo(self.TempChristInfo)
    end
    
    return info
end

function MerryChristmasChallengePanel:createTableView(display)
    local cellTag = 1024

    local ChristmasChallengeRenderer = class(TableViewRenderer)
    function ChristmasChallengeRenderer:ctor(width , height , data , creater)
        self.width = width
        self.height = height
        self.list = data or {}
        self.creater = creater
    end

    function ChristmasChallengeRenderer:buildCell(container)
        local builder = LayoutBuilder:createWithContentsOfFile("scene/Christmas.json")
        local aCell = builder:build("Christmas_list")
        container:addChild(aCell)
        aCell:setTag(cellTag)        

        aCell:getChildByName("Christmas_list_narrow"):setTag(-11)
        aCell:getChildByName("Christmas_list_wide"):setTag(-12)

        local t = {aCell:getChildByName("Christmas_list_narrow"),aCell:getChildByName("Christmas_list_wide")}
        for k,v in ipairs(t) do
            v:getChildByName("chapterSelect_btn_stageList"):setTag(-13)
            v:getChildByName("chapterSelect_btn_stageList"):getChildByName("font"):setTag(-11)
            v:getChildByName("chapterSelect_btn_stageList"):getChildByName("coin"):setTag(-12)
            v:getChildByName("chapterSelect_btn_stageList"):getChildByName("btn_light_upyellow"):setTag(-13)
            v:getChildByName("chapterSelect_btn_stageList"):getChildByName("btn"):setTag(-14)

            v:getChildByName("normal_card_small"):setTag(-14)

            v:getChildByName("txt_1"):setTag(-15)
            v:getChildByName("txt_1"):getChildByName("txt"):setTag(-11)

            v:getChildByName("txt_2"):setTag(-16)
            v:getChildByName("txt_2"):getChildByName("txt"):setTag(-11)

            v:getChildByName("txt_4"):setTag(-17)
            v:getChildByName("txt_4"):getChildByName("txt"):setTag(-11)

            v:getChildByName("txt_5"):setTag(-18)
            v:getChildByName("txt_5"):getChildByName("txt"):setTag(-11)

            v:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("possibleGet"))
        end
    end

    function ChristmasChallengeRenderer:setData(rawCocosObj, index)
        local aCell = self:getChildByTag(rawCocosObj, cellTag)
        local data = self.list[index + 1]

        local theCell = nil
        -- if index == #self.list - 1 then
        -- 改需求了，本来最后一关的框长得不一样
        if false then
            aCell:getChildByTag(-11):setVisible(true)
            aCell:getChildByTag(-12):setVisible(false)
            theCell = aCell:getChildByTag(-11)
        else
            aCell:getChildByTag(-11):setVisible(false)
            aCell:getChildByTag(-12):setVisible(true)
            theCell = aCell:getChildByTag(-12)
        end

        theCell:removeChildByTag(-30, true)

        local aBattleMonsterGroupConfig
        for _, aConfig in pairs(MetaManager.battle_monster_group) do
            if aConfig.id == data.monsterGroupId then
                aBattleMonsterGroupConfig = aConfig
                break
            end
        end

        local aCardID = MetaManager.battle_monster[tonumber(aBattleMonsterGroupConfig.monsterIdList:split("|")[1], 10)].cardId
        local itemIcon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, aCardID, 1, {sourceDisplay = theCell:getChildByTag(-14) , showInCenter = true})
        if itemIcon then
            itemIcon:setTag(-30)
            theCell:addChild(itemIcon.refCocosObj,10)
        end

        setNodeText(theCell:getChildByTag(-15):getChildByTag(-11),getTextByKey(data.chapterId))
        setNodeText(theCell:getChildByTag(-16):getChildByTag(-11),getTextByKey("cow_challengeCost",{num = MetaManager.getMerryChristmasConfig().costPower}))

        -- local regularRewardName = CanonGoodIcon.getGoodName(ResourceEnum.PROP, data.regularReward, 1, {withoutAmount = true})
        -- setNodeText(theCell:getChildByTag(-17):getChildByTag(-11),regularRewardName)
        setNodeText(theCell:getChildByTag(-17):getChildByTag(-11),getTextByKey(data.regularRewardShow))

        local challengeNum = 0
        local resetNum = 0

        local ChristInfo = self.creater:getSharkChristInfoById(data.id)
        if ChristInfo then
            challengeNum = ChristInfo.challengeNum
            resetNum = ChristInfo.resetNum
        end

        setNodeText(theCell:getChildByTag(-18):getChildByTag(-11), challengeNum.."/"..data.freeTimes)

        local buttonState = 0

        if data.id > (self.creater.TempChristInfo.maxFinishedChristId + 1) then  -- 未开启
            buttonState = 0
        elseif challengeNum < data.freeTimes then -- 可以挑战
            buttonState = 1
        elseif resetNum < data.buyTimes then -- 已用刷新次数小于购买限制
            buttonState = 2
        else
            buttonState = 3
        end
        data.buttonState = buttonState
        self:setButtonState(theCell,buttonState)
    end

    function ChristmasChallengeRenderer:setButtonState(theCell,state)
        if state == 0 then
            setNodeText(theCell:getChildByTag(-13):getChildByTag(-11),getTextByKey("beast_peaceInactive"))
            theCell:getChildByTag(-13):getChildByTag(-12):setVisible(false)
            theCell:getChildByTag(-13):getChildByTag(-13):setVisible(false)
            theCell:getChildByTag(-13):getChildByTag(-14):setVisible(false)
        elseif state == 1 then
            setNodeText(theCell:getChildByTag(-13):getChildByTag(-11),getTextByKey("arena_challengeBtn"))
            theCell:getChildByTag(-13):getChildByTag(-12):setVisible(false)
            theCell:getChildByTag(-13):getChildByTag(-13):setVisible(true)
            theCell:getChildByTag(-13):getChildByTag(-14):setVisible(true)
        elseif state == 2 then
            setNodeText(theCell:getChildByTag(-13):getChildByTag(-11),getTextByKey("pk_session_refresh"))
            theCell:getChildByTag(-13):getChildByTag(-12):setVisible(true)
            theCell:getChildByTag(-13):getChildByTag(-13):setVisible(true)
            theCell:getChildByTag(-13):getChildByTag(-14):setVisible(true)
        else  --state == 3
            setNodeText(theCell:getChildByTag(-13):getChildByTag(-11),getTextByKey("eventChristmas_other1"))
            theCell:getChildByTag(-13):getChildByTag(-12):setVisible(false)
            theCell:getChildByTag(-13):getChildByTag(-13):setVisible(false)
            theCell:getChildByTag(-13):getChildByTag(-14):setVisible(false)
        end
    end

    local tableViewSizes = getTableViewSizes(display)
    local tableData = table.clone(MetaManager.getMerryChristmasConfig().christList)

    local renderer = ChristmasChallengeRenderer.new(tableViewSizes.item_width, tableViewSizes.item_height , tableData , self)
    --btntag {-11,-13} {-12,-13}
    local aTableView = TableView:create(renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, {{-11,-13},{-12,-13}}, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
    aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))

    local function onListItemTouch( evt )        
        local aIndex      = evt.data + 1
        local newCell     = evt.target:cellAtIndex(aIndex - 1)
        local posInCell   = newCell:convertToNodeSpace(evt.globalPosition)                
        --获取tag之
        local tag = -11
        if newCell:getChildByTag(cellTag):getChildByTag(-11):isVisible() then
            tag = -11
        else
            tag = -12
        end


        --挑战按钮
        local ButtonChanglenge = newCell:getChildByTag(cellTag):getChildByTag(tag):getChildByTag(-13)
        if posInCell.x > (ButtonChanglenge:getPositionX()) and
            posInCell.x < (ButtonChanglenge:getPositionX() + 161) and
            posInCell.y > (ButtonChanglenge:getPositionY() - 64) and
            posInCell.y < (ButtonChanglenge:getPositionY()) then
            
            if self.activityOutData then
                local function callback()
                    Director:sharedDirector():replaceScene(MainMenuScene:create())
                end
                CanonMessageBox:Show( getTextByKey("activity-treasurebox-over"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 ,callback)
                return
            end

            local data = evt.target.tableViewRenderer.list[aIndex]

            if data.buttonState == 1 then  -- 挑战
                -- 判断背包是否满
                if BagCalcManager.isFull() then
                    local function closeCallBack()
                        self.TableView:setTouchEnabled(true)
                    end
                    self.TableView:setTouchEnabled(false)
                    self.container.targetInfoPanel = NewPackageFullPanel:show(closeCallBack)
                    return
                end
                -- 没体力
                if MetaManager.getMerryChristmasConfig().costPower > CalculationManager.calcComplex_getEnergyNow() then
                    local hasEnergyProp, energyPropList = BagCalcManager.getEnergyPropList()
                    if hasEnergyProp then
                        local function callback(aEnergyPropId)
                            local function usePropSucceed(event)
                                self.TableView:setTouchEnabled(true)
                                local aReward = {
                                  { itemType = ResourceEnum.PROP, metaId = aEnergyPropId, amount = -1
                                  },
                                  { itemType = ResourceEnum.ENERGY,
                                    amount = event.data.rewards[1].amount,
                                  }
                                }
                                RewardManager:getReward(aReward)
                                CanonPlayEffect("music/sfx_engly_lvup.wav")
                                SuspensionLabel:showContent(self, getTextByKey("propInfo_energyReplenished"))
                            end
                              
                            local function usePropFailed(event)
                                self.TableView:setTouchEnabled(true)
                                if event.data.retCode == 712308 then
                                    CanonMessageBox:Show( getTextByKey("propInfo_energyFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
                                elseif event.data.retCode == 712301 then
                                    local aPropMetaConfig = MetaManager.prop_meta[aEnergyPropId]
                                    CanonMessageBox:Show( getTextByKey("popup_noProp", {propname = Localization:getInstance():getText(aPropMetaConfig.name)}), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40 )
                                end
                            end
                            self.TableView:setTouchEnabled(false)
                            local request = UsePropRequest.new( {propId = aEnergyPropId, amount = 1}, rpc.SendingPriority.kHigh )
                            request:addEventListener( RequestNotifyEnum.UsePropSucceed, usePropSucceed )
                            request:addEventListener( RequestNotifyEnum.UsePropFailed, usePropFailed )
                            request:start()
                        end

                        local aPanel = EEPSupplyPanel:create(self, energyPropList, callback, true)
                        self:addChild(aPanel)
                        aPanel:scaleIn()
                    else
                        local function callback()
                            self.TableView:setTouchEnabled(true)
                        end
                        self.TableView:setTouchEnabled(false)
                        local aPanel = EENPSupplyPanel:create(self, {supplyType = EESupplyTypeEnum.Energy, callback = callback})
                        self:addChild(aPanel)
                        aPanel:scaleIn()
                    end
                    return
                end

                local function challengeSucceed(e)
                    if e.data.win then
                        RewardManager:getReward({{itemType = ResourceEnum.ENERGY, amount = -MetaManager.getMerryChristmasConfig().costPower}})
                    end
                    function beginBattle()
                        if e.data.win then
                            if data.id > self.TempChristInfo.maxFinishedChristId then
                                self.TempChristInfo.maxFinishedChristId = data.id
                            end
                            
                            local ChristInfo = self:getSharkChristInfoById(data.id)
                            if ChristInfo then
                                ChristInfo.challengeNum = ChristInfo.challengeNum + 1
                            end
                            DataManager.setSharkChristInfo(self.TempChristInfo)
                        end

                        if e.data.bigReward then
                            RewardManager:getReward(e.data.bigReward)

                            e.data.chapterFinishReward = {rewardType = e.data.bigReward[1].itemType , rewardID = e.data.bigReward[1].metaId , amount = e.data.bigReward[1].amount , alreadyGet = true}
                        end

                        Director:sharedDirector():replaceScene(BattleScene:create(e.data, BattleBackType.kActivityXmas, BattleEnterEnum.kActivityXmas))
                    end

                    -- 播放剧情
                    if data.id > self.TempChristInfo.maxFinishedChristId then
                        local originalGuideCallback = getGuideFinishCallback()
                        local function guideFinished()
                            beginBattle()
                            RegisterOnGuideFinishCallback(originalGuideCallback)
                        end

                        if e.data.win then
                            e.data.dialogId = data.dialogId
                        end

                        self.TableView:setTouchEnabled(false)

                        RegisterOnGuideFinishCallback(guideFinished)
                        Run_Script_Using_Dialog_Index(data.dialogId, 2, "event_conversation_christmas")
                    else
                        beginBattle()
                    end
                end

                local function challengeFailed(e)
                    local errorCode = tonumber(e.data.retCode)
                    local function onErrorConfirm(errorCode)
                        if errorCode == 710514 then
                            local function canonMessageBoxCallback()
                                self.TableView:setTouchEnabled(true)
                            end
                            self.TableView:setTouchEnabled(false)
                            CanonMessageBox:showSpecialErrorBox( ShowErrorCodeType.EC_REQUISITE_ENERGY_NOT_ENOUGH , nil , canonMessageBoxCallback)
                            return
                        end
                    end
                    local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
                end

                local data = evt.target.tableViewRenderer.list[aIndex]
                MerryChristmasChallengeRequest.sendRequest(challengeSucceed,challengeFailed,{christId = data.id})
            elseif data.buttonState == 2 then  -- 刷新
                local gems = CalculationManager.calcComplex_getGemsNow()
                if MetaManager.getMerryChristmasConfig().costMoney > gems then
                    local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
                    self:addChild(aPanel)
                    aPanel:scaleIn()
                    return
                end

                local function CanonMessageBoxOkFunc()
                    local function refreshSucceed(e)
                        RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -MetaManager.getMerryChristmasConfig().costMoney})

                        local ChristInfo = self:getSharkChristInfoById(data.id)
                        ChristInfo.challengeNum = 0
                        ChristInfo.resetNum = ChristInfo.resetNum + 1
                        
                        DataManager.setSharkChristInfo(self.TempChristInfo)

                        self.TableView:setTouchEnabled(true)
                        self.TableView:reloadData()
                    end

                    local function refreshFailed(e)
                        local errorCode = tonumber(e.data.retCode)
                        local function onErrorConfirm(errorCode)
                            if errorCode == 710514 then
                                local function canonMessageBoxCallback()
                                    self.TableView:setTouchEnabled(true)
                                end
                                self.TableView:setTouchEnabled(false)
                                CanonMessageBox:showSpecialErrorBox( ShowErrorCodeType.EC_REQUISITE_ENERGY_NOT_ENOUGH , nil , canonMessageBoxCallback)
                            else
                                self.TableView:setTouchEnabled(true)
                            end
                        end
                        local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
                    end
                    local data = evt.target.tableViewRenderer.list[aIndex]
                    MerryChristmasResetRequest.sendRequest(refreshSucceed,refreshFailed,{christId = data.id})
                end

                local function CanonMessageBoxCancelFunc()
                    self.TableView:setTouchEnabled(true)
                end

                self.TableView:setTouchEnabled(false)
                self.container.targetInfoPanel = CanonMessageBox:Show(getTextByKey("inquireReset",{glodNum = MetaManager.getMerryChristmasConfig().costMoney}), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, nil, CanonMessageBoxOkFunc, CanonMessageBoxCancelFunc)
            end
        end
    end
    aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)

    self.panelUI:addChild(aTableView,2)

    return aTableView
end

function MerryChristmasChallengePanel:setTableViewsEnabled(bool)
    if self.TableView then
        self.TableView:setTouchEnabled(bool)
    end
end

function MerryChristmasChallengePanel:dismiss()
    self.container:setTableViewsEnabled(true)
    self.container.targetInfoPanel = nil
    self:removeFromParentAndCleanup(true)
end

function MerryChristmasChallengePanel:dispose()
    NotificationManager:removeEventListener(PassDayManager.PASS_DAY, onPassDay, self)
    MerryChristmasChallengePanel.super.dispose(self)
end