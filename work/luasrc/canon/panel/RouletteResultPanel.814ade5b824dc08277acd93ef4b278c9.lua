require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"


local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- RouletteResultPanel
--

local function okButtonSelected(evt)
  local aPanel = evt.context
  aPanel:removeFromParentAndCleanup(true)
  aPanel.container:panelDismiss()
end

RouletteResultPanel = class(Layer)

function RouletteResultPanel:ctor()
    self.container = nil
    self.args = nil
end

--DOUBLE_REWARD_MODIFY
--doubleRewardMoudle 多倍奖励模块类型
function RouletteResultPanel:create( container, args, doubleRewardMoudle )
    local s = RouletteResultPanel.new()
    s:initLayer(container, args, doubleRewardMoudle)
    return s
end

function RouletteResultPanel:initLayer(container, args, doubleRewardMoudle)
    RouletteResultPanel.super.initLayer(self)
    
    self.container = container
    self.args = args
    self.doubleRewardMoudle = doubleRewardMoudle
    
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
    self.panelUI = builder:build("rob_result") 
    self.tempLayer:addChild(self.panelUI)
    
    local lighting = self.panelUI:getChildByName("lighting")
    lighting:setPositionX(lighting:getPositionX() + lighting:getContentSize().width / 2.0)
    lighting:setPositionY(lighting:getPositionY() - lighting:getContentSize().height / 2.0)
    lighting:setAnchorPoint(ccp(0.5, 0.5))
    lighting:runAction(CCRepeatForever:create(CCRotateBy:create(3, 360)))
    
    local iconGroup = self.panelUI:getChildByName("rob_result_reward")
    local icon_display = iconGroup:getChildByName("frame_card")
    icon_display:setVisible(false)
    local icon
    local aBorder
    local aRewardNameString
    if args.itemType == ResourceEnum.PROP then
      icon = CanonItem:create()
      icon:loadByMetaId(args.metaId)
      icon:setScale(0.6 * 1.5)
      aRewardNameString = Localization:getInstance():getText(MetaManager.prop_meta[args.metaId].name)
    elseif args.itemType == ResourceEnum.CARD then
      icon = getHeadIconCanonCardByMetaId(args.metaId)
      icon:setScale(0.7 * 1.5)
      aRewardNameString = Localization:getInstance():getText(MetaManager.card_meta[args.metaId].name)
    elseif args.itemType == ResourceEnum.COIN then
      icon = Sprite:create("common/CoinIcon_Mission.png")
      icon:setScale(0.7 * 1.6)
      aBorder = Sprite:create("Item/border/equipBorder1.png")
      aBorder:setScale(0.7 * 1.5)
      aRewardNameString = Localization:getInstance():getText("resource_silverCoin")
    elseif args.itemType == ResourceEnum.EQUIP then
      icon = CanonItem:create()
      icon:loadByMetaId(args.metaId)
      icon:setScale(0.6 * 1.5)
      aRewardNameString = Localization:getInstance():getText(MetaManager.equip_meta[args.metaId].name)
    end
    icon:setPosition(ccp(icon_display:getPositionX(), icon_display:getPositionY()))
    iconGroup:addChildAt(icon, 1)
    if aBorder then
      aBorder:setPosition(ccp(icon_display:getPositionX(), icon_display:getPositionY()))
      iconGroup:addChildAt(aBorder, 3)
    end
    iconGroup:getChildByName("txt_item_name"):getChildByName("txt_item_name"):setString(aRewardNameString)

    --DOUBLE_REWARD_MODIFY
    local useDoubleReward = false
    if self.doubleRewardMoudle then
      local doubleRewardType = Activity_DoubleRewardLayer.getRewardItemTypeById(self.doubleRewardMoudle)
      if args.itemType == doubleRewardType then
        --当前奖励的物品类型和配置的类型匹配
        useDoubleReward = true
      end
    end
    if useDoubleReward then
      --存在多倍奖励
      local doubleRate = Activity_DoubleRewardLayer.getRewardMultipleById(self.doubleRewardMoudle)
      local baseNum = args.amount / doubleRate
      local addNum = args.amount - baseNum
      
      local doubleLabel_co = CCLabelBMFont:create(string.format("x%d", doubleRate), "pic/fnt/multiple_text.fnt")
      local doubleLabel = CocosObject.new(doubleLabel_co)
      doubleLabel:setAnchorPoint(ccp(0, 1))
      doubleLabel:setPositionX(self.panelUI:getChildByName("txt_item_name"):getPositionX() + 220)
      doubleLabel:setPositionY(self.panelUI:getChildByName("txt_item_name"):getPositionY() - 100)
      self.panelUI:addChild(doubleLabel)

      iconGroup:getChildByName("txt_item_quantity"):getChildByName("txt_item_quantity"):setString(string.format("x%d", baseNum))
    else
      --正常显示
      -- self.panelUI:getChildByName("txt_item_name"):setVisible(false)
      iconGroup:getChildByName("txt_item_quantity"):getChildByName("txt_item_quantity"):setString(string.format("x%d", args.amount))
    end
    
    local okButtonDisplay = self.panelUI:getChildByName("rob_btn_sure")
    okButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("yes"))
    local okButton = Button:create(okButtonDisplay)
  okButton:addEventListener(Events.kStart, okButtonSelected, self)
    
    self.tempLayer:setScale(0.1)
end

function RouletteResultPanel:scaleIn()
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