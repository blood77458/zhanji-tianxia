require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"


local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- ExchangeStoneResultPanel
--

ExchangeStoneResultPanel = class(Layer)

function ExchangeStoneResultPanel:ctor()
    self.container = nil
    self.args = nil
end

function ExchangeStoneResultPanel:create( container, args )
    local s = ExchangeStoneResultPanel.new()
    s:initLayer(container, args)
    return s
end

function ExchangeStoneResultPanel:initLayer(container, args)
    ExchangeStoneResultPanel.super.initLayer(self)
    
    self.container = container
    self.args = args
    self.container.targetInfoPanel = self
    
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)
    
    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
    self.panelUI = builder:build("common_popup_arena_getstone") 
    self.tempLayer:addChild(self.panelUI)
    
    local function closeButtonSelected(evt)
      self:panelDismiss()
    end
    
    local closeButtonDisplay = self.panelUI:getChildByName("common_btn_close")
    local closeButton = Button:create(closeButtonDisplay)
    closeButton:addEventListener(Events.kStart, closeButtonSelected, self)
    
    self.panelUI:getChildByName("txt_getstone"):getChildByName("txt"):setString(Localization:getInstance():getText("arena_exchangeSuccess_title", {num = args.num}))
    
    local trainConfig = MetaManager.getCardTrainConfig()
    
    local icon_display = self.panelUI:getChildByName("common_icon_getstone")
    icon_display:setVisible(false)
    local icon = CanonItem:create()
    icon:loadByMetaId(trainConfig.pydMetaId)
    icon:setScale(0.6 * 1.5)
    icon:setPosition(ccp(icon_display:getPositionX(), icon_display:getPositionY()))
    self.panelUI:addChild(icon)
    
    self.panelUI:getChildByName("common_txt_getstone2"):getChildByName("txt"):setString(Localization:getInstance():getText("arena_exchangeSuccess_content1"))
      
    self.panelUI:getChildByName("txt_getstone2"):getChildByName("txt"):setString(Localization:getInstance():getText("arena_exchangeSuccess_content2"))
    
    local soulStone = CommonManager.getSubTableByKey(
      DataManager.getPropsData(),
      {name = "metaId", value = trainConfig.pydMetaId}
    )
    local amount = soulStone and soulStone.amount or 0
    self.panelUI:getChildByName("txt_getstone3"):getChildByName("txt"):setString(Localization:getInstance():getText("arena_exchangeSuccess_content3", {num = amount}))
    
    local function trainButtonSelected(evt)
      self:panelDismiss()
      --self.container:moveToCardTrainScene()
      self.container:replaceScene(CardQueueScene)
    end
    local trainButtonDisplay = self.panelUI:getChildByName("common_btn_train")
    trainButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("arena_exchangeSuccess_trainBtn"))
    local trainButton = Button:create(trainButtonDisplay)
    trainButton:addEventListener(Events.kStart, trainButtonSelected, self)
    
    local function continueButtonSelected(evt)
      self:panelDismiss()
      self.container:exchangeTrainDan(args.exchangeType)
    end
    local continueButtonDisplay = self.panelUI:getChildByName("common_btn_tochange")
    continueButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("arena_exchangeSuccess_exchangeBtn"))
    local continueButton = Button:create(continueButtonDisplay)
    continueButton:addEventListener(Events.kStart, continueButtonSelected, self)
    
    self.tempLayer:setScale(0.1)
end

function ExchangeStoneResultPanel:panelDismiss()
  self:removeFromParentAndCleanup(true)
  self.container.targetInfoPanel = nil
  if type(self.container.panelDismiss) == "function" then
    self.container:panelDismiss()
  end
end

function ExchangeStoneResultPanel:scaleIn()
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
