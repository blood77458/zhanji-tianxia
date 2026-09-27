require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

UnlockReturnSceneEnum = {
    kEliteScene = 1,
}

missionUnlockConfig = {
	{missionId = 100210, contentKey = "levelup_eliteUnlock", btnKey = "moduleName_elite", sceneType = UnlockReturnSceneEnum.kEliteScene},
}

function existInMissionUnlockConfig(aMissionId)
  local existed = false
  for _, v in pairs(missionUnlockConfig) do
    if v.missionId == aMissionId then
      existed = true
      break
    end
  end
  return existed
end

local function onCloseButtonClicked(evt)
  local aPanel = evt.context
  if type(aPanel.container.panelDismiss) == "function" then
    aPanel.container:panelDismiss()
  end
  aPanel.container.targetInfoPanel = nil
  aPanel:removeFromParentAndCleanup(true)
end

local function onGotoButtonClicked(evt)
  local aPanel = evt.context
  if type(aPanel.container.panelDismiss) == "function" then
    aPanel.container:panelDismiss()
  end
  aPanel.container.targetInfoPanel = nil
  aPanel:removeFromParentAndCleanup(true)
  aPanel.rightCallback(aPanel.returnSceneType)
end

--
-- MissionUnlockContentPanel
--

MissionUnlockContentPanel = class(Layer)

function MissionUnlockContentPanel:ctor()
    self.container = nil
    self.rightCallback = nil
    self.missionId = nil
end

function MissionUnlockContentPanel:create( container, rightCallback, missionId )
    local s = MissionUnlockContentPanel.new()
    s:initLayer(container, rightCallback, missionId)
    return s
end

function MissionUnlockContentPanel:initLayer(container, rightCallback, missionId)
    MissionUnlockContentPanel.super.initLayer(self)
    
    self.container = container
    self.rightCallback = rightCallback
    self.missionId = missionId
    
    self.container.targetInfoPanel = self
    
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)
    
    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
    
    local aUnlockConfig
    for _, v in pairs(missionUnlockConfig) do
      if v.missionId == self.missionId then
        aUnlockConfig = v
        break
      end
    end
    self.returnSceneType = aUnlockConfig.sceneType
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("common_popup_levelup4") 
    self.tempLayer:addChild(self.panelUI)
    
    self.panelUI:getChildByName("common_txt_moreplay"):getChildByName("txt"):setString(getTextByKey("levelup_newSystemText"))
    
    
    self.panelUI:getChildByName("common_txt_morefunction"):getChildByName("txt"):setString(getTextByKey(aUnlockConfig.contentKey))
    local aContentLabel = self.panelUI:getChildByName("common_txt_morefunction")
    aContentLabel:setVisible(false)
    local aPosX = aContentLabel:getPositionX()
    local aPosY = aContentLabel:getPositionY()
    aContentLabel = aContentLabel:getChildByName("txt")
    local aWidth = aContentLabel:getDimensions().width
    local aFontName = aContentLabel:getFontName()
    local aFontSize = aContentLabel:getFontSize()
    local aFontColor = aContentLabel:getColor()
    local aReplaceLabel = TextField:create(getTextByKey(aUnlockConfig.contentKey), aFontName, aFontSize, CCSizeMake(aWidth, 0), kCCTextAlignmentLeft, kCCVerticalTextAlignmentTop)
    aReplaceLabel:setColor(ccc3(aFontColor.r,aFontColor.g,aFontColor.b))
    aReplaceLabel:setAnchorPoint(ccp(0,1))
    aReplaceLabel:setPosition(ccp(aPosX, aPosY))
     self.panelUI:addChild(aReplaceLabel)
    
    local closeBtn = Button:create(self.panelUI:getChildByName("common_btn_close"))
    closeBtn:addEventListener( Events.kStart, onCloseButtonClicked, self )

    self.panelUI:getChildByName("common_btn_close"):getChildByName("txt"):setString(getTextByKey("yes"))

    local gotoBtn = Button:create(self.panelUI:getChildByName("common_btn_goarena"))
    gotoBtn:addEventListener( Events.kStart, onGotoButtonClicked, self)

    self.panelUI:getChildByName("common_btn_goarena"):getChildByName("txt"):setString(getTextByKey(aUnlockConfig.btnKey))
    
    self.tempLayer:setScale(0.1)
end

function MissionUnlockContentPanel:scaleIn()
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