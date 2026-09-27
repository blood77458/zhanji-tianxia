require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.panel.RouletteResultPanel"


local visibleSize = CCDirector:sharedDirector():getVisibleSize()
local rotate_duration = 1.0
local round_count = 5

--
-- RouletteRewardPanel
--

RouletteRewardPanel = class(Layer)

function RouletteRewardPanel:ctor()
    self.container = nil
    self.args = nil
end

function RouletteRewardPanel:show( container, args, doubleRewardMoudle )
  local aPanel = RouletteRewardPanel:create( container, args, doubleRewardMoudle )
  container:addChild(aPanel)
end

--DOUBLE_REWARD_MODIFY
--doubleRewardMoudle 多倍奖励模块类型
function RouletteRewardPanel:create( container, args, doubleRewardMoudle )
    local s = RouletteRewardPanel.new()
    s:initLayer(container, args, doubleRewardMoudle)
    return s
end

function RouletteRewardPanel:initLayer(container, args, doubleRewardMoudle)
    RouletteRewardPanel.super.initLayer(self)
    
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
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/battleResult_new.json")
    self.panelUI = builder:build("turntable") 
    self.tempLayer:addChild(self.panelUI)
    
    local turntable_back = self.panelUI:getChildByName("turntable_back_dic")
    turntable_back:setAnchorPoint(ccp(0.5,0.5))
    turntable_back:runAction(CCRepeatForever:create(CCRotateBy:create(4, -360)))
    
    local turntable_front = self.panelUI:getChildByName("turntable_front")
    
    local rotate_degree = round_count * 360
    if args.itemType == ResourceEnum.PROP then
      
    elseif args.itemType == ResourceEnum.CARD then
      rotate_degree = rotate_degree + 90
    elseif args.itemType == ResourceEnum.COIN then
      rotate_degree = rotate_degree + 180
    elseif args.itemType == ResourceEnum.EQUIP then
      rotate_degree = rotate_degree + 270
    end
    
    local function actionFinished()
      local aResultPanel = RouletteResultPanel:create( self, args, self.doubleRewardMoudle )
      self:addChild(aResultPanel)
      aResultPanel:scaleIn()  
    end
    
    local turntable_icons = self.panelUI:getChildByName("turntable_icons")
    local temp = turntable_icons:getAnchorPoint()
    turntable_icons:setAnchorPoint(ccp(0.5,0.5))
    local array = CCArray:create()
    array:addObject(CCEaseOut:create(CCRotateBy:create(rotate_duration, rotate_degree), 3))
    array:addObject(CCCallFunc:create(actionFinished))
    turntable_icons:runAction(CCSequence:create(array))
    
    local turntable_bg = self.panelUI:getChildByName("turntable_bg")
    temp = turntable_bg:getAnchorPoint()
    turntable_bg:setAnchorPoint(ccp(0.5,0.5))
    turntable_bg:runAction(CCEaseOut:create(CCRotateBy:create(rotate_duration, -rotate_degree), 3))
end

function RouletteRewardPanel:panelDismiss()
  self:removeFromParentAndCleanup(true)
end

