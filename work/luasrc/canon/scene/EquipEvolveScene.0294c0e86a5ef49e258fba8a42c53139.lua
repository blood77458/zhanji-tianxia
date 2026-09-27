require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.Button"
require "hecore.display.Sprite"
require "hecore.ui.LayoutBuilder"
require "canon.scene.BaseUIScene"
require "canon.data.MetaManager"
require "canon.request.EvolveEquipRequest"
require "canon.panel.MessageBoxPanel"
require "canon.models.CommonManager"
require "canon.scene.EquipUpgradeScene"
require "canon.customUI.SuspensionLabel"
require "canon.request.GetBabelInfoRequest"
require "canon.models.CommonManager"

local EquipPropertyEnum = {kHp = "Hp", kAttack = "Attack", kDefence = "Defence"}
local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local enter_animation_duration = 0.3

local function evolveButtonAction(evt)
  local aScene = evt.context
  
  local arg = {}
  arg.coinCost = aScene.evolveCost
  arg.gemCost = 0
  arg.propNumList = aScene.propNumList
  arg.equipId = aScene.equip.equipId
  arg.useGems = false
  aScene:startEvolveEquip(arg)
end

local function upgradeButtonAction(evt)
  local aScene = evt.context
  if aScene.argv.originalScene == "EquipQuickUpgradeScene" then
      -- aScene.argv.originalScene = aScene.argv.enterScene
      -- print("~~~~~~~~~~~~~~~~~~~~~~~~进来了")
      aScene.argv.enterScene = "EquipEvolveScene"
      aScene.argv.returnScene = "EquipEvolveScene"
      aScene:replaceScene( EquipUpgradeScene , aScene.argv)
  else
    local argv = {enterScene="EquipEvolveScene",returnScene="EquipEvolveScene",params=aScene.equip,originalScene=aScene.argv.originalScene or aScene.argv.enterScene}
    aScene:replaceScene( EquipUpgradeScene , argv)
  end
end

local function materialButtonAction(evt)
  local aScene = evt.context
  
  aScene:showGemsReplacePropPanel()
end


--
-- EquipEvolveScene
--

EquipEvolveScene = class(BaseUIScene)

function EquipEvolveScene:ctor()
	
end

function EquipEvolveScene:create(argv)
  if argv then 
        self.argv = argv 
    else
        self.argv = {enterScene=nil,returnScene=nil,params={}}
    end
  local s = EquipEvolveScene.new()
  if type(self.argv.params.equip) == "table" then
    self.equip = self.argv.params.equip
  else
    self.equip = self.argv.params
  end
  s:initScene()
  return s
end

function EquipEvolveScene:onInit()
	BaseUIScene.initBackGround(self)
  
  self.title = Localization:getInstance():getText("equipEvolve_Title")
  
  local builder = LayoutBuilder:createWithContentsOfFile("scene/equip_new.json")
  builder.useArtLabelTTF = true
  local ui = builder:build("equipEvolve")
  self:addChild(ui)
  self.ui = ui
  
  self.uiGroup1 = ui:getChildByName("equipEvolve_equip")
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
  self.uiGroup1:addChildAt(aReplaceDesLabel, 100)
  self.replaceDesLabel = aReplaceDesLabel
  ]]
  
  self.uiGroup10 = ui:getChildByName("equipEvolve_upper")
  self.uiGroup10:getChildByName("equip_normal_card_small_sb"):setVisible(false)
  self.uiGroup10:getChildByName("equip_txt_equip_Des"):setVisible(false)
  self.uiGroup10:getChildByName("equip_pattern_cardInfor_line"):setVisible(false)
  for i = 1, 3 do
    self.uiGroup10:getChildByName(string.format("equip_txt_equip_suit%d", i)):setVisible(false)
  end
  --[[
  equipDesLabel = self.uiGroup10:getChildByName("txt_equip_Des")
  equipDesPosX = equipDesLabel:getPositionX()
  equipDesPosY = equipDesLabel:getPositionY()
  equipDesLabel = equipDesLabel:getChildByName("txt")
  aWidth = equipDesLabel:getDimensions().width
  aFontName = equipDesLabel:getFontName()
  aFontSize = equipDesLabel:getFontSize()
  aFontColor = equipDesLabel:getColor()
  aReplaceDesLabel = TextField:create("", aFontName, aFontSize, CCSizeMake(aWidth, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
  aReplaceDesLabel:setColor(aFontColor)
  aReplaceDesLabel:setAnchorPoint(ccp(0, 1))
  aReplaceDesLabel:setPosition(ccp(equipDesPosX, equipDesPosY))
  self.uiGroup10:addChildAt(aReplaceDesLabel, 100)
  self.replaceDesLabel2 = aReplaceDesLabel]]
  
  self.uiGroup4 = ui:getChildByName("btn_equipEvolve")
  local equipButtonLabel = self.uiGroup4:getChildByName("txt_equip_Evolve_common")
  equipButtonLabel:setString(Localization:getInstance():getText("equip_Evolve"))
  self.evolveButton = Button:create(self.uiGroup4)
  self.evolveButton:addEventListener( Events.kStart, evolveButtonAction, self )
  
  self.uiGroup7 = ui:getChildByName("btn_equip_Evolve_max")
  equipButtonLabel = self.uiGroup7:getChildByName("txt_equip_Evolve_common")
  equipButtonLabel:setString(Localization:getInstance():getText("equip_Evolve"))
  self.evolveButton2 = Button:create(self.uiGroup7)
  self.evolveButton2:addEventListener( Events.kStart, evolveButtonAction, self )
  
  self.uiGroup2 = ui:getChildByName("bg_equipEvolve")
  
  self.uiGroup5 = ui:getChildByName("bg_equipEvolve_max")
  
  self.uiGroup3 = ui:getChildByName("equipEvolve_material")
  self.uiGroup3:getChildByName("equip_txt_equip_CoinConsume"):getChildByName("txt_equip_CoinConsume"):setString(Localization:getInstance():getText("equipEvolve_CoinConsume"))
  
  self.uiGroup6 = ui:getChildByName("equipEvolve_max")
  self.uiGroup6:getChildByName("equip_txt_txt_equipEnhance_Tips"):getChildByName("txt_equipEnhance_Tips"):setString(Localization:getInstance():getText("equipEvolve_Tips"))
  
  self.uiGroup8 = ui:getChildByName("equipEvolve_max1")
  self.uiGroup8:getChildByName("equip_txt_equipEnhance_Tips"):getChildByName("txt_equipEnhance_Tips"):setString(Localization:getInstance():getText("equipEvolve_Tips2"))
  self.uiGroup8:getChildByName("equip_btn_equip_Evolve"):getChildByName("txt_equip_Evolve"):setString(Localization:getInstance():getText("equip_Enhance"))
  self.upgradeButton = Button:create(self.uiGroup8:getChildByName("equip_btn_equip_Evolve"))
  self.upgradeButton:addEventListener( Events.kStart, upgradeButtonAction, self )
  
  self.uiGroup9 = ui:getChildByName("btn_buyMaterial")
  local evolveButtonDisplay = self.uiGroup9:getChildByName("equip_btn_equip_Evolve_common")
  evolveButtonDisplay:getChildByName("txt_equip_Evolve_common"):setString(Localization:getInstance():getText("equip_Evolve"))
  self.evolveButton3 = Button:create(evolveButtonDisplay)
  self.evolveButton3:addEventListener( Events.kStart, evolveButtonAction, self )
  local materialButtonDisplay = self.uiGroup9:getChildByName("equip_btn_buyMaterialBtn")
  materialButtonDisplay:getChildByName("font"):setString(Localization:getInstance():getText("equipEvolve_BuyMaterial"))
  self.materialButton = Button:create(materialButtonDisplay)
  self.materialButton:addEventListener( Events.kStart, materialButtonAction, self )
  
  self.propItemList = {}
  self.propNumList = {}
  self.materialPropNumList = {}
  
  self.equipItem = nil
  self.descPanel = nil
  
  self:refreshSelf()
  
  BaseUIScene.onInit(self)
end

function EquipEvolveScene:refreshSelf()
  self.equipMetaConfig = NULL
  self.equipProperty = NULL
  self.equipLevelConfig = NULL
  self.propertyValue = 0
  self.equipEvolveLevelConfig = NULL
  self.equipEvolveConfig = NULL
  self.nextEquipMetaConfig = NULL
  self.nextEquipEvolveLevelConfig = NULL
  
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
  
  for _, v in pairs(self.propItemList) do
    v:removeFromParentAndCleanup(true)
    v = nil
  end
  for _, v in pairs(self.propNumList) do
    v = nil
  end
  for _, v in pairs(self.materialPropNumList) do
    v = nil
  end
  if self.equipItem then
    self.equipItem:removeFromParentAndCleanup(true)
    self.equipItem = nil
  end
  
  if self.descPanel then
    self.descPanel:removeFromParentAndCleanup(true)
    self.descPanel = nil
  end
  
  local ui = self.ui
  
  local tempGroup
  local tempPosY
  if (self.equip.level == tonumber(self.equipEvolveLevelConfig.levelMax, 10)) and (self.equipMetaConfig.evolveLevel < self.equipMetaConfig.maxEvolveLevel) then
    self.uiGroup1:setVisible(false)
    self.uiGroup10:setVisible(true)
    tempGroup = self.uiGroup10
    tempPosY = -211
  else
    self.uiGroup1:setVisible(true)
    self.uiGroup10:setVisible(false)
    tempGroup = self.uiGroup1
    tempPosY = -218
  end
  
  local equipDisplay = tempGroup:getChildByName("equip_normal_card_small_sb")
  self.equipItem = CanonItem:create()
  self.equipItem:loadByMetaId(self.equip.metaId)
  self.equipItem:setPosition(ccp(equipDisplay:getPositionX(), equipDisplay:getPositionY()))
  self.equipItem:setScale(134.0/146.0)
  tempGroup:addChild(self.equipItem)
  self.flashPos = tempGroup:convertToWorldSpace(ccp(equipDisplay:getPositionX(), equipDisplay:getPositionY()))
  
  local equipNameLabel = tempGroup:getChildByName("equip_txt_skillEnhance_skillName"):getChildByName("txt_skillEnhance_skillName")
  equipNameLabel:setString(Localization:getInstance():getText(self.equipMetaConfig.name))
  
  for i = 1, 7 do
    local aQualityPanel = tempGroup:getChildByName(string.format("equip_panel%d", i))
    aQualityPanel:setVisible(false)
  end
  tempGroup:getChildByName(string.format("equip_panel%d", self.equipMetaConfig.quality)):setVisible(true)
  
  local lvLabel = tempGroup:getChildByName("equip_txt_equip_lv_num"):getChildByName("font")
  lvLabel:setString(string.format("%d/%d", self.equip.level, self.equipEvolveLevelConfig.levelMax))
  
  local defIcon = tempGroup:getChildByName("equip_icon_def")
  defIcon:setVisible(false)
  local attIcon = tempGroup:getChildByName("equip_icon_atk")
  attIcon:setVisible(false)
  local hpIcon = tempGroup:getChildByName("equip_icon_hp")
  hpIcon:setVisible(false)
  if self.equipProperty == EquipPropertyEnum.kAttack then
    attIcon:setVisible(true)
  elseif self.equipProperty == EquipPropertyEnum.kDefence then
    defIcon:setVisible(true)
  elseif self.equipProperty == EquipPropertyEnum.kHp then
    hpIcon:setVisible(true)
  end
  
  local propertyValueLabel = tempGroup:getChildByName("equip_txt_icon_silverCoin_test_num"):getChildByName("font")
  propertyValueLabel:setString(string.format("%d", self.propertyValue))
  
  local cardInfo = tempGroup:getChildByName("equip_txt_equip_equipedby")
  local inequip_display = tempGroup:getChildByName("equip_in_equip_sb")
  --inequip_display:setZOrder(100)
  local inequip_label = tempGroup:getChildByName("equip_txt_in_equip")
  --inequip_label:setZOrder(101)
  tempGroup:setChildIndex(inequip_display, 100)
  tempGroup:setChildIndex(inequip_label, 101)
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
    local aStarDisplay = tempGroup:getChildByName(string.format("equip_icon_star_%d", i))
    aStarDisplay:setVisible(true)
  end
  for i = self.equipMetaConfig.quality + 1, 7 do
    local aStarDisplay = tempGroup:getChildByName(string.format("equip_icon_star_%d", i))
    aStarDisplay:setVisible(false)
  end
  
  self.descPanel = CardDescPanel:create(
		self.equip.metaId,
		{height=185, width=620},
		ccc3(0,0,0)
	)
  self.descPanel:setViewPosition(13,tempPosY)
	tempGroup:addChildAt(self.descPanel, 1001)
  
  --[[
  tempReplaceDesLabel:setString(Localization:getInstance():getText(self.equipMetaConfig.desc))
  
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
    local suitLabel = tempGroup:getChildByName(string.format("txt_equip_suit%d", i)):getChildByName("txt")
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
    local suitLabel = tempGroup:getChildByName(string.format("txt_equip_suit%d", i))
    suitLabel:setVisible(false)
  end
  ]]
  
  if self.equip.level < tonumber(self.equipEvolveLevelConfig.levelMax, 10) then
    self.uiGroup4:setVisible(false)
    self.evolveButton:setEnable(false)
    self.uiGroup7:setVisible(true)
    self.uiGroup7:getChildByName("btn"):setVisible(false)
    self.uiGroup7:getChildByName("disable"):setVisible(true)
    self.evolveButton2:setEnable(false)
    self.uiGroup2:setVisible(false)
    self.uiGroup5:setVisible(true)
    self.uiGroup3:setVisible(false)
    self.uiGroup6:setVisible(false)
    self.uiGroup8:setVisible(true)
    self.upgradeButton:setEnable(true)
    self.uiGroup9:setVisible(false)
    self.evolveButton3:setEnable(false)
    self.materialButton:setEnable(false)
    self.uiGroup5:getChildByName("equipEnhance_equip"):setVisible(false)
    self.uiGroup5:getChildByName("equipEhance_maxlv"):setVisible(false)
  	self.uiGroup5:getChildByName("btn_evolve"):setVisible(false)
  	self.uiGroup5:getChildByName("btn_evolve_1"):setVisible(false)
  	self.uiGroup5:getChildByName("equip_btn_evolve_all"):setVisible(false)
    local beforeUpgradeLevelLabel = self.uiGroup8:getChildByName("equip_txt_equip_lv_num")
    beforeUpgradeLevelLabel:getChildByName("font"):setString(string.format("%d/%d", self.equip.level, tonumber(self.equipEvolveLevelConfig.levelMax, 10)))
    local defIcon_L = self.uiGroup8:getChildByName("equip_icon_def")
    defIcon_L:setVisible(false)
    local attIcon_L = self.uiGroup8:getChildByName("equip_icon_atk")
    attIcon_L:setVisible(false)
    local hpIcon_L = self.uiGroup8:getChildByName("equip_icon_hp")
    hpIcon_L:setVisible(false)
    if self.equipProperty == EquipPropertyEnum.kAttack then
      attIcon_L:setVisible(true)
    elseif self.equipProperty == EquipPropertyEnum.kDefence then
      defIcon_L:setVisible(true)
    elseif self.equipProperty == EquipPropertyEnum.kHp then
      hpIcon_L:setVisible(true)
    end
    local propertyValueLabel_L = self.uiGroup8:getChildByName("equip_txt_equip_icon_atk_num"):getChildByName("font")
    propertyValueLabel_L:setString(string.format("%d", self.propertyValue))
  elseif self.equipMetaConfig.evolveLevel < self.equipMetaConfig.maxEvolveLevel then
    self.uiGroup7:setVisible(false)
    self.evolveButton2:setEnable(false)
    self.uiGroup2:setVisible(true)
    self.uiGroup5:setVisible(false)
    self.uiGroup3:setVisible(true)
    self.uiGroup6:setVisible(false)
    self.uiGroup8:setVisible(false)
    
    self.upgradeButton:setEnable(false)
    local beforeUpgradeLevelLabel = self.uiGroup3:getChildByName("equip_txt_equip_lv_num_L1")
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
    
    self.equipEvolveConfig = MetaManager.equip_evolve[self.equip.metaId]
    self.nextEquipMetaConfig = MetaManager.equip_meta[tonumber(self.equipEvolveConfig.evolvedEquipId)]
    for _, v in ipairs(MetaManager.equip_evolve_level) do
      if tonumber(self.nextEquipMetaConfig.evolveLevel, 10) == tonumber(v.evolveLevel, 10) then
        self.nextEquipEvolveLevelConfig = v
        break
      end
    end
    local afterUpgradeLevelLabel = self.uiGroup3:getChildByName("equip_txt_equip_lv_num_L")
    local afterUpgradeLevelLabel_txt = afterUpgradeLevelLabel:getChildByName("font")
    afterUpgradeLevelLabel_txt:setDimensions(CCSizeMake(0, afterUpgradeLevelLabel_txt:getDimensions().height))
    afterUpgradeLevelLabel_txt:setString(string.format("%d/", self.equip.level))
    local afterUpgradeLevelLabel2 = self.uiGroup3:getChildByName("equip_txt_equipEnhance_num_R")
    local afterUpgradeLevelLabel2_txt = afterUpgradeLevelLabel2:getChildByName("font")
    afterUpgradeLevelLabel2_txt:setString(string.format("%d", tonumber(self.nextEquipEvolveLevelConfig.levelMax, 10)))
    afterUpgradeLevelLabel2_txt:setColor(ccc3(0,255,0))
    afterUpgradeLevelLabel2:setPositionX(afterUpgradeLevelLabel:getPositionX() + afterUpgradeLevelLabel_txt:getTexture():getContentSize().width + 2)
    local defIcon_R = self.uiGroup3:getChildByName("equip_icon_def_R")
    defIcon_R:setVisible(false)
    local attIcon_R = self.uiGroup3:getChildByName("equip_icon_atk_R")
    attIcon_R:setVisible(false)
    local hpIcon_R = self.uiGroup3:getChildByName("equip_icon_hp_R")
    hpIcon_R:setVisible(false)
    local nextPropertyValue
    if self.equipProperty == EquipPropertyEnum.kAttack then
      attIcon_R:setVisible(true)
      nextPropertyValue = self.nextEquipMetaConfig.basicAtk + self.nextEquipMetaConfig.atkSCoe * self.equipLevelConfig.atk
    elseif self.equipProperty == EquipPropertyEnum.kDefence then
      defIcon_R:setVisible(true)
      nextPropertyValue = self.nextEquipMetaConfig.basicDefence + self.nextEquipMetaConfig.defSCoe * self.equipLevelConfig.def
    elseif self.equipProperty == EquipPropertyEnum.kHp then
      hpIcon_R:setVisible(true)
      nextPropertyValue = self.nextEquipMetaConfig.basicHp + self.nextEquipMetaConfig.hpSCoe * self.equipLevelConfig.hp
    end
    local propertyValueLabel_R = self.uiGroup3:getChildByName("equip_txt_equip_icon_atk_num_R"):getChildByName("font")
    propertyValueLabel_R:setString(string.format("%d", self.propertyValue))
    local additionPropertyValue = math.modf(nextPropertyValue - self.propertyValue)
    local normalAdd = self.uiGroup3:getChildByName("equip_txt_plus")
    normalAdd:getChildByName("txt_plus"):setString(string.format("+%d", additionPropertyValue))
    normalAdd:getChildByName("txt_plus"):setColor(ccc3(0,255,0))
    
    local aCostNumLabel = self.uiGroup3:getChildByName("equip_txt_equip_CoinConsume_num"):getChildByName("font")
    self.evolveCost = math.modf(tonumber(self.equipEvolveConfig.coins, 10))
    aCostNumLabel:setString(tostring(self.evolveCost))
    local showBuyMaterial = true
    if self.evolveCost > tonumber(DataManager.getGameInitData().sharkUser.coins, 10) then
      showBuyMaterial = false
    end
    local propEnough = true
    self.evolveGemCost = 0
    self.lackPropId = 0
    for i = 1, 5 do
      local aPropID = tonumber(self.equipEvolveConfig[string.format("propId%d", i)], 10)
      local aPropDisplay = self.uiGroup3:getChildByName(string.format("equip_icon_equipEvolve_test_%d", i))
      aPropDisplay:setVisible(false)
      if aPropID ~= 0 then
        local aPropNum = tonumber(self.equipEvolveConfig[string.format("propAmount%d", i)], 10)
        local aPropConfig = MetaManager.prop_meta[aPropID]
        local aPropItem = CanonItem:create()
        aPropItem:loadByMetaId(aPropID)
        aPropItem:setScale(0.75)
        aPropItem:setPosition(ccp(aPropDisplay:getPositionX(), aPropDisplay:getPositionY()))
        self.uiGroup3:addChild(aPropItem)
        table.insert(self.propItemList, aPropItem)
        
        local propName = self.uiGroup3:getChildByName(string.format("equip_item_name%d", i))
        propName:setVisible(true)
        propName:getChildByName("txt_item_name"):getChildByName("txt_item_name"):setString(Localization:getInstance():getText(aPropConfig.name))
        propName:setZOrder(100)
        local bg = self.uiGroup3:getChildByName(string.format("equip_bg_equipEvolve_material_num_%d", i))
        bg:setVisible(true)
        
        local currentOwn = 0
        for _, v in pairs(DataManager.getPropsData()) do
          if v.metaId == aPropID then
            currentOwn = tonumber(v.amount, 10)
            break
          end
        end
        local needNum = aPropNum
        local text = self.uiGroup3:getChildByName(string.format("equip_txt_equipEvolve_material_num_%d", i))
        text:setVisible(true)
        text = text:getChildByName("font")
        text:setString(string.format("%d/%d", currentOwn, needNum))
        if needNum > currentOwn then
          if self.lackPropId == 0 then
            self.lackPropId = aPropID
          end
          self.evolveGemCost = self.evolveGemCost + (needNum - currentOwn) * MetaManager.prop_meta[aPropID].goldCost
          propEnough = false
          text:setColor(ccc3(255, 0, 0))
          local children = aPropItem.refCocosObj:getChildren()
          local len = children:count()
          for i = 0, len - 1 do
            local child = tolua.cast(children:objectAtIndex(i), "CCNodeRGBA")
            child:setColor(ccc3(128, 128, 128))
          end
        else
          text:setColor(ccc3(0, 0, 0))
        end
        table.insert(self.propNumList, {itemType = ResourceEnum.PROP, metaId = aPropID, amount = -needNum})
        table.insert(self.materialPropNumList, {itemType = ResourceEnum.PROP, metaId = aPropID, amount = -((currentOwn >= needNum) and needNum or currentOwn)})
      else
        
        local propName = self.uiGroup3:getChildByName(string.format("equip_item_name%d", i))
        propName:setVisible(false)
        local bg = self.uiGroup3:getChildByName(string.format("equip_bg_equipEvolve_material_num_%d", i))
        bg:setVisible(false)
        local text = self.uiGroup3:getChildByName(string.format("equip_txt_equipEvolve_material_num_%d", i))
        text:setVisible(false)
      end
    end
    if propEnough then
      showBuyMaterial = false
    end
    if showBuyMaterial and (DataManager.getGameInitData().sharkUser.vipLevel >= CommonManager:sharedManager():getUnlockVipLevel(VipFunctionEnum.kBuyEquipEvolveProp)) then
      self.uiGroup9:setVisible(true)
      self.evolveButton3:setEnable(true)
      self.materialButton:setEnable(true)
      self.uiGroup4:setVisible(false)
      self.evolveButton:setEnable(false)
    else
      self.uiGroup9:setVisible(false)
      self.evolveButton3:setEnable(false)
      self.materialButton:setEnable(false)
      self.uiGroup4:setVisible(true)
      self.evolveButton:setEnable(true)
      self.uiGroup4:getChildByName("btn"):setVisible(true)
      self.uiGroup4:getChildByName("disable"):setVisible(false)
    end
  else
    self.uiGroup4:setVisible(false)
    self.evolveButton:setEnable(false)
    self.uiGroup7:setVisible(true)
    self.uiGroup7:getChildByName("btn"):setVisible(false)
    self.uiGroup7:getChildByName("disable"):setVisible(true)
    self.evolveButton2:setEnable(false)
    self.uiGroup2:setVisible(false)
    self.uiGroup5:setVisible(true)
    self.uiGroup3:setVisible(false)
    self.uiGroup6:setVisible(true)
    self.uiGroup8:setVisible(false)
    self.upgradeButton:setEnable(false)
    self.uiGroup9:setVisible(false)
    self.evolveButton3:setEnable(false)
    self.materialButton:setEnable(false)
    self.uiGroup5:getChildByName("btn_evolve"):setVisible(false)
    self.uiGroup5:getChildByName("btn_evolve_1"):setVisible(false)
    self.uiGroup5:getChildByName("equip_btn_evolve_all"):setVisible(false)
    self.uiGroup5:getChildByName("equipEnhance_equip"):setVisible(false)
    self.uiGroup5:getChildByName("equipEhance_maxlv"):setVisible(false)
    local beforeUpgradeLevelLabel = self.uiGroup6:getChildByName("equip_txt_equip_lv_num")
    beforeUpgradeLevelLabel:getChildByName("font"):setString(string.format("%d/%d", self.equip.level, tonumber(self.equipEvolveLevelConfig.levelMax, 10)))
    local defIcon = self.uiGroup6:getChildByName("equip_icon_def")
    defIcon:setVisible(false)
    local attIcon = self.uiGroup6:getChildByName("equip_icon_atk")
    attIcon:setVisible(false)
    local hpIcon = self.uiGroup6:getChildByName("equip_icon_hp")
    hpIcon:setVisible(false)
    if self.equipProperty == EquipPropertyEnum.kAttack then
      attIcon:setVisible(true)
    elseif self.equipProperty == EquipPropertyEnum.kDefence then
      defIcon:setVisible(true)
    elseif self.equipProperty == EquipPropertyEnum.kHp then
      hpIcon:setVisible(true)
    end
    local propertyValueLabel = self.uiGroup6:getChildByName("equip_txt_equip_icon_atk_num"):getChildByName("font")
    propertyValueLabel:setString(string.format("%d", self.propertyValue))
  end
end

function EquipEvolveScene:moveToEliteScene()
  local argv = {enterScene="EquipEvolveScene",returnScene="EquipEvolveScene",params={equip = self.equip}}
  self:replaceScene(EliteMissionScene, argv)
end

function EquipEvolveScene:doEnterAnimation()
  self:preEnterAnimation()
  self:startEnterAnimation()
end

function EquipEvolveScene:preEnterAnimation()
  BaseUIScene.preEnterAnimation(self)
  --
  CanonPlayBackgroundMusic("music/background.mp3", true)
end

function EquipEvolveScene:startEnterAnimation()
  BaseUIScene.startEnterAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.uiGroup1:setPositionX(self.uiGroup1:getPositionX() - visibleSize.width)
  self.uiGroup1:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  self.uiGroup10:setPositionX(self.uiGroup10:getPositionX() - visibleSize.width)
  self.uiGroup10:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  self.uiGroup2:setPositionX(self.uiGroup2:getPositionX() - visibleSize.width)
  self.uiGroup2:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  self.uiGroup3:setPositionX(self.uiGroup3:getPositionX() - visibleSize.width)
  self.uiGroup3:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  self.uiGroup4:setPositionX(self.uiGroup4:getPositionX() - visibleSize.width)
  self.uiGroup4:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  self.uiGroup5:setPositionX(self.uiGroup5:getPositionX() - visibleSize.width)
  self.uiGroup5:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  self.uiGroup6:setPositionX(self.uiGroup6:getPositionX() - visibleSize.width)
  self.uiGroup6:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  self.uiGroup7:setPositionX(self.uiGroup7:getPositionX() - visibleSize.width)
  self.uiGroup7:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  self.uiGroup9:setPositionX(self.uiGroup9:getPositionX() - visibleSize.width)
  self.uiGroup9:runAction(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  self.uiGroup8:setPositionX(self.uiGroup8:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.uiGroup8:runAction(CCSequence:create(arr))
end

function EquipEvolveScene:sufEnterAnimation()
  BaseUIScene.sufEnterAnimation(self)
  --
  
  if IsGuideExecuted(GuideConfig.kRisk3) then --主要新手引导的最后一个执行完后，才执行这个
    ExeNewGuide(GuideConfig.kEquipQuality)
  end
  
end

function EquipEvolveScene:doExitAnimation()
  self:preExitAnimation()
  self:startExitAnimation()
end

function EquipEvolveScene:preExitAnimation()
  BaseUIScene.preExitAnimation(self)
end

function EquipEvolveScene:startExitAnimation()
  BaseUIScene.startExitAnimation(self)
  local function enterActionFinished()
    self:nodeAnimationFinished()
  end
  
  self.uiGroup1:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  self.uiGroup10:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  self.uiGroup2:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  self.uiGroup3:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  self.uiGroup4:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  self.uiGroup5:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  self.uiGroup6:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  self.uiGroup7:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  self.uiGroup9:runAction(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.uiGroup8:runAction(CCSequence:create(arr))
end

function EquipEvolveScene:sufExitAnimation()
  BaseUIScene.sufExitAnimation(self)
end

function EquipEvolveScene:panelDismiss()
end

function EquipEvolveScene:moveToTower()
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

function EquipEvolveScene:back()
  if self.argv.returnScene == "BackpackScene" then
		local equipId
		if self.equip then
			equipId = self.equip.equipId
		end
    self:replaceScene(BackpackScene, {enterScene="EquipEvolveScene",returnScene=nil,params={tabIndex = BAGCATEGORY.equip,filter=BACKPACK_FILTER.EQUIP, equipId = equipId}})
  elseif self.argv.returnScene == "EquipUpgradeScene" then
    if self.argv.originalScene == "EquipQuickUpgradeScene" then
      self.argv.enterScene = "EquipEvolveScene"
      self.argv.returnScene = self.argv.originalScene
      self:replaceScene( EquipUpgradeScene ,self.argv)
    else
      self:replaceScene( EquipUpgradeScene , {enterScene="EquipEvolveScene",returnScene=self.argv.originalScene,params=self.equip})
    end
  elseif self.argv.returnScene == "CardQueueScene" then
    local argv = {enterScene="EquipEvolveScene",returnScene=nil,params=nil}
    self:replaceScene( CardQueueScene , argv)
  elseif self.argv.returnScene == "EquipQuickUpgradeScene" or self.argv.originalScene == "EquipQuickUpgradeScene"  then
    -- print("~~~~~~~~~~~~~~~~~~~self.argv.params.cardPos = "..tostring(self.argv.params.cardPos))
 
    self.argv.enterScene = "CardQueueScene"
    self.argv.returnScene = "CardQueueScene"
    self:replaceScene( EquipQuickUpgradeScene , self.argv)
  else
    self:replaceScene(MainMenuScene)
  end
end

function EquipEvolveScene:moveToIAPShop()
  self:replaceScene(ShopScene, {params = {tabIndex = TABLEVIEW_TAB_INDEX.CHARGE}})
end

function EquipEvolveScene:showGemsReplacePropPanel()
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kGemReplaceProp, {num = self.evolveGemCost})
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function EquipEvolveScene:startEvolveEquip(arg)
  local currUser = DataManager.getCurrUser()
  if arg.coinCost > tonumber(currUser.coins, 10) then
    self:showCoinLimitPanel()
    return
  end
  
  if arg.gemCost > CalculationManager.calcComplex_getGemsNow() then
    self:showGemLimitPanel()
    return
  end
  
  local function evolveEquipSucceed(event)
    CanonPlayEffect("music/sfx_amer_evolve.wav")
    --evolve successfully
    RewardManager:gainReward({itemType = ResourceEnum.COIN, amount = -arg.coinCost})
    RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -arg.gemCost})
    RewardManager:getReward(arg.propNumList)
    
    local previous_strength = CommonManager:getLocalPlayerStrength()
    
    local aNewEquip = event.data.sharkEquip
    local aSharkEquips = DataManager.getEquipsData()
    for aIndex, aEquip in pairs(aSharkEquips) do
      if aEquip.equipId == aNewEquip.equipId then
        table.remove(aSharkEquips, aIndex)
        break
      end
    end
    table.insert(aSharkEquips, aNewEquip)
    DataManager.setEquipsData(aSharkEquips)
    

    if self.argv.originalScene == "EquipQuickUpgradeScene"  then
       -- self.argv.params.container.queue[self.argv.params.cardPos].equips[self.argv.params.EquipPos] = aNewEquip
       self.argv.params.equip = aNewEquip

    end
    self.equip = aNewEquip
    self:refreshSelf()
    local aContent = Localization:getInstance():getText("equipEvolve_Success")
    SuspensionLabel:showContent(self, aContent)
    
    local fspt = FlashSprite:create("EVO2/equip")
    fspt:changeAnimation(0)
    fspt:setLoop(false)
    local fspt_co = CocosObject.new(fspt)
    fspt:setPosition(self.flashPos.x, self.flashPos.y - visibleSize.height)
    self:addChild(fspt_co)
          
    --显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
    DataManager.fightCapacityMaybeUpdated()
  end
  local function evolveEquipFailed(event)
    if event.data.retCode == 710512 then
      self:showCoinLimitPanel()
    elseif event.data.retCode == 710513 then
      self:showGemLimitPanel()
    elseif event.data.retCode == 712512 then
      local aPanel = MessageBoxPanel:create(self, MessageBoxType.kEquipEvolveLevelLimit)
      self:addChild(aPanel)
      aPanel:scaleIn()
    elseif (event.data.retCode == 712300) or (event.data.retCode == 712301) then
      local eliteInfo = EliteManager.getMaterialSrc(self.lackPropId) 
      if (eliteInfo.eliteMissionId == 0) then
        CanonMessageBox.showText(
          ShowButtonType.ID_OK,
          getTextByKey("skill_MaterialShortText_cannotBuy")
        )
      else
        local aPanel = MessageBoxPanel:create(self, MessageBoxType.kEquipEvolvePropLimit, {eliteInfo = eliteInfo})
        self:addChild(aPanel)
        aPanel:scaleIn()
      end
    end
  end
  
  local params = {equipId = arg.equipId, userGems = arg.useGems}
  local request = EvolveEquipRequest.new(params, rpc.SendingPriority.kHigh)
  request:addEventListener(RequestNotifyEnum.EvolveEquipSucceed, evolveEquipSucceed)
  request:addEventListener(RequestNotifyEnum.EvolveEquipFailed, evolveEquipFailed)
  request:start() 
end

function EquipEvolveScene:confirmGemReplaceProp()
  local arg = {}
  arg.coinCost = self.evolveCost
  arg.gemCost = self.evolveGemCost
  arg.propNumList = self.materialPropNumList
  arg.equipId = self.equip.equipId
  arg.useGems = true
  self:startEvolveEquip(arg)
end

function EquipEvolveScene:showCoinLimitPanel()
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kCoinLimit)
  self:addChild(aPanel)
  aPanel:scaleIn()
end

function EquipEvolveScene:showGemLimitPanel()
  local aPanel = AssistantMessageBoxPanel:create( self, AsMessageBoxType.addCoin )
  self:addChild(aPanel)
  aPanel:scaleIn()
  --[[
  local aPanel = MessageBoxPanel:create(self, MessageBoxType.kGemLimit)
  self:addChild(aPanel)
  aPanel:scaleIn()
  ]]
end
