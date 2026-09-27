require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local scroll_width = 432
local scroll_height = 385
local scroll_posX = 145
local scroll_posY = 435
local scroll_startPosY = 355
local font_name = "Helvetica"
local font_size = 24
local round_space = 20

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- SweepResultPanel
--

SweepResultPanel = class(Layer)

function SweepResultPanel:ctor()
    self.container = nil
    self.args = nil
end

function SweepResultPanel:create( container, args )
    local s = SweepResultPanel.new()
    s:initLayer(container, args)
    return s
end

function SweepResultPanel:initLayer(container, args)
    SweepResultPanel.super.initLayer(self)
    
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
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/chapterSelect_new.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("chapterSelect_sweep_result") 
    self.tempLayer:addChild(self.panelUI)
    
    
    local function onSureButtonClicked(evt)
      self:dismissSelf()
    end
    local sureButtonDisplay = self.panelUI:getChildByName("chapterSelect_sweep_sure")
    sureButtonDisplay:getChildByName("font"):setString(Localization:getInstance():getText("yes"))
    sureButtonDisplay:getChildByName("btn_inactive"):setVisible(false)
    local sureButton = Button:create(sureButtonDisplay)
    sureButton:addEventListener( Events.kStart, onSureButtonClicked, self )
    

    local CloseButton = Button:create(self.panelUI:getChildByName("btn_close"))
    CloseButton:addEventListener( Events.kStart, onSureButtonClicked, self )
    self.panelUI:getChildByName("txt_sweep1"):getChildByName("txt"):setString(Localization:getInstance():getText("stage_stageClearResult"))
    
    
    
    local aScrollContentList = {}
    local aScrollView = ScrollView:create(scroll_width, scroll_height)
    aScrollView:setPosition(ccp(scroll_posX, scroll_posY))
    aScrollView:setDirection(kCCScrollViewDirectionVertical)
    self.panelUI:addChildAt(aScrollView, 10)
    
    local aStartPosY = scroll_startPosY
    
    local function getExpAndCoin(rewards)
      local exp = 0
      local coin = 0
      local result = {}
      for _, aValue in ipairs(rewards) do
        if aValue.itemType == ResourceEnum.EXP then
          exp = aValue.amount
        elseif aValue.itemType == ResourceEnum.COIN then
          coin = aValue.amount
        else
          table.insert(result, aValue)
        end
      end
      return exp, coin, result
    end
    
    local function getColorWithQuality(aRare)
      local aColor = ccc3(255,255,255)
      if aRare == 1 then
        aColor = ccc3(255,255,255)
      elseif aRare == 2 then
        aColor = ccc3(82,207,0)
      elseif aRare == 3 then
        aColor = ccc3(10,165,255)
      elseif aRare == 4 then
        aColor = ccc3(149,100,255)
      elseif aRare == 5 then
        aColor = ccc3(255,134,75)
      elseif aRare == 6 then
        aColor = ccc3(255,54,54)
      elseif aRare == 7 then
        aColor = ccc3(255,241,0)
      elseif aRare == 0 then
        aColor = ccc3(255,255,255)
      end
      return aColor
    end
    
    for i, aClearMissionReward in ipairs(args) do
      local aTitle = TextField:create(Localization:getInstance():getText(string.format("stage_stageClearTimes%d", i)), font_name, font_size)
      aTitle:setHorizontalAlignment(kCCTextAlignmentLeft)
      aTitle:setColor(ccc3(255,255,255))
      aTitle:setAnchorPoint(ccp(0, 1))
      aTitle:setPosition(ccp(0, aStartPosY))
      aScrollView:addChild(aTitle)
      table.insert(aScrollContentList, aTitle)
      aStartPosY = aStartPosY - aTitle:getTexture():getContentSize().height
      
      local exp, coin, rewards = getExpAndCoin(aClearMissionReward.rewards)
      local aExpTitleLabel = TextField:create(Localization:getInstance():getText("stage_stageClearExp"), font_name, font_size)
      aExpTitleLabel:setHorizontalAlignment(kCCTextAlignmentLeft)
      aExpTitleLabel:setColor(ccc3(255,255,255))
      aExpTitleLabel:setAnchorPoint(ccp(0, 1))
      aExpTitleLabel:setPosition(ccp(0, aStartPosY))
      aScrollView:addChild(aExpTitleLabel)
      table.insert(aScrollContentList, aExpTitleLabel)
      local aExpLabel = TextField:create(string.format("%d", exp), font_name, font_size)
      aExpLabel:setHorizontalAlignment(kCCTextAlignmentLeft)
      aExpLabel:setColor(ccc3(255,255,255))
      aExpLabel:setAnchorPoint(ccp(0, 1))
      aExpLabel:setPosition(ccp(aExpTitleLabel:getTexture():getContentSize().width, aStartPosY))
      aScrollView:addChild(aExpLabel)
      table.insert(aScrollContentList, aExpLabel)
      local aCoinTitleLabel = TextField:create(Localization:getInstance():getText("stage_stageClearCoin"), font_name, font_size)
      aCoinTitleLabel:setHorizontalAlignment(kCCTextAlignmentLeft)
      aCoinTitleLabel:setColor(ccc3(255,255,255))
      aCoinTitleLabel:setAnchorPoint(ccp(0, 1))
      aCoinTitleLabel:setPosition(ccp(250, aStartPosY))
      aScrollView:addChild(aCoinTitleLabel)
      table.insert(aScrollContentList, aCoinTitleLabel)
      local aCoinLabel = TextField:create(string.format("%d", coin), font_name, font_size)
      aCoinLabel:setHorizontalAlignment(kCCTextAlignmentLeft)
      aCoinLabel:setColor(ccc3(255,255,255))
      aCoinLabel:setAnchorPoint(ccp(0, 1))
      aCoinLabel:setPosition(ccp(250 + aCoinTitleLabel:getTexture():getContentSize().width, aStartPosY))
      aScrollView:addChild(aCoinLabel)
      table.insert(aScrollContentList, aCoinLabel)
      --DOUBLE_REWARD_MODIFY
      if Activity_DoubleRewardLayer.getRewardEnableById(Activity_DoubleRewardLayer.MOUDLE_CHAPTERS) then
        --多倍奖励开启
        local addPercent = (Activity_DoubleRewardLayer.getRewardMultipleById(Activity_DoubleRewardLayer.MOUDLE_CHAPTERS) - 1) * 100
        local aDoubleRewardLabel = TextField:create("("..getTextByKey("home_activityBtn") .. "+" .. addPercent .. "%)", font_name, font_size)--双倍活动+{num}
        aDoubleRewardLabel:setHorizontalAlignment(kCCTextAlignmentLeft)
        aDoubleRewardLabel:setColor(ccc3(0,204,0))
        aDoubleRewardLabel:setAnchorPoint(ccp(0, 1))
        aDoubleRewardLabel:setPosition(ccp(250, aStartPosY - aDoubleRewardLabel:getTexture():getContentSize().height))
        aScrollView:addChild(aDoubleRewardLabel)
        table.insert(aScrollContentList, aDoubleRewardLabel)
      end
      aStartPosY = aStartPosY - aCoinLabel:getTexture():getContentSize().height
      
      local aReceiveTitleLabel = TextField:create(Localization:getInstance():getText("stage_stageClearGet"), font_name, font_size)
      aReceiveTitleLabel:setHorizontalAlignment(kCCTextAlignmentLeft)
      aReceiveTitleLabel:setColor(ccc3(255,255,255))
      aReceiveTitleLabel:setAnchorPoint(ccp(0, 1))
      aReceiveTitleLabel:setPosition(ccp(0, aStartPosY))
      aScrollView:addChild(aReceiveTitleLabel)
      table.insert(aScrollContentList, aReceiveTitleLabel)
      aStartPosY = aStartPosY - aReceiveTitleLabel:getTexture():getContentSize().height
      
      local aNameLabel
      for j, aReward in ipairs(rewards) do
        local baseX = 0
        local aTempValue = math.mod(j, 2)
        if aTempValue < 0.01 then
          baseX = 250
        else
          baseX = 0
        end
        if aReward.itemType == ResourceEnum.CARD then
          local aCardMetaConfig = MetaManager.card_meta[aReward.metaId]
          aNameLabel = TextField:create(Localization:getInstance():getText(aCardMetaConfig.name), font_name, font_size)
          aNameLabel:setHorizontalAlignment(kCCTextAlignmentLeft)
          aNameLabel:setColor(getColorWithQuality(aCardMetaConfig.rare))
          aNameLabel:setAnchorPoint(ccp(0, 1))
          aNameLabel:setPosition(ccp(baseX, aStartPosY))
          aScrollView:addChild(aNameLabel)
          table.insert(aScrollContentList, aNameLabel)
          local aNumLabel = TextField:create(string.format("*%d", aReward.amount), font_name, font_size)
          aNumLabel:setHorizontalAlignment(kCCTextAlignmentLeft)
          aNumLabel:setColor(ccc3(255,255,255))
          aNumLabel:setAnchorPoint(ccp(0, 1))
          aNumLabel:setPosition(ccp(baseX + aNameLabel:getTexture():getContentSize().width, aStartPosY))
          aScrollView:addChild(aNumLabel)
          table.insert(aScrollContentList, aNumLabel)
        elseif aReward.itemType == ResourceEnum.EQUIP then
          local aEquipMetaConfig = MetaManager.equip_meta[aReward.metaId]
          aNameLabel = TextField:create(Localization:getInstance():getText(aEquipMetaConfig.name), font_name, font_size)
          aNameLabel:setHorizontalAlignment(kCCTextAlignmentLeft)
          aNameLabel:setColor(getColorWithQuality(aEquipMetaConfig.quality))
          aNameLabel:setAnchorPoint(ccp(0, 1))
          aNameLabel:setPosition(ccp(baseX, aStartPosY))
          aScrollView:addChild(aNameLabel)
          table.insert(aScrollContentList, aNameLabel)
          local aNumLabel = TextField:create(string.format("*%d", aReward.amount), font_name, font_size)
          aNumLabel:setHorizontalAlignment(kCCTextAlignmentLeft)
          aNumLabel:setColor(ccc3(255,255,255))
          aNumLabel:setAnchorPoint(ccp(0, 1))
          aNumLabel:setPosition(ccp(baseX + aNameLabel:getTexture():getContentSize().width, aStartPosY))
          aScrollView:addChild(aNumLabel)
          table.insert(aScrollContentList, aNumLabel)
        elseif aReward.itemType == ResourceEnum.PROP then
          local aPropMetaConfig = MetaManager.prop_meta[aReward.metaId]
          aNameLabel = TextField:create(Localization:getInstance():getText(aPropMetaConfig.name), font_name, font_size)
          aNameLabel:setHorizontalAlignment(kCCTextAlignmentLeft)
          aNameLabel:setColor(getColorWithQuality(aPropMetaConfig.quality))
          aNameLabel:setAnchorPoint(ccp(0, 1))
          aNameLabel:setPosition(ccp(baseX, aStartPosY))
          aScrollView:addChild(aNameLabel)
          table.insert(aScrollContentList, aNameLabel)
          local aNumLabel = TextField:create(string.format("*%d", aReward.amount), font_name, font_size)
          aNumLabel:setHorizontalAlignment(kCCTextAlignmentLeft)
          aNumLabel:setColor(ccc3(255,255,255))
          aNumLabel:setAnchorPoint(ccp(0, 1))
          aNumLabel:setPosition(ccp(baseX + aNameLabel:getTexture():getContentSize().width, aStartPosY))
          aScrollView:addChild(aNumLabel)
          table.insert(aScrollContentList, aNumLabel)
        elseif aReward.itemType == ResourceEnum.BEAST_FRAGMENT then
          local beastId = math.fmod(math.modf(aReward.metaId / 100, 10), 1000)
          local aFragmentMetaConfig = MetaManager.beast_meta[beastId]
          local fragmentList = aFragmentMetaConfig.attrs.beastFragmentId:split("|")
          local fragmentIndex
          for k, v in ipairs(fragmentList) do
            local fragmentFormat = tostring(aReward.metaId)
            if v == fragmentFormat then
              fragmentIndex = k
              break
            end
          end
          aNameLabel = TextField:create(Localization:getInstance():getText(aFragmentMetaConfig.attrs.beastNameKey) .. Localization:getInstance():getText(string.format("beastFragment_%d", fragmentIndex)), font_name, font_size)
          aNameLabel:setHorizontalAlignment(kCCTextAlignmentLeft)
          aNameLabel:setColor(ccc3(255,255,255))
          aNameLabel:setAnchorPoint(ccp(0, 1))
          aNameLabel:setPosition(ccp(baseX, aStartPosY))
          aScrollView:addChild(aNameLabel)
          table.insert(aScrollContentList, aNameLabel)
          local aNumLabel = TextField:create(string.format("*%d", aReward.amount), font_name, font_size)
          aNumLabel:setHorizontalAlignment(kCCTextAlignmentLeft)
          aNumLabel:setColor(ccc3(255,255,255))
          aNumLabel:setAnchorPoint(ccp(0, 1))
          aNumLabel:setPosition(ccp(baseX + aNameLabel:getTexture():getContentSize().width, aStartPosY))
          aScrollView:addChild(aNumLabel)
          table.insert(aScrollContentList, aNumLabel)
        elseif aReward.itemType == ResourceEnum.EQUIP_FRAGMENT then
          local aFragmentMeta= MetaManager.equip_fragment_meta[aReward.metaId]
          local aEquipMetaConfig = MetaManager.equip_meta[aFragmentMeta.equipId]
          aNameLabel = TextField:create(Localization:getInstance():getText(aEquipMetaConfig.name).. Localization:getInstance():getText("fragment_equipTab"), font_name, font_size)
          aNameLabel:setHorizontalAlignment(kCCTextAlignmentLeft)
          aNameLabel:setColor(getColorWithQuality(aEquipMetaConfig.quality))
          aNameLabel:setAnchorPoint(ccp(0, 1))
          aNameLabel:setPosition(ccp(baseX, aStartPosY))
          aScrollView:addChild(aNameLabel)
          table.insert(aScrollContentList, aNameLabel)
          local aNumLabel = TextField:create(string.format("*%d", aReward.amount), font_name, font_size)
          aNumLabel:setHorizontalAlignment(kCCTextAlignmentLeft)
          aNumLabel:setColor(ccc3(255,255,255))
          aNumLabel:setAnchorPoint(ccp(0, 1))
          aNumLabel:setPosition(ccp(baseX + aNameLabel:getTexture():getContentSize().width, aStartPosY))
          aScrollView:addChild(aNumLabel)
          table.insert(aScrollContentList, aNumLabel)
        end
        aTempValue = math.mod(j, 2)
        if aTempValue < 0.01 then
          aStartPosY = aStartPosY - aNameLabel:getTexture():getContentSize().height
        end
      end
      local aTempValue = math.mod(#rewards, 2)
      if aTempValue > 0.01 then
        aStartPosY = aStartPosY - aNameLabel:getTexture():getContentSize().height
      end
      aStartPosY = aStartPosY - round_space
    end
    
    aScrollView:setContentSize(CCSizeMake(scroll_width, (aStartPosY < 0) and (scroll_height - aStartPosY) or scroll_height))
    if aStartPosY < 0 then
      for _, aGroup in ipairs(aScrollContentList) do
        aGroup:setPositionY(aGroup:getPositionY() - aStartPosY)
      end
      aScrollView:setContentOffset(ccp(0, aStartPosY), false)
    end
    
    
    self.tempLayer:setScale(0.1)
end

function SweepResultPanel:scaleIn()
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

  --添加到二级堆栈
  UiStackManager.push(self)
end

function SweepResultPanel:dismissSelf()
  UiStackManager.remove(self)
  if type(self.container.panelDismiss) == "function" then
    self.container:panelDismiss()
  end
  self.container.targetInfoPanel = nil
  self:removeFromParentAndCleanup(true)
  if self.container.checkUserLevelUp then
    self.container:checkUserLevelUp()
  end
end