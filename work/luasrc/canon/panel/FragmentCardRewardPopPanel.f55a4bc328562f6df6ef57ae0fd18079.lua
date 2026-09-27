--
-- FragmentCardRewardPopPanel 卡牌碎片获得卡牌奖励UI
-- Author: czh
-- Date: 2014-02-17 10:09:47
--
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

FragmentCardRewardPopPanel = class(Layer)

function FragmentCardRewardPopPanel:ctor()
    self.container = nil
    self.content = nil
end

function FragmentCardRewardPopPanel:create( container, content, dropInfo, completeCallBack )
    local s = FragmentCardRewardPopPanel.new()
    s:initLayer(container, content, dropInfo, completeCallBack)
    return s
end

function FragmentCardRewardPopPanel:initLayer(container, content, dropInfo, completeCallBack)
  FragmentCardRewardPopPanel.super.initLayer(self)

  --点击确认
  local function onConfirm(evt)
    self:dismiss()
  end

  --三级框关闭
  local function onInfoClosed()
    --还不让滚动
    self.container:setTableViewsEnabled(false)
  end

  --点击卡牌
  local function onItemClick()

  	-- self.container._data = FragmentScene.Get_Card_Whole_Information( self.dropInfo.id )
   --  self.container.targetInfoPanel = EggNewCardInfoPanel:create( After_CardInfoPanel_Finished, self.container, nil, onInfoClosed )
   --  PopoutManager:sharedManager():popout(self.container.targetInfoPanel, kPopoutDir.kScale, false, false ,self.container) 
   --  self.container.targetInfoPanel = nil

    local cardPanel = GachaCardInfoPanel:create(self.container, FragmentScene.Get_Card_Whole_Information( self.dropInfo.id ))
    PopoutManager:sharedManager():popout(cardPanel, kPopoutDir.kScale, false, false, self.container)
  end
    
  self.container = container
  self.content = content
  self.dropInfo = dropInfo
  self.completeCallBack = completeCallBack
  
  self.container.targetInfoPanel = self
  
  self.colorLayer = LayerColor:create()
  self.colorLayer:setOpacity(kDarkOpacity)
  self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(self.colorLayer)
  
  self.tempLayer = Layer:create()
  self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
  self:addChild(self.tempLayer)
  self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
  
  local builder = LayoutBuilder:createWithContentsOfFile("scene/soulcombine.json")
  builder.useArtLabelTTF = true
  self.panelUI = builder:build("soulcombine_result") 
  self.tempLayer:addChild(self.panelUI)
  
  self.panelUI:getChildByName("txt_up"):getChildByName("txt"):setString(Localization:getInstance():getText("fragment_cardCombine_title"))
  self.panelUI:getChildByName("txt_buttom"):getChildByName("txt"):setString(Localization:getInstance():getText("fragment_cardCombine_text"))
  
  --确认按钮
  local gainButton = Button:create(self.panelUI:getChildByName("btn_sure"))
  self.panelUI:getChildByName("btn_sure"):getChildByName("txt"):setString(Localization:getInstance():getText("yes"))--确定

  gainButton:addEventListener(Events.kStart,onConfirm, self)

  --显示武将图片
  local dropItem = getBigCanonCardWithInfoByMetaId( self.dropInfo.metaId)
  --设置武将显示的攻击力 防御力 hp 和等级
  local cardData = FragmentScene.Get_Card_Whole_Information( self.dropInfo.id )
  local cardStatus = CommonManager:getCardPropertiesWithSharkCard( cardData )
  dropItem:setAtk(math.floor(cardStatus.att))
  dropItem:setDef(math.floor(cardStatus.def))
  dropItem:setHp(math.floor(cardStatus.hp))
  dropItem:setLevel(self.dropInfo.level)

  --图片添加点击事件
  dropItem:setPosition(ccp( visibleSize.width/2, 680 ))
  self.panelUI:addChild( dropItem )
  local Btn_dropItem = Button:create( dropItem )
  Btn_dropItem:addEventListener( Events.kStart, onItemClick, self ) 
  
  self.tempLayer:setScale(0.1)
end

function FragmentCardRewardPopPanel:scaleIn()
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

  UiStackManager.push(self)
end

function FragmentCardRewardPopPanel:dismiss()
  UiStackManager.remove(self)
  self:removeFromParentAndCleanup(true)

  if self.completeCallBack then
  	self.completeCallBack()
  end
end