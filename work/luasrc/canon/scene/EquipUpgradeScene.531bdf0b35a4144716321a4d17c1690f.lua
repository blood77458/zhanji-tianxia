require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.Button"
require "hecore.display.Sprite"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "canon.data.MetaManager"
require "canon.request.UpgradeEquipRequest"
require "canon.request.QuickUpgradeEquipRequest"
require "canon.panel.MessageBoxPanel"
require "canon.customUI.SuspensionLabel"
require "canon.request.GetBabelInfoRequest"
require "canon.panel.AttributeChangePanel"

local EquipPropertyEnum = {kHp = "Hp", kAttack = "Attack", kDefence = "Defence"}
local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local enter_animation_duration = 0.3

--
-- EquipUpgradeScene
--

local function existIntInComplexString(aInt, aString, aDelimiter)
  local aTable = aString:split(aDelimiter)
  for _, v in ipairs(aTable) do
    if string.format("%d", aInt) == v then
      return true
    end
  end
  return false
end

local function upgradeButtonAction(evt)
  local aScene = evt.context
  CanonPlayEffect("music/sfx_amer_evolve.wav")
  
  local currUser = DataManager.getCurrUser()
  
  if currUser.level <= aScene.equip.level then
    aScene:showUserLevelLimitPanel()
    return
  end
  
  if aScene.upgradeCost > tonumber(currUser.coins, 10) then
    aScene:showCoinLimitPanel()
    return
  end
  
  local function upgradeEquipSucceed(event)
    RewardManager:gainReward({itemType = ResourceEnum.COIN, amount = -aScene.upgradeCost})
    local previous_strength = CommonManager:getLocalPlayerStrength()
    
    local aNewEquip = event.data.sharkEquip
    local aSharkEquips = DataManager.getEquipsData()
    --print(table.tostring(aSharkEquips))
    for aIndex, aEquip in pairs(aSharkEquips) do
      if aEquip.equipId == aNewEquip.equipId then
        table.remove(aSharkEquips, aIndex)
        break
      end
    end
    table.insert(aSharkEquips, aNewEquip)
    DataManager.setEquipsData(aSharkEquips)
    aScene.equip = aNewEquip
    if aScene.argv.originalScene == "EquipQuickUpgradeScene"  then
       -- aScene.argv.params.container.queue[aScene.argv.params.cardPos].equips[aScene.argv.params.EquipPos] = aNewEquip
       aScene.argv.params.equip = aNewEquip
    end
    aScene:refreshSelf()
    local aContent = Localization:getInstance():getText("equipEnhance_Success")
    SuspensionLabel:showContent(aScene, aContent)
    
    local fspt = FlashSprite:create("EVO2/equip")
    fspt:changeAnimation(0)
    fspt:setLoop(false)
    local fspt_co = CocosObject.new(fspt)
    fspt:setPosition(aScene.flashPos.x, aScene.flashPos.y - visibleSize.height)
    aScene:addChild(fspt_co)
          
    --显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
    DataManager.fightCapacityMaybeUpdated()
  end
  local function upgradeEquipFailed(event)
    if event.data.retCode == 710512 then
      aScene:showCoinLimitPanel()
    elseif event.data.retCode == 712509 then
      aScene:showUserLevelLimitPanel()
    elseif event.data.retCode == 712510 then
      aScene:showEvolveLevelLimitPanel()
    end
  end 
  local params = {equipId = aScene.equip.equipId}
  local request = UpgradeEquipRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.UpgradeEquipSucceed, upgradeEquipSucceed)
  request:addEventListener(RequestNotifyEnum.UpgradeEquipFailed, upgradeEquipFailed)
  request:start()
end

local function evolveButtonAction(evt)
  local aScene = evt.context
  if aScene.argv.originalScene == "EquipQuickUpgradeScene" then
    aScene.argv.returnScene = "EquipUpgradeScene"
    aScene.argv.enterScene = "EquipUpgradeScene"
    aScene:replaceScene(EquipEvolveScene,aScene.argv)
  else
    aScene:replaceScene(EquipEvolveScene, {enterScene="EquipUpgradeScene",returnScene="EquipUpgradeScene",params=aScene.equip,originalScene=aScene.argv.originalScene or aScene.argv.enterScene})
  end
end

local function quickUpgradeButtonAction(evt)
  local aScene = evt.context
  CanonPlayEffect("music/sfx_amer_evolve.wav")
  
  local currUser = DataManager.getCurrUser()
  
  if currUser.level <= aScene.equip.level then
    aScene:showUserLevelLimitPanel()
    return
  end
  
  if aScene.quickUpgradeCost == 0 then
    aScene:showCoinLimitPanel()
    return
  end
  
  local function quickUpgradeEquipSucceed(event)
    RewardManager:gainReward({itemType = ResourceEnum.COIN, amount = -aScene.quickUpgradeCost})
    local previous_strength = CommonManager:getLocalPlayerStrength()
    
    local aNewEquip = event.data.sharkEquip
    local aSharkEquips = DataManager.getEquipsData()
    --print(table.tostring(aSharkEquips))
    for aIndex, aEquip in pairs(aSharkEquips) do
      if aEquip.equipId == aNewEquip.equipId then
        table.remove(aSharkEquips, aIndex)
        break
      end
    end
    table.insert(aSharkEquips, aNewEquip)
    DataManager.setEquipsData(aSharkEquips)
    local aContent = Localization:getInstance():getText("equipEnhance_swiftEnhanceSuccess", {num = aScene.quickUpgradeLevel})
    SuspensionLabel:showContent(aScene, aContent)
    if aScene.argv.originalScene == "EquipQuickUpgradeScene"  then
       -- aScene.argv.params.container.queue[aScene.argv.params.cardPos].equips[aScene.argv.params.EquipPos] = aNewEquip
       aScene.argv.params.equip = aNewEquip
    end
    aScene.equip = aNewEquip
    aScene:refreshSelf()
    
    local fspt = FlashSprite:create("EVO2/equip")
    fspt:changeAnimation(0)
    fspt:setLoop(false)
    local fspt_co = CocosObject.new(fspt)
    fspt:setPosition(aScene.flashPos.x, aScene.flashPos.y - visibleSize.height)
    aScene:addChild(fspt_co)
          
    --显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
    DataManager.fightCapacityMaybeUpdated()
  end
  local function quickUpgradeEquipFailed(event)
    if event.data.retCode == 710512 then
      aScene:showCoinLimitPanel()
    elseif event.data.retCode == 712509 then
      aScene:showUserLevelLimitPanel()
    elseif event.data.retCode == 712510 then
      aScene:showEvolveLevelLimitPanel()
    end
  end 
  local params = {equipId = aScene.equip.equipId}
  local request = QuickUpgradeEquipRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.QuickUpgradeEquipSucceed, quickUpgradeEquipSucceed)
  request:addEventListener(RequestNotifyEnum.QuickUpgradeEquipFailed, quickUpgradeEquipFailed)
  request:start()
end

EquipUpgradeScene = class(BaseUIScene)

function EquipUpgradeScene:ctor()
	
end

function EquipUpgradeScene:create(argv)
  if argv then 
        self.argv = argv 
    else
        self.argv = {enterScene=nil,returnScene=nil,params={}}
    end
  local s = EquipUpgradeScene.new()
  if self.argv.originalScene == "EquipQuickUpgradeScene" then
    -- print("~~~~~~~~~~~~~~~~~~~self.argv.params.equip = "..tostringRich(self.argv))
    self.equip = self.argv.params.equip
  else
    self.equip = self.argv.params
  end
  s:initScene()
  return s
end

function EquipUpgradeScene:onInit()
	BaseUIScene.initBackGround(self)
  
  self.title = Localization:getInstance():getText("equipEnhance_Title")
  
  local builder = LayoutBuilder:createWithContentsOfFile("scene/equip_new.json")
  builder.useArtLabelTTF = true
  local ui = builder:build("equip_equipEnhance")
  self:addChild(ui)
  
  self.uiGroup1 = ui:getChildByName("equipEnhance_equip")
  self.uiGroup1:getChildByName("equip_normal_card_small_sb"):setVisible(false)
  self.uiGroup1:getChildByName("equip_txt_equip_Des"):setVisible(false)
  self.uiGroup1:getChildByName("equip_pattern_cardInfor_line"):setVisible(false)
  for i = 1, 3 do
    self.uiGroup1:getChildByName(string.format("equip_txt_equip_suit%d", i)):setVisible(false)
  end
  
  --[[
  local equipDesLabel = self.uiGroup1:getChildByName("txt_equip_Des")
  local equipDesPosX = equipDesLabel:getPositionX()
  local equipDesPosY = equipDesLabel:getPositionY()
  equipDesLabel = equipDesLabel:getChildByName("txt")
  local aWidth = equipDesLabel:getDimensions().width
  local aFontName = equipDesLabel:getFontName()
  local aFontSize = equipDesLabel:getFontSize()
  local aFontColor = equipDesLabel:getColor()
  local aReplaceDesLabel = TextField:create("", aFontName, aFontSize, CCSizeMake(aWidth, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
  aReplaceDesLabel:setColor(aFontColor)
  aReplaceDesLabel:setAnchorPoint(ccp(0, 1))
  aReplaceDesLabel:setPosition(ccp(equipDesPosX, equipDesPosY))
  aReplaceDesLabel.name = "replace_equip_Des"
  self.uiGroup1:addChildAt(aReplaceDesLabel, 100)
  self.replaceDesLabel = aReplaceDesLabel
  ]]
  
  self.uiGroup4 = ui:getChildByName("btn_evolve")
  local equipButtonLabel = self.uiGroup4:getChildByName("txt_equip_Enhance")
  equipButtonLabel:setString(Localization:getInstance():getText("equip_Enhance"))
  self.upgradeButton = Button:create(self.uiGroup4)
  self.upgradeButton:addEventListener( Events.kStart, upgradeButtonAction, self )
  
  self.uiGroup2 = ui:getChildByName("bg_equipEnhance")
  
  self.uiGroup3 = ui:getChildByName("equipEhance_maxlv")
  self.uiGroup3:getChildByName("equip_txt_txt_equipEnhance_Tips"):getChildByName("txt_equipEnhance_Tips"):setString(Localization:getInstance():getText("equipEvolve_Tips"))
  self.uiGroup3:getChildByName("equip_txt_equip_CoinConsume"):getChildByName("txt_equip_CoinConsume"):setString(Localization:getInstance():getText("equipEnhance_CoinConsume"))
  self.uiGroup3:getChildByName("equip_txt_equipEnhance_Tips"):getChildByName("txt_equipEnhance_Tips"):setString(Localization:getInstance():getText("equipEnhance_Tips"))
  local evolveButtonDisplay = self.uiGroup3:getChildByName("equip_btn_equip_Evolve")
  self.evolveButton = Button:create(evolveButtonDisplay)
  self.evolveButton:addEventListener( Events.kStart, evolveButtonAction, self )
  local evolveLabel = evolveButtonDisplay:getChildByName("txt_equip_Evolve")
  evolveLabel:setString(Localization:getInstance():getText("equip_Evolve"))
  
  self.uiGroup5 = ui:getChildByName("btn_evolve_1")
  local equipButtonLabel2 = self.uiGroup5:getChildByName("txt_equip_Enhance")
  equipButtonLabel2:setString(Localization:getInstance():getText("equip_Enhance"))
  self.upgradeButton2 = Button:create(self.uiGroup5)
  self.upgradeButton2:addEventListener( Events.kStart, upgradeButtonAction, self )
  
  self.uiGroup6 = ui:getChildByName("equip_btn_evolve_all")
  local equipButtonLabel3 = self.uiGroup6:getChildByName("txt_equip_Enhance")
  equipButtonLabel3:setString(Localization:getInstance():getText("equipEnhance_swiftEnhanceBtn"))
  self.quickUpgradeButton = Button:create(self.uiGroup6)
  self.quickUpgradeButton:addEventListener( Events.kStart, quickUpgradeButtonAction, self )
  
  self.equipItem = nil
  self.flashPos = nil
  self.descPanel = nil
  
  self:refreshSelf()
  
	BaseUIScene.onInit(self)
end

function EquipUpgradeScene:refreshSelf()
  local quickUpgradeUnlock = existIntInComplexString(18, MetaManager.vip_setting[DataManager.getCurrUser().vipLevel].unlockContents, ",")
  
  self.equipMetaConfig = NULL
  self.equipProperty = NULL
  self.equipLevelConfig = NULL
  self.nextEquipLevelConfig = NULL
  self.propertyValue = 0
  self.additionPropertyValue = 0
  self.equipEvolveLevelConfig = NULL
  self.upgradeCost = 0
  
  self.equipMetaConfig = MetaManager.equip_meta[tonumber(self.equip.metaId, 10)]
  self.equipLevelConfig = MetaManager.equip_level[self.equip.level]
  
  if tonumber(self.equipMetaConfig.basicAtk, 10) > 0 then
    self.equipProperty = EquipPropertyEnum.kAttack
    self.propertyValue = self.equipMetaConfig.basicAtk + self.equipMetaConfig.atkSCoe * self.equipLevelConfig.atk
  elseif tonumber(self.equipMetaConfig.basicDefence, 10) > 0 then
    self.equipProperty = EquipPropertyEnum.kDefence
    self.propertyValue = self.equipMetaConfig.basicDefence + self.equipMetaConfig.defSCoe * self.equipLevelConfig.def
  elseif tonumber(self.equipMetaConfig.basicHp, 10) > 0 then
    self.equipProperty = EquipPropertyEnum.kHp
    self.propertyValue = self.equipMetaConfig.basicHp + self.equipMetaConfig.hpSCoe * self.equipLevelConfig.hp
  end
  self.propertyValue = math.modf(self.propertyValue)
  
  for _, v in ipairs(MetaManager.equip_evolve_level) do
    if tonumber(self.equipMetaConfig.evolveLevel, 10) == tonumber(v.evolveLevel, 10) then
      self.equipEvolveLevelConfig = v
      break
    end
  end
  
  if self.equipItem then
    self.equipItem:removeFromParentAndCleanup(true)
    self.equipItem = nil
  end
  
  if self.descPanel then
    self.descPanel:removeFromParentAndCleanup(true)
    self.descPanel = nil
  end
  
  local equipDisplay = self.uiGroup1:getChildByName("equip_normal_card_small_sb")
  self.equipItem = CanonItem:create()
  self.equipItem:loadByMetaId(self.equip.metaId)
  self.equipItem:setPosition(ccp(equipDisplay:getPositionX(), equipDisplay:getPositionY()))
  self.equipItem:setScale(134.0/146.0)
  self.uiGroup1:addChild(self.equipItem)
  self.flashPos = self.uiGroup1:convertToWorldSpace(ccp(equipDisplay:getPositionX(), equipDisplay:getPositionY()))
  
  local equipNameLabel = self.uiGroup1:getChildByName("equip_txt_skillEnhance_skillName"):getChildByName("txt_skillEnhance_skillName")
  equipNameLabel:setString(Localization:getInstance():getText(self.equipMetaConfig.name))
  
  for i = 1, 7 do
    local aQualityPanel = self.uiGroup1:getChildByName(string.format("equip_panel%d", i))
    aQualityPanel:setVisible(false)
  end
  self.uiGroup1:getChildByName(string.format("equip_panel%d", self.equipMetaConfig.quality)):setVisible(true)
  
  local lvLabel = self.uiGroup1:getChildByName("equip_txt_equip_lv_num"):getChildByName("font")
  lvLabel:setString(string.format("%d/%d", self.equip.level, self.equipEvolveLevelConfig.levelMax))
  
  local defIcon = self.uiGroup1:getChildByName("equip_icon_def")
  defIcon:setVisible(false)
  local attIcon = self.uiGroup1:getChildByName("equip_icon_atk")
  attIcon:setVisible(false)
  local hpIcon = self.uiGroup1:getChildByName("equip_icon_hp")
  hpIcon:setVisible(false)
  if self.equipProperty == EquipPropertyEnum.kAttack then
    attIcon:setVisible(true)
  elseif self.equipProperty == EquipPropertyEnum.kDefence then
    defIcon:setVisible(true)
  elseif self.equipProperty == EquipPropertyEnum.kHp then
    hpIcon:setVisible(true)
  end
  
  local propertyValueLabel = self.uiGroup1:getChildByName("equip_txt_icon_silverCoin_test_num"):getChildByName("font")
  propertyValueLabel:setString(string.format("%d", self.propertyValue))
  
  local cardInfo = self.uiGroup1:getChildByName("equip_txt_equip_equipedby")
  local inequip_display = self.uiGroup1:getChildByName("equip_in_equip_sb")
  self.uiGroup1:setChildIndex(inequip_display, 100)
  --inequip_display:setZOrder(100)
  local inequip_label = self.uiGroup1:getChildByName("equip_txt_in_equip")
  --inequip_label:setZOrder(101)
  self.uiGroup1:setChildIndex(inequip_label, 101)
  inequip_label:getChildByName("txt"):setString(Localization:getInstance():getText("equip_equipped"))
  local aCardId = self.equip.cardId
	if (aCardId~=0) then
    cardInfo:setVisible(true)
    inequip_display:setVisible(true)
    inequip_label:setVisible(true)
		local cardsData = DataManager.getCardsData()
		local aCardMeta = CommonManager.getSubTableByKey(
			cardsData,
			{name="cardId", value=aCardId}
		).metaId
		local aCardName = MetaManager.card_meta[aCardMeta].name
		cardInfo:getChildByName("txt_equip_equipedby"):setString(Localization:getInstance():getText("bag_EquippedText",{cardname = getTextByKey(aCardName)}))
	else
    inequip_display:setVisible(false)
		cardInfo:setVisible(false)
    inequip_label:setVisible(false)
	end
  for i = 1, self.equipMetaConfig.quality do
    local aStarDisplay = self.uiGroup1:getChildByName(string.format("equip_icon_star_%d", i))
    aStarDisplay:setVisible(true)
  end
  for i = self.equipMetaConfig.quality + 1, 7 do
    local aStarDisplay = self.uiGroup1:getChildByName(string.format("equip_icon_star_%d", i))
    aStarDisplay:setVisible(false)
  end
  
  self.descPanel = CardDescPanel:create(
		self.equip.metaId,
		{height=185, width=620},
		ccc3(0,0,0)
	)
  self.descPanel:setViewPosition(13,-218)
	self.uiGroup1:addChildAt(self.descPanel, 1001)
  
  --[[
  self.replaceDesLabel:setString(Localization:getInstance():getText(self.equipMetaConfig.desc))
  
  local equipSuits = {}
  for _, v in ipairs(MetaManager.equip_suit) do
    if tonumber(v.equipId, 10) == tonumber(self.equipMetaConfig.prefixId, 10) then
      local temp = {}
      temp.activeAttr = tonumber(v.activeAttr)
      temp.valueType = tonumber(v.valueType)
      temp.effectValue = tonumber(v.effectValue)
      local cardGroupId = tonumber(v.cardGroupId, 10)
      for _, aCardMeta in pairs(MetaManager.card_meta) do
        if cardGroupId == tonumber(aCardMeta.cardGroupId, 10) then
          temp.cardName = Localization:getInstance():getText(aCardMeta.name)
          break
        end
      end
      table.insert(equipSuits, temp)
    end
  end
  for i, aSuit in ipairs(equipSuits) do
    local suitLabel = self.uiGroup1:getChildByName(string.format("txt_equip_suit%d", i)):getChildByName("txt")
    local aNum
    if aSuit.valueType == 1 then
      aNum = string.format("%d%%", aSuit.effectValue * 100)
    else
      aNum = string.format("%d", aSuit.effectValue)
    end
    local aAttr
    if aSuit.activeAttr == 1 then
      aAttr = Localization:getInstance():getText("attr_Attack")
    elseif aSuit.activeAttr == 2 then
      aAttr = Localization:getInstance():getText("attr_Defense")
    else
      aAttr = Localization:getInstance():getText("attr_HP")
    end
    suitLabel:setVisible(true)
    suitLabel:setString(Localization:getInstance():getText("equip_SkillDesc", {cardname = aSuit.cardName, num = aNum, attr = aAttr}))
  end
  for i = #equipSuits + 1, 3 do
    local suitLabel = self.uiGroup1:getChildByName(string.format("txt_equip_suit%d", i))
    suitLabel:setVisible(false)
  end]]
  
  local beforeUpgradeLevelLabel = self.uiGroup3:getChildByName("equip_txt_equip_lv_num_L")
  beforeUpgradeLevelLabel:getChildByName("font"):setString(string.format("%d/%d", self.equip.level, tonumber(self.equipEvolveLevelConfig.levelMax, 10)))
  local defIcon_L = self.uiGroup3:getChildByName("equip_icon_def_L")
  defIcon_L:setVisible(false)
  local attIcon_L = self.uiGroup3:getChildByName("equip_icon_atk_L")
  attIcon_L:setVisible(false)
  local hpIcon_L = self.uiGroup3:getChildByName("equip_icon_hp_L")
  hpIcon_L:setVisible(false)
  if self.equipProperty == EquipPropertyEnum.kAttack then
    attIcon_L:setVisible(true)
  elseif self.equipProperty == EquipPropertyEnum.kDefence then
    defIcon_L:setVisible(true)
  elseif self.equipProperty == EquipPropertyEnum.kHp then
    hpIcon_L:setVisible(true)
  end
  local propertyValueLabel_L = self.uiGroup3:getChildByName("equip_txt_equip_icon_atk_num_L"):getChildByName("font")
  propertyValueLabel_L:setString(string.format("%d", self.propertyValue))
  
  local maxEvolveLevelLabel = self.uiGroup3:getChildByName("equip_txt_txt_equipEnhance_Tips")
  local maxEvolveLevelDisplay = self.uiGroup3:getChildByName("equip_icon_max_big")
  local maxUpgradeLevelLabel = self.uiGroup3:getChildByName("equip_txt_equipEnhance_Tips")
  local maxUpgradeLevelDisplay = self.uiGroup3:getChildByName("equip_icon_max")
  local evolveButtonDisplay = self.uiGroup3:getChildByName("equip_btn_equip_Evolve")
  local normalLvTitle = self.uiGroup3:getChildByName("equip_icon_lv_R")
  local normalLvNumLabel = self.uiGroup3:getChildByName("equip_txt_equip_lv_num_R")
  local normalLvNumLabel2 = self.uiGroup3:getChildByName("equip_txt_equipEnhance_num_L")
  local defIcon_R = self.uiGroup3:getChildByName("equip_icon_def_R")
  defIcon_R:setVisible(false)
  local attIcon_R = self.uiGroup3:getChildByName("equip_icon_atk_R")
  attIcon_R:setVisible(false)
  local hpIcon_R = self.uiGroup3:getChildByName("equip_icon_hp_R")
  hpIcon_R:setVisible(false)
  local normalPropertyLabel = self.uiGroup3:getChildByName("equip_txt_equip_icon_atk_num_R")
  local normalAdd = self.uiGroup3:getChildByName("equip_txt_plus")
  local normalCostTitle = self.uiGroup3:getChildByName("equip_txt_equip_CoinConsume")
  local normalCostCoin = self.uiGroup3:getChildByName("equip_icon_silverCoin")
  local normalCostNumLabel = self.uiGroup3:getChildByName("equip_txt_equip_CoinConsume_num")
  
  if self.equip.level < tonumber(self.equipEvolveLevelConfig.levelMax, 10) then
    self.quickUpgradeCost = 0
    self.quickUpgradeLevel = 0
    local currUser = DataManager.getCurrUser()
    local tempMaxLevel = math.min(tonumber(self.equipEvolveLevelConfig.levelMax, 10), currUser.level)
    for i = self.equip.level, tempMaxLevel - 1 do
      local aEquipLevelConfig = MetaManager.equip_level[i]
      local aCost = tonumber(self.equipMetaConfig.coinConsumeCoe, 10) * tonumber(aEquipLevelConfig.upgradeCoinBase, 10)
      if (self.quickUpgradeCost + math.modf(aCost)) <= tonumber(currUser.coins, 10) then
        self.quickUpgradeCost = self.quickUpgradeCost + aCost
        self.quickUpgradeCost = math.modf(self.quickUpgradeCost)
        self.quickUpgradeLevel = i + 1
      else
        break
      end
    end
    
    self.nextEquipLevelConfig = MetaManager.equip_level[self.equip.level + 1]
    if tonumber(self.equipMetaConfig.basicAtk, 10) > 0 then
      self.additionPropertyValue = math.modf(self.equipMetaConfig.basicAtk + self.equipMetaConfig.atkSCoe * self.nextEquipLevelConfig.atk) - self.propertyValue
    elseif tonumber(self.equipMetaConfig.basicDefence, 10) > 0 then
      self.additionPropertyValue = math.modf(self.equipMetaConfig.basicDefence + self.equipMetaConfig.defSCoe * self.nextEquipLevelConfig.def) - self.propertyValue
    elseif tonumber(self.equipMetaConfig.basicHp, 10) > 0 then
      self.additionPropertyValue = math.modf(self.equipMetaConfig.basicHp + self.equipMetaConfig.hpSCoe * self.nextEquipLevelConfig.hp) - self.propertyValue
    end
    
    maxEvolveLevelLabel:setVisible(false)
    maxEvolveLevelDisplay:setVisible(false)
    maxUpgradeLevelLabel:setVisible(false)
    maxUpgradeLevelDisplay:setVisible(false)
    evolveButtonDisplay:setVisible(false)
    self.evolveButton:setEnable(false)
    
    normalLvTitle:setVisible(true)
    normalLvNumLabel:setVisible(true)
    local normalLvNumLabel_txt = normalLvNumLabel:getChildByName("font")
    normalLvNumLabel_txt:setString(string.format("/%d", tonumber(self.equipEvolveLevelConfig.levelMax, 10)))
    normalLvNumLabel2:setVisible(true)
    local normalLvNumLabel2_txt = normalLvNumLabel2:getChildByName("font")
    normalLvNumLabel2_txt:setDimensions(CCSizeMake(0, normalLvNumLabel2_txt:getDimensions().height))
    normalLvNumLabel2_txt:setString(string.format("%d", self.equip.level + 1))
    normalLvNumLabel2_txt:setColor(ccc3(0,255,0))
    normalLvNumLabel:setPositionX(normalLvNumLabel2:getPositionX() + normalLvNumLabel2_txt:getTexture():getContentSize().width + 2)
    
    if self.equipProperty == EquipPropertyEnum.kAttack then
      attIcon_R:setVisible(true)
    elseif self.equipProperty == EquipPropertyEnum.kDefence then
      defIcon_R:setVisible(true)
    elseif self.equipProperty == EquipPropertyEnum.kHp then
      hpIcon_R:setVisible(true)
    end
    normalPropertyLabel:setVisible(true)
    normalPropertyLabel:getChildByName("font"):setString(string.format("%d", self.propertyValue))
    normalAdd:setVisible(true)
    normalAdd:getChildByName("txt_plus"):setString(string.format("+%d", self.additionPropertyValue))
    normalAdd:getChildByName("txt_plus"):setColor(ccc3(0,255,0))
    normalCostTitle:setVisible(true)
    normalCostCoin:setVisible(true)
    normalCostNumLabel:setVisible(true)
    self.upgradeCost = CalculationManager.calcEquip_getEquipUpgradeCost( self.equip )
    self.upgradeCost = math.modf(self.upgradeCost)
    normalCostNumLabel:getChildByName("font"):setString(string.format("%d", self.upgradeCost))
    
    self:setButtonState(quickUpgradeUnlock, true)
  elseif self.equipMetaConfig.evolveLevel < self.equipMetaConfig.maxEvolveLevel then
    maxEvolveLevelLabel:setVisible(false)
    maxEvolveLevelDisplay:setVisible(false)
    maxUpgradeLevelLabel:setVisible(true)
    maxUpgradeLevelDisplay:setVisible(true)
    evolveButtonDisplay:setVisible(true)
    self.evolveButton:setEnable(true)
    normalLvTitle:setVisible(false)
    normalLvNumLabel:setVisible(false)
    normalLvNumLabel2:setVisible(false)
    normalPropertyLabel:setVisible(false)
    normalAdd:setVisible(false)
    normalCostTitle:setVisible(false)
    normalCostCoin:setVisible(false)
    normalCostNumLabel:setVisible(false)
    
    self:setButtonState(quickUpgradeUnlock, false)
  else
    maxEvolveLevelLabel:setVisible(true)
    maxEvolveLevelDisplay:setVisible(true)
    maxUpgradeLevelLabel:setVisible(false)
    maxUpgradeLevelDisplay:setVisible(false)
    evolveButtonDisplay:setVisible(false)
    self.evolveButton:setEnable(false)
    normalLvTitle:setVisible(false)
    normalLvNumLabel:setVisible(false)
    normalLvNumLabel2:setVisible(false)
    normalPropertyLabel:setVisible(false)
    normalAdd:setVisible(false)
    normalCostTitle:setVisible(false)
    normalCostCoin:setVisible(false)
    normalCostNumLabel:setVisible(false)
    
    self:setButtonState(quickUpgradeUnlock, false)
  end
end

function EquipUpgradeScene:setButtonState(quickUpgradeUnlock, whetherEnabled)
  if quickUpgradeUnlock then
    self.uiGroup4:setVisible(false)
    self.upgradeButton:setEnable(false)
    if whetherEnabled then
      self.uiGroup5:getChildByName("btn"):setVisible(true)
      self.uiGroup5:getChildByName("disable"):setVisible(false)
      self.upgradeButton2:setEnable(true)
      self.uiGroup6:getChildByName("btn"):setVisible(true)
      self.uiGroup6:getChildByName("disable"):setVisible(false)
      self.quickUpgradeButton:setEnable(true)
    else
      self.uiGroup5:getChildByName("btn"):setVisible(false)
      self.uiGroup5:getChildByName("disable"):setVisible(true)
      self.upgradeButton2:setEnable(false)
      self.uiGroup6:getChildByName("btn"):setVisible(false)
      self.uiGroup6:getChildByName("disable"):setVisible(true)
      self.quickUpgradeButton:setEnable(false)
    end
  else
    if whetherEnabled then
      self.uiGroup4:getChildByName("btn"):setVisible(true)
      self.uiGroup4:getChildByName("disable"):setVisible(false)
      self.upgradeButton:setEnable(true)
    else
      self.uiGroup4:getChildByName("btn"):setVisible(false)
      self.uiGroup4:getChildByName("disable"):setVisible(true)
      self.upgradeButton:setEnable(false)
    end
    self.uiGroup5:setVisible(false)
    self.upgradeButton2:setEnable(false)
    self.uiGroup6:setVisible(false)
    self.quickUpgradeButton:setEnable(false)
  end
end

function EquipUpgradeScene:moveToCityMainScene()
  --[[
  local argv = {enterScene="EquipUpgradeScene",returnScene=nil,params={}}
  self:replaceScene(ChapterMapScene, argv)
  ]]
  self:moveToMap()
end

function EquipUpgradeScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function EquipUpgradeScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  --
  CanonPlayBackgroundMusic("music/background.mp3", true)
end

function EquipUpgradeScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.uiGroup1:setPositionX(self.uiGroup1:getPositionX() - visibleSize.width)
  self.uiGroup1:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  self.uiGroup2:setPositionX(self.uiGroup2:getPositionX() - visibleSize.width)
  self.uiGroup2:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  self.uiGroup3:setPositionX(self.uiGroup3:getPositionX() - visibleSize.width)
  self.uiGroup3:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  self.uiGroup5:setPositionX(self.uiGroup5:getPositionX() - visibleSize.width)
  self.uiGroup5:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  self.uiGroup6:setPositionX(self.uiGroup6:getPositionX() - visibleSize.width)
  self.uiGroup6:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  self.uiGroup4:setPositionX(self.uiGroup4:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.uiGroup4:runAction(CCSequence:create(arr))
end

function EquipUpgradeScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  --
end

function EquipUpgradeScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function EquipUpgradeScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function EquipUpgradeScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.uiGroup1:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  self.uiGroup2:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  self.uiGroup3:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  self.uiGroup5:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  self.uiGroup6:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.uiGroup4:runAction(CCSequence:create(arr))
end

function EquipUpgradeScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function EquipUpgradeScene:panelDismiss()
  
end

function EquipUpgradeScene:moveToTower()
  --[[
  local function Success(event)
    if event ~= nil then
      DataManager.GetBabelInfoData = event.data
      DataManager.GetBabelInfoData._DownloadDataTime = TimeUtil.getServerTimeSeconds()
    end
    self:replaceScene(SkyTowerMainScene)
  end
  local function Failed(event)
    if event.data == 713103 then
      local aContent = Localization:getInstance():getText("babel_levelInsufficient", {num = MetaManager.game_meta.gameSettingConfig.babelConfig.babelTowerUnlockLevel})
      SuspensionLabel:showContent(self, aContent)
    end
  end
  local params = {}
  local getBabelInfoRequest = GetBabelInfoRequest.new(params, rpc.SendingPriority.kHigh)
  getBabelInfoRequest:addEventListener(RequestNotifyEnum.GetBabelInfoSucceed, Success)
  getBabelInfoRequest:addEventListener(RequestNotifyEnum.GetBabelInfoFailed, Failed)
  getBabelInfoRequest:start()]]
  ChallengeEntersScene.readyToNewBabelEnterPanel()
end

function EquipUpgradeScene:back()
  if self.argv.returnScene == "BackpackScene" then
		local equipId
		if self.equip then
			equipId = self.equip.equipId
		end
    self:replaceScene(BackpackScene, {enterScene="EquipUpgradeScene",returnScene=nil,params={tabIndex = BAGCATEGORY.equip, equipId = equipId}})
  elseif self.argv.returnScene == "EquipEvolveScene" then
    if self.argv.originalScene == "EquipQuickUpgradeScene" then
      self.argv.enterScene = "EquipQuickUpgradeScene"
      self.argv.returnScene = "EquipQuickUpgradeScene"
      self:replaceScene( EquipEvolveScene , self.argv)
    else
      local argv = {enterScene="EquipUpgradeScene",returnScene=self.argv.originalScene,params=self.equip}
      self:replaceScene( EquipEvolveScene , argv)
    end
  elseif self.argv.returnScene == "EquipQuickUpgradeScene" then
    self.argv.enterScene = "CardQueueScene"
    self.argv.returnScene = "CardQueueScene"
    self:replaceScene( EquipQuickUpgradeScene , self.argv)
  elseif self.argv.returnScene == "CardQueueScene" then
    local argv = {enterScene="EquipUpgradeScene",returnScene=nil,params=nil}
    self:replaceScene( CardQueueScene , argv)
  else
    self:replaceScene(MainMenuScene)
  end
end

function EquipUpgradeScene:showCoinLimitPanel()
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kCoinLimit)
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function EquipUpgradeScene:showUserLevelLimitPanel()
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kEquipUpgradeLevelLimit)
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function EquipUpgradeScene:showEvolveLevelLimitPanel()
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kEquipUpgradeEvolveLevelLimit)
  self:addChild(aPanel)
  aPanel:scaleIn()
end