require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

MessageBoxType = {
  kCommon = "Common",
  kEnergyFullCanNotEatPeach = "EnergyFullCanNotEatPeach",
  kBagFullCanNotGetReward = "BagFullCanNotGetReward",
  kEquipUpgradeLevelLimit = "EquipUpgradeLevelLimit",
  kEquipUpgradeEvolveLevelLimit = "EquipUpgradeEvolveLevelLimit",
  kCoinLimit = "CoinLimit",
  kEquipEvolvePropLimit = "EquipEvolvePropLimit",
  kEquipEvolveLevelLimit = "EquipEvolveLevelLimit",
  kSkillEvolvePropLimit = "SkillEvolvePropLimit",
  kArenaScoreNotEnough = "ArenaScoreNotEnough",
  kMapChallengeTimeLimit = "MapChallengeTimeLimit",
  kCannotBuyMissionCount = "CannotBuyMissionCount",
  kResetCoolDownUseGem = "ResetCoolDownUseGem",
  kGemLimit = "GemLimit",
  kMapChallengeLevelLimit = "MapChallengeLevelLimit",
  kArenaChallengeBuyLimit = "ArenaChallengeBuyLimit",
  kArenaChallengeNumLimit = "ArenaChallengeNumLimit",
  kCardComposeRareCardWarning = "CardComposeRareCardWarning",
  kCardComposeExpWarning = "CardComposeExpWarning",
  kGainChapterRewardSucceed = "GainChapterRewardSucceed",
  kCannotGainChapterReward = "CannotGainChapterReward",
  kAlreadyGainChapterReward = "AlreadyGainChapterReward",
  kArenaChallengeBuyTip = "ArenaChallengeBuyTip",
  kEnsureBuyGridWarning = "EnsureBuyGridWarning",
  kBagFullForArenaReward = "BagFullForArenaReward",
  kAlreadyGainForArenaReward = "AlreadyGainForArenaReward",
  kCannotGainForArenaReward = "CannotGainForArenaReward",
  kBagFullForArenaExchange = "BagFullForArenaExchange",
  kGemReplaceProp = "GemReplaceProp",
  kMapEnergyLimit = "MapEnergyLimit",
  kMapUseEnergyProp = "MapUseEnergyProp",
  kMapAllFinish = "MapAllFinish",
  kEventPointLimit = "EventPointLimit",
  kUseEventPointProp = "UseEventPointProp",
  kSweepInCoolDown = "SweepInCoolDown",
  kSweepRoundLimit = "SweepRoundLimit",
  kEnsureBuySpiritGridWarning = "kEnsureBuySpiritGridWarning",
  kEnsureEatHighRareSpiritWarning = "kEnsureEatHighRareSpiritWarning",
  kHaveUnsaveSpiritWarning = "kHaveUnsaveSpiritWarning",
  kSpiritSubAttrIsMaxWarning = "kSpiritSubAttrIsMaxWarning",
  kSpeakLimitWarning = "kSpeakLimitWarning",
}

local function leftButtonAction(evt)
  local aPanel = evt.context
	
	if aPanel.container and type(aPanel.container.setTableViewsEnabled) == "function" then
		aPanel.container:setTableViewsEnabled(true)
	end
	
  if aPanel.arg and aPanel.arg.setTargetInfoPanelNil then
    aPanel.container.targetInfoPanel = nil
  end
  if type(aPanel.container.panelDismiss) == "function" then
    aPanel.container:panelDismiss()
  end
  if aPanel.container.targetInfoPanel == aPanel then
    aPanel.container.targetInfoPanel = nil
  end
  if aPanel.arg and aPanel.arg.panelCloseAction then
    aPanel.arg.panelCloseAction()
  end
  if aPanel.boxType == MessageBoxType.kEquipUpgradeLevelLimit then
    
  elseif aPanel.boxType == MessageBoxType.kCoinLimit then
    
  elseif aPanel.boxType == MessageBoxType.kEquipEvolvePropLimit then
  
  elseif aPanel.boxType == MessageBoxType.kSkillEvolvePropLimit then
    
  elseif aPanel.boxType == MessageBoxType.kMapChallengeTimeLimit then
    aPanel.container:readyToResetMissionCompleteCount(aPanel.arg.missionId, aPanel.arg.extraArgs)
  elseif aPanel.boxType == MessageBoxType.kGemLimit then
    aPanel.container:moveToIAPShop()
  elseif aPanel.boxType == MessageBoxType.kCardComposeRareCardWarning then
		if aPanel.arg and aPanel.arg.continueFunction then
			aPanel.arg.continueFunction()
		else
			onClickStartCompose({context = aPanel.container, ignoreMatterCardRare = true})
		end
  elseif aPanel.boxType == MessageBoxType.kCardComposeExpWarning then
	onClickStartCompose({context = aPanel.container, ignoreMatterCardRare = true, ignoreExp = true})
  elseif aPanel.boxType == MessageBoxType.kArenaChallengeBuyTip then
    aPanel.container:confirmPurchaseChallengeNum()
  elseif aPanel.boxType == MessageBoxType.kEnsureBuyGridWarning then
    aPanel.container:buyGridRequest(true)
  elseif aPanel.boxType == MessageBoxType.kGemReplaceProp then
    aPanel.container:confirmGemReplaceProp()
  elseif aPanel.boxType == MessageBoxType.kMapEnergyLimit then
    aPanel.container.targetInfoPanel = nil
    aPanel:removeFromParentAndCleanup(true)
    UiStackManager.remove(aPanel)
    aPanel.container:showMainActorPanel()
  elseif aPanel.boxType == MessageBoxType.kMapUseEnergyProp then
    aPanel.container:recoveryEnergy(aPanel.arg.propid)
  elseif aPanel.boxType == MessageBoxType.kUseEventPointProp then
    aPanel.container:recoveryEventPoint(aPanel.arg.propid)
  elseif aPanel.boxType == MessageBoxType.kEventPointLimit then
    aPanel.container.targetInfoPanel = nil
    aPanel:removeFromParentAndCleanup(true)
    UiStackManager.remove(aPanel)
    aPanel.container:showMainActorPanel()
  elseif aPanel.boxType == MessageBoxType.kResetCoolDownUseGem then
    aPanel.container:readyToResetCoolDownUseGem(aPanel.arg.extraArgs)
  elseif aPanel.boxType == MessageBoxType.kEnsureBuySpiritGridWarning then
    aPanel.container:buyGridRequest(true)
  elseif aPanel.boxType == MessageBoxType.kEnsureBuyTreasureGridWarning then
    aPanel.container:buyGridRequest(true)
  elseif aPanel.boxType == MessageBoxType.kEnsureEatHighRareSpiritWarning then
    aPanel.container:conformEatHighRareSpirit(true)
  elseif aPanel.boxType == MessageBoxType.kSpiritSubAttrIsMaxWarning then
    aPanel.container:RefreshConform(aPanel.arg.btnType)
  end
  --[[
  if type(aPanel.container.panelDismiss) == "function" then
    aPanel.container:panelDismiss()
  end
  if aPanel.container.targetInfoPanel == aPanel then
    aPanel.container.targetInfoPanel = nil
  end]]
  aPanel:removeFromParentAndCleanup(true)
  UiStackManager.remove(aPanel)
end

local function rightButtonAction(evt)
  local aPanel = evt.context
	
	if aPanel.container and type(aPanel.container.setTableViewsEnabled) == "function" then
		aPanel.container:setTableViewsEnabled(true)
	end
	
  if aPanel.arg and aPanel.arg.setTargetInfoPanelNil then
	aPanel.container.targetInfoPanel = nil
  end
  if aPanel.arg and aPanel.arg.panelCloseAction then
    aPanel.arg.panelCloseAction()
  end
  if aPanel.boxType == MessageBoxType.kEquipUpgradeLevelLimit then
    aPanel.container:moveToCityMainScene()
  elseif aPanel.boxType == MessageBoxType.kCoinLimit then
    --go to tower
		if aPanel.arg and aPanel.arg.onReplaceSceneFunc then
			aPanel.arg.onReplaceSceneFunc()
		end
		if type(aPanel.container.moveToTower) == "function" then
			aPanel.container:moveToTower()
		else
      --[[
			if tonumber(DataManager.getCurrUser().level) < tonumber(MetaManager.game_meta.gameSettingConfig.babelConfig.babelTowerUnlockLevel) then
				SuspensionLabel:showContent(aPanel.container, Localization:getInstance():getText("babel_levelInsufficient", {num = MetaManager.game_meta.gameSettingConfig.babelConfig.babelTowerUnlockLevel}))
			else
				aPanel.container:replaceScene(SkyTowerMainScene)
			end]]
      ChallengeEntersScene.readyToNewBabelEnterPanel()
		end
  elseif aPanel.boxType == MessageBoxType.kEquipEvolvePropLimit then
    local eliteInfo = aPanel.arg.eliteInfo
    if (eliteInfo.unlock) then
      aPanel.container:replaceScene(EliteMissionScene, {enterScene = nil, returnScene = "EquipEvolveScene", params = {eliteMissionId=eliteInfo.eliteMissionId}})
    else
      local aContent = Localization:getInstance():getText("skill_MaterialShortText_stageLocked")
      SuspensionLabel:showContent(aPanel, aContent)
    end
  elseif aPanel.boxType == MessageBoxType.kSkillEvolvePropLimit then
    local eliteInfo = EliteManager.getMaterialSrc(aPanel.arg.propId)
    if (eliteInfo.unlock) then
      aPanel.container:replaceScene(EliteMissionScene, {enterScene = nil, returnScene = "SkillEvolveScene", params = {eliteMissionId=eliteInfo.eliteMissionId}})
    else
      local aContent = Localization:getInstance():getText("skill_MaterialShortText_stageLocked")
      SuspensionLabel:showContent(aPanel, aContent)
    end
  elseif aPanel.boxType == MessageBoxType.kMapChallengeTimeLimit then
    
  elseif aPanel.boxType == MessageBoxType.kGemLimit then
  
  elseif aPanel.boxType == MessageBoxType.kCardComposeRareCardWarning then
    
  elseif aPanel.boxType == MessageBoxType.kArenaChallengeBuyTip then
  elseif aPanel.boxType == MessageBoxType.kEnsureBuyGridWarning then
	aPanel.container:buyGridRequest(false)
  elseif aPanel.boxType == MessageBoxType.kGemReplaceProp then
    
  elseif aPanel.boxType == MessageBoxType.kMapEnergyLimit then
    
  elseif aPanel.boxType == MessageBoxType.kMapUseEnergyProp then
    
  elseif aPanel.boxType == MessageBoxType.kUseEventPointProp then
    
  elseif aPanel.boxType == MessageBoxType.kEventPointLimit then
    
  elseif aPanel.boxType == MessageBoxType.kResetCoolDownUseGem then

  elseif aPanel.boxType == MessageBoxType.kEnsureBuySpiritGridWarning then
    aPanel.container:buyGridRequest(false)
  elseif aPanel.boxType == MessageBoxType.kEnsureBuyTreasureGridWarning then
    aPanel.container:buyGridRequest(false)
  elseif aPanel.boxType == MessageBoxType.kEnsureEatHighRareSpiritWarning then
    aPanel.container:conformEatHighRareSpirit(false)
  elseif aPanel.boxType == MessageBoxType.kSpiritSubAttrIsMaxWarning then
    aPanel.container:RefreshConform(false)
  end
  
  if (aPanel.boxType ~= MessageBoxType.kEquipEvolvePropLimit) and (aPanel.boxType ~= MessageBoxType.kSkillEvolvePropLimit) then
    if type(aPanel.container.panelDismiss) == "function" then
      aPanel.container:panelDismiss()
    end
    if aPanel.container.targetInfoPanel == aPanel then
      aPanel.container.targetInfoPanel = nil
    end
    aPanel:removeFromParentAndCleanup(true)
    UiStackManager.remove(aPanel)
  end
end

local function centerButtonAction(evt)
  local aPanel = evt.context
	if aPanel.container and type(aPanel.container.setTableViewsEnabled) == "function" then
		aPanel.container:setTableViewsEnabled(true)
	end
  if aPanel.arg and aPanel.arg.chatTouchEnable then--为了禁止聊天面板点击
    aPanel.container:setTableViewTouched(true)
  end
  if aPanel.arg and aPanel.arg.setTargetInfoPanelNil then
	aPanel.container.targetInfoPanel = nil
  end
  if aPanel.boxType == MessageBoxType.kArenaScoreNotEnough then
    
  elseif aPanel.boxType == MessageBoxType.kMapChallengeLevelLimit then
    
  elseif aPanel.boxType == MessageBoxType.kArenaChallengeBuyLimit then
    
  elseif aPanel.boxType == MessageBoxType.kArenaChallengeNumLimit then
    
  elseif aPanel.boxType == MessageBoxType.kGainChapterRewardSucceed then
    
  elseif aPanel.boxType == MessageBoxType.kBagFullForArenaExchange then
    
  elseif aPanel.boxType == MessageBoxType.kBagFullForArenaReward then
    
  elseif aPanel.boxType == MessageBoxType.kMapAllFinish then
    
  elseif aPanel.boxType == MessageBoxType.kCannotBuyMissionCount then
    
  elseif aPanel.boxType == MessageBoxType.kSweepInCoolDown then
    
  elseif aPanel.boxType == MessageBoxType.kSweepRoundLimit then

  elseif aPanel.boxType == MessageBoxType.kHaveUnsaveSpiritWarning then
    aPanel.container:gotoSpiritComposePanel(aPanel.arg)
  end
  if type(aPanel.container.panelDismiss) == "function" then
    aPanel.container:panelDismiss()
  end
  if aPanel.container.targetInfoPanel == aPanel then
    aPanel.container.targetInfoPanel = nil
  end
  aPanel:removeFromParentAndCleanup(true)
  UiStackManager.remove(aPanel)
  
  if aPanel.boxType == MessageBoxType.kMapAllFinish then
    aPanel.container:checkUnlockContent()
  end
end

MessageBoxPanel = class(Layer)

function MessageBoxPanel:ctor()
    self.container = nil
    self.boxType = nil
    self.arg = nil
end

function MessageBoxPanel:getCurTempLayer()
	if  self.tempLayer then
		return  self.tempLayer
	else
		return nil
	end
end

function MessageBoxPanel:create( container, boxType, arg )
    local s = MessageBoxPanel.new()
    s:initLayer(container, boxType, arg)
    return s
end

function MessageBoxPanel:initLayer(container, boxType, arg)
	if container and type(container.setTableViewsEnabled) == "function" then
		container:setTableViewsEnabled(false)
	end
  if arg and arg.chatTouchEnable then--为了禁止聊天面板点击
    container:setTableViewTouched(false)
  end
    MessageBoxPanel.super.initLayer(self)
    self.container = container
    self.container.targetInfoPanel = self
    self.boxType = boxType
    self.arg = arg
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
    self.panelUI = builder:build("common_popup1") 
    self.tempLayer:addChild(self.panelUI)
    
    local aMessageLabelTwo = self.panelUI:getChildByName("common_txt_sellItem_equip"):getChildByName("txt_sellItem_equip")
    local aMessageLabelOne = self.panelUI:getChildByName("common_txt_popup1"):getChildByName("txt_popup1")
	local size = aMessageLabelOne:getDimensions()
	size.height = 0
	aMessageLabelOne:setDimensions(size)
    local aLeftButtonDisplay = self.panelUI:getChildByName("common_btn_continue")
    local aRightButtonDisplay = self.panelUI:getChildByName("common_btn_cancel")
    local aCenterButtonDisplay = self.panelUI:getChildByName("common_btn_center")
    self.exampleBuild = builder:build("txt/common_txt_ sellItem_equip")
    local aExampleLabel = self.exampleBuild:getChildByName("txt_sellItem_equip")
    aExampleLabel:setDimensions(CCSizeMake(aExampleLabel:getDimensions().width, 0))
    aExampleLabel:setString("Example")
    local aBaseHeight = aExampleLabel:getTexture():getContentSize().height
    
    local aString
    if self.boxType == MessageBoxType.kEquipUpgradeLevelLimit then
      aString = Localization:getInstance():getText("equip_LevelMaxText")
      aLeftButtonDisplay:getChildByName("txt_continue"):setString(Localization:getInstance():getText("yes"))
      local aLeftButton = Button:create(aLeftButtonDisplay)
      aLeftButton:addEventListener( Events.kStart, leftButtonAction, self )
      aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("equip_LevelMaxBtn"))
      local aRightButton = Button:create(aRightButtonDisplay)
      aRightButton:addEventListener( Events.kStart, rightButtonAction, self )
      aCenterButtonDisplay:setVisible(false)
    elseif self.boxType == MessageBoxType.kEquipUpgradeEvolveLevelLimit then
      aString = Localization:getInstance():getText("equipEnhance_levelMaxText")
      aLeftButtonDisplay:setVisible(false)
      aRightButtonDisplay:setVisible(false)
      aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
      local aCenterButton = Button:create(aCenterButtonDisplay)
      aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
	 elseif self.boxType == MessageBoxType.kCommon then
		aString = ""
		aLeftButtonDisplay:setVisible(false)
		aRightButtonDisplay:setVisible(false)
		aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
		local aCenterButton = Button:create(aCenterButtonDisplay)
		aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
	 elseif self.boxType == MessageBoxType.kEnergyFullCanNotEatPeach then
      aString = Localization:getInstance():getText("EC_FRIEND_FREEGIFT_ENERGY_FULL_TXT")
      aLeftButtonDisplay:setVisible(false)
      aRightButtonDisplay:setVisible(false)
	  aExampleLabel:setVisible(false)
      aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
      local aCenterButton = Button:create(aCenterButtonDisplay)
      aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
    elseif self.boxType == MessageBoxType.kCoinLimit then
      aString = Localization:getInstance():getText("equip_CoinShortText")
      aLeftButtonDisplay:getChildByName("txt_continue"):setString(Localization:getInstance():getText("yes"))
      local aLeftButton = Button:create(aLeftButtonDisplay)
      aLeftButton:addEventListener( Events.kStart, leftButtonAction, self )
      aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("equip_TowerBtn"))
      local aRightButton = Button:create(aRightButtonDisplay)
      aRightButton:addEventListener( Events.kStart, rightButtonAction, self )
      aCenterButtonDisplay:setVisible(false)
    elseif self.boxType == MessageBoxType.kEquipEvolvePropLimit then
      local aEliteMeta = MetaManager.elite_setting[self.arg.eliteInfo.eliteMissionId]
      local aText = getTextByKey(aEliteMeta.stageDesc)
      aString = Localization:getInstance():getText("equip_MaterialShortText", {stagename = aText})
      aLeftButtonDisplay:getChildByName("txt_continue"):setString(Localization:getInstance():getText("yes"))
      local aLeftButton = Button:create(aLeftButtonDisplay)
      aLeftButton:addEventListener( Events.kStart, leftButtonAction, self )
      aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("equip_StageBtn"))
      local aRightButton = Button:create(aRightButtonDisplay)
      aRightButton:addEventListener( Events.kStart, rightButtonAction, self )
      aCenterButtonDisplay:setVisible(false)
    elseif self.boxType == MessageBoxType.kEquipEvolveLevelLimit then
      aString = Localization:getInstance():getText("equip_CanNotEvolveText")
      aLeftButtonDisplay:setVisible(false)
      aRightButtonDisplay:setVisible(false)
      aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
      local aCenterButton = Button:create(aCenterButtonDisplay)
      aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
    elseif self.boxType == MessageBoxType.kArenaScoreNotEnough then
      aString = Localization:getInstance():getText("arena_exchange_pointInsufficient")
      aLeftButtonDisplay:setVisible(false)
      aRightButtonDisplay:setVisible(false)
      aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
      local aCenterButton = Button:create(aCenterButtonDisplay)
      aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
    elseif self.boxType == MessageBoxType.kSkillEvolvePropLimit then
	  local aEliteMeta = CommonManager.getSubTableByKey(
		MetaManager.elite_setting,
		{name = "propId", value = self.arg.propId}
	  )
	  local aText = getTextByKey(aEliteMeta.stageDesc)
      aString = Localization:getInstance():getText("skill_MaterialShortText",{stagename = aText})
      aLeftButtonDisplay:getChildByName("txt_continue"):setString(Localization:getInstance():getText("yes"))
      local aLeftButton = Button:create(aLeftButtonDisplay)
      aLeftButton:addEventListener( Events.kStart, leftButtonAction, self )
      aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("skill_StageBtn"))
      local aRightButton = Button:create(aRightButtonDisplay)
      aRightButton:addEventListener( Events.kStart, rightButtonAction, self )
      aCenterButtonDisplay:setVisible(false)
    elseif self.boxType == MessageBoxType.kMapChallengeTimeLimit then
      aString = Localization:getInstance():getText("inquireReset", {glodNum = self.arg.glodNum})
      aLeftButtonDisplay:getChildByName("txt_continue"):setString(Localization:getInstance():getText("yes"))
      local aLeftButton = Button:create(aLeftButtonDisplay)
      aLeftButton:addEventListener( Events.kStart, leftButtonAction, self )
      aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("cancel"))
      local aRightButton = Button:create(aRightButtonDisplay)
      aRightButton:addEventListener( Events.kStart, rightButtonAction, self )
      aCenterButtonDisplay:setVisible(false)
    elseif self.boxType == MessageBoxType.kCannotBuyMissionCount then
      aString = Localization:getInstance():getText("resetLimit")
      aLeftButtonDisplay:setVisible(false)
      aRightButtonDisplay:setVisible(false)
      aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
      local aCenterButton = Button:create(aCenterButtonDisplay)
      aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
    elseif self.boxType == MessageBoxType.kGemLimit then
      aString = Localization:getInstance():getText("popup_noMoney_inquirePay")
      aLeftButtonDisplay:getChildByName("txt_continue"):setString(Localization:getInstance():getText("payBtn"))
      local aLeftButton = Button:create(aLeftButtonDisplay)
      aLeftButton:addEventListener( Events.kStart, leftButtonAction, self )
      aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("cancel"))
      local aRightButton = Button:create(aRightButtonDisplay)
      aRightButton:addEventListener( Events.kStart, rightButtonAction, self )
      aCenterButtonDisplay:setVisible(false)
    elseif self.boxType == MessageBoxType.kMapChallengeLevelLimit then
      aString = Localization:getInstance():getText("stageLevelLimite", {stageLevelLimite = self.arg.levelLimit})
      aLeftButtonDisplay:setVisible(false)
      aRightButtonDisplay:setVisible(false)
      aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
      local aCenterButton = Button:create(aCenterButtonDisplay)
      aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
	  --
	elseif self.boxType == MessageBoxType.kBagFullCanNotGetReward then
      aString = Localization:getInstance():getText("rewardPopup_inventoryFullTxt")
      aLeftButtonDisplay:setVisible(false)
      aRightButtonDisplay:setVisible(false)
      aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
      local aCenterButton = Button:create(aCenterButtonDisplay)
      aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
	  --
    elseif self.boxType == MessageBoxType.kArenaChallengeBuyLimit then
      if self.arg.fullVip then
        aString = Localization:getInstance():getText("arena_cannotPurchaseTxt_vipMax")
      else
        aString = Localization:getInstance():getText("arena_cannotPurchaseTxt")
      end
      aLeftButtonDisplay:setVisible(false)
      aRightButtonDisplay:setVisible(false)
      aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
      local aCenterButton = Button:create(aCenterButtonDisplay)
      aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
    elseif self.boxType == MessageBoxType.kArenaChallengeNumLimit then
      aString = Localization:getInstance():getText("arena_cannotChallengeTxt")
      aLeftButtonDisplay:setVisible(false)
      aRightButtonDisplay:setVisible(false)
      aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
      local aCenterButton = Button:create(aCenterButtonDisplay)
      aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
    elseif self.boxType == MessageBoxType.kCardComposeRareCardWarning then
      aString = Localization:getInstance():getText("cardEnhance_RareTips")
			if self.arg and self.arg.warningMessage then
				aString = self.arg.warningMessage
			end
      aCenterButtonDisplay:setVisible(false)
      aLeftButtonDisplay:getChildByName("txt_continue"):setString(Localization:getInstance():getText("yes"))
      aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("cancel"))
	  local aLeftButton = Button:create(aLeftButtonDisplay)
      aLeftButton:addEventListener( Events.kStart, leftButtonAction, self )
	  local aRightButton = Button:create(aRightButtonDisplay)
      aRightButton:addEventListener( Events.kStart, rightButtonAction, self )
    elseif self.boxType == MessageBoxType.kCardComposeExpWarning then
      aString = Localization:getInstance():getText("exp warning")
      aCenterButtonDisplay:setVisible(false)
      aLeftButtonDisplay:getChildByName("txt_continue"):setString(Localization:getInstance():getText("yes"))
      aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("cancel"))
	  local aLeftButton = Button:create(aLeftButtonDisplay)
      aLeftButton:addEventListener( Events.kStart, leftButtonAction, self )
	  local aRightButton = Button:create(aRightButtonDisplay)
      aRightButton:addEventListener( Events.kStart, rightButtonAction, self )
    elseif self.boxType == MessageBoxType.kGainChapterRewardSucceed then
      aString = Localization:getInstance():getText("chapterPresentDialog", {itemName = self.arg.itemName, itemNum = self.arg.itemNum})
      aLeftButtonDisplay:setVisible(false)
      aRightButtonDisplay:setVisible(false)
      aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
      local aCenterButton = Button:create(aCenterButtonDisplay)
      aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
    elseif self.boxType == MessageBoxType.kCannotGainChapterReward then
      aString = Localization:getInstance():getText("EC_BATTLE_CHAPTER_NOT_FINISH_TXT")
      aLeftButtonDisplay:setVisible(false)
      aRightButtonDisplay:setVisible(false)
      aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
      local aCenterButton = Button:create(aCenterButtonDisplay)
      aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
    elseif self.boxType == MessageBoxType.kAlreadyGainChapterReward then
      aString = Localization:getInstance():getText("EC_BATTLE_CHAPTER_FINISH_REWARD_ALREADY_GAINED_TXT")
      aLeftButtonDisplay:setVisible(false)
      aRightButtonDisplay:setVisible(false)
      aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
      local aCenterButton = Button:create(aCenterButtonDisplay)
      aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
    elseif self.boxType == MessageBoxType.kArenaChallengeBuyTip then
      aString = Localization:getInstance():getText("arena_purchaseTxt", {gem = self.arg.gem, num = self.arg.num})
      aCenterButtonDisplay:setVisible(false)
      aLeftButtonDisplay:getChildByName("txt_continue"):setString(Localization:getInstance():getText("yes"))
      aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("cancel"))
	  local aLeftButton = Button:create(aLeftButtonDisplay)
      aLeftButton:addEventListener( Events.kStart, leftButtonAction, self )
	  local aRightButton = Button:create(aRightButtonDisplay)
      aRightButton:addEventListener( Events.kStart, rightButtonAction, self )
	elseif self.boxType == MessageBoxType.kEnsureBuyGridWarning then
	  local toBuyTimes = DataManager.getGameInitData().sharkUserExtend.boughtGridTimes + 1
	  if toBuyTimes > MetaManager.game_meta.gameSettingConfig.inventoryMaxExpandTimes then
      aString = Localization:getInstance():getText("bag_canNotExpand")
		local aCenterButton = Button:create(aCenterButtonDisplay)
		aCenterButton:addEventListener( Events.kStart, rightButtonAction, self )
		aLeftButtonDisplay:setVisible(false)
		aRightButtonDisplay:setVisible(false)
        aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
	  else
      local goldCost = 0
      local increaseGridNum = MetaManager.game_meta.gameSettingConfig.inventoryExtraSlotsPerPurchase
        for k,v in pairs(MetaManager.expand_inventory)
      do
        if (tonumber(v.startTimes) <= toBuyTimes) and ((tonumber(v.endTimes) >= (toBuyTimes)) or tonumber(v.endTimes) == -1) then
          goldCost = tonumber(v.goldCost)
          break;
        end
      end
	  self.container.goldCost = goldCost
        aString = Localization:getInstance():getText("bag_confirmExpand", {num1 = goldCost, num2 = increaseGridNum})
		local aLeftButton = Button:create(aLeftButtonDisplay)
		  aLeftButton:addEventListener( Events.kStart, leftButtonAction, self )
		  local aRightButton = Button:create(aRightButtonDisplay)
		  aRightButton:addEventListener( Events.kStart, rightButtonAction, self )
		  aCenterButtonDisplay:setVisible(false)
		  aLeftButtonDisplay:getChildByName("txt_continue"):setString(Localization:getInstance():getText("yes"))
      aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("cancel"))
	  end
    --元神格子
    elseif self.boxType == MessageBoxType.kEnsureBuySpiritGridWarning then
    local toBuyTimes = DataManager.getGameInitData().sharkUserExtend.boughtSpiritPoolNum + 1
    if toBuyTimes > DataManager.GameMetaData.spiritSettingConfig.spiritPoolMaxExpandTimes then
      aString = Localization:getInstance():getText("spirit_canNotExpand")
    local aCenterButton = Button:create(aCenterButtonDisplay)
    aCenterButton:addEventListener( Events.kStart, rightButtonAction, self )
    aLeftButtonDisplay:setVisible(false)
    aRightButtonDisplay:setVisible(false)
        aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
    else
      local goldCost = DataManager.GameMetaData.spiritSettingConfig.spiritPoolExpandCost
      
    self.container.goldCost = goldCost
    local increaseGridNum = DataManager.GameMetaData.spiritSettingConfig.spiritPoolExtraSizePerPurchase
        aString = Localization:getInstance():getText("spirit_confirmExpand", {num1 = goldCost, num2 = increaseGridNum})
    local aLeftButton = Button:create(aLeftButtonDisplay)
      aLeftButton:addEventListener( Events.kStart, leftButtonAction, self )
      local aRightButton = Button:create(aRightButtonDisplay)
      aRightButton:addEventListener( Events.kStart, rightButtonAction, self )
      aCenterButtonDisplay:setVisible(false)
      aLeftButtonDisplay:getChildByName("txt_continue"):setString(Localization:getInstance():getText("yes"))
      aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("cancel"))
    end

    --宝物格子
    elseif self.boxType == MessageBoxType.kEnsureBuyTreasureGridWarning then
      local toBuyTimes = DataManager.getGameInitData().sharkUserExtendMore.treasureInfo.buyGridTimes + 1
      if toBuyTimes > DataManager.GameMetaData.treasureSettingConfig.treasurePoolMaxExpandTimes then 
        aString = Localization:getInstance():getText("Treasure_tips_5")
        local aCenterButton = Button:create(aCenterButtonDisplay)
        aCenterButton:addEventListener( Events.kStart, rightButtonAction, self )
        aLeftButtonDisplay:setVisible(false)
        aRightButtonDisplay:setVisible(false)
        aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
      else
        local goldCost = DataManager.GameMetaData.treasureSettingConfig.treasurePoolExpandCost
        self.container.goldCost = goldCost
        local increaseGridNum =DataManager.GameMetaData.treasureSettingConfig.treasureExtraSizePerPurchase
        aString = Localization:getInstance():getText("Treasure_tips_4", {nmb1 = goldCost, nmb2 = increaseGridNum})
        local aLeftButton = Button:create(aLeftButtonDisplay)
        aLeftButton:addEventListener( Events.kStart, leftButtonAction, self )
        local aRightButton = Button:create(aRightButtonDisplay)
        aRightButton:addEventListener( Events.kStart, rightButtonAction, self )
        aCenterButtonDisplay:setVisible(false)
        aLeftButtonDisplay:getChildByName("txt_continue"):setString(Localization:getInstance():getText("yes"))
        aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("cancel"))
      end
      
	  
    elseif self.boxType == MessageBoxType.kBagFullForArenaExchange then
      aString = Localization:getInstance():getText("arena_inventoryFullExchange")
      aLeftButtonDisplay:setVisible(false)
      aRightButtonDisplay:setVisible(false)
      aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
      local aCenterButton = Button:create(aCenterButtonDisplay)
      aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
    elseif self.boxType == MessageBoxType.kBagFullForArenaReward then
      aString = Localization:getInstance():getText("arena_inventoryFullReward")
      aLeftButtonDisplay:setVisible(false)
      aRightButtonDisplay:setVisible(false)
      aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
      local aCenterButton = Button:create(aCenterButtonDisplay)
      aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
    elseif self.boxType == MessageBoxType.kAlreadyGainForArenaReward then
      aString = Localization:getInstance():getText("EC_SHARK_ARENA_RANK_FIRST_REWARD_GAIN_TXT")
      aLeftButtonDisplay:setVisible(false)
      aRightButtonDisplay:setVisible(false)
      aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
      local aCenterButton = Button:create(aCenterButtonDisplay)
      aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
    elseif self.boxType == MessageBoxType.kCannotGainForArenaReward then
      aString = Localization:getInstance():getText("EC_SHARK_ARENA_REWARD_UNLOCK_TXT")
      aLeftButtonDisplay:setVisible(false)
      aRightButtonDisplay:setVisible(false)
      aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
      local aCenterButton = Button:create(aCenterButtonDisplay)
      aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
    elseif self.boxType == MessageBoxType.kGemReplaceProp then
      aString = Localization:getInstance():getText("equipEvolve_BuyMaterialTxt", {num = self.arg.num})
      aCenterButtonDisplay:setVisible(false)
      aLeftButtonDisplay:getChildByName("txt_continue"):setString(Localization:getInstance():getText("yes"))
      aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("cancel"))
	  local aLeftButton = Button:create(aLeftButtonDisplay)
      aLeftButton:addEventListener( Events.kStart, leftButtonAction, self )
	  local aRightButton = Button:create(aRightButtonDisplay)
      aRightButton:addEventListener( Events.kStart, rightButtonAction, self )
    elseif self.boxType == MessageBoxType.kMapEnergyLimit then
      aString = Localization:getInstance():getText("stage_noEnergy")
      aCenterButtonDisplay:setVisible(false)
      aLeftButtonDisplay:getChildByName("txt_continue"):setString(Localization:getInstance():getText("goReplenishBtn"))
      aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("cancel"))
	  local aLeftButton = Button:create(aLeftButtonDisplay)
      aLeftButton:addEventListener( Events.kStart, leftButtonAction, self )
	  local aRightButton = Button:create(aRightButtonDisplay)
      aRightButton:addEventListener( Events.kStart, rightButtonAction, self )
    elseif self.boxType == MessageBoxType.kMapUseEnergyProp then
      aString = Localization:getInstance():getText("popup_useEnergyPotion", {propname = self.arg.propname, num = self.arg.num})
      aCenterButtonDisplay:setVisible(false)
      aLeftButtonDisplay:getChildByName("txt_continue"):setString(Localization:getInstance():getText("yes"))
      aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("cancel"))
	  local aLeftButton = Button:create(aLeftButtonDisplay)
      aLeftButton:addEventListener( Events.kStart, leftButtonAction, self )
	  local aRightButton = Button:create(aRightButtonDisplay)
      aRightButton:addEventListener( Events.kStart, rightButtonAction, self )
    elseif self.boxType == MessageBoxType.kMapAllFinish then
      aString = Localization:getInstance():getText("finishAll")
      aLeftButtonDisplay:setVisible(false)
      aRightButtonDisplay:setVisible(false)
      aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
      local aCenterButton = Button:create(aCenterButtonDisplay)
      aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
    elseif self.boxType == MessageBoxType.kUseEventPointProp then
      aString = Localization:getInstance():getText("popup_useEventPointPotion", {propname = self.arg.propname, num = self.arg.num})
      aCenterButtonDisplay:setVisible(false)
      aLeftButtonDisplay:getChildByName("txt_continue"):setString(Localization:getInstance():getText("yes"))
      aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("cancel"))
      local aLeftButton = Button:create(aLeftButtonDisplay)
      aLeftButton:addEventListener( Events.kStart, leftButtonAction, self )
      local aRightButton = Button:create(aRightButtonDisplay)
      aRightButton:addEventListener( Events.kStart, rightButtonAction, self )
    elseif self.boxType == MessageBoxType.kEventPointLimit then
      aString = Localization:getInstance():getText("noEventPoints")
      aCenterButtonDisplay:setVisible(false)
      aLeftButtonDisplay:getChildByName("txt_continue"):setString(Localization:getInstance():getText("goReplenishBtn"))
      aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("cancel"))
      local aLeftButton = Button:create(aLeftButtonDisplay)
      aLeftButton:addEventListener( Events.kStart, leftButtonAction, self )
      local aRightButton = Button:create(aRightButtonDisplay)
      aRightButton:addEventListener( Events.kStart, rightButtonAction, self )
    elseif self.boxType == MessageBoxType.kResetCoolDownUseGem then
      aString = Localization:getInstance():getText("stage_skipCooldown", {num = self.arg.extraArgs.gemNeeded})
      aCenterButtonDisplay:setVisible(false)
      aLeftButtonDisplay:getChildByName("txt_continue"):setString(Localization:getInstance():getText("yes"))
      aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("cancel"))
      local aLeftButton = Button:create(aLeftButtonDisplay)
      aLeftButton:addEventListener( Events.kStart, leftButtonAction, self )
      local aRightButton = Button:create(aRightButtonDisplay)
      aRightButton:addEventListener( Events.kStart, rightButtonAction, self )
    elseif self.boxType == MessageBoxType.kSweepInCoolDown then
      aString = Localization:getInstance():getText("stage_inCooldown")
      aLeftButtonDisplay:setVisible(false)
      aRightButtonDisplay:setVisible(false)
      aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
      local aCenterButton = Button:create(aCenterButtonDisplay)
      aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
    elseif self.boxType == MessageBoxType.kSweepRoundLimit then
      aString = Localization:getInstance():getText("stage_roundsOverLimit")
      aLeftButtonDisplay:setVisible(false)
      aRightButtonDisplay:setVisible(false)
      aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
      local aCenterButton = Button:create(aCenterButtonDisplay)
      aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
    elseif self.boxType == MessageBoxType.kEnsureEatHighRareSpiritWarning then
      aString = Localization:getInstance():getText("spirit_highRarity_confirm")
      aCenterButtonDisplay:setVisible(false)
      aLeftButtonDisplay:getChildByName("txt_continue"):setString(Localization:getInstance():getText("yes"))
      aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("cancel"))
      local aLeftButton = Button:create(aLeftButtonDisplay)
      aLeftButton:addEventListener( Events.kStart, leftButtonAction, self )
      local aRightButton = Button:create(aRightButtonDisplay)
      aRightButton:addEventListener( Events.kStart, rightButtonAction, self )
    elseif self.boxType == MessageBoxType.kSpiritSubAttrIsMaxWarning then
      aString = Localization:getInstance():getText("spirit_refreshMax_confirm")
      aCenterButtonDisplay:setVisible(false)
      aLeftButtonDisplay:getChildByName("txt_continue"):setString(Localization:getInstance():getText("yes"))
      aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("cancel"))
      local aLeftButton = Button:create(aLeftButtonDisplay)
      aLeftButton:addEventListener( Events.kStart, leftButtonAction, self )
      local aRightButton = Button:create(aRightButtonDisplay)
      aRightButton:addEventListener( Events.kStart, rightButtonAction, self )
    elseif self.boxType == MessageBoxType.kHaveUnsaveSpiritWarning then
      aString = Localization:getInstance():getText("spirit_refresh10_unsaved")
      aLeftButtonDisplay:setVisible(false)
      aRightButtonDisplay:setVisible(false)
      aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("yes"))
      local aCenterButton = Button:create(aCenterButtonDisplay)
      aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
    elseif self.boxType == MessageBoxType.kSpeakLimitWarning then
      if self.arg and self.arg.warningMessage then
        aString = self.arg.warningMessage
      end
      aLeftButtonDisplay:setVisible(false)
      aRightButtonDisplay:setVisible(false)
      aCenterButtonDisplay:getChildByName("txt_center"):setString(Localization:getInstance():getText("silenced_Btn"))
      local aCenterButton = Button:create(aCenterButtonDisplay)
      aCenterButton:addEventListener( Events.kStart, centerButtonAction, self )
    end
    
    aExampleLabel:setString(aString)
	if aString ~= "" then
		local aMultiple = aExampleLabel:getTexture():getContentSize().height / aBaseHeight
		if aMultiple > (1.0 - 0.1) and aMultiple < (1.0 + 0.1) then
			aMessageLabelOne:setHorizontalAlignment(kCCTextAlignmentCenter)
		else
			aMessageLabelOne:setHorizontalAlignment(kCCTextAlignmentLeft)
		end
	end 
    aMessageLabelOne:setString(aString)
    aMessageLabelTwo:setVisible(false)
    
    self.tempLayer:setScale(0.1)
end

function MessageBoxPanel:dispose()
  self.exampleBuild:dispose()
  MessageBoxPanel.super.dispose(self)
end

function MessageBoxPanel:scaleIn()
  self.tempLayer.touchEnabled = false
  self.tempLayer.touchChildren = false
  local function scaleInFinished()
    Set_ShareData( "PopoutFinished_And_Can_Click_Now", 1 ) --传递动画播放完的信号
    self.tempLayer.touchEnabled = true
    self.tempLayer.touchChildren = true
  end
  local arr = CCArray:create()
  arr:addObject(CCEaseSineOut:create(CCScaleTo:create(0.3, 1.0)))
  arr:addObject(CCCallFunc:create(scaleInFinished))
  self.tempLayer:runAction(CCSequence:create(arr))

  --添加的二级堆栈
  UiStackManager.push(self)
end