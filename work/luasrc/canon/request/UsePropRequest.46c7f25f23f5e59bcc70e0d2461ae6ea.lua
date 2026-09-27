require "canon.request.BaseRequest"
require "canon.request.CommParamConstants"
require "canon.request.CommMethodConstants"
require "canon.models.RewardManager"
require "canon.manager.BagCalcManager"
require "canon.panel.VipWarningPanel"
require "canon.scene.BeastScene"
require "canon.request.GetBonusAccepterListRequest"
require "canon.scene.RedPacketDispatchScene"

UsePropRequest = class(BaseRequest)

local gotoShopCallback = nil

function UsePropRequest:ctor(params)
	self.params = params
  self.endpoint = METHOD_USEPROP
end

function UsePropRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UsePropSucceed, data))
end

function UsePropRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UsePropFailed, error))
end

--?????????
function onGotoShop()
	Director:mgr():run():replaceScene(ShopScene, {enterScene="BackpackSceneItem",returnScene="BackpackSceneItem", params = {tabIndex = TABLEVIEW_TAB_INDEX.GOLD_SHOP}})
	if gotoShopCallback then
		gotoShopCallback()
	end
end

function requestUsePropRequest(selectData, datalist, usePropResponse, usePropFailed, container, openNum, aGotoShopCallback)
	gotoShopCallback = aGotoShopCallback
	if not openNum then
		openNum = 1
	end

	if MetaManager.prop_meta[selectData.metaId].requireVipLevel > tonumber(DataManager.getCurrUser().vipLevel) then
		container.targetInfoPanel = VipWarningPanel:create( container, MetaManager.prop_meta[selectData.metaId].requireVipLevel)
		PopoutManager:sharedManager():popout(container.targetInfoPanel, kPopoutDir.kScale, true, false ,container) 
		do return end
	end
	
	local function onConfirmClick(e)
	end
						
	local function findRelationData()
		if not selectData.relationData then
			for k,v in pairs(datalist)
			do
				if v.metaId == selectData.relation then
					selectData.relationData = datalist[k]
					break;
				end
			end
		end
	end
						
	local itemType = MetaManager.prop_meta[selectData.metaId].effectType
	if tonumber(itemType) == Prop_Effect_Type.ENERGY then
		local energy,_,_,_,maxEnergy = CalculationManager.calcComplex_getEnergyNow()
		if tonumber(energy) >= tonumber(maxEnergy) then
			CanonMessageBox:Show( getTextByKey("propInfo_energyFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, onConfirmClick )
			do return end
		end
	elseif tonumber(itemType) == Prop_Effect_Type.PEACECARD then
		if DataManager.getCurrUser().level < MetaManager.game_meta.gameSettingConfig.beastConfig.beastUnlockLevel then
			SuspensionLabel:showContent(Director:sharedDirector():getRunningScene(), Localization:getInstance():getText("module_needLevel", {num = MetaManager.game_meta.gameSettingConfig.beastConfig.beastUnlockLevel}))
			do return end
		end
		local function doPrerationSucceed(fragmentsInfo)
			local argv = {enterScene="BackpackScene",returnScene="BackpackScene",params={fragmentsInfo=fragmentsInfo}}
			container:replaceScene(BeastScene, argv)
		end
				
		local function doPrerationFailed()
		end
				
		BeastScene.doPreparationBeforeReplaceToBeastScene(doPrerationSucceed, doPrerationFailed)
		do return end
	elseif tonumber(itemType) == Prop_Effect_Type.EP then
		local ep,_,_,_,maxEP = CalculationManager.calcComplex_getEPNow()
		if tonumber(ep) >= tonumber(maxEP) then
			CanonMessageBox:Show( getTextByKey("propInfo_eventPointFull"), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, onConfirmClick )
			do return end
		end
	elseif tonumber(itemType) == Prop_Effect_Type.BOX then
		if not selectData.relation then
			for k,v in pairs(MetaManager.prop_relation)
			do
				if tonumber(v.id) == tonumber(selectData.metaId) then
					selectData.relation = tonumber(v.relatedPropId)
					break;
				end
			end
		end
		findRelationData()
		if not selectData.relationData or tonumber(selectData.relationData.amount) <= 0 then
			local itemMeta = MetaManager.prop_meta[selectData.metaId]
			local relationItemMeta = MetaManager.prop_meta[selectData.relation]
			--local showMessage = Localization:getInstance():getText("propInfo_openChest_noKey", {propname1 = getTextByKey(relationItemMeta.name), propname2 = getTextByKey(itemMeta.name)})
			--CanonMessageBox:Show(showMessage, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, onConfirmClick )

			local showMessage = Localization:getInstance():getText("propInfo_openChest_noKey", {propname1 = getTextByKey(relationItemMeta.name), propname2 = getTextByKey(itemMeta.name)})
			local leftBtnInfo = {}
			local rightBtnInfo = {text = Localization:getInstance():getText("gemCard_by"), callbackFunc=onGotoShop}
			CanonMessageBox.showText(ShowButtonType.ID_OK_CANCEL, showMessage, leftBtnInfo, nil, rightBtnInfo)
			do return end
		end
	elseif tonumber(itemType) == Prop_Effect_Type.KEY then
		if not selectData.relation then
			for k,v in pairs(MetaManager.prop_relation)
			do
				if tonumber(v.relatedPropId) == tonumber(selectData.metaId) then
					selectData.relation = tonumber(v.id)
					break;
				end
			end
		end
		findRelationData()
		if not selectData.relationData or  tonumber(selectData.relationData.amount) <= 0 then
			local relationItemMeta = MetaManager.prop_meta[selectData.relation]
			--CanonMessageBox:Show( Localization:getInstance():getText("propInfo_openChest_noChest", {propname = getTextByKey(relationItemMeta.name)}), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, onConfirmClick )

			local showMessage = Localization:getInstance():getText("propInfo_openChest_noChest", {propname = getTextByKey(relationItemMeta.name)})
			local leftBtnInfo = {}
			local rightBtnInfo = {text = Localization:getInstance():getText("gemCard_by"), callbackFunc=onGotoShop}
			CanonMessageBox.showText(ShowButtonType.ID_OK_CANCEL, showMessage, leftBtnInfo, nil, rightBtnInfo)
			do return end
		end
	elseif tonumber(itemType) == Prop_Effect_Type.RED_PACKET then
		local function succeedCallback(e)
			print(table.tostring(e))
			if (#e.data.friendList + #e.data.unionList) == 0 then
				SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("redBag001"))
				return
			end

			local params = {listData = e.data , bonusId = MetaManager.prop_meta[selectData.metaId].id}
			-- local s = RedPacketDispatchScene:create(params)
			Director:mgr():run():replaceScene(RedPacketDispatchScene, {enterScene="BackpackSceneItem",returnScene="BackpackSceneItem", params = params})
		end
		local function failedCallback(e)
			
		end
		GetBonusAccepterListRequest.sendRequest({bonusId = MetaManager.prop_meta[selectData.metaId].id} , succeedCallback, failedCallback)
		return
	end
	
	if PropConfig_isCanUseProp(itemType) then
	--if tonumber(itemType) == Prop_Effect_Type.KEY or tonumber(itemType) == Prop_Effect_Type.BOX or tonumber(itemType) == Prop_Effect_Type.TREASUREBOX or tonumber(itemType) == Prop_Effect_Type.VIPBOX then
		local usedSpace = BagCalcManager.calcUsedGridNum()
		local totalSpace = BagCalcManager.calcTotalGridNum()
		if tonumber(usedSpace) >= tonumber(totalSpace) then
			local text = getTextByKey("arena_inventoryFull")
			-- CanonMessageBox:Show( text, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, onConfirmClick )
			NewPackageFullPanel:show()
			do return end
		end
		if SpiritManager.isSpiritPoolFull() then
			SpiritPackageFullPanel:show()
			return
		end
	end
											
	
	
	--print("????! ?? = " .. table.tostring({propId = selectData.metaId, amount = openNum}))
	local request = UsePropRequest.new( {propId = selectData.metaId, amount = openNum}, rpc.SendingPriority.kHigh )
	request:addEventListener( RequestNotifyEnum.UsePropSucceed, usePropResponse )
	request:addEventListener( RequestNotifyEnum.UsePropFailed, usePropFailed )
	request:start()
	container.waitRequest = true
end

function onGeneralUsePropFailed(e, selectData, container)
	container.waitRequest = false;
	if e.data == 712301 then		
		if selectData.relation then
			local itemMeta = MetaManager.prop_meta[selectData.metaId]
			local relationItemMeta = MetaManager.prop_meta[selectData.relation]
			if tonumber(itemMeta.effectType) == Prop_Effect_Type.BOX then
				--CanonMessageBox:Show(Localization:getInstance():getText("propInfo_openChest_noKey", {propname1 = getTextByKey(relationItemMeta.name), propname2 = getTextByKey(itemMeta.name)}), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, onConfirmClick )

				local showMessage = Localization:getInstance():getText("propInfo_openChest_noKey", {propname1 = getTextByKey(relationItemMeta.name), propname2 = getTextByKey(itemMeta.name)})
				local leftBtnInfo = {}
				local rightBtnInfo = {text = Localization:getInstance():getText("gemCard_by"), callbackFunc=onGotoShop}
				CanonMessageBox.showText(ShowButtonType.ID_OK_CANCEL, showMessage, leftBtnInfo, nil, rightBtnInfo)

				do return end
			elseif tonumber(itemMeta.effectType) == Prop_Effect_Type.KEY then  
				--CanonMessageBox:Show( Localization:getInstance():getText("propInfo_openChest_noChest", {propname = getTextByKey(relationItemMeta.name)}), ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, onConfirmClick )

				local showMessage = Localization:getInstance():getText("propInfo_openChest_noChest", {propname = getTextByKey(relationItemMeta.name)})
				local leftBtnInfo = {}
				local rightBtnInfo = {text = Localization:getInstance():getText("gemCard_by"), callbackFunc=onGotoShop}
				CanonMessageBox.showText(ShowButtonType.ID_OK_CANCEL, showMessage, leftBtnInfo, nil, rightBtnInfo)
				do return end
			else
				--没有关联物品 但是数量也不够的情况 显示默认提示 add by zheng.che @ 2014-3-12
				local function closeCanonMessageBox()
				end
				local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = e.data})
				container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
			end
		end
	elseif e.data == 710516 then
		local itemMeta = MetaManager.prop_meta[selectData.metaId]
		local text = getTextByKey("arena_inventoryFull")
		NewPackageFullPanel:show()
		-- CanonMessageBox:Show( text, ShowMessageType.ShowText, ShowButtonType.ID_OK, 40, onConfirmClick )
		do return end
	elseif e.data == CommErrorCodes.OPEN_VIPBOX.code then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.OPEN_VIPBOX)
		do return end
	else
		--显示默认提示 add by zheng.che @ 2014-3-12
		local function closeCanonMessageBox()
		end
		local text = Localization:getInstance():getText("defaultError_popupText", {errorCodeId = e.data})
		container.targetInfoPanel = CanonMessageBox:Show(text, ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	end
end

function onGeneralUsePropResponse(e, selectData, datalist, container, dataIndex, openNum, onClickMoreCallback)
	print("e = " .. tostringRich(e))
	--print("type(datalist) = " .. type(datalist))
	if not openNum then
		openNum = 1
	end

	RewardManager:getReward(e.data.rewards)
	selectData.amount = selectData.amount - openNum
  
  Activity_TreasureboxRankLayer.recheckFeatureBeginState()--确保数据可用

  local treasureboxConfig = DataManager.GameMetaData.activityTreasureboxPointsConfig
  if treasureboxConfig and MaintenanceManager.isActivityOpen(treasureboxConfig.featureNameTreasureboxPoints) then
    local aPoint
    if (selectData.metaId == 400019) or (selectData.metaId == 400057) then --金宝箱
      aPoint = treasureboxConfig.goldBoxPoint * openNum
    elseif (selectData.metaId == 400017) or (selectData.metaId == 400058) then --银宝箱
      aPoint = treasureboxConfig.silverBoxPoint * openNum
    elseif (selectData.metaId == 400016) or (selectData.metaId == 400059) then --铜宝箱
      aPoint = treasureboxConfig.copperBoxPoint * openNum
    end
    if aPoint then
      local gameInitData = DataManager.getGameInitData()
      local treasureBoxInfo = Activity_TreasureboxRankLayer.getTreasureboxPointsInfo()
      aPoint = treasureBoxInfo.point + aPoint
      gameInitData.sharkActivity.treasureboxPointsInfo.point = aPoint
      DataManager.setGameInitData(gameInitData)
    end
  end
  
	local itemData = DataManager.getPropsData()
	for k,v in pairs(itemData)
	do
		if v.metaId == selectData.metaId then
			v.amount = v.amount - openNum
		end
	end
	local keepOffset = true;
	local insertData = false
	if selectData.amount <= 0 then
		--table.remove(datalist, dataIndex)
		--要重新搜索一遍才放心 不要用index 否则连续使用情况可能出问题
		for k,v in pairs(datalist) do
			if v.metaId == selectData.metaId then
				table.remove(datalist, k)
			end
		end
		keepOffset = false
	end
							
	local relationData = selectData.relationData
	if relationData then
		relationData.amount = relationData.amount - openNum
		for k,v in pairs(itemData)
		do
			if v.metaId == relationData.metaId then
				v.amount = v.amount - openNum
			end
		end
		if relationData.amount <= 0 then
			for k,v in pairs(datalist)
			do
				if v.metaId == selectData.relation then
					table.remove(datalist, k)
					keepOffset = false
					break;
				end
			end
		end
	end
							
	DataManager.setPropsData(itemData)
	
	if type(e.data.rewards) == "table" then
		for key,value in pairs(e.data.rewards) do
			if value.itemType == ResourceEnum.CARD then
				local aCard = generateCard(value.id, value.metaId, value.level, tonumber(value.exp))
				local cardStatus = CommonManager:getBackpackCardPropertiesWithSharkCard( aCard )
				aCard.attack  = cardStatus.att
				aCard.defense = cardStatus.def
				aCard.hp      = cardStatus.hp
				aCard.price   = cardStatus.price
				aCard.resultExp   = math.floor(cardStatus.resultExp)
				aCard.rare = MetaManager.card_meta[aCard.metaId].rare
				table.insert(container.card_data, aCard)
			elseif value.itemType == ResourceEnum.EQUIP then
				local aEquip = generateEquip(value.id, value.metaId, value.level, tonumber(value.exp))
				aEquip.quality  = MetaManager.equip_meta[aEquip.metaId].quality
				aEquip.price = MetaManager.equip_meta[aEquip.metaId].sellPriceCoe * MetaManager.equip_level[aEquip.level].sellPriceBase
				table.insert(container.equip_data, aEquip)
			elseif value.itemType == ResourceEnum.PROP then
				local aProp = {
					metaId = value.metaId,
					amount = value.amount,
				}
				local exist = false;
				for k,v in pairs(container.item_data)
				do
					if v.metaId == aProp.metaId then
						exist = true;
						container.item_data[k].amount = container.item_data[k].amount + aProp.amount;
						break;
					end
				end
				if not exist then
					aProp.quality = MetaManager.prop_meta[aProp.metaId].quality
					aProp.price =  MetaManager.prop_meta[aProp.metaId].sellPrice 
					aProp.canSell =  MetaManager.prop_meta[aProp.metaId].canSell 
					table.insert(container.item_data, aProp)
					insertData = true
				end
			end
		end
	end

	-- print("container.item_data = " .. table.tostring(container.item_data))
	
	if type(container.recalcBagInfo) == "function" then
		container:recalcBagInfo()
	end

	if type(container.sortCardFunc) == "function" and type(container.sortEquipFunc) == "function" and type(container.sortItemFunc) == "function" then
		if HeMemDataHolder:getString("savedSortOrder_card") == "" then
			container.sortCardFunc({context = SORT_TYPE.RARE_DESC})
		else
			container.sortCardFunc({context = tonumber(HeMemDataHolder:getString("savedSortOrder_card"))})
		end

		if HeMemDataHolder:getString("savedSortOrder_equip") == "" then
			container.sortEquipFunc({context = SORT_TYPE.RARE_DESC})
		else
			container.sortEquipFunc({context = tonumber(HeMemDataHolder:getString("savedSortOrder_equip"))})
		end

		container.sortItemFunc()
	end

	container:refreshTableAfterUserProp(selectData.metaId )
							
	local itemMeta = MetaManager.prop_meta[selectData.metaId]
	local contentText = ""
							
	local function enableNextRequest()
		container.waitRequest = false;
	end
							
	local function checkLevelup()
		if  UserLevelManager.isUserLevelUp() then
			local function add_Exp_callback()
				UserLevelManager.checkUserLevelUp(enableNextRequest)
			end
			local levelLabel = g_BaseUISceneObject:getChildByName("home_menu_title"):getChildByName("txt_home_lv"):getChildByName("font")
			local expLabel = g_BaseUISceneObject:getChildByName("home_menu_title"):getChildByName("txt_icon_playerExp_num"):getChildByName("font")
			local expBar = g_BaseUISceneExpBar[0]
			doUIActionForAddedExp(levelLabel, expLabel, expBar, add_Exp_callback)
		else
			enableNextRequest()
		end
	end
		

	--?? ????					
	local function moreBtnCallback()
		enableNextRequest()
		local openMoreNum = BackpackScene.ItemCanOpenNum(selectData.metaId)
		BackpackScene.useMoreProp(openMoreNum, onClickMoreCallback)
	end
							
	local response
	if itemMeta.effectType == Prop_Effect_Type.EXP then
		contentText = Localization:getInstance():getText("propInfo_useExpSuccess", {num = itemMeta.effectValue})
		response = checkLevelup
	elseif itemMeta.effectType == Prop_Effect_Type.ENERGY then
		CanonPlayEffect("music/sfx_engly_lvup.wav")
		contentText = getTextByKey("propInfo_energyReplenished")
		enableNextRequest()
	elseif itemMeta.effectType == Prop_Effect_Type.EP then
		CanonPlayEffect("music/sfx_engly_lvup.wav")
		contentText = getTextByKey("propInfo_eventPointReplenished")
		enableNextRequest()
	elseif itemMeta.effectType == Prop_Effect_Type.TREASUREBOX or itemMeta.effectType == Prop_Effect_Type.VIPBOX or itemMeta.effectType == Prop_Effect_Type.TIMES_BOX then
		local params = {}
		if itemMeta.id == 400097 or itemMeta.id == 400098 or itemMeta.id == 400099 or itemMeta.id == 400100 then
			params.titleText = Localization:getInstance():getText("consecutiveLogin_getReward")
			params.openText = Localization:getInstance():getText("consecutiveLogin_getReward")
		else
			params.titleText = Localization:getInstance():getText("propInfo_openLockedChest", {propname = getTextByKey(itemMeta.name)})
			params.openText = Localization:getInstance():getText("propInfo_openLockedChest", {propname = getTextByKey(itemMeta.name)})
		end

		if itemMeta.effectType == Prop_Effect_Type.VIPBOX or itemMeta.effectType == Prop_Effect_Type.TIMES_BOX then
			--???????
			local openMoreNum = BackpackScene.ItemCanOpenNum(selectData.metaId)
			if openMoreNum > 0 then
				params.moreBtnText = BackpackScene.getItemUseBtnStr(selectData.metaId, true)
				params.moreBtnCallback = moreBtnCallback
			end
		end

		container.targetInfoPanel = GetRewardInfoPanel:create( container, e.data.rewards, enableNextRequest, params)
		PopoutManager:sharedManager():popout(container.targetInfoPanel, kPopoutDir.kScale, true, false ,container)
		do return end
	elseif itemMeta.effectType == Prop_Effect_Type.BOX then 
		local params = {}
		params.titleText = Localization:getInstance():getText("propInfo_openLockedChest", {propname = getTextByKey(itemMeta.name)})
		params.openText = Localization:getInstance():getText("propInfo_openLockedChest", {propname = getTextByKey(itemMeta.name)})

		--???????
		local openMoreNum = BackpackScene.ItemCanOpenNum(selectData.metaId)
		if openMoreNum > 0 then
			params.moreBtnText = BackpackScene.getItemUseBtnStr(selectData.metaId, true)
			params.moreBtnCallback = moreBtnCallback
		end

		container.targetInfoPanel = GetRewardInfoPanel:create( container, e.data.rewards, enableNextRequest, params)
		PopoutManager:sharedManager():popout(container.targetInfoPanel, kPopoutDir.kScale, true, false ,container)
		do return end
	elseif itemMeta.effectType == Prop_Effect_Type.KEY then 
		local params = {}
		local boxName = itemMeta.name
		
		params.titleText = Localization:getInstance():getText("propInfo_openLockedChest", {propname = getTextByKey(boxName)})
		params.openText = Localization:getInstance():getText("propInfo_openLockedChest", {propname = getTextByKey(boxName)})
		container.targetInfoPanel = GetRewardInfoPanel:create( container, e.data.rewards, enableNextRequest, params)
		PopoutManager:sharedManager():popout(container.targetInfoPanel, kPopoutDir.kScale, true, false ,container)
		do return end
	elseif itemMeta.effectType == Prop_Effect_Type.RED_PACKET_RECIVED then 
		local params = {}
		local boxName
		if selectData.relation then
			boxName = MetaManager.prop_meta[selectData.relation].name
		else
			boxName = itemMeta.name
		end
		params.titleText = Localization:getInstance():getText("propInfo_openLockedChest", {propname = getTextByKey(boxName)})
		params.openText = Localization:getInstance():getText("propInfo_openLockedChest", {propname = getTextByKey(boxName)})
		container.targetInfoPanel = GetRewardInfoPanel:create( container, e.data.rewards, enableNextRequest, params)
		PopoutManager:sharedManager():popout(container.targetInfoPanel, kPopoutDir.kScale, true, false ,container)
		do return end
	end
							
	SuspensionLabel:showContent(container, contentText, response)
end