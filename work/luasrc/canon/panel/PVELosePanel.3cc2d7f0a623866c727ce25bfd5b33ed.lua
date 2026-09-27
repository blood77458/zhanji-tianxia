require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.models.CountryManager"
require "canon.data.MetaManager"
require "canon.data.DataManager"

PVELosePanel = class(Layer)

function PVELosePanel:create()
  local s = PVELosePanel.new()
  s:initLayer()
  return s
end

local function confirmButtonSelected( event )
	local aPanel = event.context
  PopoutManager:sharedManager():pullin(aPanel, kPopoutDir.kFromTopToTop)
end

local function cardButtonSelected( event )
	local aPanel = event.context
  
end

local function equipButtonSelected( event )
	local aPanel = event.context
  
end

local function textRollFinished( event )
  local aPanel = event.context
  local aTextField = event.target
  aPanel.textCounter = aPanel.textCounter - 1
  if aPanel.textCounter == 0 then
    aPanel.buttonDisplay:setVisible(true)
    aPanel.buttonDisplay2:setVisible(true)
    aPanel.buttonDisplay3:setVisible(true)
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

function PVELosePanel:initLayer()
  PVELosePanel.super.initLayer(self)
  self.textCounter = 0
  
  local aTitleFlag
  local aCoinNum
  local aExpNum
  local aCurrentLevel
  local aCurrentExp
  local aNextLevelExp
  --[[
  self.battleEventModel = CountryManager:sharedManager().currentMission.currentEventModel
  if self.battleEventModel.eventData.leftHpRate <= MetaManager.battleSettingConfig.loseLevelFloor then
    aTitleFlag = 1
  elseif self.battleEventModel.eventData.leftHpRate <= MetaManager.battleSettingConfig.loseLevelTop then
    aTitleFlag = 2
  else
    aTitleFlag = 3
  end
  aCoinNum = self.battleEventModel:getBattleCoin()
  aExpNum = self.battleEventModel:getBattleExp()
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
  aExpNum = 134
  aCurrentLevel = 6
  aCurrentExp = 25
  aNextLevelExp = 500
  
  local builder = LayoutBuilder:createWithContentsOfFile("zhandou/zhandou_shengli_shibai.json")
  self.panelUI = builder:build("zhandou_shibai")
  self.panelUI:setPosition(ccp(0,1280))
  self:addChild(self.panelUI)
  
  local aTitle = self.panelUI:getChildByName("biaoti")
  local aXianbaiTitle = aTitle:getChildByName("xianbai")
  aXianbaiTitle:setVisible(false)
  local aZhanbaiTitle = aTitle:getChildByName("zhanbai")
  aZhanbaiTitle:setVisible(false)
  local aWanbaiTitle = aTitle:getChildByName("wanbai")
  aWanbaiTitle:setVisible(false)
  if aTitleFlag == 1 then
    aXianbaiTitle:setVisible(true)
  elseif aTitleFlag == 2 then
    aZhanbaiTitle:setVisible(true)
  else
    aWanbaiTitle:setVisible(true)
  end
  
  local aCoinGroup = self.panelUI:getChildByName("jinbi")
  self.coinNumLabel = aCoinGroup:getChildByName("shuju")
  self.coinNumLabel:setString("0")
  self.coinNumLabel.labelType = TextRollType.kCoin
  self.textCounter = self.textCounter + 1
  self.coinNumLabel:beginRollText(0, aCoinNum)
  self.coinNumLabel:addEventListener(TextRollEvents.kRollProcess, textRollProcess, self)
  self.coinNumLabel:addEventListener(TextRollEvents.kRollFinished, textRollFinished, self)
  local aExtraCoinNumLabel = aCoinGroup:getChildByName("+000         ")
  aExtraCoinNumLabel:setVisible(false)
  
  local aExpGroup = self.panelUI:getChildByName("jinyan")
  self.expNumLabel = aExpGroup:getChildByName("shuzi")
  self.expNumLabel:setString("0")
  self.expNumLabel.labelType = TextRollType.kExp
  self.textCounter = self.textCounter + 1
  self.expNumLabel:beginRollText(0, aExpNum)
  self.expNumLabel:addEventListener(TextRollEvents.kRollProcess, textRollProcess, self)
  self.expNumLabel:addEventListener(TextRollEvents.kRollFinished, textRollFinished, self)
  
  local aLvGroup = self.panelUI:getChildByName("dengji")
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
  
  local aTipLabel = self.panelUI:getChildByName("tishi_xiangqi"):getChildByName("miaosu")
  aTipLabel:setString(Localization:getInstance():getText("yes"))
  
  self.buttonDisplay = self.panelUI:getChildByName("panel_close_button")
  local aButton = Button:create(self.buttonDisplay)
  aButton:addEventListener(Events.kStart, confirmButtonSelected, self)
  local aButtonText = self.buttonDisplay:getChildByName("quedingzi")
  aButtonText:setString(Localization:getInstance():getText("yes"))
  self.buttonDisplay:setVisible(false)
  self.buttonDisplay2 = self.panelUI:getChildByName("anniu_kapai_button")
  aButton = Button:create(self.buttonDisplay2)
  aButton:addEventListener(Events.kStart, cardButtonSelected, self)
  aButtonText = self.buttonDisplay2:getChildByName("anniuzi")
  aButtonText:setString(Localization:getInstance():getText("battleFailedCard"))
  self.buttonDisplay2:setVisible(false)
  self.buttonDisplay3 = self.panelUI:getChildByName("anniu_hecheng_button")
  local aButton = Button:create(self.buttonDisplay3)
  aButton:addEventListener(Events.kStart, equipButtonSelected, self)
  aButtonText = self.buttonDisplay3:getChildByName("anniuzi")
  aButtonText:setString(Localization:getInstance():getText("battleFailedEquip"))
  self.buttonDisplay3:setVisible(false)
  local function onTouchEvent( evt )
    if evt.name == DisplayEvents.kTouchEnd and (not self.buttonDisplay:isVisible()) then
      self.coinNumLabel:endRollText()
      self.coinNumLabel:setString(aCoinNum)
      self.expNumLabel:endRollText()
      self.expNumLabel:setString(aExpNum)
      local aTotalValue = aNextLevelExp
      local aNewExp = aCurrentExp + aExpNum
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
      self.buttonDisplay2:setVisible(true)
      self.buttonDisplay3:setVisible(true)
    end
  end
  self:addEventListener(DisplayEvents.kTouchEnd, onTouchEvent)
  
end