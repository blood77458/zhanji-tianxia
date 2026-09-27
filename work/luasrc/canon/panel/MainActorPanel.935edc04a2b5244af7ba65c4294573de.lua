--------------------------------------------------------------------------------
-- MainActorPanel.lua - 主公信息面板
-- author: shaomin.shi & fanzhou.long
-- updated: 2013-08-15
--------------------------------------------------------------------------------
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.models.CommonManager"

require "canon.request.BuyEnergyRequest"
require "canon.request.BuyEventPointRequest"
require "canon.manager.DailyDataManager"

require "canon.panel.ReNamePropBuyPanel"
require "canon.panel.ReNameInputPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

MainActorPanel = class(Layer)

----------------------------------------
----------------------------------------
function MainActorPanel:initUserInfo ()
  local userInfo = DataManager.getCurrUser()

  local GameMetaData = MetaManager.game_meta
  userInfo.energyMax = GameMetaData.gameSettingConfig.maxEnergy
  userInfo.eventPointMax = GameMetaData.gameSettingConfig.maxEventPoint
  userInfo.expMax = MetaManager.user_level[userInfo.level].exp
  userInfo.stBuyLimit = MetaManager.vip_setting[userInfo.vipLevel].purchaseStaminaPerDay
  userInfo.viBuyLimit = MetaManager.vip_setting[userInfo.vipLevel].purchaseVigourPerDay
  userInfo.friendNum = g_homeInfo and g_homeInfo.friendNum or 0
  userInfo.maxFriendNum = MetaManager.user_level[userInfo.level].friendMax
 
  return userInfo
end

function MainActorPanel:ctor()
    self.container = nil
    self.panelUI = nil
	self.panelLoaded = false
    self.userInfo = self:initUserInfo() --用户数据
end

----------------------------------------
-- 刷新数据
----------------------------------------
function MainActorPanel:refreshData()
  self.userInfo = self:initUserInfo()
  self:initLayer() 
end

function MainActorPanel:create( container )
  self.panelLoaded = false
  self.container = container
  local s = MainActorPanel.new()
  s:refreshData()
  self.container.mainActorPanel = s
  return s
end

----------------------------------------
-- 刷新经验条
----------------------------------------
function MainActorPanel:refreshEXPBar()
  local sprite = Sprite:create(UI_RES_PATH.."/common_new/common_icon_playerExp_main_sb.png")
  local exp_pic = self.panelUI:getChildByName("common_icon_playerExp_main")

  sprite:setPosition(ccp(exp_pic:getPosition().x, exp_pic:getPosition().y))
  sprite:setAnchorPoint(exp_pic:getAnchorPoint())
  sprite:setScaleY(exp_pic:getScaleY())
  sprite:setScaleX(exp_pic:getScaleX())
  exp_pic:setVisible(false)--隐藏原进度条
  self.progress = ProgressBar:create(sprite) 
  self.progress:setPercentage(self.userInfo.exp * 100 / self.userInfo.expMax)
  
  self.panelUI:addChild(sprite)
end

----------------------------------------
----------------------------------------
function MainActorPanel:refreshBasic()
	self.panelUI:getChildByName("common_txt_lv_num"):getChildByName("font"):setString(self.userInfo.level)--等级
    local font = self.panelUI:getChildByName("common_txt_icon_playerExp_num")
    font:getChildByName("font"):setColor(ccc3(255,255,255))
    font:getChildByName("font"):setAroundColor(ccc3(0, 0, 0))
	font:getChildByName("font"):setString(self.userInfo.exp .. "/" .. self.userInfo.expMax)
	font:setZOrder(1001)
	--self.panelUI:getChildByName("icon_hone_exp"):setZOrder(901)
    --[[local text = BitmapText:create(self.userInfo.exp .. "/" .. self.userInfo.expMax,"fonts/heiti.fnt")
    text:setPosition(ccp(font:getPositionX()+font:getGroupBounds().size.width/2,font:getPositionY()-font:getGroupBounds().size.height/2))
    self:addChild(text)]]
	--刷新经验条
	self:refreshEXPBar()
end

----------------------------------------
----------------------------------------
function MainActorPanel:refreshAdvance()
  local myStrength = math.floor(CommonManager:getLocalPlayerStrength())
  local queueLeadP,totalLeadP = CalculationManager.calcComplex_getQueueLeaderPoints()
  
  --self.panelUI:getChildByName("txt_icon_vipLevel"):getChildByName("font"):setString(self.userInfo.vipLevel)
  --[[if (self.userInfo.vipLevel<=0) then
	self.panelUI:getChildByName("icon_vipLevel"):setVisible(false)
	self.panelUI:getChildByName("level_number_simple"):setVisible(false)
  else]]
    local aLabel = self.panelUI:getChildByName("common_level_number_simple")
	local aNewLabel = ViewControlUtil.buildArtLabel(nil, tostring(self.userInfo.vipLevel),ccc3(255,236,60),ccc3(96,37,8))
	aLabel:setVisible(false)
	aNewLabel:setPosition(ccp(aLabel:getPositionX(),aLabel:getPositionY()))
	self.panelUI:addChild(aNewLabel)
  --end
  
  self.panelUI:getChildByName("common_txt_playerInfo_leadership_num"):getChildByName("font"):setString( queueLeadP .. "/" .. totalLeadP )
  self.panelUI:getChildByName("common_txt_playerInfo_strength_num"):getChildByName("font"):setString( myStrength )
  self.panelUI:getChildByName("common_txt_friend_num"):getChildByName("font"):setString( self.userInfo.friendNum .. "/" .. self.userInfo.maxFriendNum )
  self.panelUI:getChildByName("common_txt_icon_silverCoin_test_num"):getChildByName("font"):setString(self.userInfo.coins) --金币
  self.panelUI:getChildByName("common_txt_icon_goldCoin_test_num"):getChildByName("font"):setString( CalculationManager.calcComplex_getGemsNow() ) --宝石
end

----------------------------------------
----------------------------------------
function MainActorPanel:refreshPP()
  local stNow, stNextTime, stAllTime = CalculationManager.calcComplex_getEnergyNow()
  --self.userInfo.energy = stNow
  self.userInfo.stNextTime = TimeUtil.formatTime( stNextTime )
  self.userInfo.stAllTime = TimeUtil.formatTime( stAllTime )
  
  local viNow, viNextTime, viAllTime = CalculationManager.calcComplex_getEPNow()
  --self.userInfo.eventPoint = viNow
  self.userInfo.viNextTime = TimeUtil.formatTime( viNextTime )
  self.userInfo.viAllTime = TimeUtil.formatTime( viAllTime )

  self.panelUI:getChildByName("common_txt_playerInfo_stamina_num"):getChildByName("font"):setColor(ccc3(0, 210, 255))
  self.panelUI:getChildByName("common_txt_playerInfo_stamina_num"):getChildByName("font"):setAroundColor(ccc3(0, 0, 0))

  self.panelUI:getChildByName("common_txt_playerInfo_vigour_num"):getChildByName("font"):setColor(ccc3(37, 255, 0))
  self.panelUI:getChildByName("common_txt_playerInfo_vigour_num"):getChildByName("font"):setAroundColor(ccc3(0, 0, 0))
  
  self.panelUI:getChildByName("common_txt_playerInfo_stamina_num"):getChildByName("font"):setString(stNow .. "/" .. self.userInfo.energyMax)    
  self.panelUI:getChildByName("common_txt_playerInfo_staminaNextRecover_num"):getChildByName("font"):setString(self.userInfo.stNextTime)
  self.panelUI:getChildByName("common_txt_playerInfo_staminaFullRecover_num"):getChildByName("font"):setString(self.userInfo.stAllTime)
    
  self.panelUI:getChildByName("common_txt_playerInfo_vigour_num"):getChildByName("font"):setString(viNow .. "/" .. self.userInfo.eventPointMax)
  self.panelUI:getChildByName("common_txt_playerInfo_vigourNextRecover_num"):getChildByName("font"):setString(self.userInfo.viNextTime)
  self.panelUI:getChildByName("common_txt_playerInfo_vigourFullRecover_num"):getChildByName("font"):setString(self.userInfo.viAllTime)
  local btnDisplay1 = self.panelUI:getChildByName("common_btn_playerInfo_instantRecover_stamina")
  if (stNow>=self.userInfo.energyMax) then
	btnDisplay1:setVisible(false)
  end
  local btnDisplay2 = self.panelUI:getChildByName("common_btn_playerInfo_instantRecover_vigour")
  if (viNow >= self.userInfo.eventPointMax) then
	btnDisplay2:setVisible(false)
  end

  --改名刷新时间

  -- local nowTime = TimeUtil.getServerTimeSeconds()
  -- local timePassed = nowTime - DataManager.getGameInitData().sharkUserExtend.lastRenameTimes
  -- local timeRemain = MetaManager.game_meta.gameSettingConfig.renameCooldown - timePassed
  local renameNextTime , timeRemain = CalculationManager.calcComplex_getRenameCoolingTime()
  self.panelUI:getChildByName("common_txt_changename_cooling_3"):getChildByName("txt"):setString(renameNextTime)
  if timeRemain <= 0 then
    self.btnChangeNamebtn:setEnable(true)
    self.panelUI:getChildByName("common_btn_playerInfo_instantRecover_name"):getChildByName("btn"):setVisible(true)
  self.panelUI:getChildByName("common_btn_playerInfo_instantRecover_name"):getChildByName("btn_inactive"):setVisible(false)
  end

end

----------------------------------------
----------------------------------------
function MainActorPanel:setButtons()
    --关闭按钮
    local function onClosePanel(evt)
		self.container.targetInfoPanel = nil
    self.container.mainActorPanel = nil
    if type(self.container.setTableViewsEnabled) == "function" then
      self.container:setTableViewsEnabled(true)
    end
		PopoutManager:pullin( self, kPopoutDir.kScale )
    end
    local bt_panel_close = Button:create(self.panelUI:getChildByName("common_btn_close"))
    bt_panel_close:addEventListener(Events.kStart, onClosePanel)
	
    --恢复体力按钮
    local function onRecoveryBtn1(evt)
      local function callback()
        self:refreshAdvance()
        self:refreshPP()
        if(self.container.__FLAG and self.container.__FLAG == "SecretaryScene") then
          self.container:afterBuyEnerySuccessed();
        end
        if(self.container.curSceneEnum == SceneEnum.ActivityScene) and self.container.selectedPanelName == "Activity_Challenge" then
          self.container.selectedPanel:refreshTableList()
        end
      end
      local aPanel = EENPSupplyPanel:create(self.container, {supplyType = EESupplyTypeEnum.Energy, callback = callback})
      self.container:addChild(aPanel)
      aPanel:scaleIn()
      --[[
      local aConfig = DataManager.GameMetaData.replenishEnergyConfig.items
      local energyGainedByGem = MetaManager.getEnergyGainedByGem()
      if (DailyDataManager.getEnergyBoughtNum() >= self.userInfo.stBuyLimit) then
        CanonMessageBox:Show(
          Localization:getInstance():getText("playerInfo_cannotRecoverStamina"),
          ShowMessageType.ShowText,
          ShowButtonType.ID_OK,
          40
        )
      else
        local price = 0
        for _,value in pairs(aConfig) do
          if (DailyDataManager.getEnergyBoughtNum() + 1 <= value["endTimes"]) then
            price = value["goldCost"]
            break
          end
          if (value["endTimes"] == -1) then
            price = value["goldCost"]
          end
        end
			
        --恢复成功后的处理
        local function afterBuyEnergy()
          -- 当前体力值
          local curEnergy = CalculationManager.calcComplex_getEnergyNow()
          -- 恢复体力值
          local energyAmount = 0
          if curEnergy + energyGainedByGem <= self.userInfo.energyMax then
            energyAmount = energyGainedByGem
          else
            energyAmount = self.userInfo.energyMax - curEnergy
          end
          if energyAmount < 0 then
            energyAmount = 0
          end
          local aReward = {
            {	itemType = ResourceEnum.GEMS,
              amount = price * -1,
            },
            {	itemType = ResourceEnum.ENERGY,
              amount = energyAmount,
            }
          }
          RewardManager:getReward(aReward)
        
          self:refreshPP()
          self:refreshAdvance()
          SuspensionLabel:showContent(self, getTextByKey("playerInfo_recoverStaminaComplete", {num = energyAmount}))
          DailyDataManager.setEnergyBoughtNum(DailyDataManager.getEnergyBoughtNum() + 1)
        end
			
        --购买体力失败
        local function buyEnergyFailed(evt) 
          local errorCode = tonumber(evt.data)
          if CommErrorCodes.USER_ENERGY_FULL == errorCode then
            CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_ENERGY_FULL, nil, nil, nil)
          elseif CommErrorCodes.USER_ENERGY_BOUGHT_NUM_FULL == errorCode then
            CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_ENERGY_BOUGHT_NUM_FULL, nil, nil, nil)
          end
        end
        
        --发送恢复请求前的检查
        local function preSendRecoverRequest()
          if (price>CalculationManager.calcComplex_getGemsNow()) then
            local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin )
            self:addChild(aPanel)
            aPanel:scaleIn()
          else
            --构造请求
            local request = BuyEnergyRequest.new( params, rpc.SendingPriority.kHigh )
            request:addEventListener(RequestNotifyEnum.BuyEnergySucceed, afterBuyEnergy)
            request:addEventListener(RequestNotifyEnum.BuyEnergyFailed, buyEnergyFailed)
            --发送请求
            request:start()
          end
        end
        CanonMessageBox:Show(
          Localization:getInstance():getText("playerInfo_recoverStaminaConfirm", {num = price, energyNum = energyGainedByGem}),
          ShowMessageType.ShowText,
          ShowButtonType.ID_OK_CANCEL,
          40,
          preSendRecoverRequest
        )
      end
      self:refreshAdvance()
      self:refreshPP()]]
    end
    local btnDisplay1 = self.panelUI:getChildByName("common_btn_playerInfo_instantRecover_stamina")
    if (self.userInfo.energy>=self.userInfo.energyMax) then
      btnDisplay1:setVisible(false)
    else
      btnDisplay1:getChildByName("txt_yes"):setString(getTextByKey("playerInfo_replenishStamina"))
      local bt_panel_recovery1 = Button:create(btnDisplay1)
      bt_panel_recovery1:addEventListener(Events.kStart, onRecoveryBtn1)
    end
    
    --恢复精力按钮
    local function onRecoveryBtn2(evt)
      local function callback()
        self:refreshAdvance()
        self:refreshPP()

        if(self.container.__FLAG and self.container.__FLAG == "SecretaryScene") then
          self.container:afterBuyEventPointSuccessed();
        end
        if(self.container.curSceneEnum == SceneEnum.ActivityScene) and self.container.selectedPanelName == "Activity_Challenge" then
          self.container.selectedPanel:refreshTableList()
        end
      end
      local aPanel = EENPSupplyPanel:create(self.container, {supplyType = EESupplyTypeEnum.EventPoint, callback = callback})
      self.container:addChild(aPanel)
      aPanel:scaleIn()
      --[[
		local aConfig = DataManager.GameMetaData.replenishEventPointConfig.items
    local eventPointGainedByGem = MetaManager.getEventPointGainedByGem()
		if (DailyDataManager.getEventPointBoughtNum() >= self.userInfo.viBuyLimit) then
			CanonMessageBox:Show(
				Localization:getInstance():getText("playerInfo_cannotRecoverVigour"),
				ShowMessageType.ShowText,
				ShowButtonType.ID_OK,
				40
			)
		else
      local price = 0
        for _,value in pairs(aConfig) do
          if (DailyDataManager.getEventPointBoughtNum() + 1 <= value["endTimes"]) then
            price = value["goldCost"]
            break
          end
          if (value["endTimes"] == -1) then
            price = value["goldCost"]
          end
        end
			
        --恢复成功后的处理
        local function afterBuyEventPoint()
          -- 当前精力值
          local curEventPoint = CalculationManager.calcComplex_getEPNow()
          -- 恢复精力值
          local eventPointAmount = 0
          if curEventPoint + eventPointGainedByGem <= self.userInfo.eventPointMax then
            eventPointAmount = eventPointGainedByGem
          else
            eventPointAmount = self.userInfo.eventPointMax - curEventPoint
          end
          if eventPointAmount < 0 then
            eventPointAmount = 0
          end
          local aReward = {
            {	itemType = ResourceEnum.GEMS,
              amount = price * -1,
            },
            {	itemType = ResourceEnum.EVENTPOINT,
              amount = eventPointAmount,
            }
          }
          RewardManager:getReward(aReward)
          RewardManager.setEventPoint(curEventPoint + eventPointAmount)
        
          self:refreshPP()
          self:refreshAdvance()
          SuspensionLabel:showContent(self, getTextByKey("playerInfo_recoverVigourComplete", {num = eventPointAmount}))
          DailyDataManager.setEventPointBoughtNum(DailyDataManager.getEventPointBoughtNum() + 1)
        end
			
        --购买精力失败
        local function buyEventPointFailed(evt) 
          local errorCode = tonumber(evt.data)
          if 712309 == errorCode then
            CanonMessageBox:showCommErrorBox(712309, nil, nil, nil)
          elseif 710093 == errorCode then
            CanonMessageBox:showCommErrorBox(710093, nil, nil, nil)
          end
        end
        
        --发送恢复请求前的检查
        local function preSendRecoverRequest()
          if (price>CalculationManager.calcComplex_getGemsNow()) then
            local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin )
            self:addChild(aPanel)
            aPanel:scaleIn()
          else
            --构造请求
            local request = BuyEventPointRequest.new( params, rpc.SendingPriority.kHigh )
            request:addEventListener(RequestNotifyEnum.BuyEventPointSucceed, afterBuyEventPoint)
            request:addEventListener(RequestNotifyEnum.BuyEventPointFailed, buyEventPointFailed)
            --发送请求
            request:start()
          end
        end
        CanonMessageBox:Show(
          Localization:getInstance():getText("playerInfo_recoverVigourConfirm", {num = price, eventPointNum = eventPointGainedByGem}),
          ShowMessageType.ShowText,
          ShowButtonType.ID_OK_CANCEL,
          40,
          preSendRecoverRequest
        )
		end
		self:refreshAdvance()
        self:refreshPP()]]
    end
    local btnDisplay2 = self.panelUI:getChildByName("common_btn_playerInfo_instantRecover_vigour")
    if (self.userInfo.eventPoint >= self.userInfo.eventPointMax) then
		  btnDisplay2:setVisible(false)
	  else
		  btnDisplay2:getChildByName("txt_yes"):setString(getTextByKey("playerInfo_replenishVigour"))
		  local bt_panel_recovery2 = Button:create(btnDisplay2)
		  bt_panel_recovery2:addEventListener(Events.kStart, onRecoveryBtn2)
	  end

    local function onChangeName( evt )
      local reNamePropId =  MetaManager.game_meta.gameSettingConfig.renamePropId
      if BagCalcManager.getNumById(reNamePropId) > 0 then
        local targetInfoPanel = ReNameInputPanel:create(self)
        PopoutManager:sharedManager():popout(targetInfoPanel, kPopoutDir.kScale, true, false, self)
      else
        local targetInfoPanel = ReNamePropBuyPanel:create(self)
        PopoutManager:sharedManager():popout(targetInfoPanel, kPopoutDir.kScale, true, false, self)
      end
    end
    local btnChangeNameDisplay = self.panelUI:getChildByName("common_btn_playerInfo_instantRecover_name")
    self.panelUI:getChildByName("common_btn_playerInfo_instantRecover_name"):getChildByName("txt_yes"):setString(getTextByKey("rename_button_rename1"))
    self.btnChangeNamebtn = Button:create(btnChangeNameDisplay)
    self.btnChangeNamebtn:addEventListener(Events.kStart, onChangeName)
    -- local renameCd = DataManager.getGameInitData().sharkUserExtend.renameCd
    local nowTime = TimeUtil.getServerTimeSeconds()
    local timePassed = nowTime - DataManager.getGameInitData().sharkUserExtend.lastRenameTimes
    local timeRemain = MetaManager.game_meta.gameSettingConfig.renameCooldown - timePassed
    if timeRemain > 0 then
      self.btnChangeNamebtn:setEnable(false)
      self.panelUI:getChildByName("common_btn_playerInfo_instantRecover_name"):getChildByName("btn"):setVisible(false)
      self.panelUI:getChildByName("common_btn_playerInfo_instantRecover_name"):getChildByName("btn_inactive"):setVisible(true)
    end
end

----------------------------------------
-- layer初始化
----------------------------------------
function MainActorPanel:initLayer()
  if type(self.container.setTableViewsEnabled) == "function" then
    self.container:setTableViewsEnabled(false)
  end
    MainActorPanel.super.initLayer(self)
	
	--[[self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height+200))
    self:addChild(self.colorLayer)]]
    
    --载入builder信息
    local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
	builder.useArtLabelTTF = true
    --获取panel信息
    self.panelUI = builder:build("common_playerInfo")
    
    --id
    self.panelUI:getChildByName("common_txt_playerid"):getChildByName("txt"):setString("ID:" .. self.userInfo.uid)
    
    --Title
	self.panelUI:getChildByName("common_txt_playerInfo_playerName"):getChildByName("txt_playerInfo_playerName"):setString(self.userInfo.nickName)--姓名
  if UnionManager.isInUnion() then
    self.panelUI:getChildByName("txt_guild_namae"):setVisible(true)
    self.panelUI:getChildByName("txt_guild_namae"):getChildByName("txt"):setString(Localization:getInstance():getText("union_name_txt", {name = UnionManager.getUnionName()}))--otherUnionName
  else
    self.panelUI:getChildByName("txt_guild_namae"):setVisible(false)
  end
  self.panelUI:getChildByName("common_txt_playerInfo_title"):getChildByName("txt_playerInfo_title"):setString(Localization:getInstance():getText("playerInfo_title"))
    
	self.panelUI:getChildByName("common_txt_playerInfo_staminaNextRecover"):getChildByName("txt_playerInfo_staminaNextRecover"):setString(Localization:getInstance():getText("playerInfo_staminaNextRecover"))
	self.panelUI:getChildByName("common_txt_playerInfo_staminaFullRecover"):getChildByName("txt_playerInfo_staminaNextRecover"):setString(Localization:getInstance():getText("playerInfo_staminaFullRecover"))
	self.panelUI:getChildByName("common_txt_playerInfo_vigourNextRecover"):getChildByName("txt_playerInfo_staminaNextRecover"):setString(Localization:getInstance():getText("playerInfo_vigourNextRecover"))
	self.panelUI:getChildByName("common_txt_playerInfo_vigourFullRecover"):getChildByName("txt_playerInfo_staminaNextRecover"):setString(Localization:getInstance():getText("playerInfo_vigourFullRecover"))
	
	self.panelUI:getChildByName("common_txt_playerInfo_strength"):getChildByName("txt_playerInfo_strength"):setString(Localization:getInstance():getText("playerInfo_strength"))
	self.panelUI:getChildByName("common_txt_friend"):getChildByName("txt_playerInfo_leadership"):setString(Localization:getInstance():getText("playerInfo_friend"))
	self.panelUI:getChildByName("common_txt_playerInfo_leadership"):getChildByName("txt_playerInfo_leadership"):setString(Localization:getInstance():getText("playerInfo_leadership"))
	self.panelUI:getChildByName("common_txt_playerInfo_stamina"):getChildByName("txt_playerInfo_stamina"):setString(Localization:getInstance():getText("playerInfo_stamina"))
	self.panelUI:getChildByName("common_txt_playerInfo_vigour"):getChildByName("txt_playerInfo_vigour"):setString(Localization:getInstance():getText("playerInfo_vigour"))

    self:refreshBasic() 
    self:refreshAdvance()
    --刷新按钮
    self:setButtons()
    self:refreshPP()
    self:addChild(self.panelUI)
	self.panelLoaded = true
	local function refreshFunc()
		self:refreshPP()
	end
	self.onUpdateFunc = CCDirector:sharedDirector():getScheduler():scheduleScriptFunc(refreshFunc,1,false);
end

function MainActorPanel:dispose()
	CCDirector:sharedDirector():getScheduler():unscheduleScriptEntry(self.onUpdateFunc)
end

function MainActorPanel:refreshName()
  self.userInfo = self:initUserInfo()
  self.panelUI:getChildByName("common_txt_playerInfo_playerName"):getChildByName("txt_playerInfo_playerName"):setString(self.userInfo.nickName)--姓名

  local nowTime = TimeUtil.getServerTimeSeconds()

  local timePassed = nowTime - DataManager.getGameInitData().sharkUserExtend.lastRenameTimes
  local timeRemain = MetaManager.game_meta.gameSettingConfig.renameCooldown - timePassed
  local renameNextTime = TimeUtil.formatTime(timeRemain)
  self.panelUI:getChildByName("common_txt_changename_cooling_3"):getChildByName("txt"):setString(renameNextTime)

  self.btnChangeNamebtn:setEnable(false)
  self.panelUI:getChildByName("common_btn_playerInfo_instantRecover_name"):getChildByName("btn"):setVisible(false)
  self.panelUI:getChildByName("common_btn_playerInfo_instantRecover_name"):getChildByName("btn_inactive"):setVisible(true)
end