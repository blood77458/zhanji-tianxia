require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "canon.data.MetaManager"
require "canon.utils.ViewControlUtil"
require "canon.manager.SpiritManager"
require "canon.request.UpgradeSpiritRequest"
require "canon.request.UnlockSubAttributeRequest"
require "canon.request.SetSpiritRefreshAutoSaveRequest"
require "canon.request.RefreshSubAttributeRequest"
require "canon.panel.SpiritBatchRefreshResultPanel"
require "canon.panel.SpiritBatchRefreshSingleResultPanel"
require "canon.panel.BatchSelectSpiritPanel"

SpiritComposePanel = class(Layer)
local visibleSize = CCDirector:sharedDirector():getVisibleSize();
local SELF

RefreshType = table.const{
	FREE = 1,
	TOOL = 2,
	GEM = 3,
	TOOL_BATCH = 4,
	GEM_BATCH = 5,
}

function SpiritComposePanel:ctor()
  SELF = self
  self.container = nil
  self.lockId = 0
  self.attributesSpirteTable = {
  [1] = {},
  [2] = {},
  [3] = {}
	}
  self.leftBtntype = 0
  self.rightBtntype = 0
end

function SpiritComposePanel:create(container , spirit , spiritInfoPanel)
  local panel = SpiritComposePanel.new()
  panel.container = container
  panel.spirit = spirit
  panel.spiritInfoPanel = spiritInfoPanel
  panel:initLayer()
  
  return panel
end

function SpiritComposePanel:RefreshConform( btnType )
  if btnType == false then
    return 
  end
  if btnType == 1 then
    self:LeftBtnRefreshConform()
  else
    self:RightBtnRefreshConform()
  end
end

-- 在属性列表的 0 位置加上元神的一个可选刷新属性
function SpiritComposePanel:addWillChangeAttribute(sharkSpiritAttributes)
  local willChangeAttribute = self.spirit.sharkSpiritAttributes
  sharkSpiritAttributes[0] = {sharkSpiritAttribute = willChangeAttribute}
end

function SpiritComposePanel:sendRequest( btnType )
  local function onRefreshSucceedResponse(params , e )
    local propCost = SpiritManager.getSpiritRefreshPropmCost( self.spirit )
    local gemCost = SpiritManager.getSpiritRefreshGemCost( self.spirit )
    local lockedRefreshMultiplier = ((self.lockId == 0) and 1) or DataManager.GameMetaData.spiritSettingConfig.lockedRefreshMultiplier
    if params.refreshType == RefreshType.FREE then
      SpiritManager.setFreeRefreshTimes(SpiritManager.getFreeRefreshTimes() - 1)
    elseif params.refreshType == RefreshType.TOOL then
      SpiritManager.useRefreshPropNum( propCost *lockedRefreshMultiplier) 
    elseif params.refreshType == RefreshType.TOOL_BATCH then
      SpiritManager.useRefreshPropNum( propCost * 10  *lockedRefreshMultiplier)
    elseif params.refreshType == RefreshType.GEM then
      RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -gemCost *lockedRefreshMultiplier})  
    elseif params.refreshType == RefreshType.GEM_BATCH then
      RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -gemCost * 10 *lockedRefreshMultiplier}) 
    end

    if #e.data.refreshSharkSpiritAttribute == 10 then
      self:addWillChangeAttribute(e.data.refreshSharkSpiritAttribute)
      local targetInfoPanel = SpiritBatchRefreshResultPanel:create( self , e.data.refreshSharkSpiritAttribute)
      PopoutManager:sharedManager():popout(targetInfoPanel, kPopoutDir.kScale, false, false ,self)
    elseif not self:getCheckBoxStatus() then
      self:addWillChangeAttribute(e.data.refreshSharkSpiritAttribute)
      local targetInfoPanel = SpiritBatchRefreshSingleResultPanel:create( self , e.data.refreshSharkSpiritAttribute)
      PopoutManager:sharedManager():popout(targetInfoPanel, kPopoutDir.kScale, false, false ,self)
    else
      self.spirit.lockAttributeIndex = self.lockId
      if #e.data.refreshSharkSpiritAttribute[1].sharkSpiritAttribute == 1 then
        local pos = (self.lockId == 1) and 2 or 1
        self.spirit.sharkSpiritAttributes[pos] = e.data.refreshSharkSpiritAttribute[1].sharkSpiritAttribute
        local spiritData = DataManager.getSpiritsData()
        for k,v in pairs(spiritData) do
          if v.spiritId == self.spirit.spiritId then
            spiritData[k] = self.spirit
          end
        end
        DataManager.setSpiritsData(spiritData)
        self:refreshAllUI(true)
      elseif #e.data.refreshSharkSpiritAttribute[1].sharkSpiritAttribute == 2 then
        for i=1,2 do
          self.spirit.sharkSpiritAttributes[i] = e.data.refreshSharkSpiritAttribute[1].sharkSpiritAttribute[i]
        end
        local spiritData = DataManager.getSpiritsData()
        for k,v in pairs(spiritData) do
          if v.spiritId == self.spirit.spiritId then
            spiritData[k] = self.spirit
          end
        end
        DataManager.setSpiritsData(spiritData)
        self:refreshAllUI(true)
      end
    end
        
    --显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
    DataManager.fightCapacityMaybeUpdated()
  end

  local function onRefreshFailedResponse( e )
    if e.data == 716858 or e.data == 716861 then
      local function sendRequest()
        local function getHomeInfoFinish(responseData)
          SpiritManager.setFreeRefreshTimes( responseData.data.freeSpiritRefreshNum )
          self:refreshAllUI(true)
        end
        local function getHomeInfoFailed(event)
        end
        
        local params = {}
        local request = GetHomeInfoRequest.new(params, rpc.SendingPriority.kHigh)
        request:addEventListener(RequestNotifyEnum.GetHomeInfoSucceed, getHomeInfoFinish)
        request:addEventListener(RequestNotifyEnum.GetHomeInfoFailed, getHomeInfoFailed)
        request:start()
      end

      CanonMessageBox:Show(
        Localization:getInstance():getText("spirit_refresh_newDay"),
        ShowMessageType.ShowText,
        ShowButtonType.ID_OK,
        40,
        sendRequest
      )
    else
      CanonMessageBox:showCommUnHandleErrorBox(e.data)
    end

  end
  g_previousBattleCount = CommonManager:getLocalPlayerStrength()
  local params = {spiritId = self.spirit.spiritId , refreshType = btnType , lockIndex = self.lockId}
  RefreshSubAttributeRequest.sendRequest(params , onRefreshSucceedResponse , onRefreshFailedResponse)
end

function SpiritComposePanel:LeftBtnRefreshConform()
  local gemCost = SpiritManager.getSpiritRefreshGemCost( self.spirit )
    local coef = ((self.lockId == 0) and 1) or DataManager.GameMetaData.spiritSettingConfig.lockedRefreshMultiplier
    if self.leftBtntype == RefreshType.GEM and CalculationManager.calcComplex_getGemsNow() < gemCost * coef then
      local function onReplaceScene()
          self.container:setTableViewsEnabled(true)
          -- self.container.targetInfoPanel = nil
        end
        self:setTableViewsEnabled(false)
        local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene , brotherLayer = self})
        self.container:addChild(aPanel)
        aPanel:scaleIn()
        return
    end
    self:sendRequest(self.leftBtntype)
end

function SpiritComposePanel:RightBtnRefreshConform()
  local gemCost = SpiritManager.getSpiritRefreshGemCost( self.spirit )
    local coef = ((self.lockId == 0) and 1) or DataManager.GameMetaData.spiritSettingConfig.lockedRefreshMultiplier
    if self.rightBtntype == RefreshType.GEM_BATCH and CalculationManager.calcComplex_getGemsNow() < gemCost * coef * 10 then
      local function onReplaceScene()
          self.container:setTableViewsEnabled(true)
          -- self.container.targetInfoPanel = nil
        end
        self:setTableViewsEnabled(false)
        local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene , brotherLayer = self})
        self.container:addChild(aPanel)
        aPanel:scaleIn()
        return
    end
    self:sendRequest(self.rightBtntype)
end

function SpiritComposePanel:conformEatHighRareSpirit(e)
	if e == false then
		return
	end
	local function onUpgradeSuccessedResponse(params , e )
		local spiritData = DataManager.getSpiritsData()
		local toremoveKeys = {}
		for k,v in pairs(spiritData) do
			if v.spiritId == e.data.sharkSpirit.spiritId then
				spiritData[k] = e.data.sharkSpirit
			end
			for i=1,#params.slaveSpiritIds do
				if params.slaveSpiritIds[i] == v.spiritId then
					table.insert(toremoveKeys , k)
				end
			end
		end
		for i = #toremoveKeys, 1, -1
		do
			table.remove(spiritData, toremoveKeys[i])
		end
		DataManager.setSpiritsData(spiritData)
		self.spirit = e.data.sharkSpirit
        
    --显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
    DataManager.fightCapacityMaybeUpdated()

    self.selectSpiritsTable = {}
    local allComposeEnabledSpirit = SpiritManager.getComposeEnabledSpirits(self.spirit)
    for i=1,#allComposeEnabledSpirit do
      self.selectSpiritsTable[i] = nil
    end
		self:refreshAllUI()
		-- self.container:refreshUI()
	end
	local function onUpgradeFailedResponse( e )
		CanonMessageBox:showCommUnHandleErrorBox(e.data)
	end

	local slaveIds = {}
	local maxRarty = 0
	for k,v in pairs(self.selectSpiritsTable) do
		if v ~= nil then
			local rare = SpiritManager.getSpiritRare( v )
			if rare > maxRarty then
				maxRarty = rare
			end
			table.insert(slaveIds , v.spiritId)
		end
	end
  g_previousBattleCount = CommonManager:getLocalPlayerStrength()
	local params = {masterSpiritId = self.spirit.spiritId , slaveSpiritIds = slaveIds}
	UpgradeSpiritRequest.sendRequest(params , onUpgradeSuccessedResponse , onUpgradeFailedResponse)
end

function SpiritComposePanel:refreshAllUI(flag)
	self.allValues = SpiritManager.getAllAttributesValue( self.spirit )
	  for i=1,2 do
	  	self.attributesSpirteTable[1][i]:setVisible(false)
	  end
	  local mainName = SpiritManager.getMainAttributeName( self.spirit )
	  self.attributesSpirteTable[1][6]:getChildByName("txt"):setString(mainName.."+"..self.allValues[1])
	  self.attributesSpirteTable[1][3]:getChildByName("txt"):setString(SpiritManager.getMainAttributeGrow( self.spirit ))
	  self.ui:getChildByName("formation_txt_lv_num"):getChildByName("font"):setString(self.spirit.level)
	self:refreshUI()
	local allComposeEnabledSpirit = SpiritManager.getComposeEnabledSpirits(self.spirit)
	if self.tableView then
		self.tableView:removeFromParentAndCleanup(true)
	end
	self.tableView = self:createTableView(allComposeEnabledSpirit)
	self.ui:addChild(self.tableView)

  if not flag then
    self.selectSpiritsTable = {}
    for i=1,#allComposeEnabledSpirit do
      self.selectSpiritsTable[i] = nil
    end
  end
  local totalExp = 0
  for k,v in pairs(self.selectSpiritsTable) do
    if v ~= nil then
      totalExp = totalExp + SpiritManager.getSpiritContainedExp( v )
    end
  end
  self:refreshProcessBar(totalExp)

	self.container:refreshUI(self.spirit)
  if self.spiritInfoPanel and self.spiritInfoPanel.refresh and type(self.spiritInfoPanel.refresh) == "function" then
    self.spiritInfoPanel:refresh()
  end
end

function SpiritComposePanel:showSubAttributes(levelUpNum)
  self.ui:getChildByName("lbl_max"):setVisible(false)
	-- self.spirit.sharkSpiritAttributes
	self.allValues = SpiritManager.getAllAttributesValue( self.spirit )
	for i=2,3 do
		self.attributesSpirteTable[i][7].refCocosObj:setColor(ccc3(255,255,255))
	end
	for i=1,2 - #self.spirit.sharkSpiritAttributes do
		for j=2,6 do
			self.attributesSpirteTable[4 - i][j]:setVisible(false)
			-- self.attributesSpirteTable[i + 1][3]:setVisible(true)
		end
		self.attributesSpirteTable[4 - i][7].refCocosObj:setColor(ccc3(100,100,100))
	end

	if #self.spirit.sharkSpiritAttributes == 2 then
		for i=1,2 do
			self.attributesSpirteTable[i + 1][1]:setVisible(true)
		end
	end

	levelUpNum = levelUpNum or 0

	self.attributesSpirteTable[1][5]:getChildByName("txt"):setString("+"..SpiritManager.getMainAttributeGrow(self.spirit) * levelUpNum)
	
	for i=1,#self.spirit.sharkSpiritAttributes do
		local name = SpiritManager.getTextBySpiritAttrType( self.spirit.sharkSpiritAttributes[i].attributeType )
		self.attributesSpirteTable[i + 1][6]:getChildByName("txt"):setString(name.."+"..self.allValues[i + 1])
		self.attributesSpirteTable[i + 1][6]:setVisible(true)
		self.attributesSpirteTable[i + 1][3]:getChildByName("txt"):setString(getFloatNumber(self.spirit.sharkSpiritAttributes[i].attributeGrowing))
		self.attributesSpirteTable[i + 1][5]:getChildByName("txt"):setString("+"..getFloatNumber(self.spirit.sharkSpiritAttributes[i].attributeGrowing) * levelUpNum)
		if self.spirit.sharkSpiritAttributes[i].max then
			self.attributesSpirteTable[i + 1][2]:setVisible(true)
		else
			self.attributesSpirteTable[i + 1][2]:setVisible(false)
		end
    local color = SpiritManager.getColorByRarity(self.spirit.sharkSpiritAttributes[i].attributeRare)
    self.attributesSpirteTable[i + 1][3]:getChildByName("txt"):setColor(color)
    self.attributesSpirteTable[i + 1][6]:getChildByName("txt"):setColor(color)
	end

	if levelUpNum == 0 then
		self.ui:getChildByName("txt_elesoul4_1"):setVisible(false)
		for i=1,1+#self.spirit.sharkSpiritAttributes do
			self.attributesSpirteTable[i][3]:setVisible(true)
			self.attributesSpirteTable[i][4]:setVisible(true)
			self.attributesSpirteTable[i][5]:setVisible(false)
		end
	else
		self.ui:getChildByName("txt_elesoul4_1"):setVisible(true)
		self.ui:getChildByName("txt_elesoul4_1"):getChildByName("txt"):setString(levelUpNum + self.spirit.level)
    if levelUpNum + self.spirit.level == #MetaManager.spirit_level then
      self.ui:getChildByName("lbl_max"):setVisible(true)
    else
      self.ui:getChildByName("lbl_max"):setVisible(false)
    end
		for i=1,1+#self.spirit.sharkSpiritAttributes do
			self.attributesSpirteTable[i][3]:setVisible(false)
			self.attributesSpirteTable[i][4]:setVisible(false)
			self.attributesSpirteTable[i][5]:setVisible(true)
		end
	end

  if SpiritManager.isExpSpirit(self.spirit) then
    self.attributesSpirteTable[1][4]:setVisible(false)
    self.attributesSpirteTable[1][3]:setVisible(false)
    self.attributesSpirteTable[1][5]:setVisible(false)
  end

end

function SpiritComposePanel:refreshProcessBar( composeExp )
	if (not self.expProcessBar ) then
	    self.expProcessBar = ProgressBar:create(self.ui:getChildByName("tab_blue"))
	end
	local expCur , expTotal = SpiritManager.getSpiritExp( self.spirit )
	local percent = expCur / expTotal

  	self.expProcessBar:setPercentage(percent * 100)

    self.ui:getChildByName("txt_elesoul_level"):getChildByName("txt"):setString(expCur.."/"..expTotal)

  	if (not self.expComposeProcessBar) then
  		self.expComposeProcessBar = ProgressBar:create(self.ui:getChildByName("tab_green"))
	end
	composeExp = composeExp or 0 
	local levelUpNum = SpiritManager.getLevelupNum(self.spirit ,composeExp )
	-- local isLevelUp = false
	local composedExp
	if levelUpNum ~= 0 then
		composedExp = expTotal
    self.ui:getChildByName("icon_arrow"):setVisible(true)
		-- isLevelUp = true
	else
		composedExp = expCur + composeExp
    self.ui:getChildByName("icon_arrow"):setVisible(false)
	end
	self:showSubAttributes(levelUpNum)
	local percent2 = composedExp / expTotal
	self.expComposeProcessBar:setPercentage(percent2 * 100)
end

function SpiritComposePanel:refreshUI( flag )
	if MetaManager.spirit_meta[self.spirit.metaId].mainAttributeType == 100 then
		-- self.ui:getChildByName("formation_btn_change_captain"):setVisible(false)
		self.ui:getChildByName("formation_btn_change_captain3"):setVisible(false)
		-- self.ui:getChildByName("formation_btn_change_captain1"):setVisible(false)
		self.ui:getChildByName("txt_elesoul8"):getChildByName("txt"):setString(getTextByKey("spirit_spiritInfo_expSpirit"))
		-- self.ui:getChildByName("other_combine"):setVisible(false)
		-- self.ui:getChildByName("other_combine"):setVisible(false)
		self.ui:getChildByName("other_combine"):setVisible(false)
		self.ui:getChildByName("other_combine1"):setVisible(false)
		self.ui:getChildByName("other_combine2"):setVisible(false)
    self.ui:getChildByName("checkBox_layer"):setVisible(false)
		self.ui:getChildByName("formation_btn_change_captain2"):setVisible(false)
    self.ui:getChildByName("txt_elesoul8_1"):setVisible(false)
    self.ui:getChildByName("formation_btn_change_captain3_1"):setVisible(false)
    self.ui:getChildByName("checkBox_layer2"):setVisible(false)
	else
		if #self.spirit.sharkSpiritAttributes ~= 2 then
			self.ui:getChildByName("other_combine"):setVisible(false)
			self.ui:getChildByName("other_combine1"):setVisible(false)
			self.ui:getChildByName("other_combine2"):setVisible(false)
      self.ui:getChildByName("checkBox_layer"):setVisible(false)
			-- self.ui:getChildByName("formation_btn_change_captain"):setVisible(false)
			self.ui:getChildByName("formation_btn_change_captain3"):setVisible(true)
      self.ui:getChildByName("formation_btn_change_captain3_1"):setVisible(false)
      self.ui:getChildByName("checkBox_layer2"):setVisible(false)
			local unLockStr = DataManager.GameMetaData.spiritSettingConfig.unlockPrice..getTextByKey("spirit_spiritUpgrade_unlockBtn")
			self.ui:getChildByName("formation_btn_change_captain3"):getChildByName("txt"):setString(unLockStr)
			-- self.ui:getChildByName("formation_btn_change_captain1"):setVisible(false)
			self.ui:getChildByName("formation_btn_change_captain2"):setVisible(false)
      self.ui:getChildByName("txt_elesoul8_1"):setVisible(true)
		else
      self.ui:getChildByName("txt_elesoul8_1"):setVisible(false)
      local lockedRefreshMultiplier = ((self.lockId == 0) and 1) or DataManager.GameMetaData.spiritSettingConfig.lockedRefreshMultiplier
      local refreshPropCost = SpiritManager.getSpiritRefreshPropmCost( self.spirit ) * lockedRefreshMultiplier
			if SpiritManager.isVipEnough() then
				self.ui:getChildByName("formation_btn_change_captain3"):setVisible(false)
				self.ui:getChildByName("formation_btn_change_captain2"):setVisible(false)
        self.ui:getChildByName("formation_btn_change_captain3_1"):setVisible(false)
				self.ui:getChildByName("checkBox_layer2"):setVisible(false)
				local combine
				if SpiritManager.getFreeRefreshTimes() > 0 and SpiritManager.getRefreshPropNum() >= refreshPropCost * 10 then
					self.ui:getChildByName("other_combine"):setVisible(false)
					self.ui:getChildByName("other_combine1"):setVisible(true)
					self.ui:getChildByName("other_combine2"):setVisible(false)
          self.ui:getChildByName("checkBox_layer"):setVisible(true)
					combine = self.ui:getChildByName("other_combine1")
					combine:getChildByName("formation_btn_change_captain1"):getChildByName("txt"):setString(getTextByKey("spirit_spiritUpgrade_freeRefreshBtn"))
					local freeTimes = Localization:getInstance():getText("spirit_spiritUpgrade_freeRefreshTxt" , {num = SpiritManager.getFreeRefreshTimes()})
					combine:getChildByName("txt_elesoul2"):getChildByName("txt"):setString(freeTimes)
					combine:getChildByName("formation_btn_change_captain2"):getChildByName("txt"):setString(getTextByKey("spirit_spiritUpgrade_refresh10Btn"))
					local usePropNum = Localization:getInstance():getText("spirit_spiritUpgrade_propRequired" , {num = refreshPropCost * 10})
					combine:getChildByName("txt_elesoul2_1"):getChildByName("txt"):setString(usePropNum)
					self.leftBtntype = RefreshType.FREE
					self.rightBtntype = RefreshType.TOOL_BATCH
				elseif SpiritManager.getFreeRefreshTimes() > 0 and SpiritManager.getRefreshPropNum() < refreshPropCost * 10 then
					self.ui:getChildByName("other_combine"):setVisible(true)
					self.ui:getChildByName("other_combine1"):setVisible(false)
					self.ui:getChildByName("other_combine2"):setVisible(false)
          self.ui:getChildByName("checkBox_layer"):setVisible(true)
					combine = self.ui:getChildByName("other_combine")
					local freeTimes = Localization:getInstance():getText("spirit_spiritUpgrade_freeRefreshTxt" , {num = SpiritManager.getFreeRefreshTimes()})
					combine:getChildByName("txt_elesoul2"):getChildByName("txt"):setString(freeTimes)
					combine:getChildByName("formation_btn_change_captain1"):getChildByName("txt"):setString(getTextByKey("spirit_spiritUpgrade_freeRefreshBtn"))
					local freeTimes = Localization:getInstance():getText("spirit_spiritUpgrade_freeRefreshTxt" , {num = SpiritManager.getFreeRefreshTimes()})
					local costGem = lockedRefreshMultiplier * SpiritManager.getSpiritRefreshGemCost( self.spirit ) * 10
					combine:getChildByName("formation_btn_change_captain2"):getChildByName("txt"):setString(costGem.." "..getTextByKey("spirit_spiritUpgrade_refresh10Btn"))
					self.leftBtntype = RefreshType.FREE
					self.rightBtntype = RefreshType.GEM_BATCH
				elseif SpiritManager.getFreeRefreshTimes() <=0 then
					if SpiritManager.getRefreshPropNum() < refreshPropCost then
						self.ui:getChildByName("other_combine"):setVisible(false)
						self.ui:getChildByName("other_combine1"):setVisible(false)
						self.ui:getChildByName("other_combine2"):setVisible(true)
            self.ui:getChildByName("checkBox_layer"):setVisible(true)
						combine = self.ui:getChildByName("other_combine2")
						-- local freeTimes = Localization:getInstance():getText("spirit_spiritUpgrade_freeRefreshTxt" , {num = SpiritManager.getFreeRefreshTimes()})
						-- combine:getChildByName("txt_elesoul2"):getChildByName("txt"):setString(freeTimes)
						local costGem = lockedRefreshMultiplier * SpiritManager.getSpiritRefreshGemCost( self.spirit )
						combine:getChildByName("formation_btn_change_captain1"):getChildByName("txt"):setString(costGem..getTextByKey("spirit_spiritUpgrade_refreshBtn"))
						combine:getChildByName("formation_btn_change_captain2"):getChildByName("txt"):setString((costGem*10).." "..getTextByKey("spirit_spiritUpgrade_refresh10Btn"))
						self.leftBtntype = RefreshType.GEM
						self.rightBtntype = RefreshType.GEM_BATCH
					elseif SpiritManager.getRefreshPropNum() >= refreshPropCost and SpiritManager.getRefreshPropNum() < refreshPropCost * 10 then
						self.ui:getChildByName("other_combine"):setVisible(true)
						self.ui:getChildByName("other_combine1"):setVisible(false)
						self.ui:getChildByName("other_combine2"):setVisible(false)
            self.ui:getChildByName("checkBox_layer"):setVisible(true)
						combine = self.ui:getChildByName("other_combine")
						combine:getChildByName("formation_btn_change_captain1"):getChildByName("txt"):setString(getTextByKey("spirit_spiritUpgrade_refreshBtn"))
						local propNeedNum = Localization:getInstance():getText("spirit_spiritUpgrade_propRequired" , {num = refreshPropCost })
						combine:getChildByName("txt_elesoul2"):getChildByName("txt"):setString(propNeedNum)
						local costGem = lockedRefreshMultiplier * SpiritManager.getSpiritRefreshGemCost( self.spirit )
						combine:getChildByName("formation_btn_change_captain2"):getChildByName("txt"):setString((costGem*10).." "..getTextByKey("spirit_spiritUpgrade_refresh10Btn"))
						self.leftBtntype = RefreshType.TOOL
						self.rightBtntype = RefreshType.GEM_BATCH
					elseif SpiritManager.getRefreshPropNum() >= refreshPropCost * 10 then
						self.ui:getChildByName("other_combine"):setVisible(false)
						self.ui:getChildByName("other_combine1"):setVisible(true)
						self.ui:getChildByName("other_combine2"):setVisible(false)
            self.ui:getChildByName("checkBox_layer"):setVisible(true)
						combine = self.ui:getChildByName("other_combine1")
						combine:getChildByName("formation_btn_change_captain1"):getChildByName("txt"):setString(getTextByKey("spirit_spiritUpgrade_refreshBtn"))
						combine:getChildByName("formation_btn_change_captain2"):getChildByName("txt"):setString(getTextByKey("spirit_spiritUpgrade_refresh10Btn"))
						local propNeedNum = Localization:getInstance():getText("spirit_spiritUpgrade_propRequired" , {num = refreshPropCost })
						combine:getChildByName("txt_elesoul2"):getChildByName("txt"):setString(propNeedNum)
						local propNeedNum2 = Localization:getInstance():getText("spirit_spiritUpgrade_propRequired" , {num = refreshPropCost * 10 })
						combine:getChildByName("txt_elesoul2_1"):getChildByName("txt"):setString(propNeedNum2)
						self.leftBtntype = RefreshType.TOOL
						self.rightBtntype = RefreshType.TOOL_BATCH
					end
				end
				combine:getChildByName("txt_elesoul3"):getChildByName("txt"):setString(getTextByKey("spirit_spiritUpgrade_propNum"))
				combine:getChildByName("txt_elesoul4"):getChildByName("txt"):setString(SpiritManager.getRefreshPropNum())
			else
				self.ui:getChildByName("other_combine"):setVisible(false)
				self.ui:getChildByName("other_combine1"):setVisible(false)
				self.ui:getChildByName("other_combine2"):setVisible(false)
        self.ui:getChildByName("checkBox_layer"):setVisible(false)
				-- self.ui:getChildByName("formation_btn_change_captain"):setVisible(false)
				self.ui:getChildByName("formation_btn_change_captain3"):setVisible(false)
				self.ui:getChildByName("formation_btn_change_captain2"):setVisible(true)
        self.ui:getChildByName("txt_elesoul3_2"):setVisible(false)
        self.ui:getChildByName("txt_elesoul4_2_2"):setVisible(false)
        self.ui:getChildByName("txt_elesoul3"):setVisible(true)
        self.ui:getChildByName("txt_elesoul4"):setVisible(true)
        self.ui:getChildByName("txt_elesoul2"):setVisible(true)
        local costGem = lockedRefreshMultiplier * SpiritManager.getSpiritRefreshGemCost( self.spirit )
				if SpiritManager.getFreeRefreshTimes() > 0 then
          self.ui:getChildByName("formation_btn_change_captain3_1"):setVisible(false)
          self.ui:getChildByName("checkBox_layer2"):setVisible(true)
          self.ui:getChildByName("formation_btn_change_captain2"):setVisible(true)
					self.ui:getChildByName("formation_btn_change_captain2"):getChildByName("txt"):setString(getTextByKey("spirit_spiritUpgrade_freeRefreshBtn"))
					local freeTimes = Localization:getInstance():getText("spirit_spiritUpgrade_freeRefreshTxt" , {num = SpiritManager.getFreeRefreshTimes()})
					self.ui:getChildByName("txt_elesoul2"):getChildByName("txt"):setString(freeTimes)
          self.leftBtntype = RefreshType.FREE
        elseif SpiritManager.getFreeRefreshTimes() <= 0 and SpiritManager.getRefreshPropNum() < refreshPropCost then
          self.ui:getChildByName("formation_btn_change_captain3_1"):setVisible(true)
          self.ui:getChildByName("checkBox_layer2"):setVisible(true)
          self.ui:getChildByName("formation_btn_change_captain2"):setVisible(false)
          self.leftBtntype = RefreshType.GEM
          local costGem = lockedRefreshMultiplier * SpiritManager.getSpiritRefreshGemCost( self.spirit )
          self.ui:getChildByName("formation_btn_change_captain3_1"):getChildByName("txt"):setString((costGem)..getTextByKey("spirit_spiritUpgrade_refreshBtn"))
          self.ui:getChildByName("txt_elesoul3_2"):setVisible(true)
          self.ui:getChildByName("txt_elesoul4_2_2"):setVisible(true)
          self.ui:getChildByName("txt_elesoul3"):setVisible(false)
          self.ui:getChildByName("txt_elesoul4"):setVisible(false)
          self.ui:getChildByName("txt_elesoul2"):setVisible(false)
				else
          self.ui:getChildByName("formation_btn_change_captain3_1"):setVisible(false)
          self.ui:getChildByName("checkBox_layer2"):setVisible(true)
          self.ui:getChildByName("formation_btn_change_captain2"):setVisible(true)
          self.leftBtntype = RefreshType.TOOL
          local propNeedNum = Localization:getInstance():getText("spirit_spiritUpgrade_propRequired" , {num = refreshPropCost })
          -- combine:getChildByName("txt_elesoul2"):getChildByName("txt"):setString(propNeedNum)
					-- local costGem = lockedRefreshMultiplier * DataManager.GameMetaData.spiritSettingConfig.unlockPrice
					self.ui:getChildByName("formation_btn_change_captain2"):getChildByName("txt"):setString(getTextByKey("spirit_spiritUpgrade_refreshBtn"))
					local freeTimes = Localization:getInstance():getText("spirit_spiritUpgrade_freeRefreshTxt" , {num = SpiritManager.getFreeRefreshTimes()})
					self.ui:getChildByName("txt_elesoul2"):getChildByName("txt"):setString(propNeedNum)
				end
				self.ui:getChildByName("txt_elesoul3"):getChildByName("txt"):setString(getTextByKey("spirit_spiritUpgrade_propNum"))
				self.ui:getChildByName("txt_elesoul4"):getChildByName("txt"):setString(SpiritManager.getRefreshPropNum())
        self.ui:getChildByName("txt_elesoul3_2"):getChildByName("txt"):setString(getTextByKey("spirit_spiritUpgrade_propNum"))
        self.ui:getChildByName("txt_elesoul4_2_2"):getChildByName("txt"):setString(SpiritManager.getRefreshPropNum())
				-- self.ui:getChildByName("formation_btn_change_captain2"):getChildByName("txt"):setString(getTextByKey("spirit_spiritUpgrade_refreshBtn"))
			end
		end
	end
  if not flag then
    self:showSubAttributes()
  end
end

function SpiritComposePanel:initLayer()
  SpiritComposePanel.super.initLayer(self)
  local unsaveSpirit = nil
  local gameInitData = DataManager.getGameInitData()
  if gameInitData.sharkSpirits.unsaveSpiritAttributes ~= nil and #gameInitData.sharkSpirits.unsaveSpiritAttributes ~= 0 then
    local spirit_data = DataManager.getSpiritsData()
    local aSpirit, spiritNo = CommonManager.getSubTableByKey(
      spirit_data , 
      {name = "spiritId", value = gameInitData.sharkSpirits.unsaveSpiritId})
    self.spirit = aSpirit
    unsaveSpirit = aSpirit
  end
  
  self.container:setTableViewsEnabled(false)
  -- 设置Layer
  local winSize = CCDirector:sharedDirector():getWinSize()
  self:setContentSize(CCSizeMake(winSize.width, winSize.height))
  
  -- 获取公告UI
  local builder = LayoutBuilder:createWithContentsOfFile("scene/elesoul.json")
  self.ui = builder:build("popup_elesoul")
  self:addChild(self.ui)

  -- 关闭Panel事件
  local function onClosePanel(evt)
    PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
    self.container:setTableViewsEnabled(true)
    -- self.container.targetInfoPanel = nil
  end

  -- 关闭按钮
  local closeButtonDisplay = self.ui:getChildByName("btn_close")
  local closeButton = Button:create(closeButtonDisplay)
  closeButton:addEventListener(Events.kStart, onClosePanel, self)

  local spirtName = SpiritManager.getSpiritName( self.spirit )
  self.ui:getChildByName("txt_elesoul1"):getChildByName("txt"):setString(spirtName)
  
  self.ui:getChildByName("normal_card_small"):setVisible(false)
  self.ui:getChildByName("reward_item"):setVisible(false)

  local params = {}
  params.sourceDisplay = self.ui:getChildByName("normal_card_small")
  -- params.showInCenter = true
  local headCard = CanonGoodIcon.createGoodIcon(ResourceEnum.SPIRIT, self.spirit.metaId, 1, params)
  -- local headCard = getHeadIconCanonCardByMetaId(101011)
  -- headCard:setPosition(ccp(picPosX, picPosY))
  self.ui:addChild(headCard, self.ui:getChildByName("normal_card_small"):getZOrder())

  local function onLock1( e )
    if self.lockId == 1 then
      self.lockId = 0
      self.ui:getChildByName("icon_lock_combine2"):getChildByName("icon_unlock"):setVisible(true)
      self.ui:getChildByName("icon_lock_combine2"):getChildByName("icon_lock"):setVisible(false)
  elseif self.lockId == 2 then
    SuspensionLabel:showContent(self, getTextByKey("spirit_spiritUpgrade_canNotLockTxt"))
    return
  elseif self.lockId == 0 then
    self.lockId = 1
    self.ui:getChildByName("icon_lock_combine2"):getChildByName("icon_unlock"):setVisible(false)
      self.ui:getChildByName("icon_lock_combine2"):getChildByName("icon_lock"):setVisible(true)
    end
    self:refreshUI(true)
  end
  local function onLock2( e )
    if self.lockId == 2 then
      self.lockId = 0
      self.ui:getChildByName("icon_lock_combine3"):getChildByName("icon_unlock"):setVisible(true)
      self.ui:getChildByName("icon_lock_combine3"):getChildByName("icon_lock"):setVisible(false)
  elseif self.lockId == 1 then
    SuspensionLabel:showContent(self, getTextByKey("spirit_spiritUpgrade_canNotLockTxt"))
    return
  elseif self.lockId == 0 then
    self.lockId = 2
    self.ui:getChildByName("icon_lock_combine3"):getChildByName("icon_unlock"):setVisible(false)
      self.ui:getChildByName("icon_lock_combine3"):getChildByName("icon_lock"):setVisible(true)
    end
    self:refreshUI(true)
  end
  self.ui:getChildByName("icon_lock_combine2"):getChildByName("icon_lock"):setVisible(false)
  self.lockButton1 = Button:create(self.ui:getChildByName("icon_lock_combine2"))
  self.lockButton1:addEventListener(Events.kStart, onLock1)
  self.ui:getChildByName("icon_lock_combine3"):getChildByName("icon_lock"):setVisible(false)
  self.lockButton2 = Button:create(self.ui:getChildByName("icon_lock_combine3"))
  self.lockButton2:addEventListener(Events.kStart, onLock2)


  if self.spirit.lockAttributeIndex ~= 0 then
    self.lockId = self.spirit.lockAttributeIndex
    if self.spirit.lockAttributeIndex == 1 then
      self.ui:getChildByName("icon_lock_combine2"):getChildByName("icon_unlock"):setVisible(false)
      self.ui:getChildByName("icon_lock_combine2"):getChildByName("icon_lock"):setVisible(true)
    elseif self.spirit.lockAttributeIndex == 2 then
      self.ui:getChildByName("icon_lock_combine3"):getChildByName("icon_unlock"):setVisible(false)
      self.ui:getChildByName("icon_lock_combine3"):getChildByName("icon_lock"):setVisible(true)
    end
  end

  local function onUnlock( e )
    local function onUnlockSuccessedResponse( e )
      table.insert(self.spirit.sharkSpiritAttributes , e.data.sharkSpiritAttribute)
      local spiritData = DataManager.getSpiritsData()
      for k,v in pairs(spiritData) do
        if v.spiritId == self.spirit.spiritId then
          spiritData[k] = self.spirit
        end
      end
      DataManager.setSpiritsData(spiritData)
      RewardManager:gainReward({itemType = ResourceEnum.GEMS, amount = -DataManager.GameMetaData.spiritSettingConfig.unlockPrice})
        
      --显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
      DataManager.fightCapacityMaybeUpdated()
      
      self:refreshAllUI(true)
    end

    local function onUnlockFailedResponse( e )
      CanonMessageBox:showCommUnHandleErrorBox(e.data)
    end

    if CalculationManager.calcComplex_getGemsNow() < DataManager.GameMetaData.spiritSettingConfig.unlockPrice then
      local function onReplaceScene()
          self.container:setTableViewsEnabled(true)
          -- self.container.targetInfoPanel = nil
        end
        self:setTableViewsEnabled(false)
        local aPanel = AssistantMessageBoxPanel:create( self.container, AsMessageBoxType.addCoin , nil, {onReplaceSceneFunc = onReplaceScene , brotherLayer = self})
        self.container:addChild(aPanel)
        aPanel:scaleIn()
        return
    end
    g_previousBattleCount = CommonManager:getLocalPlayerStrength()
    local params = {spiritId = self.spirit.spiritId}
    UnlockSubAttributeRequest.sendRequest(params , onUnlockSuccessedResponse ,onUnlockFailedResponse)
  end
  local unLockBtn = Button:create(self.ui:getChildByName("formation_btn_change_captain3"))
  unLockBtn:addEventListener(Events.kStart, onUnlock)

  self.ui:getChildByName("lbl_max"):setVisible(false)
  self.ui:getChildByName("icon_arrow"):setVisible(false)
  self.ui:getChildByName("txt_elesoul8_1"):getChildByName("txt"):setString(getTextByKey("spirit_spiritUpgrade_unlockTips"))

  for i=1,3 do
    self.attributesSpirteTable[i] = {
    [1] = self.ui:getChildByName("icon_lock_combine"..i),
    [2] = self.ui:getChildByName("icon_chp"..i),
    
    [3] = self.ui:getChildByName("txt_elesoul7_"..i - 1 ),
    [4] = self.ui:getChildByName("txt_elesoul6_"..i - 1 ),
    [5] = self.ui:getChildByName("txt_elesoul4_"..i + 1 ),
    [6] = self.ui:getChildByName("txt_elesoul5_"..i - 1 ),
    [7] = self.ui:getChildByName("q_pink_white9_panel_"..i),
  }
  end
  for i=1,3 do
    self.ui:getChildByName("txt_elesoul6_"..i-1):getChildByName("txt"):setString(getTextByKey("spirit_spiritInfo_growth"))
  end

  self.allValues = SpiritManager.getAllAttributesValue( self.spirit )
  for i=1,2 do
    self.attributesSpirteTable[1][i]:setVisible(false)
  end
  for i=1,2 do
    self.attributesSpirteTable[i + 1][1]:setVisible(false)
  end
  local mainName = SpiritManager.getMainAttributeName( self.spirit )
  self.attributesSpirteTable[1][6]:getChildByName("txt"):setString(mainName.."+"..self.allValues[1])
  self.attributesSpirteTable[1][3]:getChildByName("txt"):setString(SpiritManager.getMainAttributeGrow( self.spirit ))
  self.ui:getChildByName("formation_txt_lv_num"):getChildByName("font"):setString(self.spirit.level)

  local color = SpiritManager.getColorByRarity(SpiritManager.getSpiritRare( self.spirit  ))
  self.attributesSpirteTable[1][6]:getChildByName("txt"):setColor(color)
  self.attributesSpirteTable[1][3]:getChildByName("txt"):setColor(color)

  self:refreshUI()

  local allComposeEnabledSpirit = SpiritManager.getComposeEnabledSpirits(self.spirit)
  self.tableView = self:createTableView(allComposeEnabledSpirit)
  self.ui:addChild(self.tableView)

  self.selectSpiritsTable = {}
  for i=1,#allComposeEnabledSpirit do
    self.selectSpiritsTable[i] = nil
  end

  self:refreshProcessBar()

  if unsaveSpirit ~= nil then
    if #gameInitData.sharkSpirits.unsaveSpiritAttributes == 10 then
      local unsaveSpiritAttributes = table.clone(gameInitData.sharkSpirits.unsaveSpiritAttributes, true)
      self:addWillChangeAttribute(unsaveSpiritAttributes)
      local targetInfoPanel = SpiritBatchRefreshResultPanel:create( self , unsaveSpiritAttributes)
      PopoutManager:sharedManager():popout(targetInfoPanel, kPopoutDir.kScale, true, false ,self)
    else
      local unsaveSpiritAttributes = table.clone(gameInitData.sharkSpirits.unsaveSpiritAttributes, true)
      self:addWillChangeAttribute(unsaveSpiritAttributes)

      local targetInfoPanel = SpiritBatchRefreshSingleResultPanel:create( self , unsaveSpiritAttributes)
      PopoutManager:sharedManager():popout(targetInfoPanel, kPopoutDir.kScale, false, false ,self)
    end
  end

  local function onCompose( e )
      if SpiritManager.isSpiritFullLevel( self.spirit ) then
        SuspensionLabel:showContent(self, getTextByKey("spirit_lvMax_tips"))
        return
      end
      local slaveIds = {}
      local maxRarty = 0
      local selectNum = 0
      for k,v in pairs(self.selectSpiritsTable) do
        if v ~= nil then
          selectNum = selectNum + 1
          local rare = SpiritManager.getSpiritRare( v )
          if rare > maxRarty then
            maxRarty = rare
          end
          table.insert(slaveIds , v.spiritId)
        end
      end
      local mainRare = SpiritManager.getSpiritRare( self.spirit )
      if mainRare < maxRarty then
        SuspensionLabel:showContent(self, getTextByKey("spirit_highRarity_tips"))
        do return end
      end

      if selectNum == 0 then
        SuspensionLabel:showContent(self, getTextByKey("spirit_spiritUpgrade_noSelected"))
        do return end
      end

      if maxRarty > 3 then
        local aPanel = MessageBoxPanel:create(self, MessageBoxType.kEnsureEatHighRareSpiritWarning)
          self:addChild(aPanel)
          aPanel:scaleIn()
      else
        self:conformEatHighRareSpirit(true)
      end

  end
  local composeBtn = Button:create(self.ui:getChildByName("formation_btn_change_captain4"))
  composeBtn:addEventListener(Events.kStart, onCompose)
  self.ui:getChildByName("formation_btn_change_captain4"):getChildByName("txt"):setString(getTextByKey("spirit_spiritInfo_upgradeBtn"))

  local function onBatchSelect( evt )
    if SpiritManager.isSpiritFullLevel( self.spirit ) then
      SuspensionLabel:showContent(self, getTextByKey("spirit_lvMax_tips"))
      return
    end
    local targetInfoPanel = BatchSelectSpiritPanel:create( self )
    PopoutManager:sharedManager():popout(targetInfoPanel, kPopoutDir.kScale, true, false ,self)
  end
  local batchSelectBtn = Button:create(self.ui:getChildByName("formation_btn_change_captain4_1"))
  batchSelectBtn:addEventListener(Events.kStart, onBatchSelect)
  self.ui:getChildByName("formation_btn_change_captain4_1"):getChildByName("txt"):setString(getTextByKey("spirit_spiritUpgrade_batchBtn"))

  local function onGotoKingTemple( evt )
    self.container:replaceScene( KingTempleScene )
  end
  local gotoKingTempleBtn = Button:create(self.ui:getChildByName("formation_btn_change_captain4_2"))
  gotoKingTempleBtn:addEventListener(Events.kStart, onGotoKingTemple)
  self.ui:getChildByName("formation_btn_change_captain4_2"):getChildByName("txt"):setString(getTextByKey("spirit_unload_txt1"))
  
  local destinyInfo = DataManager.getGameInitData().sharkDestinyInfo
  if destinyInfo and destinyInfo.spiritConcentrateLevel > 0 then
    gotoKingTempleBtn:setEnable(true)
    gotoKingTempleBtn.display:getChildByName("normal"):setVisible(true)
  else
    gotoKingTempleBtn:setEnable(false)
    gotoKingTempleBtn.display:getChildByName("normal"):setVisible(false)
  end

  local function checkSubAttrIsMax()
    local isMax = false

    if self.lockId == 1 then
      if self.spirit.sharkSpiritAttributes[2].max then
        isMax = true
      end
    elseif self.lockId == 2 then
      if self.spirit.sharkSpiritAttributes[1].max then
        isMax = true
      end
    else
      for i=1,2 do
        if self.spirit.sharkSpiritAttributes[i].max then
          isMax = true
        end
      end
    end

    return isMax
  end

  local function refreshLeftButtonCallback( e )
    if checkSubAttrIsMax() then
      local aPanel = MessageBoxPanel:create(self, MessageBoxType.kSpiritSubAttrIsMaxWarning , {btnType = 1})
        self:addChild(aPanel)
        aPanel:scaleIn()
      return
    end
    self:LeftBtnRefreshConform()
  end

  local function refreshRightButtonCallback( e )
    if checkSubAttrIsMax() then
      local aPanel = MessageBoxPanel:create(self, MessageBoxType.kSpiritSubAttrIsMaxWarning , {btnType = 2})
        self:addChild(aPanel)
        aPanel:scaleIn()
      return
    end
    self:RightBtnRefreshConform()
  end

  
    local freshBtn = Button:create(self.ui:getChildByName("other_combine"):getChildByName("formation_btn_change_captain1"))
    freshBtn:addEventListener(Events.kStart, refreshLeftButtonCallback)
    local freshBtn1 = Button:create(self.ui:getChildByName("other_combine1"):getChildByName("formation_btn_change_captain1"))
    freshBtn1:addEventListener(Events.kStart, refreshLeftButtonCallback)
    local freshBtn2 = Button:create(self.ui:getChildByName("other_combine2"):getChildByName("formation_btn_change_captain1"))
    freshBtn2:addEventListener(Events.kStart, refreshLeftButtonCallback)
  
    local freshRightBtn = Button:create(self.ui:getChildByName("other_combine"):getChildByName("formation_btn_change_captain2"))
    freshRightBtn:addEventListener(Events.kStart, refreshRightButtonCallback)
    local freshRightBtn2 = Button:create(self.ui:getChildByName("other_combine1"):getChildByName("formation_btn_change_captain2"))
    freshRightBtn2:addEventListener(Events.kStart, refreshRightButtonCallback)
    local freshRightBtn3 = Button:create(self.ui:getChildByName("other_combine2"):getChildByName("formation_btn_change_captain2"))
    freshRightBtn3:addEventListener(Events.kStart, refreshRightButtonCallback)

    local notVipRefreshBtn = Button:create(self.ui:getChildByName("formation_btn_change_captain2"))
    notVipRefreshBtn:addEventListener(Events.kStart, refreshLeftButtonCallback)

    local notVipRefreshBtn2 = Button:create(self.ui:getChildByName("formation_btn_change_captain3_1"))
    notVipRefreshBtn2:addEventListener(Events.kStart, refreshLeftButtonCallback)

    local checkBox_layer = self.ui:getChildByName("checkBox_layer")
    checkBox_layer:getChildByName("txt_01"):getChildByName("txt"):setString(getTextByKey("spirit_unload_txt2"))
    self.checkBox = checkBox_layer:getChildByName("icon_m_check1"):getChildByName("btn_selected_all")

    local function onCheckBoxBtn(evt)
      local function onSpiritRefreshSucceed(evt)
        local newValue = self:getCheckBoxStatus()
        newValue = not newValue

        local gameInitData = DataManager.getGameInitData()
        gameInitData.sharkSpirits.autoSaveRefresh = newValue
        DataManager.setGameInitData(gameInitData)

        self:setCheckBoxStatus(newValue)
      end

      local function onSpiritRefreshFailed(evt)
        CanonMessageBox:showCommUnHandleErrorBox( evt.data )
      end

      local sendValue = self:getCheckBoxStatus()
      local request = SetSpiritRefreshAutoSaveRequest.new({autoSave = not sendValue}, rpc.SendingPriority.kHigh)
      request:addEventListener(RequestNotifyEnum.SetSpiritRefreshAutoSaveSucceed, onSpiritRefreshSucceed)
      request:addEventListener(RequestNotifyEnum.SetSpiritRefreshAutoSaveFailed, onSpiritRefreshFailed)
      request:start()
    end

    local checkBoxBtn = Button:create(checkBox_layer:getChildByName("icon_m_check1"))
    checkBoxBtn:addEventListener(Events.kStart, onCheckBoxBtn)

    local checkBox_layer2 = self.ui:getChildByName("checkBox_layer2")
    checkBox_layer2:getChildByName("txt_01"):getChildByName("txt"):setString(getTextByKey("spirit_unload_txt2"))
    self.checkBox2 = checkBox_layer2:getChildByName("icon_m_check1"):getChildByName("btn_selected_all")
    local checkBoxBtn2 = Button:create(checkBox_layer2:getChildByName("icon_m_check1"))
    checkBoxBtn2:addEventListener(Events.kStart, onCheckBoxBtn)

    self.checkBoxStatus = nil
    local gameInitData = DataManager.getGameInitData()
    self:setCheckBoxStatus(gameInitData.sharkSpirits.autoSaveRefresh)
end

local CELL_HEIGHT = 200
local CELL_WIDTH = 685.2
local LIST_HEIGHT = 355
local LIST_WIDTH = 660
local LIST_POS_Y = 1070
local COLS_NUM = 4

----------------------------------
-- TAG常量
----------------------------------
local TABLEVIEW_CELL_TAG = -1000
local TAG_PIC_REWARD = 100
local TAG_REWARD_NAME = 101
local TAG_REWARD_NUM = 102
local TAG_NORMAL_CARD_SMALL = 103
local TAG_PIC_REWARD_BG = 104	    
local TAG_FRAME_CARD = 105
local TAG_GREY_LAYER = 106
local TAG_START = 1000

local TAG_NORMAL_ICON_ALL = 10000
local TAG_TXT_NAME = 1002
local TAG_NORMAL_ICON = 1003
local TAG_SELECTED = 1004

function SpiritComposePanel:createTableView(data)
  local SpiritCellRenderer = class(TableViewRenderer)
  
  -- 构造函数中计算cell个数
  function SpiritCellRenderer:ctor(width, height)
		local rows = 0
    if #data % COLS_NUM == 0 then
      rows = #data / COLS_NUM
    else
      rows = #data / COLS_NUM + 1
    end
    for i = 1, rows do
      self.list[i] = i
    end
    if rows == 0 then
      self.list = {}
    end
	end
  
  -- 构建Cell
  function SpiritCellRenderer:buildCell(container)
    for cols = 1, COLS_NUM do
      local builder = LayoutBuilder:createWithContentsOfFile("scene/elesoul.json")
      local layer = builder:build("sb/reward_item")
      layer:getChildByName("normal_card_small"):setTag(TAG_NORMAL_CARD_SMALL)
      -- layer:getChildByName("bg_card"):setTag(TAG_PIC_REWARD_BG)
      layer:getChildByName("txt_item_name"):setTag(TAG_REWARD_NAME)
      -- layer:getChildByName("txt_item_quantity"):setTag(TAG_REWARD_NUM)
      layer:getChildByName("txt_item_name"):getChildByName("txt_item_name"):setTag(TAG_REWARD_NAME)
      -- layer:getChildByName("txt_item_quantity"):getChildByName("txt_item_quantity"):setTag(TAG_REWARD_NUM)
      -- layer:getChildByName("frame_card"):setTag(TAG_FRAME_CARD)
      layer:getChildByName("icon_selected"):setTag(TAG_SELECTED)
      layer:getChildByName("icon_selected"):setZOrder(1001)
      layer:getChildByName("icon_selected"):setVisible(false)
      local width = 614
      local layerPosX = cols * (width / COLS_NUM) - (width / (COLS_NUM * 2))
      layer:setPosition(ccp(layerPosX, self.height * 0.9 - 65)) 
      -- layer:setVisible(false)
      layer:getChildByName("normal_card_small"):setVisible(false)
      container:addChild(layer)
      -- local greyLayer = getGreyLayer()
      -- greyLayer:setTag(TAG_GREY_LAYER)
      -- layer:addChildAt(greyLayer , 10000)
      layer:setTag(TAG_START + cols)
    end
  end
  
  -- 设置数据
  function SpiritCellRenderer:setData(rawCocosObj, index)
    for cols = 1, COLS_NUM do 
      local cellLayer = self:getChildByTag(rawCocosObj, TAG_START + cols)
		  cellLayer:setVisible(false)
			
      local rewardId = index * COLS_NUM + cols
			if rewardId <= #data then
        -- 根据Tag设置文本
        local function setTextByTag(tag, str)
          local txt = cellLayer:getChildByTag(tag):getChildByTag(tag)
          ViewControlUtil.setLableText(txt, str)
		    end
        
        -- 根据Tag设置是否可见
		    local function setNodeVisibleByTag(tag, visible)
			    cellLayer:getChildByTag(tag):setVisible(visible)
		    end
			    
        -- 获取UI信息
        local picPosX, picPosY = cellLayer:getChildByTag(TAG_NORMAL_CARD_SMALL):getPosition()
		    -- local picZOrder = cellLayer:getChildByTag(TAG_PIC_REWARD_BG):getZOrder()
			  cellLayer:setVisible(true)
        cellLayer:removeChildByTag(TAG_PIC_REWARD, true)
		        
        -- 获取奖励信息
			  local spiritInfo = data[rewardId]

          local params = {}
          params.sourceDisplay = cellLayer:getChildByTag(TAG_NORMAL_CARD_SMALL)
          -- params.showInCenter = true
          local headCard = CanonGoodIcon.createGoodIcon(ResourceEnum.SPIRIT, spiritInfo.metaId, 1, params)
          -- local headCard = getHeadIconCanonCardByMetaId(101011)
          -- headCard:setPosition(ccp(picPosX, picPosY))
          headCard:setTag(TAG_PIC_REWARD)
          local item_lv_bg = Sprite:createWithSpriteFrameName("item_lv_bg.png")
            item_lv_bg:setPosition(ccp(28, 53))
            card_lv = TextField:create("lv" .. spiritInfo.level,"Arial", 20)
            card_lv:setPosition(ccp(42, 10))
            item_lv_bg:addChild(card_lv)
            headCard:addChild(item_lv_bg)
          cellLayer:addChild(headCard.refCocosObj, 1000)
          headCard:dispose()

            rewardName = SpiritManager.getSpiritName( spiritInfo )

        setTextByTag(TAG_REWARD_NAME, rewardName)

        setNodeVisibleByTag(TAG_SELECTED , false)
        if SELF.selectSpiritsTable and SELF.selectSpiritsTable[index * COLS_NUM + cols] then
          setNodeVisibleByTag(TAG_SELECTED , true)
        else
          setNodeVisibleByTag(TAG_SELECTED , false)
        end
			end
		end
  end

  	local function onListItemTouch( evt ) 
  		for cols = 1,COLS_NUM do
			local selectedCell = self.tableView:cellAtIndex(evt.data):getChildByTag(TAG_START + cols)

			local posInCell = selectedCell:convertToNodeSpace(evt.globalPosition)
			--这里因为每个cell的pos有153.5的偏移，所以我又给加回去了
			posInCell.x = posInCell.x + (cols - 1) * 153.5
		
			local icon = selectedCell:getChildByTag(TAG_NORMAL_CARD_SMALL)
			local itemPosX, itemPosY = icon:getPosition()
			itemPosX = itemPosX + (cols - 1) * 153.5

			local posInCell2 = selectedCell:convertToNodeSpace(ccp(itemPosX , itemPosY))
			local itemRect = {}
			itemRect.x = itemPosX - 65
			itemRect.y = itemPosY - 65
			itemRect.width = 130
			itemRect.height = 130
			local function inArea(posX, posY, rect)
			    if posX >= rect.x and posX <= rect.x + rect.width and posY >= rect.y and posY <= rect.y + rect.height then
			      return true
			    end
			    return false
			  end 

			if inArea(posInCell.x, posInCell.y, itemRect) then
				if evt.data * COLS_NUM + cols > #data then
					return 
				end

        if SpiritManager.isSpiritFullLevel( self.spirit ) then
          SuspensionLabel:showContent(self, getTextByKey("spirit_lvMax_tips"))
          return
        end

        local selectRare = SpiritManager.getSpiritRare( data[evt.data * COLS_NUM + cols] )
        local mainRare = SpiritManager.getSpiritRare( self.spirit )
        if mainRare < selectRare then
          SuspensionLabel:showContent(self, getTextByKey("spirit_highRarity_tips"))
          do return end
        end
				
				local vi = selectedCell:getChildByTag(TAG_SELECTED):isVisible()
				if vi then
					self.selectSpiritsTable[evt.data * COLS_NUM + cols] = nil
				else
					self.selectSpiritsTable[evt.data * COLS_NUM + cols] = data[evt.data * COLS_NUM + cols]
				end
				selectedCell:getChildByTag(TAG_SELECTED):setVisible(not vi)
				local totalExp = 0
				for k,v in pairs(self.selectSpiritsTable) do
					if v ~= nil then
						totalExp = totalExp + SpiritManager.getSpiritContainedExp( v )
					end
				end
				self:refreshProcessBar(totalExp)
			do return end
			end
		end
	end
  
  -- 生成TableView
  local renderer = SpiritCellRenderer.new(CELL_WIDTH, CELL_HEIGHT)
  local tableView = TableView:create(renderer, 617.6, 320)
  tableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch)
  tableView:setPosition(ccp(50, 285))
  return tableView
end

function SpiritComposePanel:setTableViewsEnabled( v )
	self.tableView:setTouchEnabled(v)
end

function SpiritComposePanel:batchSelectSpirits(selectIds)
  local allComposeEnabledSpirit = SpiritManager.getComposeEnabledSpirits(self.spirit)
  self.selectSpiritsTable = {}
  for i=1,#allComposeEnabledSpirit do
    self.selectSpiritsTable[i] = nil
  end

  for k,v in pairs(selectIds) do
    if v == true then
      for i=1,#allComposeEnabledSpirit do
        if SpiritManager.getSpiritRare( allComposeEnabledSpirit[i] ) == k then
          self.selectSpiritsTable[i] = allComposeEnabledSpirit[i]
        end
      end
    end
  end
  self.tableView:reloadData()
  local totalExp = 0
  for k,v in pairs(self.selectSpiritsTable) do
    if v ~= nil then
      totalExp = totalExp + SpiritManager.getSpiritContainedExp( v )
    end
  end
  self:refreshProcessBar(totalExp)
end

function SpiritComposePanel:setCheckBoxStatus(bool)
  self.checkBoxStatus = bool
  self.checkBox:setVisible(bool)
  self.checkBox2:setVisible(bool)
end

function SpiritComposePanel:getCheckBoxStatus()
  return self.checkBoxStatus
end