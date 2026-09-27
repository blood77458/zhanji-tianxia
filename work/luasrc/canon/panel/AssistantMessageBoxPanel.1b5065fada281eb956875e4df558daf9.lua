--------------------------------------------------------------------------------
-- AssistantMessageBoxPanel.lua - 带助手形象的提示信息面板
-- author: fanzhou.long
-- updated: 2013-08-15
--------------------------------------------------------------------------------

require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.request.localStorage"
require "canon.request.GainArenaScoreByRankRequest"
require "canon.customUI.SuspensionLabel"
require "canon.layer.Activity_ChargeRewardLayer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

AsMessageBoxType = {
  notFinished = "notFinished",
  notEnoughSoulStone = "notEnoughSoulStone",
  notEnoughPotential = "notEnoughPotential",
  giveUp = "giveUp",
  addCoin = "addCoin",
  putonCardEnough = "putonCardEnough",
  putonCardNotEnough = "putonCardNotEnough",
  }

local function leftButtonAction(evt)
  CanonPlayEffect("music/sfx_button_confirm.wav")
  local aPanel = evt.context
  
  if (aPanel.boxType == AsMessageBoxType.notFinished) then
    
  elseif (aPanel.boxType == AsMessageBoxType.putonCardEnough) then
      aPanel.container:moveOnFromEquipCardPanel(aPanel.trainOpt)
  elseif (aPanel.boxType == AsMessageBoxType.putonCardNotEnough) then
    aPanel.container:moveOnFromEquipCardPanel(aPanel.trainOpt)
  elseif (aPanel.boxType == AsMessageBoxType.notEnoughSoulStone ) then
	  --container 需继承BaseUIScene
    if aPanel.arg and aPanel.arg.onReplaceSceneFunc then
      aPanel.arg.onReplaceSceneFunc()
    end
	  aPanel.container:replaceToArena( ArenaRankScene )
  elseif (aPanel.boxType == AsMessageBoxType.notEnoughPotential ) then
      if (evt.context.choosed) then
        CardTrainingScene.saveNoShowAssistantPanel()
      end
      if aPanel.trainOpt.callback then
        aPanel.trainOpt.callback(aPanel.trainOpt)
      else
        aPanel.container:trainCard( aPanel.trainOpt )
      end
  elseif (aPanel.boxType == AsMessageBoxType.giveUp ) then
    if aPanel.arg and aPanel.arg.inCardInfoNewPanel then
      if aPanel.arg and aPanel.arg.onReplaceSceneFunc then
        aPanel.arg.onReplaceSceneFunc()
      end
    else
      aPanel.container:giveUpCardTrain( {cardId = aPanel.container.cardId}, true )
      if (aPanel.container.replaceFunc) then
      aPanel.container.replaceFunc()
      elseif (aPanel.container.params.returnScene == "CardQueueScene") then
      aPanel.container:replaceScene(CardQueueScene)
      else
      aPanel.container:replaceScene(BackpackScene)
      end
    end
  end
	if aPanel.container then
		aPanel.container.targetInfoPanel = aPanel.pre_container_targetInfoPanel
    --if (not aPanel.container.targetInfoPanel) then
      aPanel.container:setTableViewsEnabled(true)
    --end
	end
  
  aPanel:removeFromParentAndCleanup(true)
  UiStackManager.remove(aPanel)
end

local function rightButtonAction(evt)
  CanonPlayEffect("music/sfx_button_confirm.wav")
  local aPanel = evt.context
	
	local function gotoShopScene()
		if aPanel.arg and aPanel.arg.onReplaceSceneFunc then
			aPanel.arg.onReplaceSceneFunc()
		end
		if aPanel.container.curSceneEnum == SceneEnum.ShopScene and type(aPanel.container.showTableView) == "function" then
			aPanel.container:showTableView(TABLEVIEW_TAB_INDEX.CHARGE)
		elseif type(aPanel.container.replaceScene) == "function" then
			aPanel.container:replaceScene(ShopScene, {params = {tabIndex = TABLEVIEW_TAB_INDEX.CHARGE}})
    else
      Director:sharedDirector():replaceScene(ShopScene:create({params = {tabIndex = TABLEVIEW_TAB_INDEX.CHARGE}}))
		end
	end
  
  if (aPanel.boxType == AsMessageBoxType.notEnoughSoulStone ) then
    --TODO 跳转到充值界面
    --CanonMessageBox.showText(ShowButtonType.ID_OK, getTextByKey("popup_chargeDisabled"))
		gotoShopScene()
  elseif (aPanel.boxType == AsMessageBoxType.putonCardEnough) then
      aPanel.container:replaceScene(CardQueueScene, {enterScene="ChapterMapScene",returnScene="ChapterMapScene",params={}})
  elseif (aPanel.boxType == AsMessageBoxType.putonCardNotEnough) then
    aPanel.container:moveToCityMain()
  elseif (aPanel.boxType == AsMessageBoxType.addCoin ) then
		gotoShopScene()
    --CanonMessageBox.showText(ShowButtonType.ID_OK, getTextByKey("popup_chargeDisabled"))
  --[[
  elseif (aPanel.boxType == AsMessageBoxType.notFinished) then
  elseif (aPanel.boxType == AsMessageBoxType.notEnoughPotential ) then 
  elseif (aPanel.boxType == AsMessageBoxType.giveUp ) then
  --]]
  end
	if aPanel.container then
		aPanel.container.targetInfoPanel = aPanel.pre_container_targetInfoPanel
    if type(aPanel.container.setTableViewsEnabled) == "function" then
      aPanel.container:setTableViewsEnabled(true)
    end
    --if (not aPanel.container.targetInfoPanel) then
      -- aPanel.container:setTableViewsEnabled(true)
    --end
	end
  aPanel:removeFromParentAndCleanup(true)
  UiStackManager.remove(aPanel)
end

local function chooseButtonAction(evt)
  local chooseButtonDisplay = evt.context.chooseButtonDisplay
  
  if (evt.context.choosed) then
    chooseButtonDisplay:getChildByName("btn"):setVisible(false)
    evt.context.choosed = false
  else
    chooseButtonDisplay:getChildByName("btn"):setVisible(true)
    evt.context.choosed = true
  end
end

local function aCloseButtonAction(evt)
  local aPanel = evt.context
	if aPanel.container then
		aPanel.container.targetInfoPanel = aPanel.pre_container_targetInfoPanel
    --if (not aPanel.container.targetInfoPanel) then
    if type(aPanel.container.setTableViewsEnabled) == "function" then
      aPanel.container:setTableViewsEnabled(true)
    end
    --end
	end
  if aPanel.arg and aPanel.arg.brotherLayer then
    aPanel.arg.brotherLayer:setTableViewsEnabled(true)
  end
  aPanel:removeFromParentAndCleanup(true)
  UiStackManager.remove(aPanel)
end

AssistantMessageBoxPanel = class(Layer)

function AssistantMessageBoxPanel:ctor()
    self.container = nil
    self.boxType = nil
end

function AssistantMessageBoxPanel:create( container, boxType, trainOpt, arg )
    local s = AssistantMessageBoxPanel.new()
    s.container = container
    s.boxType = boxType
    s.trainOpt = trainOpt
		s.arg = arg
    s.chooseButtonDisplay = nil
    s.choosed = true
    s:initLayer()
    return s
end

function AssistantMessageBoxPanel:initLayer()
    MessageBoxPanel.super.initLayer(self)
    
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)
    
    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
    
    --Build panelUI
    local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
	builder.useArtLabelTTF = true
    local closeNameType = false
    if (self.boxType == AsMessageBoxType.notFinished) then
      self.panelUI = builder:build("common_popup_assistant_notFinish") 
    elseif (self.boxType == AsMessageBoxType.notEnoughSoulStone ) then
      self.panelUI = builder:build("common_popup_assistant_soulstone_notEnough") 
      closeNameType = true
    elseif (self.boxType == AsMessageBoxType.notEnoughPotential ) then
      self.panelUI = builder:build("common_popup_assistant_capacity_needTitle") 
    elseif (self.boxType == AsMessageBoxType.giveUp ) then
      self.panelUI = builder:build("common_popup_assistant_abandon_ensure") 
    elseif (self.boxType == AsMessageBoxType.putonCardEnough ) then
      self.panelUI = builder:build("common_popup_assistant_abandon_ensure")
    elseif (self.boxType == AsMessageBoxType.putonCardNotEnough ) then
      self.panelUI = builder:build("common_popup_assistant_abandon_ensure")
    elseif (self.boxType == AsMessageBoxType.addCoin) then
			self.chargeLevel = Activity_ChargeRewardLayer.getEnableChargeLevel()
			if MetaManager.charge_money_reward[self.chargeLevel + 1] then
				self.useNewCharge = true
			end
      closeNameType = true
			if self.useNewCharge then
				self.panelUI = builder:build("common_popup_firstCharge")
			else
				self.panelUI = builder:build("common_popup_addCoin_common1")
			end
      self.panelUI:setPosition(ccp(self.panelUI:getPosition().x,self.panelUI:getPosition().y - 150))
      
    end
    
    self.tempLayer:addChild(self.panelUI)
    
    --Build close button
    local aCloseButtonDisplay
		if closeNameType  then
			aCloseButtonDisplay = self.panelUI:getChildByName("btn_close")
		else
			aCloseButtonDisplay = self.panelUI:getChildByName("common_btn_close")
		end
		
    local aCloseButton = Button:create(aCloseButtonDisplay)
    aCloseButton:addEventListener( Events.kStart, aCloseButtonAction, self )
    
    local aLeftButtonDisplay = nil
    local aRightButtonDisplay = nil
    self.chooseButtonDisplay = nil
    --Build others
    if (self.boxType == AsMessageBoxType.notFinished) then
      --未完成的培养
      local aMessageLabel = self.panelUI:getChildByName("common_txt_cardTrain_notfinish_info"):getChildByName("txt_cardTrain_notfinish_info")
      aMessageLabel:setString(Localization:getInstance():getText("cardTrain_notfinish_info"))
      aLeftButtonDisplay = self.panelUI:getChildByName("common_btn_yes")
      aLeftButtonDisplay:getChildByName("txt_yes"):setString(Localization:getInstance():getText("yes"))
      
    elseif (self.boxType == AsMessageBoxType.notEnoughSoulStone ) then
      --魂石不够
      local aMessageTitle = self.panelUI:getChildByName("common_txt_cardTrain_soulstone_needtitle"):getChildByName("txt_cardTrain_soulstone_needtitle")
      local aMessageLabel = self.panelUI:getChildByName("common_txt_cardTrain_soulstone_needconent"):getChildByName("txt_cardTrain_soulstone_needconent")
      aLeftButtonDisplay = self.panelUI:getChildByName("common_btn_arena_entrance")
      aRightButtonDisplay = self.panelUI:getChildByName("common_btn_arena_entrance_addCoin")
      aMessageTitle:setString(Localization:getInstance():getText("cardTrain_soulstone_needtitle"))
      aMessageLabel:setString(Localization:getInstance():getText("cardTrain_soulstone_needconent"))
      aLeftButtonDisplay:getChildByName("txt_arena_entrance"):setString(Localization:getInstance():getText("cardTrain_enter_arena"))
      aRightButtonDisplay:getChildByName("txt_arena_entrance_addCoin"):setString(Localization:getInstance():getText("cardTrain_enter_addCoin"))
      
    elseif (self.boxType == AsMessageBoxType.notEnoughPotential ) then
      --潜力点不够
      local aMessageTitle = self.panelUI:getChildByName("common_txt_cardTrain_capacity_needtitle"):getChildByName("txt_cardTrain_capacity_needtitle")
      local aMessageLabel = self.panelUI:getChildByName("common_txt_cardTrain_capacity_needconent"):getChildByName("txt_cardTrain_capacity_needconent")
      local aChooseLabel = self.panelUI:getChildByName("common_txt_cardTrain_capacity_neednoinfo"):getChildByName("txt_cardTrain_capacity_neednoinfo")
      aMessageTitle:setString(Localization:getInstance():getText("cardTrain_capacity_needtitle"))
      aMessageLabel:setString(Localization:getInstance():getText("cardTrain_capacity_needconent"))
      aChooseLabel:setString(Localization:getInstance():getText("cardTrain_capacity_neednoinfo"))
      
      aLeftButtonDisplay = self.panelUI:getChildByName("common_btn_yes")
      aRightButtonDisplay = self.panelUI:getChildByName("common_btn_cancel")
      self.chooseButtonDisplay = self.panelUI:getChildByName("common_icon_checkbox")
      
      aLeftButtonDisplay:getChildByName("txt_yes"):setString(Localization:getInstance():getText("yes"))
      aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("cancel"))
      
    elseif (self.boxType == AsMessageBoxType.giveUp ) then
      --放弃培养
       local aMessageLabel = self.panelUI:getChildByName("common_txt_cardTrain_abandon_ensure"):getChildByName("txt_cardTrain_abandon_ensure")
        aMessageLabel:setString(Localization:getInstance():getText("cardTrain_abandon_ensure"))
        aLeftButtonDisplay = self.panelUI:getChildByName("common_btn_yes")
        aRightButtonDisplay = self.panelUI:getChildByName("common_btn_cancel")
        aLeftButtonDisplay:getChildByName("txt_yes"):setString(Localization:getInstance():getText("yes"))
        aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("cancel"))
    elseif (self.boxType == AsMessageBoxType.putonCardEnough ) then
       local aMessageLabel = self.panelUI:getChildByName("common_txt_cardTrain_abandon_ensure"):getChildByName("txt_cardTrain_abandon_ensure")
        aMessageLabel:setString(Localization:getInstance():getText("stageRemind_txt1"))--
        aLeftButtonDisplay = self.panelUI:getChildByName("common_btn_yes")
        aRightButtonDisplay = self.panelUI:getChildByName("common_btn_cancel")
        aLeftButtonDisplay:getChildByName("txt_yes"):setString(Localization:getInstance():getText("stageRemind_continueBtn"))
        aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("stageRemind_formationBtn"))
    elseif (self.boxType == AsMessageBoxType.putonCardNotEnough ) then
       local aMessageLabel = self.panelUI:getChildByName("common_txt_cardTrain_abandon_ensure"):getChildByName("txt_cardTrain_abandon_ensure")
        aMessageLabel:setString(Localization:getInstance():getText("stageRemind_txt2"))
        aLeftButtonDisplay = self.panelUI:getChildByName("common_btn_yes")
        aRightButtonDisplay = self.panelUI:getChildByName("common_btn_cancel")
        aLeftButtonDisplay:getChildByName("txt_yes"):setString(Localization:getInstance():getText("stageRemind_continueBtn"))
        aRightButtonDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("mail_backBtn"))
    elseif (self.boxType == AsMessageBoxType.addCoin ) then
      --金币不够
			if self.useNewCharge then
				self.panelUI:getChildByName("common_txt_popup_addCoin_common1_needtitle"):getChildByName("txt_popup_addCoin_common1_needtitle"):setString(getTextByKey("popup_addCoin_common1_needtitle"))
				self.panelUI:getChildByName("charge_reward_item"):setVisible(false)
				
				local rewardsLayer = Activity_ChargeRewardLayer.createRewardLayer(self.chargeLevel, ccc3(255, 255, 255))
				rewardsLayer:setPositionXY(self.panelUI:getChildByName("charge_reward_item"):getPositionX() + 75, self.panelUI:getChildByName("charge_reward_item"):getPositionY() - 60)
				self.panelUI:addChild(rewardsLayer)
				aRightButtonDisplay = self.panelUI:getChildByName("common_btn_arena_entrance_addCoin")
				aRightButtonDisplay:getChildByName("txt_arena_entrance_addCoin"):setString(Localization:getInstance():getText("cardTrain_enter_addCoin"))
			
				local rewardMeta = MetaManager.charge_money_reward[self.chargeLevel + 1]
				self.panelUI:getChildByName("txt_jiazhi_font"):getChildByName("txt"):setString(tostring(rewardMeta.worthGold))
				self.panelUI:getChildByName("txt_charge_5"):getChildByName("txt"):setString(getTextByKey(rewardMeta.describe))
				self.panelUI:getChildByName("txt_jiazhi"):getChildByName("txt"):setString(getTextByKey("chargeMoney_popup_dec_part_common"))
				self.panelUI:getChildByName("txt_charge_4"):getChildByName("txt"):setString(getTextByKey("chargeMoney_popup_dec_part_end_common"))
				self.panelUI:getChildByName("txt_charge_3"):getChildByName("txt"):setString(getTextByKey("chargeMoney_popup_dec_part2_not_first"))
				self.panelUI:getChildByName("txt_charge_2"):getChildByName("txt"):setString(tostring(rewardMeta.requireGold - tonumber(DataManager.getCurrUser().rechargeGems)))
				self.panelUI:getChildByName("txt_charge_1"):getChildByName("txt"):setString(getTextByKey("chargeMoney_popup_dec_part1_not_first"))
				self.panelUI:getChildByName("txt_charge_any2"):getChildByName("txt"):setString(getTextByKey("chargeMoney_popup_dec_part3_first"))
				self.panelUI:getChildByName("txt_charge_any"):getChildByName("txt"):setString(getTextByKey("chargeMoney_popup_dec_part2_first"))
				self.panelUI:getChildByName("common_txt_popup_addCoin_common1_needconent1"):getChildByName("txt_popup_addCoin_common1_needcontent"):setString(getTextByKey("chargeMoney_popup_dec_part1_first"))
				
				if self.chargeLevel == 0 then
					self.panelUI:getChildByName("txt_charge_1"):setVisible(false)
					self.panelUI:getChildByName("txt_charge_2"):setVisible(false)
					self.panelUI:getChildByName("txt_charge_3"):setVisible(false)
				else
					self.panelUI:getChildByName("txt_charge_any2"):setVisible(false)
					self.panelUI:getChildByName("txt_charge_any"):setVisible(false)
					self.panelUI:getChildByName("common_txt_popup_addCoin_common1_needconent1"):setVisible(false)
				end
			else
				local aMessageTitle = self.panelUI:getChildByName("common_txt_popup_addCoin_common1_needtitle"):getChildByName("txt_popup_addCoin_common1_needtitle")
				local aMessageLabel = self.panelUI:getChildByName("common_txt_popup_addCoin_common1_needcontent"):getChildByName("txt_popup_addCoin_common1_needcontent")
				aRightButtonDisplay = self.panelUI:getChildByName("common_btn_arena_entrance_addCoin")
				aMessageTitle:setString(Localization:getInstance():getText("popup_addCoin_common1_needtitle"))
				aMessageLabel:setString(Localization:getInstance():getText("popup_addCoin_common1_needcontent"))
				aRightButtonDisplay:getChildByName("txt_arena_entrance_addCoin"):setString(Localization:getInstance():getText("cardTrain_enter_addCoin"))
			end
      
    end
    
    if (aLeftButtonDisplay) then
      local aLeftButton = Button:create(aLeftButtonDisplay)
      aLeftButton:addEventListener( Events.kStart, leftButtonAction, self )
    end
    
    if (aRightButtonDisplay) then
      local aRightButton = Button:create(aRightButtonDisplay)
      aRightButton:addEventListener( Events.kStart, rightButtonAction, self )
    end

    if (self.chooseButtonDisplay) then
      local aChooseButton = Button:create(self.chooseButtonDisplay)
      aChooseButton:addEventListener( Events.kStart, chooseButtonAction, self )
    end
        
    self.tempLayer:setScale(0.1)
end

function AssistantMessageBoxPanel:scaleIn()
	if self.container then
		self.pre_container_targetInfoPanel = self.container.targetInfoPanel
		self.container.targetInfoPanel = self
    if type(self.container.setTableViewsEnabled) == "function" then
		  self.container:setTableViewsEnabled(false)
    end
	end
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

  --添加的二级堆栈
  UiStackManager.push(self)
end