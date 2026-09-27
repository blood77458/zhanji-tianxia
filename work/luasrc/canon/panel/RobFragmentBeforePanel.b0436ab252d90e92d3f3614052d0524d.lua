require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.request.RobBeastFragmentRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- RobFragmentBeforePanel
--

local function onCloseBtnClicked(evt)
  local aPanel = evt.context
  aPanel:removeFromParentAndCleanup(true)
  aPanel.container.targetInfoPanel = nil
  aPanel.container:panelDismiss()
end

local function onRobBtnClicked(evt)
  local aPanel = evt.context
  
  local function gotoFight()
    local robConsumeEventPoints = DataManager.GameMetaData.battleSettingConfig.robSettingConfig.robConsumeEventPoints
    if CalculationManager.calcComplex_getEPNow() < robConsumeEventPoints - 0.01 then
      onCloseBtnClicked({context = aPanel})
      aPanel.container:showNotEnoughEventPointPanel()
      return
    end
    if BagCalcManager.isFull() then
      onCloseBtnClicked({context = aPanel})
      local aContent = getTextByKey("bagFull_move")
      -- SuspensionLabel:showContent(aPanel.container, aContent)
      NewPackageFullPanel:show()
      return 
    end
    
    local function successCallback(data)
      onCloseBtnClicked({context = aPanel})
      
      RewardManager:getReward({{itemType = ResourceEnum.EVENTPOINT, amount = -robConsumeEventPoints}})
      local robSucceed = false
      for _, v in pairs(data.rewards) do
        if v.itemType == ResourceEnum.BEAST_FRAGMENT then
          robSucceed = true
          break
        end
      end
      local backType = robSucceed and BattleBackType.kBeastScene or BattleBackType.kRobFragmentScene
      data.beastFragmentId = aPanel.beastFragmentId
      data.enemyUid = aPanel.robPlayer.uid
      data.robType = aPanel.robPlayer.playerOrRobot
      data.robotId = aPanel.robPlayer.robotId
      Director:sharedDirector():replaceScene(BattleScene:create(data, backType, BattleEnterEnum.kRobFragmentScene))
    end
    
    local function failureCallback(data)
      onCloseBtnClicked({context = aPanel})
      if data.retCode == 716018 then
        local function closeCanonMessageBox()
        end
        local text = Localization:getInstance():getText("beastRob_opponentPeace")
        aPanel.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
      elseif data.retCode == 710515 then
        aPanel.container:showNotEnoughEventPointPanel()
      else
        local function closeCanonMessageBox()
        end
        local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = data.retCode})
        aPanel.container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
      end
    end
    local params = {beastFragmentId = aPanel.beastFragmentId, enemyUid = aPanel.robPlayer.uid , 
                    robType = aPanel.robPlayer.playerOrRobot , robotId = aPanel.robPlayer.robotId}
    RobFragmentScene.doPreparationBeforeReplaceToBattleScene(params, successCallback, failureCallback)
  end
  
  if aPanel.leftTime + aPanel.startTime > TimeUtil.getServerTimeSeconds() then
    onCloseBtnClicked(evt)
    local function closeCanonMessageBox()
    end
    aPanel.container.targetInfoPanel = CanonMessageBox:Show(getTextByKey("beastRob_peaceTips"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 40, gotoFight, closeCanonMessageBox)
  else
    gotoFight()
  end
end

RobFragmentBeforePanel = class(Layer)

function RobFragmentBeforePanel:ctor()
    self.container = nil
    self.args = nil
end

function RobFragmentBeforePanel:create( container, args )
    local s = RobFragmentBeforePanel.new()
    s:initLayer(container, args)
    return s
end

function RobFragmentBeforePanel:initLayer(container, args)
    RobFragmentBeforePanel.super.initLayer(self)
    
    self.container = container
    self.robPlayer = args.robPlayer
    self.beastFragmentId = args.beastFragmentId
    self.leftTime = args.leftTime
    self.startTime = args.startTime
    
    self.container.targetInfoPanel = self
    
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)
    
    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/rob.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("rob_popup_getplayer") 
    self.tempLayer:addChild(self.panelUI)
    
    local beastId = math.fmod(math.modf(self.beastFragmentId / 100, 10), 1000)
    local fragmentList = MetaManager.beast_meta[beastId].attrs.beastFragmentId:split("|")
    local fragmentIndex
    for k, v in ipairs(fragmentList) do
      local fragmentFormat = tostring(self.beastFragmentId)
      if v == fragmentFormat then
        fragmentIndex = k
        break
      end
    end
    self.panelUI:getChildByName("art_exhibit"):getChildByName("art_exhibit_baihu"):setDisplayFrame(createSpriteFrame(UI_RES_PATH.."/rob/"..beastFrameNameDic[beastId]..".png"))
    
    self.panelUI:getChildByName("art_exhibit"):getChildByName("art_exhibit_1"):setDisplayFrame(createSpriteFrame(string.format(UI_RES_PATH.."/rob/rob_art_exhibit_%d.png", fragmentIndex)))
      
    self.panelUI:getChildByName("txt_player_name"):getChildByName("txt"):setString(string.format("%s%s", Localization:getInstance():getText("beastRob_opponent"), self.robPlayer.nickName))
    
    self.panelUI:getChildByName("txt_wintime"):getChildByName("txt"):setString(Localization:getInstance():getText("beastRob_win"))
    
    local currentUser = DataManager.getCurrUser()
    local robConfig = DataManager.GameMetaData.battleSettingConfig.robSettingConfig
    local userLevelConfig = MetaManager.user_level[currentUser.level]
    local coinForWin = math.modf(userLevelConfig.coinRewardCoefficient * robConfig.beastRobCoinRewardCoef * (1 + (self.robPlayer.level - currentUser.level) * robConfig.beastRobCoinRewardLevelDiffCoef))
    self.panelUI:getChildByName("rob_txt_getcoin"):getChildByName("txt"):setString(string.format("+%d", coinForWin))
    
    local probForRobFragment = math.modf(math.min(math.max(robConfig.beastRobBaseProb + (self.robPlayer.level - currentUser.level) * robConfig.beastRobProbLevelDiffCoef, robConfig.beastRobProbLowerLimit), robConfig.beastRobProbUpperLimit) * 100)
    local lowProp = robConfig.robLowProb * 100
    local upProp = robConfig.robHighProb * 100
    local propLabel = self.panelUI:getChildByName("txt_getchip_info"):getChildByName("txt")
    if probForRobFragment < lowProp then
      propLabel:setString(Localization:getInstance():getText("beastRob_lowChance"))
    elseif probForRobFragment > upProp then
      propLabel:setString(Localization:getInstance():getText("beastRob_highChance"))
    else
      propLabel:setString(Localization:getInstance():getText("beastRob_midChance"))
    end
        --机器人一直显示几率低
    if (self.robPlayer.playerOrRobot == 1) then
      propLabel:setString(Localization:getInstance():getText("beastRob_veryLowChance"))
    end
    
    self.panelUI:getChildByName("txt_losttime"):getChildByName("txt"):setString(Localization:getInstance():getText("beastRob_lose"))
    
    local coinForLose = math.min(math.modf(tonumber(currentUser.coins, 10) * robConfig.beastRobCoinLossCoef), robConfig.beastRobCoinLossLimit)
    self.panelUI:getChildByName("rob_txt_getcoin2"):getChildByName("txt"):setString(string.format("-%d", coinForLose))

    local closeBtn = Button:create(self.panelUI:getChildByName("btn_close"))
    closeBtn:addEventListener( Events.kStart, onCloseBtnClicked, self)

    local robBtn = Button:create(self.panelUI:getChildByName("btn_knock"))
    robBtn:addEventListener( Events.kStart, onRobBtnClicked, self)
    self.panelUI:getChildByName("btn_knock"):getChildByName("txt"):setString(getTextByKey("beastRob_robBtn"))
    
    self.tempLayer:setScale(0.1)
end

function RobFragmentBeforePanel:scaleIn()
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

