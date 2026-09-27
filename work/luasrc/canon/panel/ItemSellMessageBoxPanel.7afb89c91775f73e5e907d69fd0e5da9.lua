--------------------------------------------------------------------------------
-- ItemSellMessageBoxPanel.lua - 物品（卡片，道具，装备）出售通用弹窗
-- author: fanzhou.long
-- updated: 2013-08-20
--------------------------------------------------------------------------------

require "canon.request.SellEquipsRequest"
require "canon.request.SellCardsRequest"
require "canon.request.SellPropsRequest"
require "canon.request.SellSpiritRequest"
require "canon.models.RewardManager"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

ItemSellMessageBoxPanel = class(Layer)

function ItemSellMessageBoxPanel:ctor()
    self.container = nil
end

function ItemSellMessageBoxPanel:create( container, params, infoPanel , index)
    self.container = container
    self.items = params
	self.infoPanel = infoPanel
	self.newIndex = index or -1
    local s = ItemSellMessageBoxPanel.new()
    s:initLayer()
    self.backupTargetInfoPanel = container.targetInfoPanel
    return s
end

function ItemSellMessageBoxPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	local btName = self.items.bagCategory or self.container.currentTab
	ItemSellMessageBoxPanel.super.initLayer(self)
	
	self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height+200))
    self:addChild(self.colorLayer)
	
	self.tempLayer = Layer:create()
	self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
	self:addChild(self.tempLayer)
	self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
  
	local builder = LayoutBuilder:createWithContentsOfFile("scene/common_new.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("common_popup_sellItem")
	
	self.panelUI:getChildByName("common_txt_sellItem_price"):getChildByName("txt_sellItem_price"):setString(Localization:getInstance():getText("sellItem_price"))
	
	--Count Price
	local price = 0
	if btName == BAGCATEGORY.card  then
		--Begin to count cards value
		local GameData = DataManager.getGameInitData() --table.deserialize(HeMemDataHolder:getString("GameInit"))
		local SharkCards = GameData.sharkCards.sharkCards
		local i = 1
    
		local cardId2MetaIdAndLevel = {}
		for _, value in pairs(SharkCards) do
			cardId2MetaIdAndLevel[value.cardId] = {
			metaId = value.metaId,
			level = value.level}
		end
		for _, value in pairs(self.items.cardData) do
			local aCard = cardId2MetaIdAndLevel[value]
			price = price + MetaManager.card_meta[aCard.metaId].basicPrice * MetaManager.card_level[aCard.level].priceCoefficient
		end
		if (#self.items.cardData>1) then
			self.panelUI:getChildByName("common_txt_sellItem_equip"):getChildByName("txt_sellItem_equip"):setString(Localization:getInstance():getText("sellItem_cardBatch"))
		else
			self.panelUI:getChildByName("common_txt_sellItem_equip"):getChildByName("txt_sellItem_equip"):setString(Localization:getInstance():getText("sellItem_card"))
		end
		--Done
	elseif btName == BAGCATEGORY.item  then 
		self.panelUI:getChildByName("common_txt_sellItem_equip"):getChildByName("txt_sellItem_equip"):setString(Localization:getInstance():getText("sellItem_propBatch"))
		--Begin to count props value
		for _, value in pairs(self.items.propData) do
			price = price + MetaManager.prop_meta[value.metaId].sellPrice * value.amount
		end
		--Done
	elseif btName == BAGCATEGORY.equip  then
		--Begin to count equips value
		local SharkEquips = DataManager.getEquipsData()
		local i = 1
    
		local equipId2MetaIdAndLevel = {}
		for _, value in pairs(SharkEquips) do
			equipId2MetaIdAndLevel[value.equipId] = {
			metaId = value.metaId,
			level = value.level}
		end  
		for _, value in pairs(self.items.equipData) do
			local aEquip = equipId2MetaIdAndLevel[value]
			price = price + MetaManager.equip_meta[aEquip.metaId].sellPriceCoe * MetaManager.equip_level[aEquip.level].sellPriceBase
		end
		if (#self.items.equipData>1) then
			self.panelUI:getChildByName("common_txt_sellItem_equip"):getChildByName("txt_sellItem_equip"):setString(Localization:getInstance():getText("sellItem_equipBatch"))
		else
			self.panelUI:getChildByName("common_txt_sellItem_equip"):getChildByName("txt_sellItem_equip"):setString(Localization:getInstance():getText("sellItem_equip"))
		end
	elseif btName == BAGCATEGORY.spirit  then
		--Begin to count equips value
		local SharkSpirits = DataManager.getSpiritsData()
		local i = 1
    
		local equipId2MetaIdAndLevel = {}
		for _, value in pairs(SharkSpirits) do
			equipId2MetaIdAndLevel[value.spiritId] = {
			metaId = value.metaId}
		end  
		for _, value in pairs(self.items.spiritData) do
			local aEquip = equipId2MetaIdAndLevel[value]
			price = price + MetaManager.spirit_meta[aEquip.metaId].price
			-- price = price + MetaManager.spirit_meta[aEquip.metaId].sellPriceCoe * MetaManager.equip_level[aEquip.level].sellPriceBase
		end
		if (#self.items.spiritData>1) then
			self.panelUI:getChildByName("common_txt_sellItem_equip"):getChildByName("txt_sellItem_equip"):setString(Localization:getInstance():getText("sellItem_spiritBatch"))
		else
			self.panelUI:getChildByName("common_txt_sellItem_equip"):getChildByName("txt_sellItem_equip"):setString(Localization:getInstance():getText("sellItem_spirit"))
		end
	elseif btName == BAGCATEGORY.treasure then --l1ghtsaber
		local treasure = DataManager.getTreasuresData()
		local metaPool = {}
		for _, value in pairs(treasure) do
			metaPool[value.treasureId] = {
				metaId = value.metaId
			}
		end
		for _,value in pairs(self.items.treasureData) do
			local aEquip = metaPool[value]
			price = price + MetaManager.treasure_meta[aEquip.metaId].basicPrice
		end
		if (#self.items.treasureData>1) then
			self.panelUI:getChildByName("common_txt_sellItem_equip"):getChildByName("txt_sellItem_equip"):setString(getTextByKey("Treasure_sell2"))
		else
			self.panelUI:getChildByName("common_txt_sellItem_equip"):getChildByName("txt_sellItem_equip"):setString(getTextByKey("Treasure_sell1"))
		end
	end
	price = math.floor(price)
	self.panelUI:getChildByName("common_txt_sellItem_price_num"):getChildByName("font"):setString(""..price)
	
	--Sell button listener
	local function onClickSellBtn(evt)
		local aPanel = evt.context
		-- local btName = aPanel.container.currentTab --武将卖出修改
		local items = {}
		
		if btName == BAGCATEGORY.card  then 
			--Send card sell request
			local function cardSellResponse( evt )
				CanonPlayEffect("music/sfx_amer_sale.wav")
				RewardManager:getReward(evt.data.rewards)
				local GameData = DataManager.getGameInitData() --table.deserialize(HeMemDataHolder:getString("GameInit"))
				local SharkCards = GameData.sharkCards.sharkCards
				local tempCards = {}
				for key, value in pairs(SharkCards) do
					local flag = true
					for _, iValue in pairs(items) do
						if (iValue == value.cardId) then
							flag = false
							break
						end
					end
					if (flag) then
						table.insert(tempCards,value)
					end
				end
				GameData.sharkCards.sharkCards = tempCards
				DataManager.setGameInitData(GameData)
				if self.items.onSellFinish then
					self.items.onSellFinish()
				else
					for _,value in pairs(self.items.cardData) do
						for k, v in pairs(self.container.card_data)
						do
							if v.cardId == value then
								table.remove(self.container.card_data, k)
								break;
							end
						end
					end
					self.container:onSellFinish()
					if self.newIndex ~= -1 then
						self.container:refreshTable(true, nil, true,self.newIndex)
					else
						self.container:refreshTable(false, nil, true,self.newIndex)
					end
				end
			end
			for _,value in pairs(self.items.cardData) do
				table.insert(items, value)
			end
			local request = SellCardsRequest.new( {cardIds = items}, rpc.SendingPriority.kHigh )
			request:addEventListener( RequestNotifyEnum.SellCardsSucceed, cardSellResponse )
			request:start()
			
		elseif btName == BAGCATEGORY.item  then 
			--Send prop sell request
			for _,value in pairs(self.items.propData) do
				table.insert(items, value)
			end
			local function propSellResponse( evt )
				RewardManager:getReward(evt.data.rewards)
				
				local function GetPropsCallBack(e) --道具信息
					for _,value in pairs(self.items.propData) do
						for k, v in pairs(self.container.item_data)
						do
							if v.metaId == value.metaId then
								table.remove(self.container.item_data, k)
								break;
							end
						end
					end
					self.container:onSellFinish()
                    if self.newIndex ~= -1 then
						self.container:refreshTable(true, nil, true,self.newIndex)
					else
						self.container:refreshTable(false, nil, true,self.newIndex)
					end              
                end    
				
				local request = GetPropsRequest.new( params, rpc.SendingPriority.kHigh )
                request:addEventListener( RequestNotifyEnum.GetPropsSucceed, GetPropsCallBack )
                request:start() 
			end
			local request = SellPropsRequest.new( {requisite = items}, rpc.SendingPriority.kHigh )
			request:addEventListener( RequestNotifyEnum.SellPropSucceed, propSellResponse )
			request:start()
			
		elseif btName == BAGCATEGORY.equip  then 
			--Send equip sell request
			local function equipSellResponse( evt )
				RewardManager:getReward(evt.data.rewards)
				
				local function GetEquipsCallBack(e) --装备信息
					if self.items.onSellFinish then
							self.items.onSellFinish()
					else
						for _,value in pairs(self.items.equipData) do
							for k, v in pairs(self.container.equip_data)
							do
								if v.equipId == value then
									table.remove(self.container.equip_data, k)
									break;
								end
							end
						end
						self.container:onSellFinish()
	                    if self.newIndex ~= -1 then
							self.container:refreshTable(true, nil, true,self.newIndex)
						else
							self.container:refreshTable(false, nil, true,self.newIndex)
						end           
					end
                end    
				
				local request = GetEquipsRequest.new( params, rpc.SendingPriority.kHigh )
                request:addEventListener( RequestNotifyEnum.GetEquipsSucceed, GetEquipsCallBack )
                request:start()
			end
			for _,value in pairs(self.items.equipData) do
				table.insert(items, value)
			end
			local request = SellEquipsRequest.new( {equipIds = items}, rpc.SendingPriority.kHigh )
			request:addEventListener( RequestNotifyEnum.SellEquipsSucceed, equipSellResponse )
			request:start()
		elseif btName == BAGCATEGORY.spirit  then
			--Send equip sell request
			local function spiritSellResponse( evt )
				RewardManager:getReward(evt.data.rewards)
				
				-- local function GetSpiritsCallBack(e) --装备信息
					for _,value in pairs(self.items.spiritData) do
						for k, v in pairs(self.container.spirit_data)
						do
							if v.spiritId == value then
								table.remove(self.container.spirit_data, k)
								local gameInitData = DataManager.getGameInitData()
								if gameInitData.sharkSpirits.unsaveSpiritAttributes ~= nil and #gameInitData.sharkSpirits.unsaveSpiritAttributes ~= 0 and gameInitData.sharkSpirits.unsaveSpiritId == value then
									gameInitData.sharkSpirits.unsaveSpiritAttributes = nil
							    	DataManager.setGameInitData(gameInitData)
								end
								break;
							end
						end
					end

					local SharkCards = DataManager.getSpiritsData()
					local tempCards = {}
					for key, value in pairs(SharkCards) do
						local flag = true
						for _, iValue in pairs(items) do
							if (iValue == value.spiritId) then
								flag = false
								break
							end
						end
						if (flag) then
							table.insert(tempCards,value)
						end
					end
					DataManager.setSpiritsData(tempCards)

					self.container:onSellFinish()
                    if self.newIndex ~= -1 then
						self.container:refreshTable(true, nil, true,self.newIndex)
					else
						self.container:refreshTable(false, nil, true,self.newIndex)
					end             
                -- end    
				
				-- local request = GetSpiritsRequest.new( params, rpc.SendingPriority.kHigh )
    --             request:addEventListener( RequestNotifyEnum.GetEquipsSucceed, GetSpiritsCallBack )
    --             request:start()
			end
			for _,value in pairs(self.items.spiritData) do
				table.insert(items, value)
			end
			SellSpiritRequest.sendRequest({spiritIds = items}, spiritSellResponse, nil)
		elseif btName == BAGCATEGORY.treasure then --l1ghtsaber 
			local function afterSellTreasure()
				local treasure = self.container.treasure_data
				for i = #treasure,1,-1 do 
					for _,value in pairs(self.items.treasureData) do
						if treasure[i].treasureId == value then 
							table.remove(treasure,i)
							break
						end
					end
				end
				DataManager.setTreasuresData( treasure )
				self.container:onSellFinish()
				if self.newIndex ~= -1 then
					self.container:refreshTable(true, nil, true,self.newIndex)
				else
					self.container:refreshTable(false, nil, true,self.newIndex)
				end     
			end
			SellTreasureRequest.sendRequestDefalut(self.items.treasureData,afterSellTreasure)
		end
		
		--Ending process

		aPanel.container:setTableViewsEnabled(true)
		aPanel.container.targetInfoPanel = self.backupTargetInfoPanel
    if (aPanel.infoPanel) then
      aPanel.container.targetInfoPanel = self.backupTargetInfoPanel
			PopoutManager:sharedManager():pullin(aPanel.infoPanel, kPopoutDir.kScale )
			aPanel.container:setTableViewsEnabled(true)
		end
    aPanel:removeFromParentAndCleanup(true)
	end
	local confirmBtnDisplay = self.panelUI:getChildByName("common_btn_sellItem_yes")
	confirmBtnDisplay:getChildByName("txt_yes"):setString(Localization:getInstance():getText("yes"))
	local confirmBtn = Button:create(confirmBtnDisplay)
	confirmBtn:addEventListener(Events.kStart, onClickSellBtn, self)
	
	local function onCancelBtn(evt)
		self.container:setTableViewsEnabled(true)
		self.container.UIStatus = BACKPACK_STATUS.NORMAL
		self.container.targetInfoPanel = self.backupTargetInfoPanel
		self:removeFromParentAndCleanup(true)
	end
	local cancelBtnDisplay = self.panelUI:getChildByName("common_btn_sellItem_no")
	cancelBtnDisplay:getChildByName("txt_cancel"):setString(Localization:getInstance():getText("cancel"))
	local cancelBtn = Button:create(cancelBtnDisplay)
	cancelBtn:addEventListener(Events.kStart, onCancelBtn, self)
	
	local closeBtn = Button:create(self.panelUI:getChildByName("btn_close"))
	closeBtn:addEventListener(Events.kStart, onCancelBtn, self)
	
	self.tempLayer:addChild(self.panelUI)
	self.tempLayer:setScale(0.1)
end

function ItemSellMessageBoxPanel:scaleIn()
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