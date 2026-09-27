require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.request.GainCrossPkRankRewardRequest"
require "canon.request.GainCrossPkGuessRewardRequest"
require "canon.request.GainCrossPkServerRewardRequest"

local enter_animation_duration = 0.3
local enter_animation_cell_duration = 0.15
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
--AcrossRewardPanel
--

AcrossRewardPanel = class(Layer)

function AcrossRewardPanel:ctor()
	self.container = nil
end

function AcrossRewardPanel:create(container)
	local s = AcrossRewardPanel.new()
	s:initLayer(container)
	return s
end

function AcrossRewardPanel:initLayer(container)
	AcrossRewardPanel.super.initLayer(self)
	self.container = container

	local builder = LayoutBuilder:createWithContentsOfFile("scene/across_fight.json")
  builder.useArtLabelTTF = true
  self.uiView = builder:build("across_fight_award")
  self:addChild(self.uiView)
  
  local rewardTimeLabel = self.uiView:getChildByName("txt_across_fight_14")
  rewardTimeLabel:getChildByName("txt"):setString(getTextByKey("cross_reward_finish"))
  local rankRewardBtnDisplay = self.uiView:getChildByName("common_button_long_blue")
  rankRewardBtnDisplay:getChildByName("txt_sure"):setString(getTextByKey("cross_reward_rank"))
  local guessRewardBtnDisplay = self.uiView:getChildByName("common_button_long_blue_award_quiz")
  guessRewardBtnDisplay:getChildByName("txt_sure"):setString(getTextByKey("cross_reward_guess"))
  local serverRewardBtnDisplay = self.uiView:getChildByName("btn_welfare")
  
  local playerInfo = {"playerlist_fo_m", "playerlist_fo_l", "playerlist_fo_r"}
  local playerList = AcrossFightManager.getRewardPlayerList()
  if not playerList then
    for _, aName in ipairs(playerInfo) do
      self.uiView:getChildByName(aName):setVisible(false)
    end
    rankRewardBtnDisplay:getChildByName("bg_button_long_blue"):setVisible(false)
    rankRewardBtnDisplay:getChildByName("btn_common_inactive"):setVisible(true)
    guessRewardBtnDisplay:getChildByName("bg_button_long_blue"):setVisible(false)
    guessRewardBtnDisplay:getChildByName("btn_common_inactive"):setVisible(true)
    serverRewardBtnDisplay:getChildByName("icon_reward_champion_tab"):setVisible(false)
    serverRewardBtnDisplay:getChildByName("icon_reward_champion_tab_grey"):setVisible(true)
    rewardTimeLabel:setVisible(false)
  else
    for i = 1, 3 do
      local localInfo = self.uiView:getChildByName(playerInfo[i])
      local newMeta = CommonManager:getSelfAvatarMetaByUid( playerList[i].uid )
      if not newMeta then
          newMeta = playerList[i].mainCardMetaId
      end
      local card = Sprite:createWithSpriteFrame(getFullCardSpriteFrame(newMeta))
      card:setAnchorPoint(ccp(0.5, 0))
      card:setScaleX(0.7)
      card:setScaleY(0.7)
      local posRef = localInfo:getChildByName("bg_player_name")
      local posX = localInfo:getPositionX() + posRef:getPositionX() + 0.5 * posRef:getContentSize().width
      local posY = localInfo:getPositionY() + posRef:getPositionY()
      card:setPosition(ccp(posX, posY))
      self.uiView:addChildAt(card, 2+i)
      card.hitTestPoint = function (self, worldPosition, useGroupTest)
        local posX = self:getPositionX()
        local posY = self:getPositionY()
        return worldPosition.x > posX - 105 and worldPosition.x < posX + 105 and worldPosition.y > posY and worldPosition.y < posY + 300
      end
      local button = Button:create(card)
      local function onClickFight()
        if tonumber(playerList[i].uid) == tonumber(DataManager.getCurrUser().uid) then
          return
        end
        local userDetailPanel = AcrossUserDetailPanel:create( self.container, {uid = playerList[i].uid} )
        PopoutManager:sharedManager():popout(userDetailPanel, kPopoutDir.kScale, true, false, self.container)
      end
      button:addEventListener(Events.kStart, onClickFight)
      
      localInfo:getChildByName("txt_player_level"):getChildByName("txt"):setString(tostring(playerList[i].level or 0))
      localInfo:getChildByName("txt_player_name"):getChildByName("txt"):setString(playerList[i].nickName)
      local serverNumber = tonumber(string.sub(tostring(playerList[i].uid), -4, -1))
      if __IOS then
        localInfo:getChildByName("txt_across_fight_1"):getChildByName("txt"):setString(Localization:getInstance():getText("cross_list_text", {num1 = serverNumber}))
      else
        localInfo:getChildByName("txt_across_fight_1"):getChildByName("txt"):setString(Localization:getInstance():getText("cross_list_android", {num1 = serverNumber}))
      end
    end
    
    local function rankRewardBtnSelected()
      if SpiritManager.isSpiritPoolFull() then
        SpiritPackageFullPanel:show()
        return
      end
      if BagCalcManager.isFull() then
        local aContent = Localization:getInstance():getText("rewardPopup_inventoryFullTxt")
        -- SuspensionLabel:showContent(self.container, aContent)
        NewPackageFullPanel:show()
        return
      end
      local function onSucceed(requestEvent)
        GainCrossPkRankRewardRequest.onSucceedDefault(requestEvent)
        local RewardPanel1 = GetRewardInfoPanel:create( self.container, requestEvent.data.rewards )
        RewardPanel1.callBackFunc = function()
          self.container:setTableViewsEnabled(true)
        end
        PopoutManager:sharedManager():popout( RewardPanel1, kPopoutDir.kScale, true, false ,self.container )
        self.refreshSelf()
        self.container:refreshTabTag()
      end
      GainCrossPkRankRewardRequest.sendRequest(onSucceed, GainCrossPkRankRewardRequest.onFailedDefault)
    end
    local rankRewardBtn = Button:create(rankRewardBtnDisplay)
    rankRewardBtn:addEventListener(Events.kStart, rankRewardBtnSelected, self)
    local function guessRewardBtnSelected()
      if SpiritManager.isSpiritPoolFull() then
        SpiritPackageFullPanel:show()
        return
      end
      if BagCalcManager.isFull() then
        local aContent = Localization:getInstance():getText("rewardPopup_inventoryFullTxt")
        -- SuspensionLabel:showContent(self.container, aContent)
        NewPackageFullPanel:show()
        return
      end
      local function onSucceed(requestEvent)
        GainCrossPkGuessRewardRequest.onSucceedDefault(requestEvent)
        local RewardPanel1 = GetRewardInfoPanel:create( self.container, requestEvent.data.rewards )
        RewardPanel1.callBackFunc = function()
          self.container:setTableViewsEnabled(true)
        end
        PopoutManager:sharedManager():popout( RewardPanel1, kPopoutDir.kScale, true, false ,self.container )
        self.refreshSelf()
        self.container:refreshTabTag()
      end
      GainCrossPkGuessRewardRequest.sendRequest(onSucceed, GainCrossPkGuessRewardRequest.onFailedDefault)
    end
    local guessRewardBtn = Button:create(guessRewardBtnDisplay)
    guessRewardBtn:addEventListener(Events.kStart, guessRewardBtnSelected, self)
    local function serverRewardBtnSelected()
      if SpiritManager.isSpiritPoolFull() then
        SpiritPackageFullPanel:show()
        return
      end
      if BagCalcManager.isFull() then
        local aContent = Localization:getInstance():getText("rewardPopup_inventoryFullTxt")
        -- SuspensionLabel:showContent(self.container, aContent)
        NewPackageFullPanel:show()
        return
      end
      local function onSucceed(requestEvent)
        GainCrossPkServerRewardRequest.onSucceedDefault(requestEvent)
        local RewardPanel1 = GetRewardInfoPanel:create( self.container, requestEvent.data.rewards )
        RewardPanel1.callBackFunc = function()
          self.container:setTableViewsEnabled(true)
        end
        PopoutManager:sharedManager():popout( RewardPanel1, kPopoutDir.kScale, true, false ,self.container )
        self.refreshSelf()
        self.container:refreshTabTag()
      end
      GainCrossPkServerRewardRequest.sendRequest(onSucceed, GainCrossPkServerRewardRequest.onFailedDefault)
    end
    local serverRewardBtn = Button:create(serverRewardBtnDisplay)
    serverRewardBtn:addEventListener(Events.kStart, serverRewardBtnSelected, self)
    
    self.refreshSelf = function()
      if AcrossFightManager.whetherHasRankReward() then
        rankRewardBtn:setEnable(true)
        rankRewardBtnDisplay:getChildByName("bg_button_long_blue"):setVisible(true)
        rankRewardBtnDisplay:getChildByName("btn_common_inactive"):setVisible(false)
      else
        rankRewardBtn:setEnable(false)
        rankRewardBtnDisplay:getChildByName("bg_button_long_blue"):setVisible(false)
        rankRewardBtnDisplay:getChildByName("btn_common_inactive"):setVisible(true)
      end
      if AcrossFightManager.whetherHasGuessReward() then
        guessRewardBtn:setEnable(true)
        guessRewardBtnDisplay:getChildByName("bg_button_long_blue"):setVisible(true)
        guessRewardBtnDisplay:getChildByName("btn_common_inactive"):setVisible(false)
      else
        guessRewardBtn:setEnable(false)
        guessRewardBtnDisplay:getChildByName("bg_button_long_blue"):setVisible(false)
        guessRewardBtnDisplay:getChildByName("btn_common_inactive"):setVisible(true)
      end
      if AcrossFightManager.whetherHasServerReward() then
        serverRewardBtn:setEnable(true)
        serverRewardBtnDisplay:getChildByName("icon_reward_champion_tab"):setVisible(true)
        serverRewardBtnDisplay:getChildByName("icon_reward_champion_tab_grey"):setVisible(false)
      else
        serverRewardBtn:setEnable(false)
        serverRewardBtnDisplay:getChildByName("icon_reward_champion_tab"):setVisible(false)
        serverRewardBtnDisplay:getChildByName("icon_reward_champion_tab_grey"):setVisible(true)
      end
    end
    
    self.refreshSelf()
  end
  
end

function AcrossRewardPanel:dispose()
  AcrossRewardPanel.super.dispose(self)
end

function AcrossRewardPanel:setTableViewTouched(enabled)
  
end

function AcrossRewardPanel:panelEnter(callback)
  local function enterActionFinished()
    if callback then
      callback()
    end
  end
  self.uiView:setPositionX(self.uiView:getPositionX() - visibleSize.width)
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(enterActionFinished))
  self.uiView:runAction(CCSequence:create(arr))
end

function AcrossRewardPanel:panelExit(callback)
  local function exitActionFinished()
    if callback then
      callback()
    end
  end
  local arr = CCArray:create()
  arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
  arr:addObject(CCCallFunc:create(exitActionFinished))
  self.uiView:runAction(CCSequence:create(arr))
end