--
-- TreasureNewInfoPanel.lua
-- Author: meilam.xie
-- Date: 2015-07-27 15:08:32
-- 创建宝物详情面板
--


local visibleSize = CCDirector:sharedDirector():getVisibleSize()


local function getTreasureInfoFromInitData(treasureId)
  local TreasuresData = DataManager.getTreasuresData()
  local aTreasure = {} 
  -- print("~~~~~~~~~~~~~~~~~~~~gameInitData.sharkTreasures = "..tostringRich(TreasuresData))   
  for _, temp in ipairs(TreasuresData) do
    if treasureId == temp.treasureId then
      aTreasure = temp
      break
      end
  end
  return aTreasure
end

local function refeshTreasureInfoFromInitData(aNewTreasure)
   local aSharkTreasures = DataManager.getTreasuresData()
    --print(table.tostring(aSharkEquips))
    for aIndex, Treasure in pairs(aSharkTreasures) do
      if Treasure.treasureId == aNewTreasure.treasureId then
        table.remove(aSharkTreasures, aIndex)
        break
      end
    end
    table.insert(aSharkTreasures, aNewTreasure)
    DataManager.setTreasuresData(aSharkTreasures)
end



--TreasureIntroductionTabView 简介


TreasureIntroductionTabView = class(Layer)

function TreasureIntroductionTabView:ctor()
    self.parentView = nil
    self.panelUI = nil
   
end

function TreasureIntroductionTabView:create(aParentView)
    local s = TreasureIntroductionTabView.new()
    s.parentView = aParentView
    s:initLayer()
    return s
end

function TreasureIntroductionTabView:initLayer()
	TreasureIntroductionTabView.super.initLayer(self)
  self.parentView:ShowPotentialNum (false)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/treasure.json")
	self.builder = builder
	builder.useArtLabelTTF = true
    self.panelUI = builder:build("frame_treasure_01")
    self:addChild(self.panelUI)
    
    
    
  --更换
	local function onClickChangeBtn(evt)
		local aTreasureData = getTreasureInfoFromInitData(self.parentView.Treasure.treasureId)
		 if (self.parentView.Treasure.cardId ~= 0 ) then
			local cardQueue = CommonManager.getQueueData()
			local cardIds = {}
			for aKey, aCardId  in pairs(cardQueue) do
				cardIds[aCardId] = aKey
			end
			-- HeMemDataHolder:setInteger("CardQueue_RollTo", cardIds[self.parentView.Treasure.cardId])
			HeMemDataHolder:setInteger("TreasureChange_CardId", self.parentView.Treasure.cardId)
			local argv = {
				enterScene="CardQueueScene",
				returnScene="CardQueueScene",
				params={
					
					cardId = self.parentView.Treasure.cardId,
          filterFunc = CardQueueScene.treasureFilterFunc,
          -- equipedDown = true,
          -- backToTreasure = true,
				}
			}
		    if self.parentView.enterAndReturnScene then
		      -- argv.enterScene = self.enterAndReturnScene
		      argv.returnScene = self.parentView.enterAndReturnScene
		    end
        -- print("~~~~~~~~~~~~~~~~~~~~~~~self.parentView.enterAndReturnScene = "..tostringRich(self.parentView.enterAndReturnScene))
       
		    
			PopoutManager:sharedManager():pullin(self.parentView.container.targetInfoPanel, kPopoutDir.kScale )
			self.parentView.container:replaceScene( TreasureBackpackScene , argv)
		else
     
        local aPanel = ItemSellMessageBoxPanel:create( self.parentView.container , {treasureData={self.parentView.Treasure.treasureId}, bagCategory = BAGCATEGORY.treasure}, self.parentView , self.parentView.newIndex)--self.newIndex
  			self.parentView.container:addChild(aPanel)
  			aPanel:scaleIn()  
     
		end
		
	end

    -- 
  self.ChangeBtnDisplay = self.panelUI:getChildByName("treasure_btn_equip_SellBtn")
	local aTreasureData = getTreasureInfoFromInitData(self.parentView.Treasure.treasureId)
	self.sellBtn = Button:create(self.ChangeBtnDisplay)
	self.sellBtn:addEventListener(Events.kStart, onClickChangeBtn, self)
  self:refreshChangeSellBtnName(aTreasureData.lock)


  --锁定
  self:refreshLockState(true)
  local function OnLockFunc(evt)
    self = evt.context
    local aTreasureData = getTreasureInfoFromInitData(self.parentView.Treasure.treasureId)
  local function succeedCallback(event)
    self.parentView.refeshContainer = true
    self:refreshLockState()
  end
  LockTreasuresRequest.sendRequestDefalut( {types = aTreasureData.lock and 2 or 1, treasureIds = self.parentView.Treasure.treasureId},succeedCallback)

  end
  
  local LockBtnDisplay = self.panelUI:getChildByName("treasure_btn_equip_enhance")
  local LockBtn = Button:create(LockBtnDisplay)
  LockBtn:addEventListener(Events.kStart, OnLockFunc, self)  
    
	--简介
	local aDescArea = self.panelUI:getChildByName("green_tanslucent_grid9_pic")
	local aPanel = CardDescPanel:create(
		self.parentView.Treasure.metaId,
		{height=280, width=572},
		ccc3(255,255,255),
		self.parentView.Treasure.cardId
	)
	aPanel:setViewPosition(aDescArea:getPosition().x,aDescArea:getPosition().y-320)
	self.panelUI:getChildByName("green_tanslucent_grid9_pic"):addChild(aPanel)
	
    self:refreshInfoPanel()
end

function TreasureIntroductionTabView:refreshInfoPanel()
	self.parentView:refreshTreasureTips(false)

end

function TreasureIntroductionTabView:refreshChangeSellBtnName(lockAdejude)
  local queueList = {}
  local gameData = DataManager.getGameInitData()
  for BattleArrayId = 1,3 do
    local quedata = gameData.sharkUserBattleArray[BattleArrayId] and gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue or {}
    for k,v in pairs(quedata) do
      queueList[v.treasureId] = true
    end 
  end
	if (self.parentView.Treasure.cardId ~= 0 ) then
		self.panelUI:getChildByName("treasure_btn_equip_SellBtn"):getChildByName("txt_equip_SellBtn"):setString(Localization:getInstance():getText("Treasure_titel_8"))
	else
    self.panelUI:getChildByName("treasure_btn_equip_SellBtn"):getChildByName("txt_equip_SellBtn"):setString(Localization:getInstance():getText("equip_SellBtn"))
	  if lockAdejude or queueList[self.parentView.Treasure.treasureId] then
      self.ChangeBtnDisplay:getChildByName("btn"):setVisible(false)
      self.sellBtn:setEnable(false)
    else
      self.ChangeBtnDisplay:getChildByName("btn"):setVisible(true)
      self.sellBtn:setEnable(true)
    end
  end
end


function TreasureIntroductionTabView:refreshLockState(notRefreshContainer)
	local aCardData = getTreasureInfoFromInitData(self.parentView.Treasure.treasureId)

	local lockBtnDisplay = self.panelUI:getChildByName("treasure_btn_equip_enhance")
	self:refreshChangeSellBtnName(aCardData.lock)
	if not aCardData.lock then
		
		lockBtnDisplay:getChildByName("txt_equip_enhance"):setString(Localization:getInstance():getText("Treasure_titel_7"))
	else
		
		lockBtnDisplay:getChildByName("txt_equip_enhance"):setString(Localization:getInstance():getText("cardInfo_unlockBtn"))
	end
	self.parentView:refreshTreasureLockState(aCardData.lock, notRefreshContainer)
end

--TreasureStrengthenTabView 强化

local EvolvedTypeEnum = 
					{
					  oneEvolved = 1,
                      twoEvolved = 2,
					}

local PositionTypeEnum = 
					{
					  leftPosition = 1,
                      middlePosition = 2,
                      rightPosition = 3,
					}


local function quickUpgradeButtonAction(evt)
	local aScene = evt.context
    -- print("~~~~~~~~~~~~~~~~~~~~~~~~一键强化")
    local quickUpgradeCost = 0
	  local quickUpgradeLevel = 0
    local function quickUpgradeCostFun()
		
	    local currUser = DataManager.getCurrUser()

        local TreasuetmaxEvolvedLevelConfig = MetaManager.treasure_meta[aScene.parentView.Treasure.metaId]
	    local tempMaxLevel = math.min(tonumber(TreasuetmaxEvolvedLevelConfig.maxEvolvedLevel, 10), currUser.level)
	    for i = aScene.parentView.Treasure.level+1, tempMaxLevel do
	      local aTreasureStrengthenConfig = MetaManager.treasure_strengthen[i]
	      local aCost = tonumber(aTreasureStrengthenConfig.treasureUpCoin, 10) 
	      if (quickUpgradeCost + math.modf(aCost)) <= tonumber(currUser.coins, 10) then
	        quickUpgradeCost = quickUpgradeCost + aCost
	        quickUpgradeCost = math.modf(quickUpgradeCost)
	        quickUpgradeLevel = i + 1
	      else
          -- quickUpgradeCost = 0
	        break
	      end
	    end
	    return quickUpgradeCost 
	end
  CanonPlayEffect("music/sfx_amer_evolve.wav")
  
  local currUser = DataManager.getCurrUser()
  
  if currUser.level <= aScene.parentView.Treasure.level then
    local aContent = Localization:getInstance():getText("Treasure_tips21")
    SuspensionLabel:showContent(aScene, aContent)
    return
  end
  
  local NewquickUpgradeCost = quickUpgradeCostFun()
  -- if NewquickUpgradeCost == 0 then
  --   aScene:showCoinLimitPanel()
  --   return
  -- end
  
  local function quickUpgradeEquipSucceed(event)
    local function removeFlash()
      aScene.fspt_co:removeFromParentAndCleanup(true)
      aScene.fspt:unregisterEndAnimationScriptHandler()
    end
    aScene.parentView.refeshContainer = true
    RewardManager:gainReward({itemType = ResourceEnum.COIN, amount = -NewquickUpgradeCost})
    -- local previous_strength = CommonManager:getLocalPlayerStrength()
    
    local aNewTreasure = event.data.sharkTreasure
 
    refeshTreasureInfoFromInitData(aNewTreasure)
    aScene.parentView.Treasure = aNewTreasure
    local showTxt = nil
    local EvolvedType = -1
    local aTreasureData = MetaManager.treasure_meta[aScene.parentView.Treasure.metaId]
    showTxt = "Treasure_tips21"
    if aScene.parentView.Treasure.level == aTreasureData.maxEvolvedLevel then
        EvolvedType = EvolvedTypeEnum.oneEvolved
    else
        EvolvedType = EvolvedTypeEnum.twoEvolved
    end
    aScene.parentView:refreshTreasureAtt(aScene.parentView.Treasure.treasureId)
    aScene:refreshInfoEvolved(EvolvedType)
    local aContent = Localization:getInstance():getText(showTxt)
    SuspensionLabel:showContent(aScene, aContent)
    
    aScene.fspt = FlashSprite:create("EVO2/equip")
    aScene.fspt:changeAnimation(0)
    aScene.fspt:setLoop(false)
    aScene.fspt_co = CocosObject.new(aScene.fspt)
    aScene.fspt:registerEndAnimationScriptHandler(removeFlash)
    aScene.fspt:setPosition(aScene.parentView.flashPos.x, aScene.parentView.flashPos.y - visibleSize.height)
    aScene.parentView:addChild(aScene.fspt_co)
          
    --显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
    DataManager.fightCapacityMaybeUpdated()
  end
  
   UpgradeTreasureRequest.sendRequestDefalut({oneclick = true, treasureIds = aScene.parentView.Treasure.treasureId},quickUpgradeEquipSucceed)
  
end


local function upgradeEquipSucceed(evt)
	
  local aScene = evt.context
  CanonPlayEffect("music/sfx_amer_evolve.wav")
  
  local currUser = DataManager.getCurrUser()
  
  if currUser.level <= aScene.parentView.Treasure.level then
    
    local aContent = Localization:getInstance():getText("Treasure_tips21")
    SuspensionLabel:showContent(aScene, aContent)
    return
  end
  local upgradeCost = aScene:getCost(aScene.parentView.Treasure.level+1)
  if upgradeCost > tonumber(currUser.coins, 10) then
    aScene:showCoinLimitPanel()
    return
  end
  
  local function upgradeEquipSucceed(event)
    aScene.parentView.refeshContainer = true
    RewardManager:gainReward({itemType = ResourceEnum.COIN, amount = -upgradeCost})
    -- local previous_strength = CommonManager:getLocalPlayerStrength()
    local function removeFlash()
      aScene.fspt_co:removeFromParentAndCleanup(true)
      aScene.fspt:unregisterEndAnimationScriptHandler()
      -- aScene.EnhanceBtn:setEnable(true)
      -- aScene.AllEnhanceBtn:setEnable(true)
      aScene.parentView.CloseBtn:setEnable(true)
      
    end
    local aNewTreasure = event.data.sharkTreasure
   
    refeshTreasureInfoFromInitData(aNewTreasure)
    aScene.parentView.Treasure = aNewTreasure
    
    local showTxt = nil
    local EvolvedType = -1
    local aTreasureData = MetaManager.treasure_meta[aScene.parentView.Treasure.metaId]
    if aScene.parentView.Treasure.level == aTreasureData.maxEvolvedLevel then
        EvolvedType = EvolvedTypeEnum.oneEvolved
        showTxt = "Treasure_tips21"
    else
        EvolvedType = EvolvedTypeEnum.twoEvolved
        showTxt = "Treasure_tips20"
    end
    
    local aContent = Localization:getInstance():getText(showTxt)
    SuspensionLabel:showContent(aScene, aContent)
    aScene.fspt = FlashSprite:create("EVO2/equip")
    aScene.fspt:changeAnimation(0)
    aScene.fspt:setLoop(false)
    aScene.fspt_co = CocosObject.new(aScene.fspt)
    aScene.fspt:registerEndAnimationScriptHandler(removeFlash)
    aScene.fspt:setPosition(aScene.parentView.flashPos.x, aScene.parentView.flashPos.y - visibleSize.height)
    aScene.parentView:addChild(aScene.fspt_co)
    aScene.EnhanceBtn:setEnable(false)
    aScene.AllEnhanceBtn:setEnable(false)
    aScene.parentView.CloseBtn:setEnable(false)
    aScene.parentView:setBtnEnabel(false)
    aScene.parentView:refreshTreasureAtt(aScene.parentView.Treasure.treasureId)
    aScene:refreshInfoEvolved(EvolvedType)      
    --显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
    DataManager.fightCapacityMaybeUpdated()
  end
  
   UpgradeTreasureRequest.sendRequestDefalut({oneclick = false, treasureIds = aScene.parentView.Treasure.treasureId},upgradeEquipSucceed)
     
end



TreasureStrengthenTabView = class(Layer)
function TreasureStrengthenTabView:getCost(level)
 	local treasureMate = MetaManager.treasure_strengthen[level]
	
	return treasureMate.treasureUpCoin 
 end 

function TreasureStrengthenTabView:ctor()
    self.parentView = nil
    self.panelUI = nil
    self.leftTxtList = {}
    self.rightTxtList = {}
    self.middleTxtList = {}
    self.lefticonList = {}
    self.righticonList = {}
    self.middleiconList = {}
   
end

function TreasureStrengthenTabView:create(aParentView)
    local s = TreasureStrengthenTabView.new()
    s.parentView = aParentView
    s:initLayer()
    return s
end

function TreasureStrengthenTabView:initLayer()
	TreasureStrengthenTabView.super.initLayer(self)
  self.parentView:ShowPotentialNum (false)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/treasure.json")
	self.builder = builder
	builder.useArtLabelTTF = true
  self.panelUI = builder:build("frame_treasure_02")
  self:addChild(self.panelUI)
 

  self.EnhanceBtnDisplay = self.panelUI:getChildByName("treasure_btn_equip_enhance")
  self.EnhanceBtnDisplay:getChildByName("txt_equip_enhance"):setString(getTextByKey("Treasure_titel_5"))
  self.EnhanceBtn = Button:create(self.EnhanceBtnDisplay)
	self.EnhanceBtn:addEventListener(Events.kStart, upgradeEquipSucceed, self)

  self.AllEnhanceBtnDisplay = self.panelUI:getChildByName("treasure_btn_equip_SellBtn_yjqh")
  self.AllEnhanceBtnDisplay:getChildByName("txt_equip_SellBtn"):setString(getTextByKey("Treasure_titel_9"))
  self.AllEnhanceBtn = Button:create(self.AllEnhanceBtnDisplay)
	self.AllEnhanceBtn:addEventListener(Events.kStart, quickUpgradeButtonAction, self)
	
   --问号按钮
  local  function helpBtnAction(evt)
    local para = evt.context
    self.parentView.container:setTableViewsEnabled(false)
    local aInfoPanel = ActivityInfoPanel:create(self.parentView.container, getTextByKey("Treasure_help_1"),"Treasure_titel_5")
    self.parentView:addChild(aInfoPanel)
    aInfoPanel:scaleIn()
  end
  local helpBtn = Button:create(self.panelUI:getChildByName("sky_btn_qa"))
  helpBtn:addEventListener(Events.kStart,helpBtnAction,self)
    
    for i=1,3 do
    	
    	local hpTxt = nil
    	local defTxt = nil
    	local attTxt = nil
    	local lvIcon = nil
    	local hpIcon = nil
    	local defIcon = nil
    	local attIcon = nil
    	local lvPanel = nil
      local hpPanel = nil
      local defPanel = nil
      local attPanel = nil
        hpTxt = self.panelUI:getChildByName("txt_hp_"..i)
        defTxt = self.panelUI:getChildByName("txt_def_"..i)
        attTxt = self.panelUI:getChildByName("txt_att_"..i)
        lvIcon = self.panelUI:getChildByName("icon_lv"..i)
        hpIcon = self.panelUI:getChildByName("icon_hp"..i)
        defIcon = self.panelUI:getChildByName("icon_def"..i)
        attIcon = self.panelUI:getChildByName("icon_atk"..i)
        lvPanel = self.panelUI:getChildByName("red_purple9_panel_LV_"..i)
        hpPanel = self.panelUI:getChildByName("red_purple9_panel_hp_"..i)
        defPanel = self.panelUI:getChildByName("red_purple9_panel_def_"..i)
        attPanel = self.panelUI:getChildByName("red_purple9_panel_att_"..i)
    	if i == PositionTypeEnum.leftPosition then
    	
        table.insert(self.leftTxtList,hpTxt)
	      table.insert(self.leftTxtList,defTxt)
	      table.insert(self.leftTxtList,attTxt)
        table.insert(self.lefticonList,lvIcon)
	      table.insert(self.lefticonList,hpIcon)
	      table.insert(self.lefticonList,defIcon)
        table.insert(self.lefticonList,attIcon)
        table.insert(self.lefticonList,lvPanel)
        table.insert(self.lefticonList,hpPanel)
        table.insert(self.lefticonList,defPanel)
        table.insert(self.lefticonList,attPanel)
         
    	elseif i == PositionTypeEnum.middlePosition then
        hpTxt:setVisible(false)
        defTxt:setVisible(false)
        attTxt:setVisible(false)
        lvIcon:setVisible(false)
        hpIcon:setVisible(false)
        defIcon:setVisible(false)
        attIcon:setVisible(false)
        lvPanel:setVisible(false)
        hpPanel:setVisible(false)
        defPanel:setVisible(false)
        attPanel:setVisible(false)
       --[[
        table.insert(self.middleTxtList,hpTxt)
	      table.insert(self.middleTxtList,defTxt)
	      table.insert(self.middleTxtList,attTxt)
        table.insert(self.middleiconList,lvIcon)
	      table.insert(self.middleiconList,hpIcon)
	      table.insert(self.middleiconList,defIcon)
        table.insert(self.middleiconList,attIcon)
        table.insert(self.middleiconList,lvPanel)
        table.insert(self.middleiconList,hpPanel)
        table.insert(self.middleiconList,defPanel)
        table.insert(self.middleiconList,attPanel)
        ]]
    	elseif i == PositionTypeEnum.rightPosition then
    	  table.insert(self.rightTxtList,hpTxt)
	      table.insert(self.rightTxtList,defTxt)
	      table.insert(self.rightTxtList,attTxt)
        table.insert(self.righticonList,lvIcon)
	      table.insert(self.righticonList,hpIcon)
	      table.insert(self.righticonList,defIcon)
        table.insert(self.righticonList,attIcon)
        table.insert(self.righticonList,lvPanel)
        table.insert(self.righticonList,hpPanel)
        table.insert(self.righticonList,defPanel)
        table.insert(self.righticonList,attPanel)
          
      
    	end
    end
    local aTreasureData = MetaManager.treasure_meta[self.parentView.Treasure.metaId]
    self.panelUI:getChildByName("icon_arrow_green"):setVisible(true)
    if self.parentView.Treasure.level == aTreasureData.maxEvolvedLevel then

        self:refreshInfoEvolved(EvolvedTypeEnum.oneEvolved)
    else
        self:refreshInfoEvolved(EvolvedTypeEnum.twoEvolved)
    end

    
end

function TreasureStrengthenTabView:refreshInfoEvolved(num)
	self.parentView:refreshTreasureTips(false)
  local function setBtnStaus(btnadjude)
    self.EnhanceBtnDisplay:getChildByName("btn"):setVisible(btnadjude)
    self.EnhanceBtn:setEnable(btnadjude)
    self.AllEnhanceBtnDisplay:getChildByName("normal"):setVisible(btnadjude)
    self.AllEnhanceBtn:setEnable(btnadjude)
  end
	local function setTwoVisible( adjude)
        -- self.panelUI:getChildByName("txt_lv_1"):setVisible(adjude)
        self.panelUI:getChildByName("txt_lv_03"):setVisible(adjude)
        self.panelUI:getChildByName("txt_lv_3"):setVisible(adjude)
        self.panelUI:getChildByName("txt_5"):setVisible(adjude)
        self.panelUI:getChildByName("txt_4"):setVisible(adjude)
        self.panelUI:getChildByName("icon_silverCoin"):setVisible(adjude)
        self.panelUI:getChildByName("txt_hp_add_1"):getChildByName("txt"):setVisible(adjude)
        self.panelUI:getChildByName("txt_def_add_1"):getChildByName("txt"):setVisible(adjude)
        self.panelUI:getChildByName("txt_att_add_1"):getChildByName("txt"):setVisible(adjude)
        self.panelUI:getChildByName("halfblack1"):setVisible(adjude)
        self.panelUI:getChildByName("halfblack2"):setVisible(adjude)
		for i = 1,8 do
			
			-- self.lefticonList[i]:setVisible(adjude)
			self.righticonList[i]:setVisible(adjude)
			if i < 4 then
				-- self.leftTxtList[i]:setVisible(adjude)
				self.rightTxtList[i]:setVisible(adjude)
			end
		end
	
	 if adjude then
			self:refreshInfoPanel(PositionTypeEnum.leftPosition)
			self:refreshInfoPanel(PositionTypeEnum.rightPosition)
      local currUser = DataManager.getCurrUser()
      local aTreasureStrengthenConfig = MetaManager.treasure_strengthen[self.parentView.Treasure.level]
      if currUser.level <= self.parentView.Treasure.level or tonumber(currUser.coins) < aTreasureStrengthenConfig.treasureUpCoin  then
        setBtnStaus(false)
      else
        setBtnStaus(true)
      end
		end
    -- self.panelUI:getChildByName("icon_arrow_green"):setVisible(adjude)
	end

	local function setOneVisible( adjude)
		self.panelUI:getChildByName("txt_lv_2"):setVisible(false)
    self.panelUI:getChildByName("equip_icon_max"):setVisible(adjude)
    self.panelUI:getChildByName("equip_txt_equipEnhance_Tips"):setVisible(adjude)
    self.panelUI:getChildByName("equip_txt_equipEnhance_Tips"):getChildByName("txt_equipEnhance_Tips"):setString(getTextByKey("Treasure_text_41"))
	  --[[
      for i = 1,8 do
			
			self.middleiconList[i]:setVisible(false)
			-- self.lefticonList[i]:setVisible(true)
			if i < 4 then
				self.middleTxtList[i]:setVisible(false)
				-- self.leftTxtList[i]:setVisible(true)
			end
		end
    ]]
		if adjude then
           -- self:refreshInfoPanel(PositionTypeEnum.middlePosition)
           self:refreshInfoPanel(PositionTypeEnum.leftPosition)
           setBtnStaus(false)
		end
        -- self.panelUI:getChildByName("icon_arrow_green"):setVisible(adjude)
	end
	if num == EvolvedTypeEnum.oneEvolved then
      setOneVisible(true)
      setTwoVisible(false)
     

	elseif num == EvolvedTypeEnum.twoEvolved  then
      setOneVisible(false)
      setTwoVisible(true)
      --显示银币消耗
      local aTreasureData = getTreasureInfoFromInitData(self.parentView.Treasure.treasureId)
      local cost = TreasureSystemUtils.CountCost(aTreasureData)
      self.panelUI:getChildByName("txt_5"):getChildByName("txt"):setString(cost)
      self.panelUI:getChildByName("txt_4"):getChildByName("txt"):setString(getTextByKey("cardEnhance_CoinConsume"))
      local addNumlist = {}
      addNumlist[1],addNumlist[2],addNumlist[3] = TreasureSystemUtils.CountAttandDefandHpAddNum(aTreasureData)
      self.panelUI:getChildByName("txt_hp_add_1"):getChildByName("txt"):setString("+"..addNumlist[3])
      self.panelUI:getChildByName("txt_def_add_1"):getChildByName("txt"):setString("+"..addNumlist[2])
      self.panelUI:getChildByName("txt_att_add_1"):getChildByName("txt"):setString("+"..addNumlist[1])
      
	end
   self.parentView:setBtnEnabel(true) 
end



function TreasureStrengthenTabView:refreshInfoPanel(position) -- 告知是左右中哪个位置的显示
	local aTreasureData = getTreasureInfoFromInitData(self.parentView.Treasure.treasureId)
	local level =  aTreasureData.level
	local treasureMate = MetaManager.treasure_meta[aTreasureData.metaId]
	local tableTxt = {}

	if position == PositionTypeEnum.leftPosition then
		self.panelUI:getChildByName("txt_lv_1"):getChildByName("txt"):setString(level.."/"..treasureMate.maxEvolvedLevel) 
		tableTxt = self.leftTxtList
	elseif position == PositionTypeEnum.rightPosition then
		
		level = level +1
		tableTxt = self.rightTxtList
		self.panelUI:getChildByName("txt_lv_3"):getChildByName("txt"):setString(level)
		self.panelUI:getChildByName("txt_lv_03"):getChildByName("txt"):setString("/"..treasureMate.maxEvolvedLevel)
	elseif position == PositionTypeEnum.middlePosition then 
		
		tableTxt = self.middleTxtList
		self.panelUI:getChildByName("txt_lv_2"):getChildByName("txt"):setString(level.."/"..treasureMate.maxEvolvedLevel) 
    end

	-- local  dataTabList = {}
   local hp , def , att = TreasureSystemUtils.CountAttandDefandHp(aTreasureData,level)
    
    -- for i,uiTxt in ipairs(tableTxt) do
    --   if i == 1 then

    --   elseif i == 3 then
    --     tableTxt[3]:getChildByName("txt"):setString(dataTabList[i])
    --   else

    --   end
    	
    -- end

    for i=1,3 do
      if i == 1 then
         tableTxt[i]:getChildByName("txt"):setString(att)
      elseif i == 2 then
         tableTxt[i]:getChildByName("txt"):setString(def)
      else
        tableTxt[i]:getChildByName("txt"):setString(hp)
      end
    end
   
  
    
end


function TreasureStrengthenTabView:showCoinLimitPanel()
   local aPanel = MessageBoxPanel:create(self,MessageBoxType.kCoinLimit)
   self.parentView:addChild(aPanel)
  aPanel:scaleIn()
   
end


--TreasureRisingStarTabView 升星
local StarTypeEnum = 
					{
					  oneStar = 1,
            twoStar = 2,
					}

local function RiseStarBtnFun(evt)
  self = evt.context
  local function FlashFinish()

    self.Newfspt:unregisterEndAnimationScriptHandler()
    self.Newfspt_co:removeFromParentAndCleanup(true)
    for i=1,3 do
      if i ~= 3 then
        self.IconTab[i]:removeFromParentAndCleanup(true)
      end
      self.Starflash[i]:removeFromParentAndCleanup(true)
      -- self.StarFlashdisplay[i]:unregisterEndAnimationScriptHandler()
    end
    local showTxt = nil
    local RiseStarType = -1
    -- print("~~~~~~~~~~~~~~~~~~aNewTreasure = "..tostringRich(aNewTreasure))
    
    local aTreasureData = MetaManager.treasure_meta[self.parentView.Treasure.metaId]
    if aTreasureData.rare == 6 then
      RiseStarType = StarTypeEnum.oneStar
      showTxt = "Treasure_tips23"
      
    else
      RiseStarType = StarTypeEnum.twoStar
      showTxt = "Treasure_tips22"
    end

    self.parentView:refreshTreasureAtt(self.parentView.Treasure.treasureId)
    self.parentView:refreshTreasureIconandStar()
    self:refreshInfoStar(RiseStarType)
    local aContent = Localization:getInstance():getText(showTxt)
    SuspensionLabel:showContent(self, aContent)
    self.parentView.CloseBtn:setEnable(true)
  end
  local function showflash(flashPos,num)
    local fspt = FlashSprite:create("EVO2/equip")
    fspt:changeAnimation(0)
    fspt:setLoop(false)
    local fspt_co = CocosObject.new(fspt)
    fspt:setPosition(flashPos.x, flashPos.y - visibleSize.height)
    self.parentView:addChild(fspt_co)
    -- fspt:registerEndAnimationScriptHandler(FlashFinish)
    
    self.Starflash[num] = fspt_co
    self.StarFlashdisplay[num] = fspt
  end
  -- local TreasureFragmentNum = DataManager.getTreasureFragmentNum()
  local treasureMate = MetaManager.treasure_meta[self.parentView.Treasure.metaId]
  
  -- print("~~~~~~~~~~~~~~~~~~~~~~~~~升星treasureMate.astralEssence = "..tostring(treasureMate.astralEssence))
 

  local function riseStarSucceed(event)
    self.parentView.refeshContainer = true
    RewardManager:getReward{{itemType = ResourceEnum.TREASURE_FRAGMENT, amount = - MetaManager.treasure_star[treasureMate.rare].number}}
   
    local aNewTreasure = event.data.sharkTreasure
   
    refeshTreasureInfoFromInitData(aNewTreasure)
    self.parentView.Treasure = aNewTreasure
    -- aScene:refreshSelf()
    showflash(self.StarIconPositionList[1],1)
    showflash(self.StarIconPositionList[2],2)
    showflash(self.parentView.flashPos,3)
    self.RiseStarBtn:setEnable(false)
    self.parentView:setBtnEnabel(false)
    self.parentView.CloseBtn:setEnable(false)
    self.Newfspt = FlashSprite:create("EVO2/equip_01")
    self.Newfspt:changeAnimation(0)
    self.Newfspt:setLoop(false)
    self.Newfspt_co = CocosObject.new(self.Newfspt)
    self.Newfspt:setPosition(self.StarIconPositionList[3].x+30, self.StarIconPositionList[3].y - visibleSize.height)
    self.parentView:addChild(self.Newfspt_co)
    self.Newfspt:registerEndAnimationScriptHandler(FlashFinish)      
    --显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
    DataManager.fightCapacityMaybeUpdated()
  end
  
   EvolveTreasureRequest.sendRequestDefalut({treasureIds = self.parentView.Treasure.treasureId},riseStarSucceed)
  
end 

TreasureRisingStarTabView = class(Layer)

function TreasureRisingStarTabView:ctor()
    self.parentView = nil
    self.panelUI = nil
    self.StarIconPositionList = {}
    self.IconTab = {}
    self.Starflash = {}
    self.StarFlashdisplay = {}
   
end

function TreasureRisingStarTabView:create(aParentView)
    local s = TreasureRisingStarTabView.new()
    s.parentView = aParentView
    s:initLayer()
    return s
end

function TreasureRisingStarTabView:initLayer()
	TreasureRisingStarTabView.super.initLayer(self)
  self.parentView:ShowPotentialNum (false)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/treasure.json")
	self.builder = builder
	builder.useArtLabelTTF = true
  self.panelUI = builder:build("frame_treasure_03")
  self:addChild(self.panelUI)
  --问号按钮
  local  function helpBtnAction(evt)
    local para = evt.context
    self.parentView.container:setTableViewsEnabled(false)
    local aInfoPanel = ActivityInfoPanel:create(self.parentView.container, getTextByKey("Treasure_help_2"),"Treasure_titel_6")
    self.parentView:addChild(aInfoPanel)
    aInfoPanel:scaleIn()
  end
  local helpBtn = Button:create(self.panelUI:getChildByName("sky_btn_qa"))
  helpBtn:addEventListener(Events.kStart,helpBtnAction,self)

    
    for i=1,3 do
    	if i == 1 then
	    	self.panelUI:getChildByName("normal_card_small"):setVisible(false)
	    else
	    	self.panelUI:getChildByName("normal_card_small"..i):setVisible(false)
        end
    end
    self.panelUI:getChildByName("icon_arrow_green"):setVisible(false)
   
    self.RiseStarBtnDisplay = self.panelUI:getChildByName("treasure_btn_equip_enhance")
    self.RiseStarBtnDisplay:getChildByName("txt_equip_enhance"):setString(getTextByKey("Treasure_titel_6"))
    self.RiseStarBtn = Button:create(self.RiseStarBtnDisplay)
    self.RiseStarBtn:addEventListener(Events.kStart, RiseStarBtnFun, self)

    local aRareData = MetaManager.treasure_meta[self.parentView.Treasure.metaId].rare
    if aRareData == 6 then
      self:refreshInfoStar(StarTypeEnum.oneStar)
    else
      self:refreshInfoStar(StarTypeEnum.twoStar)
    end


   self.parentView:refreshTreasureTips(false)
   local IconPostiion1 = self.panelUI:getChildByName("normal_card_small"):getPosition()
   local IconPostiion2 = self.panelUI:getChildByName("normal_card_small2"):getPosition()
   local IconPostiion3 = self.panelUI:getChildByName("icon_arrow_green"):getPosition()
   self.StarIconPositionList[1] = self.panelUI:convertToWorldSpace(ccp(IconPostiion1.x,IconPostiion1.y))
   self.StarIconPositionList[2] = self.panelUI:convertToWorldSpace(ccp(IconPostiion2.x,IconPostiion2.y))
   self.StarIconPositionList[3] = self.panelUI:convertToWorldSpace(ccp(IconPostiion3.x,IconPostiion3.y))
   self.panelUI:getChildByName("txt_10"):getChildByName("txt"):setString(getTextByKey("Treasure_text_2"))
   self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("Treasure_text_3"))
    
end 


function TreasureRisingStarTabView:refreshInfoStar(num)
    local treasureMate = MetaManager.treasure_meta[self.parentView.Treasure.metaId]
    local TreasureFragmentNum = DataManager.getTreasureFragmentNum()
    self.panelUI:getChildByName("txt_11"):getChildByName("txt"):setString(TreasureFragmentNum)
    local Starconfig = MetaManager.treasure_star[treasureMate.rare]
    -- print("~~~~~~~~~~~~~~~~~~~~~~TreasureFragmentNum = "..tostringRich(TreasureFragmentNum))
	local function showStarandIconnum(IconStar,StarTextname,metaId,IconTextName,iconnum)
      
      local  NewtreasureMate = MetaManager.treasure_meta[metaId]  
      for quality = 1, 7 do
        	
  			if (quality == NewtreasureMate.rare+1) then
  				break
  			end
  		    IconStar:getChildByName(StarTextname..quality):setVisible(true)
	    end
       
	    if iconnum then
        if self.IconTab[iconnum] then
  			 self.IconTab[iconnum]:removeFromParentAndCleanup(true)
        end
	    end 
		local IconObject = CanonItem:create()
	  IconObject:loadByMetaId(metaId)
		IconObject:setScale(130/150)
		local position = self.panelUI:getChildByName(IconTextName):getPosition()
		IconObject:setPosition(ccp(position.x,position.y))
    if iconnum then
      self.IconTab[iconnum] = nil
      self.IconTab[iconnum] = IconObject
      -- table.insert(self.IconTab,IconObject)
    end
		self.panelUI:addChild(IconObject)
		

	end
	local function setTwoVisible( adjude)
		self.panelUI:getChildByName("icon_arrow_green"):setVisible(adjude)
    -- self.panelUI:getChildByName("txt_10"):setVisible(adjude)
    -- self.panelUI:getChildByName("icon_snl2"):setVisible(adjude)
    -- self.panelUI:getChildByName("txt_11"):setVisible(adjude)
    -- self.panelUI:getChildByName("txt_12"):setVisible(adjude)
    -- self.panelUI:getChildByName("txt_13"):setVisible(adjude)
    -- self.panelUI:getChildByName("icon_snl1"):setVisible(adjude)
    self.panelUI:getChildByName("red_purple9_panel_atk"):setVisible(adjude)
    self.panelUI:getChildByName("red_purple9_panel_atk2"):setVisible(adjude)
    
	    local Textname = nil
	    local MateId = -1
	    local LvTxt = nil
	    local LvTxtName = nil
		for i=1,2 do
			self.panelUI:getChildByName("txt_"..i+5):setVisible(adjude)

			
			self.panelUI:getChildByName("icon_lv"..i+1):setVisible(adjude)
            if i == StarTypeEnum.oneStar then
            	Textname = "normal_card_small"
            	MateId = self.parentView.Treasure.metaId
            	LvTxt = self.parentView.Treasure.level.."/"..treasureMate.maxEvolvedLevel
            	LvTxtName = "txt_6"
		    else
		    	
		    	Textname = "normal_card_small"..i
		    	MateId =  treasureMate.evolvedCardId
		    	LvTxt = self.parentView.Treasure.level.."/"..MetaManager.treasure_meta[MateId].maxEvolvedLevel
		    	LvTxtName = "txt_7"
		    end
	        self.panelUI:getChildByName(LvTxtName):setVisible(adjude)

	       if adjude then
          
  				local Star = self.panelUI:getChildByName("icon_star_"..i)
          
  				showStarandIconnum(Star,"icon_star",MateId,Textname,i)
          self.panelUI:getChildByName(LvTxtName):getChildByName("txt"):setString(LvTxt)
          -- self.panelUI:getChildByName("txt_10"):getChildByName("txt"):setString(getTextByKey("Treasure_text_2"))
          
          -- self.panelUI:getChildByName("txt_12"):getChildByName("txt"):setString(getTextByKey("Treasure_text_3"))
          
          self.panelUI:getChildByName("txt_13"):getChildByName("txt"):setString(Starconfig.number)
          if Starconfig.number > tonumber(TreasureFragmentNum,10)  then
            self.panelUI:getChildByName("txt_13"):getChildByName("txt"):setColor(ccc3(234 ,85,4))
          else
            self.panelUI:getChildByName("txt_13"):getChildByName("txt"):setColor(ccc3(255 ,255,255))
          end
         
		    end
	    end

	end

	local function setOneVisible( adjude)
		self.panelUI:getChildByName("icon_arrow_green"):setVisible(adjude)
    self.panelUI:getChildByName("red_purple9_panel_atk1"):setVisible(adjude)
		local i = StarTypeEnum.twoStar+1
	    self.panelUI:getChildByName("txt_"..i+5):setVisible(adjude)
		self.panelUI:getChildByName("icon_lv1"):setVisible(adjude)
		local Textname = "normal_card_small"..i
		self.panelUI:getChildByName("txt_8"):setVisible(adjude)
      if adjude then
  			local Star = self.panelUI:getChildByName("icon_star_"..i)
  			showStarandIconnum(Star,"icon_star",self.parentView.Treasure.metaId,Textname)
        -- print("~~~~~~~~~~~~~~~~~~self.parentView.Treasure.level = "..tostringRich(self.parentView.Treasure.level))
  			self.panelUI:getChildByName("txt_8"):getChildByName("txt"):setString(self.parentView.Treasure.level.."/"..treasureMate.maxEvolvedLevel)
	      self.panelUI:getChildByName("txt_13"):getChildByName("txt"):setString(0)
      end

    end
	for i=1,3 do
		for j=1,6 do
			self.panelUI:getChildByName("icon_star_"..i):getChildByName("icon_star"..j):setVisible(false)
		end
	end
  -- print("~~~~~~~~~~~~~~~~~~~受限升星等级treasureMate.evolutionLevel = "..tostringRich(treasureMate.evolutionLevel))
  --[[
  碎片不够等级不够，满6颗星
  ]]
  if Starconfig.number > tonumber(TreasureFragmentNum,10) 
    or self.parentView.Treasure.level < treasureMate.evolutionLevel  
    or treasureMate.rare == 6 then 
    -- print("~~~~~~~~~~~~~~~~~~~~~~~~~碎片不够")
    self.RiseStarBtnDisplay:getChildByName("btn"):setVisible(false)
    self.RiseStarBtn:setEnable(false)
  else
    self.RiseStarBtnDisplay:getChildByName("btn"):setVisible(true)
    self.RiseStarBtn:setEnable(true)
    
  end
	if num == StarTypeEnum.oneStar then
      setOneVisible(true)
      setTwoVisible(false)
    
	elseif num == StarTypeEnum.twoStar  then
      setOneVisible(false)
      setTwoVisible(true)

  end
  self.parentView:setBtnEnabel(true)
end




--TreaseurePotentialTabView 潜力
local PotentialTypeEnum = 
          {
            ordinaryPotential = 1,
            silverPotential = 2,
            goldPotential = 3,
          }

local function ResetPotentialBtnFun(evt)
  self = evt.context
  -- print("~~~~~~~~~~~~~~~~~~~~~~~~重置激发")
  
  local function onConfirm()
    local NowGems = CalculationManager.calcComplex_getGemsNow()
    if NowGems < 100 then
      self:showGemLimitPanel()
      return
    end
    local function ResetPotentialSucceed(event)
      -- print("重写数据")
      local  TreasureSetting = TreasureSystemConfig.getTreasureSettingConfig()
      self.parentView.refeshContainer = true 
      RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -TreasureSetting.treasurePotentialCost}) --重置减100金
      self.parentView.Treasure.addPotential = 0
      self.parentView.Treasure.addGemPotential = 0
      self.parentView.Treasure.usedPotential = 0
      local  NewTreasure = self.parentView.Treasure
      
      refeshTreasureInfoFromInitData(NewTreasure)
      self:refreshInfoPotential()
      self.parentView:refreshTreasureAtt(self.parentView.Treasure.treasureId)
      if self.selectPotentialType == PotentialTypeEnum.goldPotential then
        local  hp,def,att = TreasureSystemUtils.CountPotentialAttandDefandHpAddNum(self.parentView.Treasure,true)
        self.parentView:SetPotentialNum (hp,def,att) 
      else
        local  hp,def,att = TreasureSystemUtils.CountPotentialAttandDefandHpAddNum(self.parentView.Treasure,false)
        self.parentView:SetPotentialNum (hp,def,att)

      end
    end
    ResetTreasurePotentialRequest.sendRequestDefalut({treasureIds = self.parentView.Treasure.treasureId},ResetPotentialSucceed)
  end
  local TreasureSetting = TreasureSystemConfig.getTreasureSettingConfig()
  CanonMessageBox.showAsConfirmBox(getTextByKey("Treasure_text_39",{num = TreasureSetting.treasurePotentialCost}), onConfirm, nil)
end

local function PotentialBtnFun(evt)
  self = evt.context
  -- print("~~~~~~~~~~~~~~~~~~~~~~~~激发")
  local function removeFlash()
    self.fspt_co:removeFromParentAndCleanup(true)
    self.fspt:unregisterEndAnimationScriptHandler()
    -- self.PotentialBtn:setEnable(true)
    -- self.ResetPotentialBtn:setEnable(true)
    self.parentView.CloseBtn:setEnable(true)
    
  end

  local oldSucceePoentialNum = self.parentView.Treasure.addPotential
  local NowGems = CalculationManager.calcComplex_getGemsNow()
  local Nowcoins  = DataManager.getCurrUser().coins
  if self.selectPotentialType == PotentialTypeEnum.silverPotential then
    if tonumber(self.ConsumeSilverNum,10)  > tonumber(Nowcoins,10) then
      self:showCoinLimitPanel()
      return
    end
  elseif self.selectPotentialType == PotentialTypeEnum.goldPotential then
     if tonumber(self.ConsumeGoldNum,10)  >tonumber(NowGems,10)  then
      
      self:showGemLimitPanel()
      return
    end
  end
  -- local function onConfirm()
    local function PotentialSucceed(event)
      self.parentView.refeshContainer = true
      if self.selectPotentialType == PotentialTypeEnum.silverPotential then
        RewardManager:gainReward({itemType = ResourceEnum.COIN, amount = -self.ConsumeSilverNum})
      elseif self.selectPotentialType == PotentialTypeEnum.goldPotential then
        RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -self.ConsumeGoldNum})
        
      end
      
      TreasureSystemUtils.setPotentialStone(self.ConsumeStonelist[self.selectPotentialType])  
      
      local aNewTreasure = event.data.sharkTreasure


      refeshTreasureInfoFromInitData(aNewTreasure)
      self.parentView.Treasure = aNewTreasure
      -- aScene:refreshSelf()
     
      -- print("~~~~~~~~~~~~~~~~~~aNewTreasure = "..tostringRich(aNewTreasure))
      -- local aTreasureData = MetaManager.treasure_meta[self.parentView.Treasure.metaId]
      if self.selectPotentialType == PotentialTypeEnum.goldPotential then
        local  hp,def,att = TreasureSystemUtils.CountPotentialAttandDefandHpAddNum(self.parentView.Treasure,true)
        self.parentView:SetPotentialNum (hp,def,att) 
      else
        local  hp,def,att = TreasureSystemUtils.CountPotentialAttandDefandHpAddNum(self.parentView.Treasure,false)
        self.parentView:SetPotentialNum (hp,def,att)

      end
      local treasureMate = MetaManager.treasure_meta[self.parentView.Treasure.metaId]

      local PotentialSettingMeta = MetaManager.treasure_potential_setting[treasureMate.rare]
      if self.parentView.Treasure.addPotential >= PotentialSettingMeta.PotentialMax  then
         CanonMessageBox.showTextBox(getTextByKey("Treasure_tips25"), nil)
      else
        local PotentialSure = self.parentView.Treasure.addPotential -  oldSucceePoentialNum
        local PotentialTxt = nil
        if PotentialSure > 0  then
          self.fspt = FlashSprite:create("EVO2/equip")
          self.fspt:changeAnimation(0)
          self.fspt:setLoop(false)
          self.fspt_co = CocosObject.new(self.fspt)
          self.fspt:setPosition(self.parentView.flashPos.x, self.parentView.flashPos.y - visibleSize.height)
          self.fspt:registerEndAnimationScriptHandler(removeFlash)
          self.parentView:addChild(self.fspt_co)
          self.PotentialBtn:setEnable(false)
          self.ResetPotentialBtn:setEnable(false)
          self.parentView.CloseBtn:setEnable(false)
          self.parentView:setBtnEnabel(false)
          PotentialTxt = "Treasure_tips24"
        else
          PotentialTxt = "Treasure_tips24_1"
        end

        local aContent = Localization:getInstance():getText(PotentialTxt)
          SuspensionLabel:showContent(self, aContent)
      end  
      self.parentView:refreshTreasureAtt(self.parentView.Treasure.treasureId)
      self:refreshInfoPotential()    
      --显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
      DataManager.fightCapacityMaybeUpdated()
    end
    
     PotentialTreasureRequest.sendRequestDefalut({treasureIds = self.parentView.Treasure.treasureId, types = self.selectPotentialType},PotentialSucceed)
  -- end
  --[[local PotentialTypeEnum = 
          {
            ordinaryPotential = 1,
            silverPotential = 2,
            goldPotential = 3,
          }]]
  local function setConfirmBoxTxtname(number1,number2,txtname)
    local NewTxtname = getTextByKey("Treasure_text_29",{num1 = self.ConsumeStonelist[number1]  ,name1 = getTextByKey("潜力石") ,num2 = number2 ,name2 = txtname ,name3 = getTextByKey(self.TreasureMeta.name)})
     return NewTxtname
  end
  local TreasureTxt = nil
  if self.selectPotentialType == PotentialTypeEnum.ordinaryPotential then
    TreasureTxt = getTextByKey("Treasure_text_30",{num1 = self.ConsumeStonelist[self.selectPotentialType]  ,name1 = getTextByKey("潜力石") ,name2 = getTextByKey(self.TreasureMeta.name)})
  elseif self.selectPotentialType == PotentialTypeEnum.silverPotential then
    TreasureTxt = setConfirmBoxTxtname(self.selectPotentialType,self.ConsumeSilverNum,getTextByKey("elite_coin"))
  elseif self.selectPotentialType == PotentialTypeEnum.goldPotential then
    TreasureTxt = setConfirmBoxTxtname(self.selectPotentialType,self.ConsumeGoldNum,getTextByKey("gemCard_dec3")) 
  end
  -- CanonMessageBox.showAsConfirmBox(TreasureTxt, onConfirm, nil)
end


local function ChcekBoxCallBackFun(evt)

  self = evt.context.container
  local NowGems = CalculationManager.calcComplex_getGemsNow()
  local Nowcoins = DataManager.getCurrUser().coins
  local PotentialSetting  = MetaManager.treasure_potential_setting[self.TreasureMeta.rare]
  local NowPotential = PotentialSetting.PotentialMax - self.parentView.Treasure.usedPotential
  local function BtnStaus(adjude)
    self.PotentialBtn:setEnable(adjude)
    self.PotentialBtnDisplay:getChildByName("btn"):setVisible(adjude)
  end
  self.selectPotentialType = -1
  self.selectPotentialType = evt.context.ChcekIndex
  -- print("~~~~~~~~~~~~~~~~~~~~~~evt.context.ChcekIndex = "..tostringRich(evt.context.ChcekIndex))
  if self.CheckBoxSelectTabList then 
    for i,CheckBoxSelect in ipairs(self.CheckBoxSelectTabList) do
      CheckBoxSelect:setVisible(false)

    end
  end

  if evt.context.ChcekIndex == PotentialTypeEnum.ordinaryPotential then
    
    if TreasureSystemCheck.CheckOrdinaryStone(self.PotentialStone,self.ConsumeStonelist[PotentialTypeEnum.ordinaryPotential]) 
      and NowPotential > 0  then
       BtnStaus(true)
    else
       BtnStaus(false)
    end
    local  hp,def,att = TreasureSystemUtils.CountPotentialAttandDefandHpAddNum(self.parentView.Treasure,false)
    -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~hp,def,att = "..hp.."~~~~~~~~~~"..def.."~~~~~~~~~~~~~~~"..att)
    self.parentView:SetPotentialNum (hp,def,att)
    self.CheckBoxSelectTabList[PotentialTypeEnum.ordinaryPotential]:setVisible(true)
  elseif  evt.context.ChcekIndex == PotentialTypeEnum.silverPotential then
    
    if TreasureSystemCheck.CheckSilverStone(self.PotentialStone,self.ConsumeStonelist[PotentialTypeEnum.silverPotential]) 
      and  TreasureSystemCheck.CheckSilverMoney(Nowcoins,self.ConsumeSilverNum)
       and NowPotential > 0 then
       BtnStaus(true)
    else
       BtnStaus(false)
    end
    local  hp,def,att = TreasureSystemUtils.CountPotentialAttandDefandHpAddNum(self.parentView.Treasure,false)
    self.parentView:SetPotentialNum (hp,def,att)
    self.CheckBoxSelectTabList[PotentialTypeEnum.silverPotential]:setVisible(true)
  elseif  evt.context.ChcekIndex == PotentialTypeEnum.goldPotential then

    if TreasureSystemCheck.CheckGoldStone(self.PotentialStone,self.ConsumeStonelist[PotentialTypeEnum.goldPotential])
      and TreasureSystemCheck.CheckGoldMoney(NowGems,self.ConsumeGoldNum) 
      and NowPotential > 0 then
       BtnStaus(true)
    else
       BtnStaus(false)
    end
    local  hp,def,att = TreasureSystemUtils.CountPotentialAttandDefandHpAddNum(self.parentView.Treasure,true)
    self.parentView:SetPotentialNum (hp,def,att)
    self.CheckBoxSelectTabList[PotentialTypeEnum.goldPotential]:setVisible(true)
  end
  
end


TreaseurePotentialTabView = class(Layer)

function TreaseurePotentialTabView:ctor()
    self.parentView = nil
    self.panelUI = nil
    self.PotentialStone = nil
    self.selectPotentialType = -1
    
end

function TreaseurePotentialTabView:create(aParentView)
    local s = TreaseurePotentialTabView.new()
    s.parentView = aParentView
    s:initLayer()
    return s
end

function TreaseurePotentialTabView:initLayer()
	TreaseurePotentialTabView.super.initLayer(self)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/treasure.json")
	self.builder = builder
	builder.useArtLabelTTF = true
  self.panelUI = builder:build("frame_treasure_04")
  self:addChild(self.panelUI)

  --问号按钮
  local  function helpBtnAction(evt)
    local para = evt.context
    self.parentView.container:setTableViewsEnabled(false)
    local aInfoPanel = ActivityInfoPanel:create(self.parentView.container, getTextByKey("Treasure_help_3"),"Treasure_text_7")
    self.parentView:addChild(aInfoPanel)
    aInfoPanel:scaleIn()
  end
  local helpBtn = Button:create(self.panelUI:getChildByName("halfblack1"))
  helpBtn:addEventListener(Events.kStart,helpBtnAction,self)


  self.PotentialStone = TreasureSystemUtils.getPotentialStone()
  -- self.parentView:refreshTreasureTips(false)
  self.panelUI:getChildByName("txt_10"):getChildByName("txt"):setString(getTextByKey("Treasure_text_2")) 
  self.panelUI:getChildByName("txt_16"):getChildByName("txt"):setString(getTextByKey("Treasure_text_2")) 
  self.panelUI:getChildByName("txt_13"):getChildByName("txt"):setString(getTextByKey("Treasure_text_9"))
  self.panelUI:getChildByName("txt_14"):getChildByName("txt"):setString(getTextByKey("Treasure_text_11"))
  self.panelUI:getChildByName("txt_15"):getChildByName("txt"):setString(getTextByKey("Treasure_text_26"))
  self.panelUI:getChildByName("txt_16"):getChildByName("txt"):setString(getTextByKey("Treasure_text_27"))
  self.panelUI:getChildByName("txt_17"):getChildByName("txt"):setString(getTextByKey("Treasure_text_28"))



  self.ResetPotentialBtnDisplay = self.panelUI:getChildByName("treasure_btn_equip_enhance_czql")
  self.ResetPotentialBtnDisplay:getChildByName("txt_equip_enhance"):setString(getTextByKey("Treasure_text_14"))
  self.ResetPotentialBtn = Button:create(self.ResetPotentialBtnDisplay)
  self.ResetPotentialBtn:addEventListener(Events.kStart, ResetPotentialBtnFun, self)

  self.PotentialBtnDisplay = self.panelUI:getChildByName("treasure_btn_equip_enhance")
  self.PotentialBtnDisplay:getChildByName("txt_equip_enhance"):setString(getTextByKey("Treasure_text_15"))
  self.PotentialBtn = Button:create(self.PotentialBtnDisplay)
  self.PotentialBtn:addEventListener(Events.kStart, PotentialBtnFun, self)
  self.selectPotentialType = PotentialTypeEnum.goldPotential
  self:refreshInfoPotential()
  self:CreateCheckBoxBtn()
  

end
--[[ordinaryPotential = 1,
            silverPotential = 2,
            goldPotential = 3,]]

function TreaseurePotentialTabView:refreshTxtColor(NowGems,NowCoins)
 
  for i=1,5 do
    self.panelUI:getChildByName("txt_11_"..2+i):getChildByName("txt"):setColor(ccc3(255,255,255))
  end
  if not TreasureSystemCheck.CheckOrdinaryStone(self.PotentialStone,self.ConsumeStonelist[PotentialTypeEnum.ordinaryPotential]) then
    self.panelUI:getChildByName("txt_11_7"):getChildByName("txt"):setColor(ccc3(234 ,85,4))
  end
  if not TreasureSystemCheck.CheckSilverStone(self.PotentialStone,self.ConsumeStonelist[PotentialTypeEnum.silverPotential]) then
    self.panelUI:getChildByName("txt_11_5"):getChildByName("txt"):setColor(ccc3(234 ,85,4))
  end

  if not TreasureSystemCheck.CheckGoldStone(self.PotentialStone,self.ConsumeStonelist[PotentialTypeEnum.goldPotential]) then
    self.panelUI:getChildByName("txt_11_3"):getChildByName("txt"):setColor(ccc3(234 ,85,4))
  end

   if not TreasureSystemCheck.CheckGoldMoney(NowGems,self.ConsumeGoldNum) then
    self.panelUI:getChildByName("txt_11_4"):getChildByName("txt"):setColor(ccc3(234 ,85,4))
  end
  
  if not TreasureSystemCheck.CheckGoldMoney(NowCoins,self.ConsumeSilverNum) then
    self.panelUI:getChildByName("txt_11_6"):getChildByName("txt"):setColor(ccc3(234 ,85,4))
  end
end



function TreaseurePotentialTabView:refreshInfoPotential()
  local showPotentialTip = false
  local  function ResetBtnStaus(astaus)
    self.ResetPotentialBtn:setEnable(astaus)
    self.ResetPotentialBtnDisplay:getChildByName("btn"):setVisible(astaus)
  end
  local NowGems = CalculationManager.calcComplex_getGemsNow()
  local Nowcoins = DataManager.getCurrUser().coins
  self.TreasureMeta = MetaManager.treasure_meta[self.parentView.Treasure.metaId]
  self.PotentialStone = TreasureSystemUtils.getPotentialStone()
  -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~self.PotentialStone = "..tostringRich(self.PotentialStone))
  self.panelUI:getChildByName("txt_11_2"):getChildByName("txt"):setString(NowGems)
  self.panelUI:getChildByName("txt_11_8"):getChildByName("txt"):setString(Nowcoins)
  local PotentialSetting  = MetaManager.treasure_potential_setting[self.TreasureMeta.rare]
  local NowPotential = PotentialSetting.PotentialMax - self.parentView.Treasure.usedPotential
  self.panelUI:getChildByName("txt_11_9"):getChildByName("txt"):setString(NowPotential)
  self.panelUI:getChildByName("txt_18"):getChildByName("txt"):setString(self.parentView.Treasure.addPotential.."/"..PotentialSetting.PotentialMax)
 
  local level = TreasureSystemUtils.CheckPotentialRank(self.parentView.Treasure)
  -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~level = "..tostringRich(level))
  local goldPotentialMeta = TreasureSystemConfig.getTreasureGoldCnfig(level) 
  local TreasuetSettingConfig = TreasureSystemConfig.getTreasureSettingConfig()
  local silverPotentialMeta = TreasureSystemConfig.getTreasureSilverCnfig(level)
  local ordinaryPotentialMeta = TreasureSystemConfig.getTreasureOrdinaryCnfig(level)
  self.ConsumeStonelist = {} 
  self.ConsumeGoldNum = -1
  self.ConsumeSilverNum = -1
  self.panelUI:getChildByName("txt_11_4"):getChildByName("txt"):setString(goldPotentialMeta.number2)
  self.ConsumeGoldNum = goldPotentialMeta.number2
  self.panelUI:getChildByName("txt_11_3"):getChildByName("txt"):setString(goldPotentialMeta.number)
  self.ConsumeStonelist[3] = goldPotentialMeta.number
  self.panelUI:getChildByName("txt_19"):getChildByName("txt"):setString(getTextByKey("Treasure_text_10",{num = goldPotentialMeta.successRate,num2 = TreasuetSettingConfig.treasurePotentialUp}))
  self.panelUI:getChildByName("txt_11_6"):getChildByName("txt"):setString(silverPotentialMeta.number2)
  self.ConsumeSilverNum = silverPotentialMeta.number2
  self.panelUI:getChildByName("txt_11_5"):getChildByName("txt"):setString(silverPotentialMeta.number)
  self.ConsumeStonelist[2] = silverPotentialMeta.number
  self.panelUI:getChildByName("txt_20"):getChildByName("txt"):setString(getTextByKey("Treasure_text_12",{num = silverPotentialMeta.successRate}))
  self.panelUI:getChildByName("txt_11_7"):getChildByName("txt"):setString(ordinaryPotentialMeta.number)
  self.ConsumeStonelist[1] = ordinaryPotentialMeta.number
  self.panelUI:getChildByName("txt_21"):getChildByName("txt"):setString(getTextByKey("Treasure_text_12",{num = ordinaryPotentialMeta.successRate}))
  self.panelUI:getChildByName("txt_11_1"):getChildByName("txt"):setString(self.PotentialStone)
  --设置文本的颜色
  self:refreshTxtColor(NowGems,Nowcoins)
  --设置潜力品阶
  --self.parentView.Treasure.addPotential
  local NewMax = MetaManager.treasure_potential_setting[level+1].PotentialMax
  if self.parentView.Treasure.addPotential == NewMax then
    showPotentialTip = true
  end
 --[[refreshTreasureTipsRight(adjude)
refreshTreasureTipsOne(level)]]
  self.parentView:refreshTreasureTips(true)
  if showPotentialTip then
    
    self.parentView:refreshTreasureTipsRight(true)
    self.parentView:refreshTreasureTipsnum(level)
  elseif level > TreasureSystemConsts.Potentiallevel_NONE  then
  -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~level = "..level)
    self.parentView:refreshTreasureTipsRight(false)
    self.parentView:refreshTreasureTipsOne(level)
  else
    self.parentView:refreshTreasureTips(false)
  end
  if  self.PotentialStone < self.ConsumeStonelist[self.selectPotentialType] 
    or NowPotential <= 0 then
    self.PotentialBtn:setEnable(false)
    self.PotentialBtnDisplay:getChildByName("btn"):setVisible(false)
  else
    self.PotentialBtn:setEnable(true)
    self.PotentialBtnDisplay:getChildByName("btn"):setVisible(true)
  end
  --冲制潜力 
  if self.parentView.Treasure.usedPotential <= 0 then
    ResetBtnStaus(false)
  else
    ResetBtnStaus(true)
  end
  self.parentView:setBtnEnabel(true)
end

function TreaseurePotentialTabView:RefreshBtnStaus(types)

end

function TreaseurePotentialTabView:CreateCheckBoxBtn()
   self.CheckBoxSelectTabList = {}
  -- self.CheckBoxBtnTabList = {}
  local PotentialSetting  = MetaManager.treasure_potential_setting[self.TreasureMeta.rare]
  local NowPotential = PotentialSetting.PotentialMax - self.parentView.Treasure.usedPotential  
  local NowGems = CalculationManager.calcComplex_getGemsNow()

  for i=1,3 do
    local checkBoxdisplay = self.panelUI:getChildByName("treasure_btn_cardTrain_levellow"..i)
    local checkSelectdisplay = checkBoxdisplay:getChildByName("common_icon_checkbox_sb")
    if i == PotentialTypeEnum.goldPotential then
      checkSelectdisplay:setVisible(true)
      local  hp,def,att = TreasureSystemUtils.CountPotentialAttandDefandHpAddNum(self.parentView.Treasure,true)
      self.parentView:SetPotentialNum (hp,def,att)
      if TreasureSystemCheck.CheckGoldStone(self.PotentialStone,self.ConsumeStonelist[PotentialTypeEnum.goldPotential])
      and TreasureSystemCheck.CheckGoldMoney(NowGems,self.ConsumeGoldNum) 
      and NowPotential > 0 then
        self.PotentialBtn:setEnable(true)
        self.PotentialBtnDisplay:getChildByName("btn"):setVisible(true)
      else
        self.PotentialBtn:setEnable(false)
        self.PotentialBtnDisplay:getChildByName("btn"):setVisible(false)
      end
    else
      checkSelectdisplay:setVisible(false)
    end
    local checkBoxBtn = Button:create(checkBoxdisplay)
    checkBoxBtn:addEventListener(Events.kStart, ChcekBoxCallBackFun, {ChcekIndex = i,container = self})
    -- table.insert(self.CheckBoxBtnTabList,checkBoxBtn)
    table.insert(self.CheckBoxSelectTabList,checkSelectdisplay)
  end


end

function TreaseurePotentialTabView:showCoinLimitPanel( )
   local aPanel = MessageBoxPanel:create(self,MessageBoxType.kCoinLimit)
   self.parentView:addChild(aPanel)
   aPanel:scaleIn()
end


function TreaseurePotentialTabView:showGemLimitPanel()
  
  local function onReplaceScene()
    self.parentView.container:setTableViewsEnabled(true)
    self.parentView.container.targetInfoPanel = nil
  end
  local aPanel = AssistantMessageBoxPanel:create( self.parentView.container, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene})
  self.parentView:addChild(aPanel)
  aPanel:scaleIn()
end

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == evt.context)
end

--清除场景事件
local function onSceneClear(evt)
	PopoutManager:sharedManager():pullin(evt.context, kPopoutDir.kScale )
end
------------------------------------------------------------------------------------------------------


local tabTypeEnum = {
	introduction = 1,
	strengthen = 2,
	risingStar = 3,
	potential = 4,
}

local showTypeEnum = {
  att = 1,
	def = 2,
  hp = 3,
}


local tabViewList = {
	TreasureIntroductionTabView,
	TreasureStrengthenTabView,
	TreasureRisingStarTabView,
	TreaseurePotentialTabView,
}

TreasureNewInfoPanel = class(Layer)

function TreasureNewInfoPanel.clear()
 
end
function TreasureNewInfoPanel:ctor()
	self.container = nil
	self.content = nil
 
end

function TreasureNewInfoPanel:create(container,Treasureids,Selectnum, index,enterAndReturnScene )
	local s = TreasureNewInfoPanel.new()
	self.container = container
	self.enterAndReturnScene = enterAndReturnScene
  self.newIndex = index
  self.selectnum = Selectnum
	self.Treasure = getTreasureInfoFromInitData(Treasureids)
	
	s:initLayer(container)
	return s
end



function TreasureNewInfoPanel:initLayer(container)
	TreasureNewInfoPanel.super.initLayer(self)
  self.container:setTableViewsEnabled(false)
  self.refeshContainer  = false
	local builder = LayoutBuilder:createWithContentsOfFile("scene/treasure.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_treasure1") 
	-- print("~~~~~~~~~~~~~~~~~~self.Treasure = "..tostringRich(self.Treasure))
	local function onClose(evt)
    PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
    self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
    if self.refeshContainer then
      -- print("~~~~~~~~~~~~刷新了")
      self.container:refreshUI(self.Treasure)
    end
    
	end
	local Closedisplay = self.panelUI:getChildByName("frame_treasure_dk"):getChildByName("btn_close_sb")
	
	self.CloseBtn = Button:create(Closedisplay)
	self.CloseBtn:addEventListener(Events.kStart, onClose, self)
	self:addChild(self.panelUI)
	-- local Closedisplay = self.panelUI:getChildByName("frame_treasure_dk"):getChildByName("btn_close_sb")
	

	local tabUI = self.panelUI:getChildByName("treasure_01_title")
	
  local function onClickTab( e )
	self:changeToTab(e.context.tabIndex)
    --[[
		if e.context.tabIndex == tabTypeEnum.introduction then
			print("~~~~~~~~~~~简介")
		elseif e.context.tabIndex == tabTypeEnum.strengthen then
			print("~~~~~~~~~~~强化")
		elseif e.context.tabIndex == tabTypeEnum.risingStar then
			print("~~~~~~~~~~~升星")
		elseif e.context.tabIndex == tabTypeEnum.potential then
			print("~~~~~~~~~~~潜力")
		end
    ]]
	end
   
  --Title
  self.panelUI:getChildByName("frame_treasure_dk"):getChildByName("treasure_txt_bwxq"):getChildByName("txt_bwxq"):setString(getTextByKey("Treasure_titel_10"))
	
  self.tipsName = {}
	self.tabButtonList = {}
	self.tabSelectedStateList = {}
	self.tabUnselectedStateList = {}
	local introductionTab = tabUI:getChildByName("btn_introduction")
	local aIntroductionButton = Button:create(introductionTab)  --简介
	aIntroductionButton:addEventListener(Events.kStart, onClickTab, {tabIndex = tabTypeEnum.introduction})
	table.insert(self.tabButtonList, aIntroductionButton)
	table.insert(self.tipsName,tabUI:getChildByName("tips_yellow_sj"))
	table.insert(self.tabSelectedStateList, {introductionTab:getChildByName("lbl_in_introductiontothecard"), introductionTab:getChildByName("btn_tab_active")})
	table.insert(self.tabUnselectedStateList, {introductionTab:getChildByName("lbl_introductiontothecard"), introductionTab:getChildByName("btn_details_card_inactive")})
	local strengthenTab = tabUI:getChildByName("btn_enchant")
	local aStrengthenButton = Button:create(strengthenTab)        --强化
	aStrengthenButton:addEventListener(Events.kStart, onClickTab, {tabIndex = tabTypeEnum.strengthen})
	table.insert(self.tabButtonList, aStrengthenButton)
	table.insert(self.tipsName,tabUI:getChildByName("tips_yellow_sj"..tabTypeEnum.strengthen-1))
	table.insert(self.tabSelectedStateList, {strengthenTab:getChildByName("lbl_in_introductiontothecard_qh"), strengthenTab:getChildByName("btn_tab_active")})
	table.insert(self.tabUnselectedStateList, {strengthenTab:getChildByName("lbl_introductiontothecard_qh"), strengthenTab:getChildByName("btn_details_card_inactive")})
	local RisingStarTab = tabUI:getChildByName("btn_equipInfo_03_enchant")
	local RisingStarButton = Button:create(RisingStarTab)          --升星
	RisingStarButton:addEventListener(Events.kStart, onClickTab, {tabIndex = tabTypeEnum.risingStar})
	table.insert(self.tabButtonList, RisingStarButton)
	table.insert(self.tipsName,tabUI:getChildByName("tips_yellow_sj"..tabTypeEnum.risingStar-1))
	table.insert(self.tabSelectedStateList, {RisingStarTab:getChildByName("lbl_in_introductiontothecard_sx"), RisingStarTab:getChildByName("btn_tab_active")})
	table.insert(self.tabUnselectedStateList, {RisingStarTab:getChildByName("lbl_introductiontothecard_sx"), RisingStarTab:getChildByName("btn_details_card_inactive")})
	local PotentialTab = tabUI:getChildByName("btn_equipInfo_04_enchant")
	local PotentialButton = Button:create(PotentialTab)    --潜力
	PotentialButton:addEventListener(Events.kStart, onClickTab, {tabIndex = tabTypeEnum.potential})
	table.insert(self.tabButtonList, PotentialButton)
	table.insert(self.tipsName,tabUI:getChildByName("tips_yellow_sj"..tabTypeEnum.potential-1))
	table.insert(self.tabSelectedStateList, {PotentialTab:getChildByName("lbl_in_introductiontothecard_ql"), PotentialTab:getChildByName("btn_tab_active")})
	table.insert(self.tabUnselectedStateList, {PotentialTab:getChildByName("lbl_introductiontothecard_ql"), PotentialTab:getChildByName("btn_details_card_inactive")})
    local aTreasureData = getTreasureInfoFromInitData(self.Treasure.treasureId)
    self:refreshTreasureLockState(aTreasureData.lock , true)
    
 

    local aCardId = aTreasureData.cardId
	if (aCardId~=0) then
		local cardsData = DataManager.getCardsData()
		local aCardMeta = CommonManager.getSubTableByKey(
			cardsData,
			{name="cardId", value=aCardId}
		).metaId
		local aCardName = MetaManager.card_meta[aCardMeta].name
		self.panelUI:getChildByName("popup_treasure_01"):getChildByName("treasure_equipInfo_upper_01"):getChildByName("zhuangbeizhong"):setZOrder(2001)
    self.panelUI:getChildByName("popup_treasure_01"):getChildByName("treasure_equipInfo_upper_01"):getChildByName("common_txt_ cc_max"):getChildByName("txt"):setString(Localization:getInstance():getText("bag_EquippedText",{cardname = getTextByKey(aCardName)}))
	else
		self.panelUI:getChildByName("popup_treasure_01"):getChildByName("treasure_equipInfo_upper_01"):getChildByName("common_txt_ cc_max"):setVisible(false)
		self.panelUI:getChildByName("popup_treasure_01"):getChildByName("treasure_equipInfo_upper_01"):getChildByName("zhuangbeizhong"):setVisible(false)
	end
	
    local  Celldisplay = self.panelUI:getChildByName("popup_treasure_01"):getChildByName("treasure_equipInfo_upper_01")
    for i=1,3 do
	   	Celldisplay:getChildByName("attribute_0"..i):getChildByName("icon_atk"):setVisible(false)
	   	Celldisplay:getChildByName("attribute_0"..i):getChildByName("icon_hp"):setVisible(false)
	   	Celldisplay:getChildByName("attribute_0"..i):getChildByName("icon_def"):setVisible(false)
    end
  -- self.ColorPanleList = {}
  for i=0,6 do

    local txtName = TreasureSystemUtils.getUINameTreasureAttrType(i)
    -- print("~~~~~~~~~~~~~~~~txtName = "..tostringRich(txtName))
    -- self.ColorPanleList[i+1] = txtName
    Celldisplay:getChildByName(txtName):setVisible(false)

  end
  self:refreshTreasureIconandStar()--aTreasureData.metaId
  self:refreshTreasureAtt(self.Treasure.treasureId)
  local Selectnum = self.selectnum or tabTypeEnum.introduction
	self:changeToTab(Selectnum)
	

		
end


function TreasureNewInfoPanel:changeToTab(tabType)
	self.currentTabType = tabType
	for i = 1, 4 do
		if i == self.currentTabType then
			self.tabButtonList[i]:setEnable(false)
			self.tabSelectedStateList[i][1]:setVisible(true)
			self.tabSelectedStateList[i][2]:setVisible(true)
			self.tabUnselectedStateList[i][1]:setVisible(false)
			self.tabUnselectedStateList[i][2]:setVisible(false)
			self.tipsName[i]:setVisible(true)
			self.tipsName[i]:setZOrder(1000)
		else
			self.tabButtonList[i]:setEnable(true)
			self.tabSelectedStateList[i][1]:setVisible(false)
			self.tabSelectedStateList[i][2]:setVisible(false)
			self.tabUnselectedStateList[i][1]:setVisible(true)
			self.tabUnselectedStateList[i][2]:setVisible(true)
			self.tipsName[i]:setVisible(false)
		end
	end
	if self.currentTabView then
		self.currentTabView:removeFromParentAndCleanup(true)
	end
	self.panelUI:getChildByName("treasure_01_title"):setZOrder(5)
	self.currentTabView = tabViewList[self.currentTabType]:create(self)
  self.panelUI:addChild(self.currentTabView)
end

function TreasureNewInfoPanel:refreshTreasureTips(adjude)
	self.panelUI:getChildByName("popup_treasure_01"):getChildByName("tips_treasure_01"):setVisible(adjude)
	
end

function TreasureNewInfoPanel:refreshTreasureTipsRight(adjude)
  self.panelUI:getChildByName("popup_treasure_01"):getChildByName("tips_treasure_01"):getChildByName("lbl_ji"):setVisible(adjude)
  self.panelUI:getChildByName("popup_treasure_01"):getChildByName("tips_treasure_01"):getChildByName("lbl_jiantou"):setVisible(adjude)
end

function TreasureNewInfoPanel:refreshTreasureTipsOne(level)
   local oneTipsdispaly = self.panelUI:getChildByName("popup_treasure_01"):getChildByName("tips_treasure_01"):getChildByName("lbl_you"):setVisible(true)
  local oneTipsdispaly = self.panelUI:getChildByName("popup_treasure_01"):getChildByName("tips_treasure_01"):getChildByName("lbl_you"):getChildByName("txt")
  local oneColor = TreasureSystemUtils.getColorByRarity( level)
  local oneTxtName = TreasureSystemUtils.getTextByTreasureAttrType( level)
  oneTipsdispaly:setColor(oneColor)
  oneTipsdispaly:setString(oneTxtName)
end

function TreasureNewInfoPanel:refreshTreasureTipsnum(level)
  local oneTipsdispaly = self.panelUI:getChildByName("popup_treasure_01"):getChildByName("tips_treasure_01"):getChildByName("lbl_you"):getChildByName("txt")
  local twoTipsdispaly = self.panelUI:getChildByName("popup_treasure_01"):getChildByName("tips_treasure_01"):getChildByName("lbl_ji"):getChildByName("txt")
  local oneColor = TreasureSystemUtils.getColorByRarity( level)
  local twoColor = TreasureSystemUtils.getColorByRarity( level+1)
  local oneTxtName = TreasureSystemUtils.getTextByTreasureAttrType( level)
  local twoTxtName = TreasureSystemUtils.getTextByTreasureAttrType( level+1)
  -- if oneColor then
    oneTipsdispaly:setColor(oneColor)
    oneTipsdispaly:setString(oneTxtName)
  -- end
  twoTipsdispaly:setColor(twoColor)
  
 
  twoTipsdispaly:setString(twoTxtName)
end

function TreasureNewInfoPanel:refreshTreasureLockState(locked, notRefreshContainer)
	local lockStateDisplay = self.panelUI:getChildByName("popup_treasure_01"):getChildByName("treasure_equipInfo_upper_01"):getChildByName("icon_lock_big")
	lockStateDisplay:setZOrder(100)
	if locked then
		lockStateDisplay:setVisible(true)
	else
		lockStateDisplay:setVisible(false)
	end
	-- if not notRefreshContainer then
	-- 	self.container:refreshUIForPanelInfo(self.cardId)
	-- end
end

function TreasureNewInfoPanel:refreshTreasureColorPanel(star)
  local  Celldisplay = self.panelUI:getChildByName("popup_treasure_01"):getChildByName("treasure_equipInfo_upper_01")

    for i=0,6 do
   
      local txtName = TreasureSystemUtils.getUINameTreasureAttrType(i)
      if i == star-1 then
        Celldisplay:getChildByName(txtName):setVisible(true)
      else
        Celldisplay:getChildByName(txtName):setVisible(false)
      end
   
    end
   
  
  
end

function TreasureNewInfoPanel:refreshTreasureIconandStar()


	local  Celldisplay = self.panelUI:getChildByName("popup_treasure_01"):getChildByName("treasure_equipInfo_upper_01")
	Celldisplay:getChildByName("normal_card_small_sb"):setVisible(false)
  self:refreshTreasureColorPanel(MetaManager.treasure_meta[self.Treasure.metaId].rare)  
	--设置装备
	if self.treasureObject then
		self.treasureObject:removeFromParentAndCleanup(true)
    end 
	self.treasureObject = CanonItem:create()
    self.treasureObject:loadByMetaId(self.Treasure.metaId)
	self.treasureObject:setScale(130/150)
	local position = Celldisplay:getChildByName("normal_card_small_sb"):getPosition()
	self.treasureObject:setPosition(ccp(position.x,position.y))
	Celldisplay:addChild(self.treasureObject)
    self.flashPos = Celldisplay:convertToWorldSpace(ccp(position.x, position.y))
    
    for i=1,6 do
    	Celldisplay:getChildByName("common_star_sb"..i):setVisible(false)
    end

	for quality = 1, 6 do
		
		if (quality == MetaManager.treasure_meta[self.Treasure.metaId].rare+1) then
			break
		end
		Celldisplay:getChildByName("common_star_sb"..quality):setVisible(true)
	end
    Celldisplay:getChildByName("common_txt_bw_name"):getChildByName("txt"):setString(Localization:getInstance():getText(MetaManager.treasure_meta[self.Treasure.metaId].name))
	
end

--[[self.treasureMate = MetaManager.treasure_meta
    self.treasurePotentialMate = MetaManager.treasure_potential_setting
    self.treasureStarMate = MetaManager.treasure_star
]]
function TreasureNewInfoPanel:ShowPotentialNum (adjude)
  local Celldisplay = self.panelUI:getChildByName("popup_treasure_01"):getChildByName("treasure_equipInfo_upper_01")
  Celldisplay:getChildByName("txt_21_1"):setVisible(adjude)
  Celldisplay:getChildByName("txt_21_2"):setVisible(adjude)
  Celldisplay:getChildByName("txt_21_3"):setVisible(adjude)
end

function TreasureNewInfoPanel:SetPotentialNum (hp,def,att)
  self:ShowPotentialNum (true)
  local Celldisplay = self.panelUI:getChildByName("popup_treasure_01"):getChildByName("treasure_equipInfo_upper_01")
  Celldisplay:getChildByName("txt_21_1"):getChildByName("txt"):setString("+"..att)
  Celldisplay:getChildByName("txt_21_2"):getChildByName("txt"):setString("+"..def)
  Celldisplay:getChildByName("txt_21_3"):getChildByName("txt"):setString("+"..hp)
 
end

function TreasureNewInfoPanel:refreshTreasureAtt(treasureId)
 local  Celldisplay = self.panelUI:getChildByName("popup_treasure_01"):getChildByName("treasure_equipInfo_upper_01")
 
 local sharkTreasure = getTreasureInfoFromInitData(treasureId)	
 -- print("~~~~~~~~~~~~~~~~~~~sharkTreasure = "..tostringRich(sharkTreasure))
 Celldisplay:getChildByName("txt_equip_lv_num"):getChildByName("font"):setString(sharkTreasure.level)
 local hp,def,att   = TreasureSystemUtils.CountAttandDefandHp(sharkTreasure,sharkTreasure.level)
 -- print("~~~~~~~~~~~~~~~~~~~~~~~~~~~hp,def,att = "..hp.."~~~~hp "..def.." def "..att.." att ")
 for i=1,3 do

 	local display = Celldisplay:getChildByName("attribute_0"..i)
 	if i == showTypeEnum.hp then
 		display:getChildByName("icon_hp"):setVisible(true)
 		display:getChildByName("txt_03"):getChildByName("txt"):setString(hp)
 		display:getChildByName("txt_02"):getChildByName("txt"):setString(hp)
 	elseif i == showTypeEnum.att then
 		display:getChildByName("icon_atk"):setVisible(true)
 		display:getChildByName("txt_03"):getChildByName("txt"):setString(att)
 		display:getChildByName("txt_02"):getChildByName("txt"):setString(att)
 	elseif i == showTypeEnum.def then
 		display:getChildByName("icon_def"):setVisible(true)
 		display:getChildByName("txt_03"):getChildByName("txt"):setString(def)
 		display:getChildByName("txt_02"):getChildByName("txt"):setString(def)
 	end
 	
 end

end

function TreasureNewInfoPanel:setBtnEnabel(adjude)
  for i,tabButton in ipairs(self.tabButtonList) do
    tabButton:setEnable(adjude)
  end
end

