require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.models.CountryManager"
require "canon.data.MetaManager"
require "canon.data.DataManager"

TextRollType = {
  kCoin = 1,
  kExp = 2
}

PVEWinPanel = class(Layer)

function PVEWinPanel:create()
  local s = PVEWinPanel.new()
  s:initLayer()
  return s
end

local function confirmButtonSelected( event )
	local aPanel = event.context
  PopoutManager:sharedManager():pullin(aPanel, kPopoutDir.kFromTopToTop)
end

local function textRollFinished( event )
  local aPanel = event.context
  local aTextField = event.target
  aPanel.textCounter = aPanel.textCounter - 1
  if aPanel.textCounter == 0 then
    aPanel.buttonDisplay:setVisible(true)
  end
end

local function textRollProcess( event )
  local aPanel = event.context
  local aTextField = event.target
  local aNumAdded = event.data
  if aTextField.labelType == TextRollType.kCoin then
    --modify user's coin
  elseif aTextField.labelType == TextRollType.kExp then
    --modify user's exp
    local aTotalValue = tonumber(string.gsub(aPanel.totalExpLabel:getString(), "/", ""), 10)
    local aNewExp = aPanel.currentExpLabel:getString() + aNumAdded
    local aNewLv = aPanel.lvNumLabel:getString()
    if aNewExp >= aTotalValue then
      aNewLv = aNewLv + 1
      aNewExp = aNewExp - aTotalValue
      --[[
      for _, v in ipairs(DataManager.user_level) do
        if v.level == aNewLv then
          aTotalValue = v.exp
          break
        end
      end
      ]]--
      aTotalValue = 1000
    end
    aPanel.lvNumLabel:setString(aNewLv)
    aPanel.currentExpLabel:setString(aNewExp)
    aPanel.totalExpLabel:setString(string.format("/%d", aTotalValue))
    aPanel.expProgressBar:setPercentage(100.0 * aNewExp / aTotalValue)
  end
end

function PVEWinPanel:initLayer()
  PVEWinPanel.super.initLayer(self)
  self.textCounter = 0
  
  local aTitleFlag
  local aCoinNum
  local aExtraCoinNum
  local aExpNum
  local aExtraExpNum
  local aCurrentLevel
  local aCurrentExp
  local aNextLevelExp
  --[[
  self.battleEventModel = CountryManager:sharedManager().currentMission.currentEventModel
  if self.battleEventModel.eventData.leftHpRate <= MetaManager.battleSettingConfig.victoryLevelFloor then
    aTitleFlag = 1
  elseif self.battleEventModel.eventData.leftHpRate <= MetaManager.battleSettingConfig.victoryLevelTop then
    aTitleFlag = 2
  else
    aTitleFlag = 3
  end
  aCoinNum = self.battleEventModel:getBattleCoin()
  aExtraCoinNum = self.battleEventModel:getQteCoin()
  aExpNum = self.battleEventModel:getBattleExp()
  aExtraExpNum = self.battleEventModel:getQteExp()
  aCurrentLevel = DataManager.SharkUser.level
  aCurrentExp = DataManager.SharkUser.exp
  for _, v in ipairs(DataManager.user_level) do
    if v.level == aCurrentLevel then
      aNextLevelExp = v.exp
      break
    end
  end
  ]]--
  
  aTitleFlag = 1
  aCoinNum = 99
  aExtraCoinNum = 66
  aExpNum = 134
  aExtraExpNum = 455
  aCurrentLevel = 6
  aCurrentExp = 25
  aNextLevelExp = 500
  
  local builder = LayoutBuilder:createWithContentsOfFile("zhandou/zhandou_shengli_shibai.json")
  self.panelUI = builder:build("zhandou_shengli")
  self.panelUI:setPosition(ccp(0,1280))
  self:addChild(self.panelUI)
  
  local aTitle = self.panelUI:getChildByName("biaoti")
  local aXianshengTitle = aTitle:getChildByName("xiansheng")
  aXianshengTitle:setVisible(false)
  local aZhanshengTitle = aTitle:getChildByName("zhansheng")
  aZhanshengTitle:setVisible(false)
  local aWanshengTitle = aTitle:getChildByName("wansheng")
  aWanshengTitle:setVisible(false)
  if aTitleFlag == 1 then
    aXianshengTitle:setVisible(true)
  elseif aTitleFlag == 2 then
    aZhanshengTitle:setVisible(true)
  else
    aWanshengTitle:setVisible(true)
  end
  
  local aCoinGroup = self.panelUI:getChildByName("jinbihuode")
  self.coinNumLabel = aCoinGroup:getChildByName("shuju")
  self.coinNumLabel:setString("0")
  self.coinNumLabel.labelType = TextRollType.kCoin
  self.textCounter = self.textCounter + 1
  self.coinNumLabel:beginRollText(0, aCoinNum)
  self.coinNumLabel:addEventListener(TextRollEvents.kRollProcess, textRollProcess, self)
  self.coinNumLabel:addEventListener(TextRollEvents.kRollFinished, textRollFinished, self)
  self.extraCoinNumLabel = aCoinGroup:getChildByName("+000         ")
  if aExtraCoinNum > 0 then 
    self.extraCoinNumLabel:setString("0")
    self.extraCoinNumLabel.labelType = TextRollType.kCoin
    self.textCounter = self.textCounter + 1
    self.extraCoinNumLabel:beginRollText(0, aExtraCoinNum, "+%d")
    self.extraCoinNumLabel:addEventListener(TextRollEvents.kRollProcess, textRollProcess, self)
    self.extraCoinNumLabel:addEventListener(TextRollEvents.kRollFinished, textRollFinished, self)
  else
    self.extraCoinNumLabel:setVisible(false)
  end
  
  local aExpGroup = self.panelUI:getChildByName("jinyanhuode")
  self.expNumLabel = aExpGroup:getChildByName("shuju")
  self.expNumLabel:setString("0")
  self.expNumLabel.labelType = TextRollType.kExp
  self.textCounter = self.textCounter + 1
  self.expNumLabel:beginRollText(0, aExpNum)
  self.expNumLabel:addEventListener(TextRollEvents.kRollProcess, textRollProcess, self)
  self.expNumLabel:addEventListener(TextRollEvents.kRollFinished, textRollFinished, self)
  self.extraExpNumLabel = aExpGroup:getChildByName("+000         ")
  if aExtraExpNum > 0 then 
    self.extraExpNumLabel:setString("0")
    self.extraExpNumLabel.labelType = TextRollType.kExp
    self.textCounter = self.textCounter + 1
    self.extraExpNumLabel:beginRollText(0, aExtraExpNum, "+%d")
    self.extraExpNumLabel:addEventListener(TextRollEvents.kRollProcess, textRollProcess, self)
    self.extraExpNumLabel:addEventListener(TextRollEvents.kRollFinished, textRollFinished, self)
  else
    self.extraExpNumLabel:setVisible(false)
  end
  
  local aLvGroup = self.panelUI:getChildByName("dengjijindu")
  local aLvNameLabel = aLvGroup:getChildByName("lvzi")
  aLvNameLabel:setString("Lv")
  self.lvNumLabel = aLvGroup:getChildByName("yuanyouzi")
  self.lvNumLabel:setString(string.format("%d", aCurrentLevel))
  self.expProgressBar = ProgressBar.new(aLvGroup:getChildByName("progress"))
  self.expProgressBar:setPercentage(100.0 * aCurrentExp / aNextLevelExp)
  self.currentExpLabel = aLvGroup:getChildByName("kezhengjia_1")
  self.currentExpLabel:setString(string.format("%d", aCurrentExp))
  self.totalExpLabel = aLvGroup:getChildByName("kezhengjia_2")
  self.totalExpLabel:setString(string.format("/%d", aNextLevelExp))
  
  
  self.buttonDisplay = self.panelUI:getChildByName("panel_close_button")
  local aButton = Button:create(self.buttonDisplay)
  aButton:addEventListener(Events.kStart, confirmButtonSelected, self)
  local aButtonText = self.buttonDisplay:getChildByName("quedingzi")
  aButtonText:setString(Localization:getInstance():getText("yes"))
  self.buttonDisplay:setVisible(false)
  local function onTouchEvent( evt )
    if evt.name == DisplayEvents.kTouchEnd and (not self.buttonDisplay:isVisible()) then
      self.coinNumLabel:endRollText()
      self.coinNumLabel:setString(aCoinNum)
      self.extraCoinNumLabel:endRollText()
      self.extraCoinNumLabel:setString(aExtraCoinNum)
      self.expNumLabel:endRollText()
      self.expNumLabel:setString(aExpNum)
      self.extraExpNumLabel:endRollText()
      self.extraExpNumLabel:setString(aExtraExpNum)
      local aTotalValue = aNextLevelExp
      local aNewExp = aCurrentExp + aExpNum + aExtraExpNum
      local aNewLv = aCurrentLevel
      while aNewExp >= aTotalValue do
        aNewLv = aNewLv + 1
        aNewExp = aNewExp - aTotalValue
        --[[
        for _, v in ipairs(DataManager.user_level) do
          if v.level == aNewLv then
            aTotalValue = v.exp
            break
          end
        end
        ]]--
        aTotalValue = 1000
      end
      self.lvNumLabel:setString(aNewLv)
      self.currentExpLabel:setString(aNewExp)
      self.totalExpLabel:setString(string.format("/%d", aTotalValue))
      self.expProgressBar:setPercentage(100.0 * aNewExp / aTotalValue)
      self.buttonDisplay:setVisible(true)
    end
  end
  self:addEventListener(DisplayEvents.kTouchEnd, onTouchEvent)
  
  local aCardIDs = {100011,100011,100011,100011,100011}--self.battleEventModel:getRewardCardMetaIDs()
  for i = 1, #aCardIDs do
    local aCardDisplay = self.panelUI:getChildByName(string.format("kapai_%d", i))
    local aNameLabel = aCardDisplay:getChildByName("mingzi")
    local aFrame = aCardDisplay:getChildByName("waikuangjinn")
    local aCard = aCardDisplay:getChildByName("pai")
    local aCardMeta
    for _, v in ipairs(MetaManager.card_meta) do
      if tonumber(v.id, 10) == tonumber(aCardIDs[i], 10) then
        aCardMeta = v
        break
      end
    end
    aNameLabel:setString(Localization:getInstance():getText(aCardMeta.name))
    local aFrameName = "others/cardFrame/frameRare" .. aCardMeta.rare .. ".png"
    local aFrameTexture = CCTextureCache:sharedTextureCache():addImage(aFrameName)
    local aFrameOriginalWidth = aFrame:getContentSize().width
    local aFrameOriginalHeight = aFrame:getContentSize().height
    aFrame:setDisplayFrame(CCSpriteFrame:createWithTexture(aFrameTexture, CCRect(0, 0, aFrameTexture:getContentSize().width, aFrameTexture:getContentSize().height)))
    aFrame:setScaleX(aFrameOriginalWidth / aFrameTexture:getContentSize().width)
    aFrame:setScaleY(aFrameOriginalHeight / aFrameTexture:getContentSize().height)
    local aCardName = "card/card/Card_" .. aCardMeta.figureId .. ".png"
    local aCardTexture = CCTextureCache:sharedTextureCache():addImage(aCardName)
    local aCardOriginalWidth = aCard:getContentSize().width
    local aCardOriginalHeight = aCard:getContentSize().height
    aCard:setDisplayFrame(CCSpriteFrame:createWithTexture(aCardTexture, CCRect(0, 0, aCardTexture:getContentSize().width, aCardTexture:getContentSize().height)))
    aCard:setScaleX(aCardOriginalWidth / aCardTexture:getContentSize().width)
    aCard:setScaleY(aCardOriginalHeight / aCardTexture:getContentSize().height)
  end
  for i = #aCardIDs + 1, 8 do
    local aCardDisplay = self.panelUI:getChildByName(string.format("kapai_%d", i))
    aCardDisplay:setVisible(false)
  end
  
  local aEquipIDs = {210011, 210011}--self.battleEventModel:getRewardEquipMetaIDs()
  for i = 1, #aEquipIDs do
    local aEquipDisplay = self.panelUI:getChildByName(string.format("jineng_%d", i))
    local aNameLabel = aEquipDisplay:getChildByName("zhuangbeiming")
    local aFrame = aEquipDisplay:getChildByName("baikuang")
    local aCard = aEquipDisplay:getChildByName("baojian")
    local aCardMeta
    for _, v in ipairs(MetaManager.equip_meta) do
      if tonumber(v.id, 10) == tonumber(aEquipIDs[i], 10) then
        aCardMeta = v
        break
      end
    end
    aNameLabel:setString(Localization:getInstance():getText(aCardMeta.name))
    local aFrameName = "others/equipCardFrame/Item_Quality" .. aCardMeta.quality .. ".png"
    local aFrameTexture = CCTextureCache:sharedTextureCache():addImage(aFrameName)
    local aFrameOriginalWidth = aFrame:getContentSize().width
    local aFrameOriginalHeight = aFrame:getContentSize().height
    aFrame:setDisplayFrame(CCSpriteFrame:createWithTexture(aFrameTexture, CCRect(0, 0, aFrameTexture:getContentSize().width, aFrameTexture:getContentSize().height)))
    aFrame:setScaleX(aFrameOriginalWidth / aFrameTexture:getContentSize().width)
    aFrame:setScaleY(aFrameOriginalHeight / aFrameTexture:getContentSize().height)
    local aCardName = "card/equip/Equip_" .. aCardMeta.icon .. ".png"
    local aCardTexture = CCTextureCache:sharedTextureCache():addImage(aCardName)
    local aCardOriginalWidth = aCard:getContentSize().width
    local aCardOriginalHeight = aCard:getContentSize().height
    aCard:setDisplayFrame(CCSpriteFrame:createWithTexture(aCardTexture, CCRect(0, 0, aCardTexture:getContentSize().width, aCardTexture:getContentSize().height)))
    aCard:setScaleX(aCardOriginalWidth / aCardTexture:getContentSize().width)
    aCard:setScaleY(aCardOriginalHeight / aCardTexture:getContentSize().height)
  end
  local aPropIDs = {{metaId = 1001, amount = 2}}--self.battleEventModel:getRewardPropMetaIDs()
  for i = #aEquipIDs + 1, #aEquipIDs + #aPropIDs do
    local aPropDisplay = self.panelUI:getChildByName(string.format("jineng_%d", i))
    local aNameLabel = aPropDisplay:getChildByName("zhuangbeiming")
    local aFrame = aPropDisplay:getChildByName("baikuang")
    local aCard = aPropDisplay:getChildByName("baojian")
    local aCardMeta
    for _, v in ipairs(MetaManager.prop_meta) do
      if tonumber(v.id, 10) == tonumber(aPropIDs[i - #aEquipIDs].metaId, 10) then
        aCardMeta = v
        break
      end
    end
    aNameLabel:setString(Localization:getInstance():getText(aCardMeta.desc))
    local aFrameName = "others/equipCardFrame/Item_Quality" .. aCardMeta.quality .. ".png"
    local aFrameTexture = CCTextureCache:sharedTextureCache():addImage(aFrameName)
    local aFrameOriginalWidth = aFrame:getContentSize().width
    local aFrameOriginalHeight = aFrame:getContentSize().height
    aFrame:setDisplayFrame(CCSpriteFrame:createWithTexture(aFrameTexture, CCRect(0, 0, aFrameTexture:getContentSize().width, aFrameTexture:getContentSize().height)))
    aFrame:setScaleX(aFrameOriginalWidth / aFrameTexture:getContentSize().width)
    aFrame:setScaleY(aFrameOriginalHeight / aFrameTexture:getContentSize().height)
    local aCardName = "card/prop/" .. aCardMeta.iconName .. ".png"
    local aCardTexture = CCTextureCache:sharedTextureCache():addImage(aCardName)
    local aCardOriginalWidth = aCard:getContentSize().width
    local aCardOriginalHeight = aCard:getContentSize().height
    aCard:setDisplayFrame(CCSpriteFrame:createWithTexture(aCardTexture, CCRect(0, 0, aCardTexture:getContentSize().width, aCardTexture:getContentSize().height)))
    aCard:setScaleX(aCardOriginalWidth / aCardTexture:getContentSize().width)
    aCard:setScaleY(aCardOriginalHeight / aCardTexture:getContentSize().height)
  end
  for i = #aEquipIDs + #aPropIDs + 1, 4 do
    local aDisplay = self.panelUI:getChildByName(string.format("jineng_%d", i))
    aDisplay:setVisible(false)
  end
end