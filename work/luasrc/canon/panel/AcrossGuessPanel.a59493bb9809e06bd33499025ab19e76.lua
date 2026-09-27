require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.request.GetCrossPkCapacityRequest"
require "canon.panel.AcrossGuessSelectPanel"
require "canon.request.GuessCrossPkRankRequest"

local enter_animation_duration = 0.3
local enter_animation_cell_duration = 0.15
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--
--AcrossGuessPanel
--

local function getTimePartFromSeconds(aSeconds)
  local result = {}
  result.hour = math.modf(aSeconds / 3600)
  local leftSeconds = math.mod(aSeconds, 3600)
  result.min = math.modf(leftSeconds / 60)
  result.sec = math.mod(leftSeconds, 60)
  return result
end

AcrossGuessPanel = class(Layer)

function AcrossGuessPanel:ctor()
	self.container = nil
  self.selectedUid = nil
end

function AcrossGuessPanel:create(container)
	local s = AcrossGuessPanel.new()
	s:initLayer(container)
	return s
end

function AcrossGuessPanel:initLayer(container)
	AcrossGuessPanel.super.initLayer(self)
	self.container = container

	local builder = LayoutBuilder:createWithContentsOfFile("scene/across_fight.json")
  builder.useArtLabelTTF = true
  self.uiView = builder:build("across_fight_quiz")
  self:addChild(self.uiView)
  
  local sharkCrossPkUser = DataManager.getSharkCrossPkUser()
  local curVersion = AcrossFightManager.getCurVersion()
  if sharkCrossPkUser.crossVersion ~= curVersion then
    DataManager.resetSharkCrossPkUser(curVersion)
    sharkCrossPkUser = DataManager.getSharkCrossPkUser()
  end
  self.selectedUid = sharkCrossPkUser.guessUid
  
  local guessTimeLabel1 = self.uiView:getChildByName("txt_across_fight_11_1")
  guessTimeLabel1:getChildByName("txt"):setString(getTextByKey("cross_guess_over"))
  local guessTimeLabel2 = self.uiView:getChildByName("txt_across_fight_3")
  guessTimeLabel2:getChildByName("txt"):setString(getTextByKey("cross_guess_time"))
  local guessTimeLabel3 = self.uiView:getChildByName("txt_across_fight_4")
  local rankFlag1 = self.uiView:getChildByName("lbl_rank_oen")
  local rankFlag2 = self.uiView:getChildByName("lbl_rank_two")
  local rankFlag3 = self.uiView:getChildByName("lbl_rank_three")
  local rankFlag4 = self.uiView:getChildByName("lbl_rank_four")
  rankFlag1:setVisible(false)
  rankFlag2:setVisible(false)
  rankFlag3:setVisible(false)
  rankFlag4:setVisible(false)
  local guessRank = AcrossFightManager.getGuessRank()
  if guessRank == 1 then
    rankFlag1:setVisible(true)
  elseif guessRank == 2 then
    rankFlag2:setVisible(true)
  elseif guessRank == 3 then
    rankFlag3:setVisible(true)
  else
    rankFlag4:setVisible(true)
  end
  local selectedLabel1 = self.uiView:getChildByName("txt_across_fight_1")
  local selectedLabel2 = self.uiView:getChildByName("txt_across_fight_2")
  local chooseBtnDisplay = self.uiView:getChildByName("btn_the_choose")
  local function chooseBtnSelected(evt)
    local function onSucceed(requestEvent)
      GetCrossPkCapacityRequest.onSucceedDefault(requestEvent)
      local aPanel = AcrossGuessSelectPanel:create( self.container, self )
      --[[
      RewardPanel1.callBackFunc = function()
        self.container:setTableViewsEnabled(true)
      end
      ]]
      PopoutManager:sharedManager():popout( aPanel, kPopoutDir.kScale, true, false ,self.container )
    end
    GetCrossPkCapacityRequest.sendRequest(onSucceed, GetCrossPkCapacityRequest.onFailedDefault)
  end
  local chooseBtn = Button:create(chooseBtnDisplay)
  chooseBtn:addEventListener(Events.kStart, chooseBtnSelected, self)
  local crossServerSettingConfig = DataManager.GameMetaData.crossServerSettingConfig
  local guessSucceedLabel = self.uiView:getChildByName("txt_across_fight_11")
  guessSucceedLabel:getChildByName("txt"):setString(getTextByKey("cross_guess_wait"))
  local guessBtnDisplay = self.uiView:getChildByName("common_btn_long_yellow")
  guessBtnDisplay:getChildByName("txt"):setString(getTextByKey("cross_guess_confim"))
  local function guessBtnSelected(evt)
    if crossServerSettingConfig.guessPayGold > CalculationManager.calcComplex_getGemsNow() then
      local function onReplaceScene()
        self.container:setTableViewsEnabled(true)
        self.container.targetInfoPanel = nil
      end
      
      local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = nil})
      self.container:addChild(aPanel)
      aPanel:scaleIn()
      return
    end
    local function onSucceed(requestEvent)
      GuessCrossPkRankRequest.onSucceedDefault(requestEvent)
      RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -crossServerSettingConfig.guessPayGold})
      sharkCrossPkUser = DataManager.getSharkCrossPkUser()
      local curVersion = AcrossFightManager.getCurVersion()
      if sharkCrossPkUser.crossVersion ~= curVersion then
        DataManager.resetSharkCrossPkUser(curVersion)
        sharkCrossPkUser = DataManager.getSharkCrossPkUser()
      end
      sharkCrossPkUser.guessUid = self.selectedUid
      DataManager.setSharkCrossPkUser(sharkCrossPkUser)
      self.refreshSelf()
      self.container:refreshTabTag()
    end
    GuessCrossPkRankRequest.sendRequest(onSucceed, GuessCrossPkRankRequest.onFailedDefault, {guessUid = tonumber(self.selectedUid)})
  end
  local guessBtn = Button:create(guessBtnDisplay)
  guessBtn:addEventListener(Events.kStart, guessBtnSelected, self)
  
  self.uiView:getChildByName("txt_across_fight_9"):getChildByName("txt"):setString(getTextByKey("cross_guess_gold"))
  self.uiView:getChildByName("txt_across_fight_10"):getChildByName("txt"):setString(string.format("%d", crossServerSettingConfig.guessPayGold))
  self.uiView:getChildByName("txt_across_fight_6"):getChildByName("txt"):setString(getTextByKey("cross_guess_wingold"))
  self.uiView:getChildByName("txt_across_fight_7"):getChildByName("txt"):setString(string.format("%d", crossServerSettingConfig.guessPayGold * (crossServerSettingConfig.guessFactorMax or 1.5)))
  self.uiView:getChildByName("txt_across_fight_5"):getChildByName("txt"):setString(getTextByKey("cross_guess_losegold"))
  self.uiView:getChildByName("txt_across_fight_8"):getChildByName("txt"):setString(string.format("%d", crossServerSettingConfig.guessPayGold))
  
  local guessLeftSeconds = AcrossFightManager.getGuessLeftSeconds()
  
  local refreshSelf = function()
    if guessLeftSeconds > 0 then
      guessTimeLabel1:setVisible(false)
      guessTimeLabel2:setVisible(true)
      guessTimeLabel3:setVisible(true)
      local timePart = getTimePartFromSeconds(guessLeftSeconds)
      guessTimeLabel3:getChildByName("txt"):setString(string.format("%02d:%02d:%02d", timePart.hour, timePart.min, timePart.sec))
      if tonumber(sharkCrossPkUser.guessUid) == 0 then
        chooseBtn:setEnable(true)
        chooseBtnDisplay:getChildByName("btn"):setVisible(true)
        chooseBtnDisplay:getChildByName("btn_disable"):setVisible(false)
        if tonumber(self.selectedUid) == 0 then
          chooseBtnDisplay:getChildByName("txt"):setString(getTextByKey("cross_guess_choose"))
          guessBtn:setEnable(false)
          guessBtnDisplay:getChildByName("bg_btn"):setVisible(false)
          guessBtnDisplay:getChildByName("btn_common_inactive"):setVisible(true)
        else
          chooseBtnDisplay:getChildByName("txt"):setString(getTextByKey("cross_guess_change"))
          guessBtn:setEnable(true)
          guessBtnDisplay:getChildByName("bg_btn"):setVisible(true)
          guessBtnDisplay:getChildByName("btn_common_inactive"):setVisible(false)
        end
      else
        chooseBtn:setEnable(false)
        chooseBtnDisplay:getChildByName("btn"):setVisible(false)
        chooseBtnDisplay:getChildByName("btn_disable"):setVisible(true)
        chooseBtnDisplay:getChildByName("txt"):setString(getTextByKey("cross_guess_change"))
        guessBtn:setEnable(false)
        guessBtnDisplay:getChildByName("bg_btn"):setVisible(false)
        guessBtnDisplay:getChildByName("btn_common_inactive"):setVisible(true)
      end
    else
      guessTimeLabel1:setVisible(true)
      guessTimeLabel2:setVisible(false)
      guessTimeLabel3:setVisible(false)
      chooseBtn:setEnable(false)
      chooseBtnDisplay:getChildByName("btn"):setVisible(false)
      chooseBtnDisplay:getChildByName("btn_disable"):setVisible(true)
      if tonumber(sharkCrossPkUser.guessUid) == 0 then
        chooseBtnDisplay:getChildByName("txt"):setString(getTextByKey("cross_guess_choose"))
      else
        chooseBtnDisplay:getChildByName("txt"):setString(getTextByKey("cross_guess_change"))
      end
      guessBtn:setEnable(false)
      guessBtnDisplay:getChildByName("bg_btn"):setVisible(false)
      guessBtnDisplay:getChildByName("btn_common_inactive"):setVisible(true)
    end
    if tonumber(self.selectedUid) == 0 then
      selectedLabel1:getChildByName("txt"):setString("")
      selectedLabel2:getChildByName("txt"):setString("")
      
    else
      local serverNumber = tonumber(string.sub(self.selectedUid, -4, -1))
      if __IOS then
        selectedLabel1:getChildByName("txt"):setString(Localization:getInstance():getText("cross_list_text", {num1 = serverNumber}))
      else
        selectedLabel1:getChildByName("txt"):setString(Localization:getInstance():getText("cross_list_android", {num1 = serverNumber}))
      end
      selectedLabel2:getChildByName("txt"):setString(AcrossFightManager.getGuessUsername(self.selectedUid))
      
    end
    if tonumber(sharkCrossPkUser.guessUid) == 0 then
      guessSucceedLabel:setVisible(false)
    else
      guessSucceedLabel:setVisible(true)
    end
  end
  self.refreshSelf = refreshSelf
  
  refreshSelf()
  
  local function checkGuessTimeCallback()
    if guessLeftSeconds > 0 then
      guessLeftSeconds = guessLeftSeconds - 1
    end
    refreshSelf()
    if guessLeftSeconds <= 0 then
      if self.checkGuessTimeEntry then
        CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkGuessTimeEntry)
        self.checkGuessTimeEntry = nil
      end
    end
  end
  
  self.checkGuessTimeEntry = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(checkGuessTimeCallback,1,false)
end

function AcrossGuessPanel:dispose()
  if self.checkGuessTimeEntry then
    CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.checkGuessTimeEntry)
    self.checkGuessTimeEntry = nil
  end
  AcrossGuessPanel.super.dispose(self)
end

function AcrossGuessPanel:guessUidSelected(aUid)
  self.selectedUid = aUid
  self.refreshSelf()
end

function AcrossGuessPanel:setTableViewTouched(enabled)
  
end

function AcrossGuessPanel:panelEnter(callback)
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

function AcrossGuessPanel:panelExit(callback)
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