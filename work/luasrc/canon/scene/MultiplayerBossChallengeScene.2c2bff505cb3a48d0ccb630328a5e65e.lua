require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.Button"
require "hecore.display.Sprite"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "canon.request.ChallengeMultiplayerBossRequest"
require "canon.request.GetMultiplayerBossDamageRequest"
require "canon.request.BuyActionPowerRequest"
require "canon.panel.MBDamageRecordPopPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local enter_animation_duration = 0.3

MultiplayerBossChallengeEnum = {
  Normal = 1,
  Full = 2
}

--
-- MultiplayerBossChallengeScene
--





local function challengeButtonSelected(evt)
  local activityMultiplayerBossConfig = DataManager.GameMetaData.activityMultiplayerBossConfig
  evt.context:readyToChallengeMultiplayerBoss(activityMultiplayerBossConfig.battleCost, MultiplayerBossChallengeEnum.Normal)
end

local function fullChallengeButtonSelected(evt)
  local activityMultiplayerBossConfig = DataManager.GameMetaData.activityMultiplayerBossConfig
  evt.context:readyToChallengeMultiplayerBoss(activityMultiplayerBossConfig.fullBattleCost, MultiplayerBossChallengeEnum.Full)
end

MultiplayerBossChallengeScene = class(BaseUIScene)

function MultiplayerBossChallengeScene:ctor()
	
end

local globalReturnScene

function MultiplayerBossChallengeScene:create(argv)
  local s = MultiplayerBossChallengeScene.new()
  if argv then 
      self.argv = argv 
  else
      self.argv = {enterScene=nil,returnScene=nil,params={}}
  end
  self.bossInfo = self.argv.params.data
  if self.argv.returnScene == "MultiplayerBossScene" then
    globalReturnScene = "MultiplayerBossScene"
  elseif self.argv.returnScene == "ChapterMapScene" then
    globalReturnScene = "ChapterMapScene"
  end
  s:initScene()
  return s
end

function MultiplayerBossChallengeScene:onInit()
  --移动到这里 因为要用到self
  ----------------------------------------------
  --伤害记录
  ----------------------------------------------
  function harmRecordButtonSelected(evt)
    --print("harmRecordButtonSelected")
    local function getMultiplayerBossDamageSucceed(event)
      --print("getMultiplayerBossDamageSucceed: " .. table.tostring(event))
      --弹出伤害面板
      self.aInfoPanel = MBDamageRecordPopPanel:create(self, event.data.damages)
      self:addChild(self.aInfoPanel)
      self.aInfoPanel:scaleIn()
    end 
    local function getMultiplayerBossDamageFailed(event)
      --print("getMultiplayerBossDamageFailed")
      if event.data.retCode == 714520 then  --Multiplayer boss activity is closed: {0:uid}, {1:featureName}
        local function closeCanonMessageBox()
          self:replaceScene(MainMenuScene)
        end
        local text = Localization:getInstance():getText("activityNian_timeOver")
        CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
      else
        local function closeCanonMessageBox()
        end
        local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
        CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
      end
    end
    local params = {triggerUid = self.bossInfo.triggerUid, bossId = self.bossInfo.id}
    local request = GetMultiplayerBossDamageRequest.new(params, rpc.SendingPriority.kHigh)
    request:addEventListener( RequestNotifyEnum.GetMultiplayerBossDamageSucceed, getMultiplayerBossDamageSucceed )
    request:addEventListener( RequestNotifyEnum.GetMultiplayerBossDamageFailed, getMultiplayerBossDamageFailed )
    request:start()
  end

  ----------------------------------------------
  --补充行动点
  ----------------------------------------------
  local function replenishButtonSelected(evt)
    
    local activityMultiplayerBossConfig = DataManager.GameMetaData.activityMultiplayerBossConfig

    local function replenishYes()
      --print("harmRecordButtonSelected")
      local function buyActionPowerSucceed(event)
        --print("buyActionPowerSucceed: " .. table.tostring(event))
        --扣除消耗
        local delItems = {}
        for _,v in ipairs(event.data.requisites) do
          table.insert(delItems, {itemType = v.itemType, metaId = v.metaId, amount = -v.amount, id = v.id})
        end
        RewardManager:getReward(delItems)
        --补充体力
        local gameInitData = DataManager.getGameInitData()
        gameInitData.sharkMultiplayerBossInfo.actionPower = activityMultiplayerBossConfig.activityPointMax
        gameInitData.sharkMultiplayerBossInfo.actionPowerLastUpdateTime = 0
        DataManager.setGameInitData(gameInitData)
        --刷新显示
        self.refreshSelf()
      end 
      local function buyActionPowerFailed(event)
        print("buyActionPowerFailed")
        if event.data.retCode == 714515 then  --activity closed
          local function closeCanonMessageBox()
            self:replaceScene(MainMenuScene)
          end
          local text = Localization:getInstance():getText("activityNian_timeOver")
          CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        elseif event.data.retCode == 714529 then  --actionPower is full: {0:uid}, {1:currActionPower}, {2:actionPower}, {3:lastestUpdateTime}
          local function closeCanonMessageBox()
            self:enterBossListPanel()
          end
          local text = Localization:getInstance():getText("activityNian_replenishAP_full")
          CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        elseif event.data.retCode == 710513 then
          --金币不足 给提示
          local function replaceSceneFunc()
            self:runAction(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
          end
          local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin, nil, {onReplaceSceneFunc = replaceSceneFunc} )
          self:addChild(aPanel)
          aPanel:scaleIn()
        else
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
          CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        end
      end
      --开始补充
      local params = {}
      local request = BuyActionPowerRequest.new(params, rpc.SendingPriority.kHigh)
      request:addEventListener( RequestNotifyEnum.BuyActionPowerSucceed, buyActionPowerSucceed )
      request:addEventListener( RequestNotifyEnum.BuyActionPowerFailed, buyActionPowerFailed )
      request:start()
    end

    --print("replenishButtonSelected")

    local gameInitData = DataManager.getGameInitData()
    local actionPowerRemain = activityMultiplayerBossConfig.activityPointMax - gameInitData.sharkMultiplayerBossInfo.actionPower
    local needGold = actionPowerRemain * activityMultiplayerBossConfig.activityPointGoldCost
    if CalculationManager.calcComplex_getGemsNow() < needGold then
      --金币不足 不发指令 给提示
      -- local function replaceSceneFunc()
      --   self:runAction(CCMoveBy:create(0.0, ccp(-visibleSize.width, 0)))
      -- end
      local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
      self:addChild(aPanel)
      aPanel:scaleIn()
      return
    end
    if actionPowerRemain <= 0 then
      --全满 不需要补充
      return
    end

    --提示需要的金币数量
    local showText = getTextByKey("activityNian_popup_replenishAPTxt1") .. tostring(needGold) .. getTextByKey("activityNian_popup_replenishAPTxt2")
    CanonMessageBox:Show( showText, ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, 40, replenishYes )
  end
  self.replenishButtonSelected = replenishButtonSelected

  ---=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= refreshSelf 函数开始
	BaseUIScene.initBackGround(self)
  
  --新UI加黑底
  local colorLayer = LayerColor:create()
  colorLayer:setOpacity(kDarkOpacity)
  colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(colorLayer)

  self.title = Localization:getInstance():getText("title_activityNian")
  
  local builder = LayoutBuilder:createWithContentsOfFile("scene/monster_nian.json")
  builder.useArtLabelTTF = true
  local ui = builder:build("monster_nian")
  self:addChild(ui)
  self.ui = ui
  
  local aBossConfig = MetaManager.multiplayer_boss_level[self.bossInfo.level]
  -- if aBossConfig.cardId == 104141 then
  --   self.ui:getChildByName("lbl_monster_nian"):setVisible(false)
  --   -- self.ui:getChildByName("lbl_monster_nian2"):setVisible(true)
  -- else
  --   self.ui:getChildByName("lbl_monster_nian"):setVisible(true)
  --   -- self.ui:getChildByName("lbl_monster_nian2"):setVisible(false)
  -- end
  -- local card3_spf = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(aBossConfig.cardId))
  -- card3_spf:setPosition(ccp(360,630))
  -- self.ui:addChildAt(card3_spf, 3)
  
  local hpBarBg = Sprite:create("battle/pic/xuecao.png")
	hpBarBg:setPosition(ccp(visibleSize.width/2, 836))
	--hpBarBg:setScaleX(0.6)
	self.ui:addChild(hpBarBg)
  
  local aPercentage = self.bossInfo.leftHp / aBossConfig.hp * 100.0
  self.enemyHpPB = CCProgressTimer:create(CCSprite:create("battle/pic/xue.png"))
	self.enemyHpPB:setPosition(ccp(visibleSize.width/2, 836))
	self.enemyHpPB:setType(kCCProgressTimerTypeBar);
	self.enemyHpPB:setMidpoint(ccp(0,1))
	self.enemyHpPB:setBarChangeRate(ccp(1, 0))
	self.enemyHpPB:setPercentage(aPercentage)
	--self.enemyHpPB:setScaleX(0.6)
	self.ui:addChild(CocosObject.new(self.enemyHpPB))
  
  local aBloodLabel = ArtLabelTTF:create(string.format("%d/%d", self.bossInfo.leftHp, aBossConfig.hp), true)
	--aBloodLabel:setCenterColor(ccc3(255,236,60))
	--aBloodLabel:setAroundColor(ccc3(96,37,8))
	aBloodLabel:setSize(35)
	aBloodLabel:construct()
	aBloodLabel:setPosition(ccp(visibleSize.width/2, 836))
	self.ui:addChild(CocosObject.new(aBloodLabel))
  
 --  local aLevelLabel = ArtLabelTTF:create(tostring(self.bossInfo.level), true)
	-- aLevelLabel:setCenterColor(ccc3(255,236,60))
	-- aLevelLabel:setAroundColor(ccc3(96,37,8))
 --  aLevelLabel:setHorizontalAlignment(kCCTextAlignmentLeft)--改为左对齐 2014-6-10
	-- aLevelLabel:setSize(50)--改了下等级文字的大小 原先是35 2014-6-9
	-- aLevelLabel:construct()
 --  aLevelLabel:setAnchorPoint(ccp(0, 0.5))
	-- aLevelLabel:setPosition(ccp(454,835))--改字体大小顺便改了下位置
	-- self.ui:addChild(CocosObject.new(aLevelLabel))

  --描边 2014-6-10
  local aLevelLabel = self.ui:getChildByName("txt_monster_lv"):getChildByName("txt")
  aLevelLabel:setString(tostring(self.bossInfo.level))--
  aLevelLabel:setColor(ccc3(255, 255, 255))
  -- aLevelLabel:setAroundColor(ccc3(0, 0, 0))
  aLevelLabel:setVisible(false)

  local bossLV = CCLabelAtlas:create(tostring(self.bossInfo.level), "pic/lbl_numberYellow.png", 28, 34, 48)
  bossLV:setScale(1.1)
  bossLV:setAnchorPoint(ccp(0.5, 1))
  local numberLabel_co = CocosObject.new(bossLV)
  if self.bossInfo.level > 99 then
    numberLabel_co:setPositionXY(self.ui:getChildByName("txt_monster_lv"):getPositionX() + 28, self.ui:getChildByName("lbl_lv"):getPositionY() + 3)
  elseif self.bossInfo.level <= 99 and self.bossInfo.level >= 10 then
    numberLabel_co:setPositionXY(self.ui:getChildByName("txt_monster_lv"):getPositionX() + 14, self.ui:getChildByName("lbl_lv"):getPositionY() + 3 )
  else
    numberLabel_co:setPositionXY(self.ui:getChildByName("txt_monster_lv"):getPositionX(), self.ui:getChildByName("lbl_lv"):getPositionY() + 3)
  end
  -- numberLabel_co:setPositionXY(self.ui:getChildByName("txt_monster_lv"):getPositionX(), self.ui:getChildByName("lbl_lv"):getPositionY() - 3)
  self.ui:addChild(numberLabel_co )
  
  local recordButtonDisplay = ui:getChildByName("btn_battle_record")
  recordButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_rewardList_recordBtn"))
  local recordButton = Button:create(recordButtonDisplay)
  recordButton:addEventListener(Events.kStart, harmRecordButtonSelected, self)
  
  local activityMultiplayerBossConfig = DataManager.GameMetaData.activityMultiplayerBossConfig
  local gameInitData = DataManager.getGameInitData()
  if not gameInitData.sharkMultiplayerBossInfo then
    gameInitData.sharkMultiplayerBossInfo = {}
    gameInitData.sharkMultiplayerBossInfo.actionPower = activityMultiplayerBossConfig.activityPointMax
    gameInitData.sharkMultiplayerBossInfo.actionPowerLastUpdateTime = 0
  else
    local passedTime = TimeUtil.getServerTimeSeconds() - gameInitData.sharkMultiplayerBossInfo.actionPowerLastUpdateTime
    local recoverNum = math.modf(passedTime / activityMultiplayerBossConfig.activityPointRecoverTime)
    gameInitData.sharkMultiplayerBossInfo.actionPower = gameInitData.sharkMultiplayerBossInfo.actionPower + recoverNum
    gameInitData.sharkMultiplayerBossInfo.actionPowerLastUpdateTime = gameInitData.sharkMultiplayerBossInfo.actionPowerLastUpdateTime + recoverNum * activityMultiplayerBossConfig.activityPointRecoverTime
    if gameInitData.sharkMultiplayerBossInfo.actionPower >= activityMultiplayerBossConfig.activityPointMax then
      gameInitData.sharkMultiplayerBossInfo.actionPower = activityMultiplayerBossConfig.activityPointMax
      gameInitData.sharkMultiplayerBossInfo.actionPowerLastUpdateTime = 0
    end
  end
  DataManager.setGameInitData(gameInitData)
  
  ui:getChildByName("txt_nian_5"):getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_timeRemain"))
  local timeRemainLabel = ui:getChildByName("txt_nian_6")
  ui:getChildByName("txt_nian_7"):getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_battle_activityPoints"))
  local supplyButtonDisplay = ui:getChildByName("btn_supply")
  supplyButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_battle_replenishBtn"))
  local replenishButton = Button:create(supplyButtonDisplay)
  replenishButton:addEventListener(Events.kStart, replenishButtonSelected, self)
  local tipLabel1 = ui:getChildByName("txt_nian_8")
  tipLabel1:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_battle_recoverTips"))
  local tipLabel2 = ui:getChildByName("txt_nian_9")
  ui:getChildByName("txt_nian_10"):getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_battle_costTxt1"))
  ui:getChildByName("txt_nian_11"):getChildByName("txt"):setString(string.format("%d", activityMultiplayerBossConfig.battleCost))
  ui:getChildByName("txt_nian_12"):getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_battle_costTxt2"))
  local challengeButtonDisplay = ui:getChildByName("btn_challenge")
  challengeButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_battle_battleBtn"))
  local challengeButton = Button:create(challengeButtonDisplay)
  challengeButton:addEventListener(Events.kStart, challengeButtonSelected, self)
  
  ui:getChildByName("txt_nian_10_1"):getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_battle_costTxt1"))
  ui:getChildByName("txt_nian_11_1"):getChildByName("txt"):setString(string.format("%d", activityMultiplayerBossConfig.fullBattleCost))
  ui:getChildByName("txt_nian_12_1"):getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_battle_costTxt2"))
  local fullChallengeButtonDisplay = ui:getChildByName("btn_challenge_full")
  fullChallengeButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_battle_fullBattleBtn"))
  local fullChallengeButton = Button:create(fullChallengeButtonDisplay)
  fullChallengeButton:addEventListener(Events.kStart, fullChallengeButtonSelected, self)
  ui:getChildByName("txt_nian_13"):getChildByName("txt"):setString(Localization:getInstance():getText("activityNian_battle_fullBattleTips"))
  ui:getChildByName("txt_nian_14"):getChildByName("txt"):setString(string.format("+%d%%", math.modf(100 * activityMultiplayerBossConfig.fullBattleBuff)))
  
  local function refreshSelf()
    local aLeftTime = self.bossInfo.triggerSecond + activityMultiplayerBossConfig.escapeTime - TimeUtil.getServerTimeSeconds()
    if aLeftTime < 0 then
      aLeftTime = 0
    end
    local hour = math.modf(aLeftTime / 3600)
    local min = math.modf(math.mod(aLeftTime, 3600) / 60)
    local sec = math.mod(math.mod(aLeftTime, 3600), 60)
    timeRemainLabel:getChildByName("txt"):setString(string.format("%02d:%02d:%02d", hour, min, sec))
    
    local gameInitData = DataManager.getGameInitData()
    local passedTime = TimeUtil.getServerTimeSeconds() - gameInitData.sharkMultiplayerBossInfo.actionPowerLastUpdateTime
    local recoverNum = math.modf(passedTime / activityMultiplayerBossConfig.activityPointRecoverTime)
    if recoverNum > 0 then
      gameInitData.sharkMultiplayerBossInfo.actionPower = gameInitData.sharkMultiplayerBossInfo.actionPower + recoverNum
      gameInitData.sharkMultiplayerBossInfo.actionPowerLastUpdateTime = gameInitData.sharkMultiplayerBossInfo.actionPowerLastUpdateTime + recoverNum * activityMultiplayerBossConfig.activityPointRecoverTime
      if gameInitData.sharkMultiplayerBossInfo.actionPower >= activityMultiplayerBossConfig.activityPointMax then
        gameInitData.sharkMultiplayerBossInfo.actionPower = activityMultiplayerBossConfig.activityPointMax
        gameInitData.sharkMultiplayerBossInfo.actionPowerLastUpdateTime = 0
      end
      DataManager.setGameInitData(gameInitData)
    end
    for i = 1, 6 do
      local aDisplay = ui:getChildByName(string.format("firecracker%d", i))
      if i <= gameInitData.sharkMultiplayerBossInfo.actionPower then
        aDisplay:getChildByName("icon_firecracker"):setVisible(true)
        aDisplay:getChildByName("icon_firecracker_inactive"):setVisible(false)
      else
        aDisplay:getChildByName("icon_firecracker"):setVisible(false)
        aDisplay:getChildByName("icon_firecracker_inactive"):setVisible(true)
      end
    end
    -- print("gameInitData.sharkMultiplayerBossInfo.actionPower = " .. gameInitData.sharkMultiplayerBossInfo.actionPower)
    -- print("activityMultiplayerBossConfig.activityPointMax = " .. activityMultiplayerBossConfig.activityPointMax)
    if gameInitData.sharkMultiplayerBossInfo.actionPower>= activityMultiplayerBossConfig.activityPointMax then
      supplyButtonDisplay:getChildByName("btn_common_inactive"):setVisible(true)
      supplyButtonDisplay:getChildByName("btn"):setVisible(false)
      replenishButton:setEnable(false)
      tipLabel1:setVisible(false)
      tipLabel2:setVisible(false)
    else
      supplyButtonDisplay:getChildByName("btn_common_inactive"):setVisible(false)
      supplyButtonDisplay:getChildByName("btn"):setVisible(true)
      replenishButton:setEnable(true)
      tipLabel1:setVisible(true)
      tipLabel2:setVisible(true)
      local aLeftTime = gameInitData.sharkMultiplayerBossInfo.actionPowerLastUpdateTime + activityMultiplayerBossConfig.activityPointRecoverTime - TimeUtil.getServerTimeSeconds()
      local hour = math.modf(aLeftTime / 3600)
      local min = math.modf(math.mod(aLeftTime, 3600) / 60)
      local sec = math.mod(math.mod(aLeftTime, 3600), 60)
      tipLabel2:getChildByName("txt"):setString(string.format("%02d:%02d:%02d", hour, min, sec))
    end
  end
  
  refreshSelf()
  self.refreshSelf = refreshSelf
  
  local function checkLeftTime()
    refreshSelf()
  end
  self.time_script_handler = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(checkLeftTime,1,false)
  
  BaseUIScene.onInit(self)
end

function MultiplayerBossChallengeScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function MultiplayerBossChallengeScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  --
  CanonPlayBackgroundMusic("music/background.mp3", true)
end

function MultiplayerBossChallengeScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.ui:setPositionX(self.ui:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.ui:runAction(CCSequence:create(arr))
end

function MultiplayerBossChallengeScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  --
end

function MultiplayerBossChallengeScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function MultiplayerBossChallengeScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function MultiplayerBossChallengeScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.ui:runAction(CCSequence:create(arr))
end

function MultiplayerBossChallengeScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function MultiplayerBossChallengeScene:enterBossListPanel(tagType)
  local function successCallback(data)
    local argv = {enterScene="MultiplayerBossChallengeScene",returnScene=nil,params={selectedTag = tagType or MultiplayerBossTagEnum.BossList, data = data}}
    self:replaceScene(MultiplayerBossScene, argv)
  end
  
  local function failureCallback(data)
    if data.retCode == 714520 then
      local function closeCanonMessageBox()
        self:replaceScene(MainMenuScene)
      end
      local text = Localization:getInstance():getText("activityNian_timeOver")
      CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    else
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = data.retCode})
      CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    end
  end
  
  MultiplayerBossScene.doPreparationBeforeEnterMultiplayerBossPanel(successCallback, failureCallback)
end

function MultiplayerBossChallengeScene:back()
  local function enterMBScene(tagType)
    self:enterBossListPanel(tagType)
  end
  
  
  if globalReturnScene == "MultiplayerBossScene" then
    enterMBScene(MultiplayerBossTagEnum.BossList)
  elseif globalReturnScene == "ChapterMapScene" then
    self:replaceScene(ChapterMapScene)
  else
    enterMBScene(MultiplayerBossTagEnum.BossList)
  end
end

function MultiplayerBossChallengeScene:dispose()
  if self.time_script_handler then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.time_script_handler)
    self.time_script_handler = nil
  end
  MultiplayerBossChallengeScene.super.dispose(self)
end

function MultiplayerBossChallengeScene:showNotEnoughActionPowerPanel()
  --print("show not enough actionPower panel")
  self.replenishButtonSelected(nil)
end

function MultiplayerBossChallengeScene:readyToChallengeMultiplayerBoss(aNum, battleType)
  if BagCalcManager.isFull() then
    local aContent = Localization:getInstance():getText("bagFull_move")
    -- SuspensionLabel:showContent(self, aContent)
    NewPackageFullPanel:show()
    return
  end
  
  local gameInitData = DataManager.getGameInitData()
  if gameInitData.sharkMultiplayerBossInfo.actionPower < aNum then
    self:showNotEnoughActionPowerPanel()
    return
  end
  local function challengeMultiplayerBossSucceed(event)
    --print("challengeMultiplayerBossSucceed")
    local activityMultiplayerBossConfig = DataManager.GameMetaData.activityMultiplayerBossConfig
    if gameInitData.sharkMultiplayerBossInfo.actionPower >= activityMultiplayerBossConfig.activityPointMax then
      gameInitData.sharkMultiplayerBossInfo.actionPowerLastUpdateTime = TimeUtil.getServerTimeSeconds()
    end
    gameInitData.sharkMultiplayerBossInfo.actionPower = gameInitData.sharkMultiplayerBossInfo.actionPower - aNum
    DataManager.setGameInitData(gameInitData)
    local backType
    if not event.data.win then
      backType = BattleBackType.kMultiplayerBossChallengeScene
      event.data.bossInfo = self.bossInfo
      event.data.globalReturnScene = globalReturnScene
    else
      if globalReturnScene=="MultiplayerBossScene" then
        backType = BattleBackType.kMultiplayerBossSceneBossListPanel
      else
        backType = BattleBackType.kChapterMapScene
      end
    end
    local aBossConfig = MetaManager.multiplayer_boss_level[self.bossInfo.level]
    event.data.bossHpMax = aBossConfig.hp
    Director:sharedDirector():replaceScene(BattleScene:create(event.data, backType, BattleEnterEnum.kMultiplayerBossChallengeScene))
  end 
  local function challengeMultiplayerBossFailed(event)
    if event.data.retCode == 714515 then  --activity closed
      local function closeCanonMessageBox()
        self:replaceScene(MainMenuScene)
      end
      local text = Localization:getInstance():getText("activityNian_timeOver")
      CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    elseif event.data.retCode == 714518 then  --overdue
      local function closeCanonMessageBox()
        self:enterBossListPanel()
      end
      local text = Localization:getInstance():getText("activityNian_nianList_escapedTips")
      CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    elseif event.data.retCode == 714517 then  --boss dead
      local function closeCanonMessageBox()
        self:enterBossListPanel()
      end
      local text = Localization:getInstance():getText("activityNian_nianList_defeatedTips")
      CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    elseif event.data.retCode == 714514 then  --actionPower not enough
      self:showNotEnoughActionPowerPanel()
    elseif event.data.retCode == 710516 then  --grid not enough
      local aContent = Localization:getInstance():getText("bagFull_move")
      -- SuspensionLabel:showContent(self, aContent)
      NewPackageFullPanel:show()
    else
      local function closeCanonMessageBox()
      end
      local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
      CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    end
  end
  local params = {triggerUid = self.bossInfo.triggerUid, bossId = self.bossInfo.id, battleType = battleType}
  local request = ChallengeMultiplayerBossRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener( RequestNotifyEnum.ChallengeMultiplayerBossSucceed, challengeMultiplayerBossSucceed )
  request:addEventListener( RequestNotifyEnum.ChallengeMultiplayerBossFailed, challengeMultiplayerBossFailed )
  request:start()
end