require "hecore.display.Layer"
require "canon.panel.ActivityInfoPanel"
require "canon.panel.QuestionActivityInfoPanel"
require "canon.panel.QuestionActivityRewardPanel"
require "canon.request.QuestionActAnswerRequest"
require "canon.request.QuestionActGetStateRequest"
require "canon.request.QuestionActDailyRewardRequest"
require "canon.panel.NewPackageFullPanel"

--
-- Activity_QuestionLayer
--

Activity_QuestionLayer = class(Layer)
function Activity_QuestionLayer:ctor()
    self.container = nil
end

function Activity_QuestionLayer:create(container , extraArgs)
    local s = Activity_QuestionLayer.new()
    s.container = container
    s.extraArgs = extraArgs
    s:initLayer()
    return s
end

function Activity_QuestionLayer:initLayer()
    Activity_QuestionLayer.super.initLayer(self)
    
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/question_activity.json")
    self.builder.useArtLabelTTF = true
    self.mainUI = self.builder:build("question_activity_combination")
    self:addChild(self.mainUI)

    if g_homeInfo == nil then
        g_homeInfo = {}
    end

    self.Layer_Home = self:CreateHomeLayer(self.builder)
    self.Layer_Game = self:CreateGameLayer(self.builder)

    self.mainUI:getChildByName("txt_03"):getChildByName("txt"):setString(getTextByKey("activity_question_stem"))
    self.mainUI:getChildByName("txt_03"):getChildByName("txt"):setColor(ccc3(56,2,2))
    self.mainUI:getChildByName("txt_03"):getChildByName("txt"):setAroundColor(ccc3(255, 255, 255))

    self.Layer_Game.UI_CurrentIndex = self.mainUI:getChildByName("txt_02"):getChildByName("txt")
    self.Layer_Game.UI_CurrentIndex:setColor(ccc3(255,0,0))
    self.Layer_Game.UI_CurrentIndex:setAroundColor(ccc3(255,255,255))

    -- 帮助界面
    local function infoButtonSelected(evt)
        self.container:setTableViewsEnabled(false)

        local begainTime , endTime = getEatPeachTime("questionDaily")
        local aInfoPanel = ActivityInfoPanel:create(self.container, getTextByKey("activity_question_explain",{time1 = begainTime..":00" , time2 = endTime..":00"}))
        self.container:addChild(aInfoPanel)
        aInfoPanel:scaleIn()
    end
    self.infoButton = Button:create(self.mainUI:getChildByName("sky_btn_qa"))
    self.infoButton:addEventListener(Events.kStart, infoButtonSelected, self)

    -- 奖励预览
    local function rewardButtonSelected(evt)
        self.container:setTableViewsEnabled(false)
        local aInfoPanel = QuestionActivityInfoPanel:create(self.container , self.thisWeekNum)
        self.container:addChild(aInfoPanel)
        aInfoPanel:scaleIn()
    end
    self.rewardButton = Button:create(self.mainUI:getChildByName("icon_reward_tab"))
    self.rewardButton:addEventListener(Events.kStart, rewardButtonSelected, self)

    self.lastWeekNum = self.extraArgs.lastWeekNum
    self.thisWeekNum = self.extraArgs.thisWeekNum
    self.sessionNum = self.extraArgs.currVersion

    -- 设置界面内容
    self:setData()

    -- 是否有周奖励
    if self.extraArgs.getWeeklyReward then
        self.container:setTableViewsEnabled(false)

        RewardManager:getReward(self.extraArgs.rewards)
        local aRewardPanel = QuestionActivityRewardPanel:create(self,2,self.extraArgs.rewards,self.lastWeekNum,nil)
        self.container:addChild(aRewardPanel)
        aRewardPanel:scaleIn()
    end
end

function Activity_QuestionLayer:setData()
    local isEnable, isOpenTime = MaintenanceManager.isActivityOpen("questionDaily")
    if not isOpenTime then
        g_homeInfo.dailyQuestionStatus = -1
    end

    local mode = 0
    -- 2-进行时
    if g_homeInfo.dailyQuestionStatus and (g_homeInfo.dailyQuestionStatus == 2) then
        mode = 1
    end

    self:switchMode(mode)
end

-- 0：主界面  1：答题界面
function Activity_QuestionLayer:switchMode(ModeType)
    if ModeType == 0 then
        self.mainUI:getChildByName("txt_03"):getChildByName("txt"):setVisible(false)
        self.mainUI:getChildByName("txt_02"):getChildByName("txt"):setVisible(false)
        self.Layer_Home.freshUI()
        self.Layer_Game.hideLayer()
        self.infoButton:setVisible(true)
        self.rewardButton:setVisible(true)
        self.infoButton.display.touchEnabled = true
        self.infoButton.display.touchChildren = true
        self.rewardButton.display.touchEnabled = true
        self.rewardButton.display.touchChildren = true
    elseif ModeType == 1 then
        local function successCallback(evt)
            g_homeInfo.dailyQuestionStatus = 2
            self.currentQuestionIndex = evt.data.questionNum
            self.dailyCorrectNum = evt.data.dailyNum
            self.currentQuestionId = evt.data.questionId
            self.wrongAnswer1Key = evt.data.wrongAnswer1Key
            self.wrongAnswer2Key = evt.data.wrongAnswer2Key
            self.wrongAnswer3Key = evt.data.wrongAnswer3Key

            self.mainUI:getChildByName("txt_03"):getChildByName("txt"):setVisible(true)
            self.mainUI:getChildByName("txt_02"):getChildByName("txt"):setVisible(true)
            self.Layer_Home.hideLayer()
            self.Layer_Game.freshUI()
            self.infoButton:setVisible(false)
            self.rewardButton:setVisible(false)
            self.infoButton.display.touchEnabled = false
            self.infoButton.display.touchChildren = false
            self.rewardButton.display.touchEnabled = false
            self.rewardButton.display.touchChildren = false
        end

        local function failedCallback(evt)
            local errorCode = tonumber(evt.data)
            if errorCode == 716923 then
                g_homeInfo.dailyQuestionStatus = -1
                self:switchMode(0)
                CanonMessageBox:Show(getTextByKey("activity_question_errorClose"),ShowMessageType.ShowText,ShowButtonType.ID_OK, 40)
            elseif errorCode == 716924 then
                self:setData()
            elseif errorCode == 716925 then
                CanonMessageBox:Show(getTextByKey("activity_question_errorAlreadyReward"),ShowMessageType.ShowText,ShowButtonType.ID_OK, 40)
            else
                CanonMessageBox:showCommUnHandleErrorBox(errorCode)
            end
        end

        local StateRequest = QuestionActGetStateRequest.new({}, rpc.SendingPriority.kHigh)
        StateRequest:addEventListener(RequestNotifyEnum.QuestionActGetStateRequestSucceed, successCallback)
        StateRequest:addEventListener(RequestNotifyEnum.QuestionActGetStateRequestFailed, failedCallback)
        StateRequest:start()
    else
        print("fuck !!!  bug !!!")
    end
end

function Activity_QuestionLayer:enable()
    local isEnable = MaintenanceManager.isActivityOpen("questionDaily")
    
    if not isEnable then
        isEnable = MaintenanceManager.isActivityOpen("questionReward")
    end

    return isEnable
end

function Activity_QuestionLayer:dispose()
    Activity_QuestionLayer.super.dispose(self)
end

function Activity_QuestionLayer.getTipNum()
    if not Activity_QuestionLayer.enable() then
        return 0
    end
    
    if not g_homeInfo or not g_homeInfo.dailyQuestionStatus or g_homeInfo.dailyQuestionStatus == 0 or g_homeInfo.dailyQuestionStatus == -1 then
        return 0
    else
        return 1
    end
end





function Activity_QuestionLayer:CreateHomeLayer(builder)
    local display = builder:build("questionactivity_text_home")
    
    local homeLayer = {}
    homeLayer.display = display
    
    local function hideLayer()
        if homeLayer.inited then
            display:setVisible(false)
        end
    end
    homeLayer.hideLayer = hideLayer


    local function initLayer()
        if homeLayer.inited then
            return
        end
        display:getChildByName("txt_01"):getChildByName("txt"):setColor(ccc3(255, 254, 143))
        display:getChildByName("txt_01"):getChildByName("txt"):setAroundColor(ccc3(79, 0, 0))
        display:getChildByName("txt_01"):getChildByName("txt"):setString(getTextByKey("activity_question_lastCorrect"))

        display:getChildByName("txt_02"):getChildByName("txt"):setColor(ccc3(255, 254, 143))
        display:getChildByName("txt_02"):getChildByName("txt"):setAroundColor(ccc3(79, 0, 0))
        display:getChildByName("txt_02"):getChildByName("txt"):setString(getTextByKey("activity_question_answerNum"))

        display:getChildByName("txt_04"):getChildByName("txt"):setColor(ccc3(255, 254, 143))
        display:getChildByName("txt_04"):getChildByName("txt"):setAroundColor(ccc3(79, 0, 0))
        display:getChildByName("txt_04"):getChildByName("txt"):setString(getTextByKey("activity_question_currCorrect"))

        display:getChildByName("txt_05"):getChildByName("txt"):setColor(ccc3(255, 254, 143))
        display:getChildByName("txt_05"):getChildByName("txt"):setAroundColor(ccc3(79, 0, 0))
        display:getChildByName("txt_05"):getChildByName("txt"):setString(getTextByKey("activity_question_answerNum"))

        display:getChildByName("txt_07"):getChildByName("txt"):setAroundColor(ccc3(79, 0, 0))
        display:getChildByName("txt_07"):getChildByName("txt"):setString(getTextByKey("activity_question_effort"))

        display:getChildByName("txt_08"):getChildByName("txt"):setString(getTextByKey("activity_question_welcome"))
        display:getChildByName("txt_09"):getChildByName("txt"):setString(getTextByKey("activity-sworn-title1"))
        display:getChildByName("txt_10"):getChildByName("txt"):setString(getTextByKey("activity_question_everyDay"))
        display:getChildByName("txt_11"):getChildByName("txt"):setString(getTextByKey("activity_question_open"))

        -- 活动时间
        local begainTime , endTime = getEatPeachTime("questionDaily")
        display:getChildByName("txt_12"):getChildByName("txt"):setString(begainTime..":00".."-"..endTime..":00")
        
        local function onBegainBtn(evt)
            -- 开始答题
            if evt.target.clickType == 1 then
                self:switchMode(1)
            -- 领取奖励
            elseif evt.target.clickType == 2 then
                if BagCalcManager.isFull() then
                   NewPackageFullPanel:show()
                   return
                end

                local function successCallback(evt)
                    RewardManager:getReward(evt.data.rewards)
                    -- 弹奖励逻辑
                    self.container:setTableViewsEnabled(false)
                    local function callBackFunc()
                        g_homeInfo.dailyQuestionStatus = 0
                        self.container:resetTipInfoForActivity("Activity_Question")
                        self.Layer_Home.freshUI()
                    end
                    local aRewardPanel = QuestionActivityRewardPanel:create(self,1,evt.data.rewards,evt.data.dailyNum,callBackFunc)
                    self.container:addChild(aRewardPanel)
                    aRewardPanel:scaleIn()
                end

                local function failedCallback(evt)
                    local errorCode = tonumber(evt.data)
                    if errorCode == 716923 then
                        g_homeInfo.dailyQuestionStatus = -1
                        self:switchMode(0)
                        CanonMessageBox:Show(getTextByKey("activity_question_errorClose"),ShowMessageType.ShowText,ShowButtonType.ID_OK, 40)
                    elseif errorCode == 716924 then
                        self:setData()
                    elseif errorCode == 716925 then
                        CanonMessageBox:Show(getTextByKey("activity_question_errorAlreadyReward"),ShowMessageType.ShowText,ShowButtonType.ID_OK, 40)
                    else
                        CanonMessageBox:showCommUnHandleErrorBox(errorCode)
                    end
                end

                local RewardRequest = QuestionActDailyRewardRequest.new({}, rpc.SendingPriority.kHigh)
                RewardRequest:addEventListener(RequestNotifyEnum.QuestionActDailyRewardRequestSucceed, successCallback)
                RewardRequest:addEventListener(RequestNotifyEnum.QuestionActDailyRewardRequestFailed, failedCallback)
                RewardRequest:start()
            end
        end
        homeLayer.begainBtn = Button:create(display:getChildByName("btn"))
        homeLayer.begainBtn:addEventListener(Events.kStart, onBegainBtn, self)

        homeLayer.hideLayer()
        self:addChild(display)

        homeLayer.inited = true
    end
    homeLayer.initLayer = initLayer
    
    local function freshUI()
        homeLayer.initLayer()
        ------

        display:getChildByName("txt_03"):getChildByName("txt"):setString(self.lastWeekNum)
        display:getChildByName("txt_06"):getChildByName("txt"):setString(self.thisWeekNum)

        local function showBtnOrLabel(bool)
            homeLayer.begainBtn.display:setVisible(bool)
            display:getChildByName("bg_group_l"):setVisible(not bool)
            display:getChildByName("bg_group_r"):setVisible(not bool)
            display:getChildByName("lbl_quesetion_activity_03"):setVisible(not bool)
        end
        if g_homeInfo.dailyQuestionStatus then
            -- 1-未参与
            if g_homeInfo.dailyQuestionStatus == 1 then
                homeLayer.begainBtn.display:getChildByName("txt"):setString(getTextByKey("activity_question_beginPlay"))
                homeLayer.begainBtn.display:getChildByName("normal"):setVisible(true)
                homeLayer.begainBtn.clickType = 1
                homeLayer.begainBtn:setEnable(true)
                showBtnOrLabel(true)
            -- 3-日奖励可领取
            elseif g_homeInfo.dailyQuestionStatus == 3 then
                homeLayer.begainBtn.display:getChildByName("txt"):setString(getTextByKey("invitation_rewardsBtn"))
                homeLayer.begainBtn.display:getChildByName("normal"):setVisible(true)
                homeLayer.begainBtn.clickType = 2
                homeLayer.begainBtn:setEnable(true)
                showBtnOrLabel(true)
            -- 0-已参与
            elseif g_homeInfo.dailyQuestionStatus == 0 then
                homeLayer.begainBtn.display:getChildByName("txt"):setString(getTextByKey("activity_question_alreadyPlay"))
                homeLayer.begainBtn.display:getChildByName("normal"):setVisible(false)
                homeLayer.begainBtn.clickType = 3
                homeLayer.begainBtn:setEnable(false)
                showBtnOrLabel(false)
            else
                homeLayer.begainBtn.display:getChildByName("txt"):setString(getTextByKey("beast_peaceInactive"))
                homeLayer.begainBtn.display:getChildByName("normal"):setVisible(false)
                homeLayer.begainBtn.clickType = 3
                homeLayer.begainBtn:setEnable(false)
                showBtnOrLabel(true)
            end
        end
        ------
        display:setVisible(true)
    end
    homeLayer.freshUI = freshUI

    return homeLayer
end


function Activity_QuestionLayer:CreateGameLayer(builder)
    local gameLayer = {}
    gameLayer.answerDisplay = builder:build("question_activity_ABCD")
    gameLayer.picQueDisplay = builder:build("questionactivity_text_guess")
    gameLayer.textQueDisplay = builder:build("questionactivity_text_topic")

    gameLayer.picQueDisplay.touchEnabled = false
    gameLayer.picQueDisplay.touchChildren = false
    gameLayer.textQueDisplay.touchEnabled = false
    gameLayer.textQueDisplay.touchChildren = false

    local function hideLayer()
        if gameLayer.inited then
            gameLayer.answerDisplay:setVisible(false)
            gameLayer.picQueDisplay:setVisible(false)
            gameLayer.textQueDisplay:setVisible(false)
        end
    end
    gameLayer.hideLayer = hideLayer

    local function initLayer()
        if gameLayer.inited then
            return
        end

        self.Question_Bank = {}
        for k,v in ipairs(MetaManager.activity_question_bank) do
            local questionInfo = {
                id = v.id,
                type = v.type,
                correctAnswerKey = v.correctAnswerKey
            }
            if v.type == 0 then
                questionInfo.cardMetaId = v.cardMetaId
            else
                questionInfo.stemKey = v.stemKey
                questionInfo.wrongAnswer1Key = v.wrongAnswer1Key
                questionInfo.wrongAnswer2Key = v.wrongAnswer2Key
                questionInfo.wrongAnswer3Key = v.wrongAnswer3Key
            end
            
            self.Question_Bank[questionInfo.id] = questionInfo
        end

        -- answerDisplay
        gameLayer.answerDisplay:getChildByName("txt_04"):getChildByName("txt"):setColor(ccc3(255, 254, 143))
        gameLayer.answerDisplay:getChildByName("txt_04"):getChildByName("txt"):setAroundColor(ccc3(79, 0, 0))
        gameLayer.answerDisplay:getChildByName("txt_04"):getChildByName("txt"):setString(getTextByKey("activity_question_correctNum"))
        gameLayer.answerDisplay:getChildByName("txt_02"):getChildByName("txt"):setColor(ccc3(255, 254, 143))
        gameLayer.answerDisplay:getChildByName("txt_02"):getChildByName("txt"):setAroundColor(ccc3(79, 0, 0))
        gameLayer.answerDisplay:getChildByName("txt_02"):getChildByName("txt"):setString(getTextByKey("activity_question_wrongNum"))

        gameLayer.UI_RightNum = gameLayer.answerDisplay:getChildByName("txt_05"):getChildByName("txt")
        gameLayer.UI_RightNum:setColor(ccc3(255, 0, 0))
        gameLayer.UI_RightNum:setAroundColor(ccc3(79, 0, 0))

        gameLayer.UI_WrongNum = gameLayer.answerDisplay:getChildByName("txt_03"):getChildByName("txt")
        gameLayer.UI_WrongNum:setColor(ccc3(255, 0, 0))
        gameLayer.UI_WrongNum:setAroundColor(ccc3(79, 0, 0))

        local function onChoseAnswer(evt)
            local function answerQuestionSucceed(evt)
                -- 胜负动画
                local picLabel = nil
                local RunningScene = Director:sharedDirector():getRunningScene()
                local visibleSize = CCDirector:sharedDirector():getVisibleSize()

                local arr = CCArray:create()

                if evt.data.result then
                    self.thisWeekNum = self.thisWeekNum + 1
                    self.dailyCorrectNum = self.dailyCorrectNum + 1

                    picLabel = Sprite:create("pic/lbl_quesetion_activity_correct.png")
                    picLabel:setScale(10)

                    arr:addObject(CCScaleTo:create(0.3, 1))
                    arr:addObject(CCDelayTime:create(0.5))
                    arr:addObject(CCFadeOut:create(0.3))
                else
                    picLabel = Sprite:create("pic/lbl_quesetion_activity_error.png")

                    arr:addObject(CCFadeIn:create(0.3))
                    arr:addObject(CCDelayTime:create(0.5))
                    arr:addObject(CCFadeOut:create(0.3))
                end
                RunningScene:setTouchEnabled(false)

                local function enterActionFinished()
                    RunningScene:removeChild(picLabel, true)
                    RunningScene:setTouchEnabled(true)

                    if evt.data.over then
                        -- 3-日奖励可领取
                        g_homeInfo.dailyQuestionStatus = 3
                        self:switchMode(0)
                    else
                        self.currentQuestionIndex = self.currentQuestionIndex + 1
                        self.currentQuestionId = evt.data.nextQuestionMetaId
                        self.wrongAnswer1Key = evt.data.wrongAnswer1Key
                        self.wrongAnswer2Key = evt.data.wrongAnswer2Key
                        self.wrongAnswer3Key = evt.data.wrongAnswer3Key

                        self.Layer_Game.freshUI()
                    end
                end
                
                picLabel:setPositionXY(visibleSize.width/2 , visibleSize.height/2)
                RunningScene:addChild(picLabel)

                arr:addObject(CCCallFunc:create(enterActionFinished))
                picLabel:runAction(CCSequence:create(arr)) 
            end

            local function answerQuestionFailed(evt)
                local errorCode = tonumber(evt.data)
                if errorCode == 716923 then
                    g_homeInfo.dailyQuestionStatus = -1
                    self:switchMode(0)
                    CanonMessageBox:Show(getTextByKey("activity_question_errorClose"),ShowMessageType.ShowText,ShowButtonType.ID_OK, 40)
                elseif errorCode == 716924 then
                    self:setData()
                elseif errorCode == 716925 then
                    CanonMessageBox:Show(getTextByKey("activity_question_errorAlreadyReward"),ShowMessageType.ShowText,ShowButtonType.ID_OK, 40)
                else
                    CanonMessageBox:showCommUnHandleErrorBox(errorCode)
                end
            end

            local params = {questionMetaId = self.currentQuestionId , answer = self.answerKeyArr[evt.target.index]}
            local request = QuestionActAnswerRequest.new(params, rpc.SendingPriority.kHigh)
            request:addEventListener(RequestNotifyEnum.QuestionActAnswerRequestSucceed, answerQuestionSucceed)
            request:addEventListener(RequestNotifyEnum.QuestionActAnswerRequestFailed, answerQuestionFailed)
            request:start()
        end

        gameLayer.UI_AnswerBtnArr = {}
        for i=1,4 do
            local newButtn = Button:create(gameLayer.answerDisplay:getChildByName("btn_ABCD"..i))
            newButtn.display:getChildByName("txt"):setAroundColor(ccc3(79,0,0))
            newButtn.index = i
            newButtn:addEventListener(Events.kStart, onChoseAnswer, self)

            table.insert(gameLayer.UI_AnswerBtnArr, newButtn)
        end

        -- textQueDisplay
        -- 活动时间
        local _,endTime = getEatPeachTime("questionDaily")
        gameLayer.textQueDisplay:getChildByName("txt_04"):getChildByName("txt"):setString(getTextByKey("activity_question_deadline"))
        gameLayer.textQueDisplay:getChildByName("txt_05"):getChildByName("txt"):setString(endTime..":00")

        gameLayer.UI_TextQuestion = gameLayer.textQueDisplay:getChildByName("txt_01"):getChildByName("txt")

        -- picQueDisplay
        gameLayer.picQueDisplay:getChildByName("txt_01"):getChildByName("txt"):setString(getTextByKey("activity_question_deadline"))
        gameLayer.picQueDisplay:getChildByName("txt_04"):getChildByName("txt"):setString(endTime..":00")
        gameLayer.picQueDisplay:getChildByName("txt_02"):getChildByName("txt"):setString(getTextByKey("activity_question_guessCard"))


        gameLayer.UI_PicQuestion = gameLayer.picQueDisplay:getChildByName("picQuestion_container")
        gameLayer.UI_PicQuestion:getChildByName("full"):setVisible(false)

        -- addchild
        gameLayer.hideLayer()
        self:addChild(gameLayer.picQueDisplay)
        self:addChild(gameLayer.textQueDisplay)
        self:addChild(gameLayer.answerDisplay)

        gameLayer.inited = true
    end
    gameLayer.initLayer = initLayer
    
    local function freshUI()
        gameLayer.initLayer()
        ------
        
        -- 题目编号
        gameLayer.UI_CurrentIndex:setString(self.currentQuestionIndex.."/"..DataManager.GameMetaData.activityQuestionSettingConfig.questionGroupNum)
        -- 正确和错误的数量
        gameLayer.UI_RightNum:setString(self.dailyCorrectNum)
        gameLayer.UI_WrongNum:setString(self.currentQuestionIndex - self.dailyCorrectNum - 1)

        self.currentQuestionData = self.Question_Bank[self.currentQuestionId]
        
        -- 设置正确答案
        local answerKeyArr = {
            [1] = self.currentQuestionData.correctAnswerKey
        }

        -- 图片问题
        if self.currentQuestionData.type == 0 then
            gameLayer.picQueDisplay:setVisible(true)
            gameLayer.textQueDisplay:setVisible(false)

            table.insert(answerKeyArr,self.wrongAnswer1Key)
            table.insert(answerKeyArr,self.wrongAnswer2Key)
            table.insert(answerKeyArr,self.wrongAnswer3Key)

            if self.cardimage then
                gameLayer.UI_PicQuestion:removeChild(self.cardimage,true)
            end
            self.cardimage = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(self.currentQuestionData.cardMetaId))
            self.cardimage:setAnchorPoint(ccp(0.5, 0))
            self.cardimage:setPositionX(324)
            self.cardimage:setPositionY(-480)
            self.cardimage:setScale(460/self.cardimage:getContentSize().height)
            self.cardimage:setColor(ccc3(0, 0, 0))
            gameLayer.UI_PicQuestion:addChild(self.cardimage)

        -- 文字问题
        else
            gameLayer.picQueDisplay:setVisible(false)
            gameLayer.textQueDisplay:setVisible(true)
            
            answerKeyArr[2] = self.currentQuestionData.wrongAnswer1Key
            answerKeyArr[3] = self.currentQuestionData.wrongAnswer2Key
            answerKeyArr[4] = self.currentQuestionData.wrongAnswer3Key

            gameLayer.UI_TextQuestion:setString(getTextByKey(self.currentQuestionData.stemKey))
        end
        
        self.answerKeyArr = {}
        for i=1,3 do
            local tempValue = math.random(1,(5-i))
            local tempAnswerKey = answerKeyArr[tempValue]
            
            table.insert(self.answerKeyArr, tempAnswerKey)
            table.remove(answerKeyArr, tempValue)
        end
        table.insert(self.answerKeyArr, answerKeyArr[1])

        local titleArr = {"A." , "B." , "C." , "D."}
        for i=1,4 do
            gameLayer.UI_AnswerBtnArr[i].display:getChildByName("txt"):setString(titleArr[i]..getTextByKey(self.answerKeyArr[i]))
        end
        
        ------

        gameLayer.answerDisplay:setVisible(true)        
    end
    gameLayer.freshUI = freshUI
    
    return gameLayer
end