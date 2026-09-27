require "canon.request.GetRechargeInfoRequest"
require "canon.request.GainRechargeReward"
require "canon.manager.MaintenanceManager"
require "canon.panel.GachaShowCardPanel"
require "canon.panel.DailyChargeRewardPanel"
require "canon.panel.RewardReviewPanel"
require "canon.panel.DailyChargeActivityInfoPanel"
require "canon.panel.SpiritInfoPanelNoBtn"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
-- Activity_DailyFirstChargeLayer
--


Activity_DailyFirstChargeLayer = class(Layer)
function Activity_DailyFirstChargeLayer:ctor()
    self.container = nil
end

function Activity_DailyFirstChargeLayer:create( container )
    local s = Activity_DailyFirstChargeLayer.new()
    s.container = container
    s:initLayer()
    return s
end

function Activity_DailyFirstChargeLayer:initLayer()
    Activity_DailyFirstChargeLayer.super.initLayer(self)
    self.constCardId = 106021
    
    self.builder = LayoutBuilder:createWithContentsOfFile("scene/launch_activity.json")
    self.builder.useArtLabelTTF = true
    self.mainUI = self.builder:build("launch_activity10")
    self:addChild(self.mainUI)
    
    self.mainUI:getChildByName("normal_card_small1"):setVisible(false)
    self.mainUI:getChildByName("normal_card_small2"):setVisible(false)
	
  	local lastDays = self.mainUI:getChildByName("txt_LA10_4"):getChildByName("txt")
  	lastDays:setColor(ccc3(0,255,0))
  	lastDays:setAroundColor(ccc3(255, 255, 255))

    -- 帮助界面
    local function infoButtonSelected(evt)
      self.container:setTableViewsEnabled(false)
      local aInfoPanel = DailyChargeActivityInfoPanel:create(self.container, {content1 = content1, content2 = content2, cardIdList = {101181, 101231}})
      self.container:addChild(aInfoPanel)
      aInfoPanel:scaleIn()
    end

    local infoButton = Button:create(self.mainUI:getChildByName("sky_btn_qa"))
    infoButton:addEventListener(Events.kStart, infoButtonSelected, self)

    -- 超级小玉卡牌详情，写死
    local cardFigure = getBigCanonCardWithInfoByMetaId(self.constCardId)
    local cardDetail = self.mainUI:getChildByName("card_icon_evolve_result_card_sb")
    cardFigure:setPosition(ccp(22,32))
    cardFigure:setScale(0.15)
    cardFigure.touchEnabled = false
    cardFigure.touchChildren = false

    cardFigure.atkBgSpt:setVisible(false)
    cardFigure.atkIconSpt:setVisible(false)
    cardFigure.textAtk:setVisible(false)
    cardFigure.defBgSpt:setVisible(false)
    cardFigure.defIconSpt:setVisible(false)
    cardFigure.textDef:setVisible(false)
    cardFigure.hpBgSpt:setVisible(false)
    cardFigure.hpIconSpt:setVisible(false)
    cardFigure.textHp:setVisible(false)

    cardDetail:addChild(cardFigure)

    local cardDetailBtn = Button:create(cardDetail)
    local function onCardDetailBtn(evt)
      CanonGoodIcon.popoutGoodPanel(ResourceEnum.CARD, self.constCardId)
    end
    cardDetailBtn:addEventListener(Events.kStart,onCardDetailBtn, self)

    -- 领取超级小玉按钮
    local receiveButtonDisplay = self.mainUI:getChildByName("btn_the_receive")
    receiveButtonDisplay:getChildByName("txt"):setString(getTextByKey("invitation_rewardsBtn"))
    local function receiveButtonSelected(evt)
      local function getGainRewardSucceed(responseData)
        local function onShowCardFinish()
          self.accumulateRechargeAwardNum = self.accumulateRechargeAwardNum - 1
          g_homeInfo.accumulateRechargeAwardNum = self.accumulateRechargeAwardNum
          self:setRechargeAwardNum()
    		  --添加卡牌获取提示框及更新本地数据 by dc
    		  local RewardPanel = GetRewardInfoPanel:create( self.container, responseData.data.rewards )
    		  PopoutManager:sharedManager():popout( RewardPanel, kPopoutDir.kScale, true, false ,self.container )
    		  RewardManager:getReward(responseData.data.rewards)

          self.container:resetTipInfoForActivity("Activity_DailyFirstCharge")
        end

        local panel = GachaShowCardPanel:create(self, responseData.data.rewards, 1, onShowCardFinish, 4)
        PopoutManager:sharedManager():popout(panel, nil, true, false, self)
      end

      local function getGainRewardFailed(evt)
			  local errorCode = tonumber(evt.data)
        if errorCode == 710516 then  --背包已满
          self.targetInfoPanel = NewPackageFullPanel:show()
        elseif errorCode == 714650 or errorCode == 714651 then
          self.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("activity_dailyCharge_overTime"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
        elseif errorCode == 716845 then
          self.targetInfoPanel = SpiritPackageFullPanel:show()
        else
          CanonMessageBox:showCommUnHandleErrorBox(errorCode)
        end
      end

      local params = {rewardType = 2}
      local request = GainRechargeReward.new(params, rpc.SendingPriority.kHigh)
      request:addEventListener(RequestNotifyEnum.GainRechargeRewardSucceed, getGainRewardSucceed)
      request:addEventListener(RequestNotifyEnum.GainRechargeRewardFailed, getGainRewardFailed)
      request:start()
    end

    self.receiveButton = Button:create(receiveButtonDisplay)
    self.receiveButton:addEventListener(Events.kStart,receiveButtonSelected, self)

    self.accumulateRechargeAwardNum = (g_homeInfo and g_homeInfo.accumulateRechargeAwardNum) and g_homeInfo.accumulateRechargeAwardNum or 0
    self:setRechargeAwardNum()

    -- 充值按钮和领取每日奖励按钮
    local chargeButtonDisplay = self.mainUI:getChildByName("btn_chr3")
    local function chargeButtonSelected(evt)
      if g_homeInfo.accumulateRechargeType == 1 then
        self.container:replaceScene(ShopScene, {enterScene="ActivityPanelScene",returnScene="ActivityPanelScene",selectPanelName="Activity_DailyFirstCharge", params = {tabIndex = TABLEVIEW_TAB_INDEX.CHARGE}})
      elseif g_homeInfo.accumulateRechargeType == 2 then
        local function getGainRewardSucceed(responseData)
          local function onGet()
            RewardManager:getReward(responseData.data.rewards)
            self.icon:setVisible(false)

            local function onGetInfoSucceed(evt)
              self.mainUI:getChildByName("txt_LA10_4"):getChildByName("txt"):setString(evt.data.remainingDays)
              self.rewardTable = evt.data.rewards[1]
              g_homeInfo.accumulateRechargeType = 3
              self:checkHomeInfo(g_homeInfo)
              self.container:resetTipInfoForActivity("Activity_DailyFirstCharge")
            end

            local function onGetInfoFailed(evt)
              local errorCode = tonumber(evt.data)
              CanonMessageBox:showCommUnHandleErrorBox(errorCode)

              self:checkHomeInfo(g_homeInfo)
            end

            local request = GetRechargeInfoRequest.new({}, rpc.SendingPriority.kHigh)
            request:addEventListener(RequestNotifyEnum.GetRechargeInfoSucceed, onGetInfoSucceed)
            request:addEventListener(RequestNotifyEnum.GetRechargeInfoFailed, onGetInfoFailed)
            request:start()
          end

          local rewardPanel = nil;
          if responseData.data.crit then
            rewardPanel = DailyChargeRewardPanel:create( self.container, {rewardList = responseData.data.rewards, rewardTitle = getTextByKey("reward_title"), callback = onGet} )
          else
            rewardPanel = RewardReviewPanel:create( self.container, {rewardList = responseData.data.rewards, rewardTitle = getTextByKey("reward_title"), callback = onGet} )
          end
          self.container:addChild(rewardPanel)
          rewardPanel:scaleIn()
        end

        local function getGainRewardFailed(evt)
			    local errorCode = tonumber(evt.data)
          if errorCode == 710516 then  --背包已满
            self.targetInfoPanel = NewPackageFullPanel:show()
          elseif errorCode == 714650 or errorCode == 714651 then
            self.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("activity_dailyCharge_overTime"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
          elseif errorCode == 716845 then
            self.targetInfoPanel = SpiritPackageFullPanel:show()
          else
            CanonMessageBox:showCommUnHandleErrorBox(errorCode)
          end
        end

        local params = {rewardType = 1}
        local request = GainRechargeReward.new(params, rpc.SendingPriority.kHigh)
        request:addEventListener(RequestNotifyEnum.GainRechargeRewardSucceed, getGainRewardSucceed)
        request:addEventListener(RequestNotifyEnum.GainRechargeRewardFailed, getGainRewardFailed)
        request:start()
      end
    end
    local chargeButton = Button:create(chargeButtonDisplay)
    chargeButton:addEventListener(Events.kStart,chargeButtonSelected, self)

    -- 剩余天数 面板状态
    local function onGetInfoSucceed(evt)
      self.mainUI:getChildByName("txt_LA10_4"):getChildByName("txt"):setString(evt.data.remainingDays)
      self.rewardTable = evt.data.rewards[1]

      if g_homeInfo == nil then
        g_homeInfo = {}
      end

      g_homeInfo.accumulateRechargeAwardNum = evt.data.accumulateRechargeAwardNum
      g_homeInfo.accumulateRechargeType = evt.data.accumulateRechargeType

      self:checkHomeInfo(g_homeInfo)
    end

    local function onGetInfoFailed(evt)
      self.mainUI:getChildByName("txt_LA10_4"):getChildByName("txt"):setString("??")
      self.container.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("activity-treasurebox-over"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
    end

    local request = GetRechargeInfoRequest.new({}, rpc.SendingPriority.kHigh)
    request:addEventListener(RequestNotifyEnum.GetRechargeInfoSucceed, onGetInfoSucceed)
    request:addEventListener(RequestNotifyEnum.GetRechargeInfoFailed, onGetInfoFailed)
    request:start()
end

function Activity_DailyFirstChargeLayer:checkHomeInfo(g_homeInfo)
    --(1-可充值;2-可领取;3-已领取)
    local iconNameStr = nil
    if g_homeInfo.accumulateRechargeType == 1 then
      self.mainUI:getChildByName("txt_LA10_1"):getChildByName("txt"):setString(getTextByKey("activity_dailyCharge_text1"))
      self.mainUI:getChildByName("txt_LA10_2"):getChildByName("txt"):setString(getTextByKey("activity_dailyCharge_text2"))
      self.mainUI:getChildByName("btn_chr3"):getChildByName("txt"):setString(getTextByKey("activity_dailyCharge_button1"))
      iconNameStr = "normal_card_small1"
    elseif g_homeInfo.accumulateRechargeType == 2 then
      self.mainUI:getChildByName("txt_LA10_1"):getChildByName("txt"):setString(getTextByKey("activity_dailyCharge_text3"))
      self.mainUI:getChildByName("txt_LA10_2"):getChildByName("txt"):setString(getTextByKey("activity_dailyCharge_text4"))
      self.mainUI:getChildByName("btn_chr3"):getChildByName("txt"):setString(getTextByKey("activity_dailyCharge_button2"))
      iconNameStr = "normal_card_small1"
    elseif g_homeInfo.accumulateRechargeType == 3 then
      self.mainUI:getChildByName("txt_LA10_1"):getChildByName("txt"):setString("")
      self.mainUI:getChildByName("txt_LA10_2"):getChildByName("txt"):setString("")
      self.mainUI:getChildByName("txt_LA10_9"):getChildByName("txt"):setString(getTextByKey("activity_dailyCharge_text5"))
      self.mainUI:getChildByName("txt_LA10_10"):getChildByName("txt"):setString(getTextByKey("activity_dailyCharge_text6"))

      self.mainUI:getChildByName("btn_chr3"):setVisible(false)
      iconNameStr = "normal_card_small2"
    else
      self.container.targetInfoPanel = CanonMessageBox:Show(Localization:getInstance():getText("activity-treasurebox-over"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
      return
    end

    local params = {sourceSizes = {118,118}}
    local goodType = self.rewardTable.itemType
    self.icon = CanonGoodIcon.createGoodIcon(goodType, tonumber(self.rewardTable.metaId), tonumber(self.rewardTable.amount), params)

    local posX = self.mainUI:getChildByName(iconNameStr):getPositionX()
    local posY = self.mainUI:getChildByName(iconNameStr):getPositionY()
    self.icon:setPositionXY(posX,posY)

    self.mainUI:addChild(self.icon);

    --num
    local numLabel = TextField:create(tonumber(self.rewardTable.amount), nil, 25)
    numLabel:setAnchorPoint(ccp(1,0.5))
    numLabel:setPositionXY(60,-50)
    self.icon:addChild(numLabel)

    local function onClickIconButton(evt)
      CanonGoodIcon.popoutGoodPanel(evt.target.goodType, evt.target.metaId)
    end

    self.iconBtn = Button:create(self.icon)
    self.iconBtn.goodType = self.rewardTable.itemType
    self.iconBtn.metaId = tonumber(self.rewardTable.metaId)
    self.iconBtn:addEventListener(Events.kStart, onClickIconButton)
end

function Activity_DailyFirstChargeLayer:setRechargeAwardNum()
  self.mainUI:getChildByName("txt_LA10_8"):getChildByName("txt"):setString(self.accumulateRechargeAwardNum)

  if self.accumulateRechargeAwardNum > 0 then
    self.receiveButton.display:getChildByName( "btn" ):setVisible(true)
    self.receiveButton.display:getChildByName( "btn_inactive" ):setVisible(false)
    self.receiveButton:setEnable(true)
  else
    self.receiveButton.display:getChildByName( "btn" ):setVisible(false)
    self.receiveButton.display:getChildByName( "btn_inactive" ):setVisible(true)
    self.receiveButton:setEnable(false)
  end
end

function Activity_DailyFirstChargeLayer:enable()
    --return 1
     local isEnable = MaintenanceManager.isActivityOpen("activityDailyCharge")
     return isEnable
end

function Activity_DailyFirstChargeLayer:dispose()
    Activity_DailyFirstChargeLayer.super.dispose(self)
end

function Activity_DailyFirstChargeLayer.getTipNum()
    --return 0

   if not Activity_DailyFirstChargeLayer.enable() then
     return 0
   end
  
   if g_homeInfo then
     local aTipNum = 0

     if g_homeInfo.accumulateRechargeAwardNum and g_homeInfo.accumulateRechargeAwardNum > 0 then
       aTipNum = aTipNum + 1
     end

     if g_homeInfo.accumulateRechargeType and g_homeInfo.accumulateRechargeType == 2 then
       aTipNum = aTipNum + 1
     end

     return aTipNum
   else
     return 0
   end
end