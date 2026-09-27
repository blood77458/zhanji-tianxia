-- modified by zheng.che @ 2014-8-18 10:39:13 增加万能转生卡处理require "canon.manager.MaintenanceManager"

require "canon.request.PrayCardFragmentRequest"
require "canon.panel.SoulPrayerResultPopPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- Activity_SoulPrayerLayer
--

local lastPrayCardId
local whetherGot

Activity_SoulPrayerLayer = class(Layer)
function Activity_SoulPrayerLayer:ctor()
    self.container = nil
    self.cardId = nil
end

function Activity_SoulPrayerLayer:create( container, extraArgs, extraArgs2 )
    local s = Activity_SoulPrayerLayer.new()
    self.container = container
    if type(extraArgs2) == "table" then
      self.cardId = extraArgs2.cardId
    else
      self.cardId = nil
    end
    s:initLayer()
    return s
end

function Activity_SoulPrayerLayer:initLayer()
    Activity_SoulPrayerLayer.super.initLayer(self)
    
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/soulprayer.json")
    self.builder.useArtLabelTTF = true
    self.mainUI = self.builder:build("soulprayer")
    self:addChild(self.mainUI)
    
    local prayerOriginalDisplay = self.mainUI:getChildByName("formation_item_l")
    local function selectButtonSelected(evt)
      --print("selectButtonSelected")
      --选择主卡过滤规则：稀有度大于等于4卡牌
      local function filterMasterCardFunc( cardList )
        local result = {}
        for k,card in pairs(cardList) do
          if MetaManager.card_meta[card.metaId].rare >= 4 then
            if MetaManager.card_meta[card.metaId].maxEvolvedLevel > 1 then
              if ItemManager.checkCardTypeCanPray(card.metaId) then
                --卡牌类型允许祈祷 add by czh @ 2014-8-18 16:46:09
                table.insert(result,card)
              end
            end
          end
        end
      return result
      end
      local argv = {enterScene="ActivityPanelScene",returnScene="ActivityPanelScene",params={cardType="master",filter=BACKPACK_FILTER.CARD,filterFunc = filterMasterCardFunc, preReturnScene = self.argv, isCardTrain = false}}
      self.container:replaceScene( BackpackScene , argv)    
    end
    local prayerOriginalButton = Button:create(prayerOriginalDisplay)
    prayerOriginalButton:addEventListener(Events.kStart,selectButtonSelected, self)
    local prayerCardDisplay
    local prayerCardButton
    local prayerNameLabel = self.mainUI:getChildByName("txt_cardname_l")
    
    local prayederOriginalDisplay = self.mainUI:getChildByName("frame_card")
    local prayederCardDisplay
    local prayederNameLabel = self.mainUI:getChildByName("txt_cardname_r")
    
    local selectButtonDisplay = self.mainUI:getChildByName("btn_select_card")
    selectButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity_pray_chooseCardBtn"))
    local selectButton = Button:create(selectButtonDisplay)
    selectButton:addEventListener(Events.kStart,selectButtonSelected, self)
    
    local advanceConsumeLabel = self.mainUI:getChildByName("txt_cost_info")
    advanceConsumeLabel:getChildByName("txt"):setString(Localization:getInstance():getText("activity_pray_advancedPrayTxt1"))
    
    local vipTipLabel = self.mainUI:getChildByName("txt_pray_info")
    
    local refreshSelf
    local prayButtonDisplay = self.mainUI:getChildByName("btn_pray")
    local function prayButtonSelected(evt)
      local prayConfig = DataManager.GameMetaData.prayConfig
      local whetherCousumeProp
      if DailyDataManager.getDailyDataPrayNum() >= 1 then
        whetherCousumeProp = true
      end
      if whetherCousumeProp and (BagCalcManager.getNumById(prayConfig.prayItemId) < 1) then
        local aContent = Localization:getInstance():getText("activity_pray_itemNotEnough")
        SuspensionLabel:showContent(self.container, aContent)
        return
      end
      local function prayCardFragmentSucceed(event)
        DailyDataManager.setDailyDataPrayNum(event.data.prayNum)
        lastPrayCardId = self.sharkCard.cardId
        if whetherCousumeProp then
          RewardManager:getReward({{itemType = ResourceEnum.PROP, metaId = prayConfig.prayItemId, amount = -1}})
        end
        RewardManager:getReward(event.data.rewards)
        refreshSelf()
        localStorage.setSoulPrayerCardId( lastPrayCardId )
        
        self.container:setTableViewsEnabled(false)
        local colorLayer = LayerColor:create()
        colorLayer:setOpacity(kDarkOpacity)
        colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
        self.container:addChild(colorLayer)
        local fspt = FlashSprite:create("EVO2/qidao")
        fspt:changeAnimation(0)
        fspt:setLoop(false)
        self.fspt_co = CocosObject.new(fspt)
        --self.fspt_co:setPositionX(visibleSize.width / 2.0)
        --self.fspt_co:setPositionY(visibleSize.height / 2.0)
        local function animationEnd(anim)
          fspt:unregisterEndAnimationScriptHandler()
          self.container:removeChild(self.fspt_co)
          self.container:setTableViewsEnabled(true)
          self:openResultPanel(event.data.rewards[1].metaId)
          self.container:removeChild(colorLayer)
        end
        fspt:registerEndAnimationScriptHandler(animationEnd)
        self.container:addChild(self.fspt_co)
        
        if event.data.prayNum == 1 then
          self.container:resetTipInfoForActivity("Activity_Pray")
        end
      end 
      local function prayCardFragmentFailed(event)
        if event.data.retCode == 713609 then
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("activity_pray_noMoreTimes", {errorCodeId = event.data.retCode})
          CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        else
          local function closeCanonMessageBox()
          end
          local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = event.data.retCode})
          CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        end
      end
      local params = {cardId = self.sharkCard.cardId}
      local request = PrayCardFragmentRequest.new(params, rpc.SendingPriority.kHigh)
      request:addEventListener(RequestNotifyEnum.PrayCardFragmentSucceed, prayCardFragmentSucceed)
      request:addEventListener(RequestNotifyEnum.PrayCardFragmentFailed, prayCardFragmentFailed)
      request:start()
    end
    local prayButton = Button:create(prayButtonDisplay)
    prayButton:addEventListener(Events.kStart,prayButtonSelected, self)
    
    if __IOS and toluahelper.isIOS64bit() then
      self.mainUI:getChildByName("txt_pray_info2"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_pray_tips") .. "\n\n")
    else
      self.mainUI:getChildByName("txt_pray_info2"):getChildByName("txt"):setString(Localization:getInstance():getText("activity_pray_tips"))
    end
    
    if not whetherGot then
      lastPrayCardId = localStorage.getSoulPrayerCardId()
      whetherGot = true
    end
    
    refreshSelf = function()
      if not self.cardId then
        if lastPrayCardId then
          self.cardId = lastPrayCardId
        end
      end
      
      if self.cardId then
        local cardsData = DataManager.getCardsData()
        if cardsData then
          for _, aCard in ipairs(cardsData) do
            if aCard.cardId == self.cardId then
              self.sharkCard = aCard
              break
            end
          end
        end
      end
      
      --self.sharkCard = {metaId = 101741}--测试用

      local haveLastCard = false

      if self.sharkCard then
        local aCardMetaConfig = MetaManager.card_meta[self.sharkCard.metaId]
        local aActivityPrayConfig = MetaManager.activity_pray[aCardMetaConfig.cardGroupId]
        if aActivityPrayConfig then
          --容错 有这个卡牌id (如果切换账号后 两个账号刚巧有相同id的卡牌 可能会导致崩溃) by zheng.che
          haveLastCard = true
        end
      end

      if haveLastCard then
        local aCardMetaConfig = MetaManager.card_meta[self.sharkCard.metaId]
        local aActivityPrayConfig = MetaManager.activity_pray[aCardMetaConfig.cardGroupId]
        prayerOriginalDisplay:setVisible(false)
        prayerOriginalButton:setEnable(false)
        prayerCardDisplay = getHeadIconCanonCardByMetaId( CommonManager:changeAvatarByCardInfo( self.sharkCard ) )
        prayerCardDisplay:setPositionX(prayerOriginalDisplay:getPositionX() + 67.5)
        prayerCardDisplay:setPositionY(prayerOriginalDisplay:getPositionY() - 67.5)
        self.mainUI:addChildAt(prayerCardDisplay, 20)
        prayerCardButton = Button:create(prayerCardDisplay)
        prayerCardButton:addEventListener(Events.kStart,selectButtonSelected, self)
        prayerNameLabel:setVisible(true)
        
        prayerNameLabel:getChildByName("txt"):setString(Localization:getInstance():getText(aCardMetaConfig.name))
        
        prayederOriginalDisplay:setVisible(false)
        local aCardFragmentMetaConfig = MetaManager.card_fragment_meta[aActivityPrayConfig.targetId]
        prayederCardDisplay = getHeadIconCanonCardByMetaId(aCardFragmentMetaConfig.cardId)
        prayederCardDisplay:setPositionX(prayederOriginalDisplay:getPositionX())
        prayederCardDisplay:setPositionY(prayederOriginalDisplay:getPositionY())
        self.mainUI:addChildAt(prayederCardDisplay, 20)
        prayederNameLabel:setVisible(true)
        
        local aGenerateCardMetaConfig = MetaManager.card_meta[aCardFragmentMetaConfig.cardId]
        prayederNameLabel:getChildByName("txt"):setString(Localization:getInstance():getText(aGenerateCardMetaConfig.name))
        
        local aPrayNum = DailyDataManager.getDailyDataPrayNum()
        local aExtraPrayNum = MetaManager.vip_setting[DataManager.getCurrUser().vipLevel].extraPrayPerDay
        
        prayButtonDisplay:setVisible(true)
        if aPrayNum == 0 then
          advanceConsumeLabel:setVisible(false)
          vipTipLabel:setVisible(false)
          prayButtonDisplay:getChildByName("btn"):setVisible(true)
          prayButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity_pray_prayBtn"))
          prayButton:setEnable(true)
        else
          advanceConsumeLabel:setVisible(true)
          vipTipLabel:setVisible(true)
          if DataManager.getCurrUser().vipLevel < 3 then
            vipTipLabel:getChildByName("txt"):setString(Localization:getInstance():getText("activity_pray_advancedPrayTxt2"))
            prayButtonDisplay:getChildByName("btn"):setVisible(false)
            prayButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity_pray_advancedPrayBtn"))
            prayButton:setEnable(false)
          elseif aPrayNum < 1 + aExtraPrayNum then
            vipTipLabel:getChildByName("txt"):setString(Localization:getInstance():getText("activity_pray_advancedPrayTxt3", {num = 1 + aExtraPrayNum - aPrayNum}))
            prayButtonDisplay:getChildByName("btn"):setVisible(true)
            prayButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity_pray_advancedPrayBtn"))
            prayButton:setEnable(true)
          else
            vipTipLabel:getChildByName("txt"):setString(Localization:getInstance():getText("activity_pray_advancedPrayTxt3", {num = 1 + aExtraPrayNum - aPrayNum}))
            prayButtonDisplay:getChildByName("btn"):setVisible(false)
            prayButtonDisplay:getChildByName("txt"):setString(Localization:getInstance():getText("activity_pray_advancedPrayBtn"))
            prayButton:setEnable(false)
          end
        end
        
      else
        prayerOriginalDisplay:setVisible(true)
        selectButton:setEnable(true)
        if prayerCardDisplay then
          prayerCardButton:setEnable(false)
          prayerCardButton = nil
          prayerCardDisplay:removeFromParentAndCleanup(true)
          prayerCardDisplay = nil
        end
        prayerNameLabel:setVisible(false)
        prayederOriginalDisplay:setVisible(true)
        if prayederCardDisplay then
          prayederCardDisplay:removeFromParentAndCleanup(true)
          prayederCardDisplay = nil
        end
        prayederNameLabel:setVisible(false)
        
        advanceConsumeLabel:setVisible(false)
        vipTipLabel:setVisible(false)
        prayButtonDisplay:setVisible(false)
        prayButton:setEnable(false)
      end
    end
    
    refreshSelf()
    
    local oldDate = TimeUtil.getYmd()
    local function checkSwitchDay()
      local aTempTime = TimeUtil.getYmd()
      if oldDate ~= aTempTime then
        oldDate = aTempTime
        refreshSelf()
      end
    end
    self.checkSwitchDayFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(checkSwitchDay, 15, false)
end

function Activity_SoulPrayerLayer:enable()
    if not DataManager.GameMetaData.prayConfig then
      return false
    end
    local isEnable = MaintenanceManager.isActivityOpen(DataManager.GameMetaData.prayConfig.featureName)
    return isEnable
end 

function Activity_SoulPrayerLayer:dispose()
  if self.checkSwitchDayFunc then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkSwitchDayFunc)
    self.checkSwitchDayFunc = nil
  end
  Activity_SoulPrayerLayer.super.dispose(self)
end

--打开结算画面
function Activity_SoulPrayerLayer:openResultPanel(resultFragmentMetaId)
  local function onClose()
    --启用列表滚动
    self.container:setTableViewsEnabledInner(true)
    self.container.targetInfoPanel = nil--不加这句不让返回主scene
  end
  --弹出奖励
  self.aInfoPanel = SoulPrayerResultPopPanel:create(self.container, self, {metaId = resultFragmentMetaId}, onClose)
  self.container:addChild(self.aInfoPanel, 100)
  self.aInfoPanel:scaleIn()
  self.container:setTableViewsEnabledInner(false)
end

function Activity_SoulPrayerLayer.getTipNum()
  if not Activity_SoulPrayerLayer.enable() then
    return 0
  end
  
  if DailyDataManager.getDailyDataPrayNum() < 1 then
    return 1
  else
    return 0
  end
end