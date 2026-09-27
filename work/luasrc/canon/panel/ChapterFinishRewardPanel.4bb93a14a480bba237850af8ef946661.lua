require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- ChapterFinishRewardPanel
--

ChapterFinishRewardPanel = class(Layer)

function ChapterFinishRewardPanel:ctor()
    self.container = nil
    self.arg = nil
end

function ChapterFinishRewardPanel:create( container, arg, callback )
    local s = ChapterFinishRewardPanel.new()
    s:initLayer(container, arg, callback)
    return s
end

function ChapterFinishRewardPanel:initLayer(container, arg, callback)
    ChapterFinishRewardPanel.super.initLayer(self)
    self.container = container
    self.container.targetInfoPanel = self
    self.arg = arg
    self.callback = callback
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)
    
    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("common_popup_stageclear") 
    self.tempLayer:addChild(self.panelUI)
    
    self.panelUI:getChildByName("common_txt_get"):getChildByName("txt"):setString(Localization:getInstance():getText("gotCharpterPresentTip"))
    local aIconDisplay = self.panelUI:getChildByName("common_normal_card_small_sb")
    aIconDisplay:setVisible(false)
    local icon
    local aBorder
    local aRewardName
    if self.arg.rewardType == 5 then
      icon = getHeadIconCanonCardByMetaId(self.arg.rewardID)
      icon:setScale(0.6)
      aRewardName = Localization:getInstance():getText(MetaManager.card_meta[self.arg.rewardID].name)
    elseif (self.arg.rewardType == 6) or (self.arg.rewardType == 7) then
      icon = CanonItem:create()
      icon:loadByMetaId(self.arg.rewardID)
      icon:setScale(0.6)
      if self.arg.rewardType == 6 then
        aRewardName = Localization:getInstance():getText(MetaManager.equip_meta[self.arg.rewardID].name)
      else
        aRewardName = Localization:getInstance():getText(MetaManager.prop_meta[self.arg.rewardID].name)
      end
    elseif self.arg.rewardType == 1 then
      icon = Sprite:create("common/CoinIcon_Mission.png")
      icon:setScale(0.65)
      aBorder = Sprite:create("Item/border/equipBorder1.png")
      aBorder:setScale(0.6)
      aRewardName = Localization:getInstance():getText("resource_silverCoin")
    elseif self.arg.rewardType == 2 then
      icon = Sprite:create("common/GemIcon_Mission.png")
      icon:setScale(0.65)
      aBorder = Sprite:create("Item/border/equipBorder1.png")
      aBorder:setScale(0.6)
      aRewardName = Localization:getInstance():getText("resource_goldCoin")
    else
      --碎片等
      local params = {}
      --params.sourceDisplay = aIconDisplay--美术资源有问题 改用写死尺寸
      params.sourceSizes = {80,80}
      params.isShowStar = false--显示稀有度星星
      params.withoutAmount = true--不显示数量
      icon = CanonGoodIcon.createGoodIcon(self.arg.rewardType, self.arg.rewardID, self.arg.amount, params)
      aRewardName = CanonGoodIcon.getGoodName(self.arg.rewardType, self.arg.rewardID, self.arg.amount, params)
    end
    self.panelUI:getChildByName("common_txtname"):getChildByName("txt"):setString(aRewardName)
    icon:setPosition( ccp(aIconDisplay:getPositionX(), aIconDisplay:getPositionY()) )
    self.panelUI:addChild(icon)
    if aBorder then
      aBorder:setPosition( ccp(aIconDisplay:getPositionX(), aIconDisplay:getPositionY()) )
      self.panelUI:addChild(aBorder)
    end
    self.panelUI:getChildByName("common_txt_shu"):getChildByName("txt"):setString(string.format("x%d", self.arg.amount))
    local aButtonDisplay = self.panelUI:getChildByName("common_button_long_yellow_sb")
    aButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("yes"))
    local function sureButtonSelected(evt)
      if self.arg.alreadyGet then
        self.container.targetInfoPanel = nil
        self:removeFromParentAndCleanup(true)
        callback()
      else
        local function gainChapterFinishRewardSucceed(event)
          RewardManager:getReward(event.data.reward)
          CountryManager:sharedManager():receiveChapterFinishReward(CountryManager:sharedManager().selectedChapterID)
          self.container.targetInfoPanel = nil
          self:removeFromParentAndCleanup(true)
		--
		--facebook share charpter clean
		FacebookShareManager.facebookShareCharpterMapClean(callback)
        --callback()
		--]]
        end
        
        local function gainChapterFinishRewardFailed(event)
          if event.data.retCode == 710407 then
            local aPanel = MessageBoxPanel:create(self, MessageBoxType.kCannotGainChapterReward)
            self:addChild(aPanel)
            aPanel:scaleIn()
          elseif event.data.retCode == 710408 then
            local aPanel = MessageBoxPanel:create(self, MessageBoxType.kAlreadyGainChapterReward)
            self:addChild(aPanel)
            aPanel:scaleIn()
          end
        end
        
        local params = {chapterId = CountryManager:sharedManager().selectedChapterID}
        local request = GainChapterFinishRewardRequest.new(params, rpc.SendingPriority.kHigh)
        request:addEventListener(RequestNotifyEnum.GainChapterFinishRewardSucceed, gainChapterFinishRewardSucceed)
        request:addEventListener(RequestNotifyEnum.GainChapterFinishRewardFailed, gainChapterFinishRewardFailed)
        request:start()
      end
    end

    local sureButton = Button:create(aButtonDisplay)
    sureButton:addEventListener(Events.kStart, sureButtonSelected, self)
    
    self.tempLayer:setScale(0.1)
end

function ChapterFinishRewardPanel:panelDismiss()
  self.container.targetInfoPanel = nil
  self:removeFromParentAndCleanup(true)
  local callback = self.callback
  callback()
end

function ChapterFinishRewardPanel:scaleIn()
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