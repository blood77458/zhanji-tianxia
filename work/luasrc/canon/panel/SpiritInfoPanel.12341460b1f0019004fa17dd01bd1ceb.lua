--
-- SpiritInfoPanel
-- Author: czh
-- Date: 2014-02-18 14:05:02
--
require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.panel.ItemSellMessageBoxPanel"
require "canon.manager.SpiritManager"
require "canon.request.UnequipSpiritRequest"
require "canon.panel.SpiritPackageFullPanel"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

SpiritInfoPanel = class(Layer)

function SpiritInfoPanel:ctor()
	self.container = nil
end

function SpiritInfoPanel:create( container , enterAndReturnScene ,index)
	local s = SpiritInfoPanel.new()
	s.container = container
	s.enterAndReturnScene = enterAndReturnScene
	s.newIndex = index 
	s:initLayer()
	return s
end

function SpiritInfoPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	SpiritInfoPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/formation_new.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_elesoul_info")
	self.panelUI:getChildByName("common_txt_propInfo_title"):getChildByName("txt_propInfo_title"):setString(Localization:getInstance():getText("popup_spiritInfo_title"))
	
	--self.panelUI:getChildByName("popup_equipInfo_upper"):getChildByName("txt_equip_Quality"):getChildByName("txt_equip_Quality"):setString(Localization:getInstance():getText("equip_Quality"))
	
	self.spirit = self.container._data
    self.equipMetaData = MetaManager.spirit_meta[self.spirit.metaId]    
    self.equipLevelConfig = MetaManager.equip_level[self.spirit.level]

    local allAttrValue = SpiritManager.getAllAttributesValue( self.spirit )
    
    self.panelUI:getChildByName("common_txt_propInfo_title"):getChildByName("txt_propInfo_title"):setString(getTextByKey("spirit_spiritInfo_title"))
    self.panelUI:getChildByName("txt_elesoul2"):getChildByName("txt"):setString(SpiritManager.getSpiritName( self.spirit ))
	self.panelUI:getChildByName("formation_txt_lv_num"):getChildByName("font"):setString(self.spirit.level)
    self.panelUI:getChildByName("txt_elesoul3"):getChildByName("txt"):setString(getTextByKey("popup_spiritInfo_growth"))
    self.panelUI:getChildByName("txt_elesoul3_2"):getChildByName("txt"):setString(getTextByKey("popup_spiritInfo_growth"))
    self.panelUI:getChildByName("txt_elesoul3_3"):getChildByName("txt"):setString(getTextByKey("popup_spiritInfo_growth"))

	local color = SpiritManager.getColorByRarity(self.equipMetaData.rarity)
	self.panelUI:getChildByName("txt_elesoul1"):getChildByName("txt"):setColor(color)
	self.panelUI:getChildByName("txt_elesoul7"):getChildByName("txt"):setColor(color)
	self.panelUI:getChildByName("txt_elesoul7"):getChildByName("txt"):setString(tostring(self.equipMetaData.mainAttributeGrowth))
	local spiritAttrValue = allAttrValue[1]
	self.panelUI:getChildByName("txt_elesoul1"):getChildByName("txt"):setString(SpiritManager.getTextBySpiritAttrType(self.equipMetaData.mainAttributeType).."+"..spiritAttrValue)

	if SpiritManager.isExpSpirit( self.spirit ) then
    	self.panelUI:getChildByName("txt_elesoul7"):setVisible(false)
    	self.panelUI:getChildByName("txt_elesoul3"):setVisible(false)
    else
    	self.panelUI:getChildByName("txt_elesoul7"):setVisible(true)
    	self.panelUI:getChildByName("txt_elesoul3"):setVisible(true)
    end

	for i=1,2 do
		self.panelUI:getChildByName("txt_elesoul1_"..(i + 1)):setVisible(false)
		self.panelUI:getChildByName("txt_elesoul3_"..(i + 1)):setVisible(false)
		self.panelUI:getChildByName("txt_elesoul7_"..(i)):setVisible(false)
		self.panelUI:getChildByName("icon_chp"..(i)):setVisible(false)
	end

	for i=1,#self.spirit.sharkSpiritAttributes do
		self.panelUI:getChildByName("txt_elesoul1_"..(i + 1)):setVisible(true)
		local str = SpiritManager.getTextBySpiritAttrType( self.spirit.sharkSpiritAttributes[i].attributeType ).."+"..allAttrValue[i + 1]
		-- local color = SpiritManager.getColorByRarity( rarity )
		self.panelUI:getChildByName("txt_elesoul1_"..(i + 1)):getChildByName("txt"):setString(str)

		self.panelUI:getChildByName("txt_elesoul3_"..(i + 1)):setVisible(true)
		self.panelUI:getChildByName("txt_elesoul7_"..(i)):setVisible(true)
		
		local subSpiritAttr = self.spirit.sharkSpiritAttributes[i]
		if subSpiritAttr.max then
			self.panelUI:getChildByName("icon_chp"..(i)):setVisible(true)
		end

		local color = SpiritManager.getColorByRarity(subSpiritAttr.attributeRare)
		self.panelUI:getChildByName("txt_elesoul7_"..(i)):getChildByName("txt"):setColor(color)
		self.panelUI:getChildByName("txt_elesoul1_"..(i + 1)):getChildByName("txt"):setColor(color)
		self.panelUI:getChildByName("txt_elesoul7_"..(i)):getChildByName("txt"):setString(getFloatNumber(subSpiritAttr.attributeGrowing))

	end
	
	--关闭
	local function onClosePanel(evt)
		self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	end
	
	local bt_panel_close = Button:create(self.panelUI:getChildByName("btn_close"))
	bt_panel_close:addEventListener(Events.kStart, onClosePanel)

	local isEnable = SpiritManager.isSpiritEnable( self.spirit )

	local function onReplace( evt )
		if self.spirit.cardId ~= 0 then
			-- if SpiritManager.isSpiritPoolFull() then
			-- 	SpiritPackageFullPanel:show()
			-- 	return
			-- end
			local cardQueue = CommonManager.getQueueData()
			local cardIds = {}
			for aKey, aCardId  in pairs(cardQueue) do
				cardIds[aCardId] = aKey
			end
			HeMemDataHolder:setInteger("CardQueue_RollTo", cardIds[self.spirit.cardId])
			HeMemDataHolder:setInteger("SpiritChange_Position", SpiritManager.getSpiritEquipPos( self.spirit ))
			HeMemDataHolder:setInteger("SpiritChange_NowSpiritId", self.spirit.spiritId)
			local argv = {
				enterScene="CardQueueScene",
				returnScene="CardQueueScene",
				params={
					--cardPos = cardNo,
					cardId = self.spirit.cardId,
					filterFunc = CardQueueScene.spiritFilterFunc,
					equipedDown = true,
					backToSpirit = true,
				}
			}
			if self.enterAndReturnScene then
		        argv.returnScene = self.enterAndReturnScene
		    end
		    
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
			self.container:replaceScene( SpiritBackPackScene , argv)
		else
			local aPanel = ItemSellMessageBoxPanel:create( self.container , {spiritData={self.spirit.spiritId} , bagCategory = BAGCATEGORY.spirit}, self , self.newIndex)
			self.container:addChild(aPanel)
			aPanel:scaleIn()
		end
	end

	--阵容状态（不可卖出）
	local queueList = {}
	local gameData = DataManager.getGameInitData()
	for BattleArrayId = 1,3 do	
		local quedata = gameData.sharkUserBattleArray[BattleArrayId] and gameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue or {}
		for k,v in pairs(quedata) do
			if (not v.spirits) then v.spirits = {} end
			for _,value in pairs(v.spirits) do
				queueList[value.spiritId] = true
			end		
		end	
	end

	if self.spirit.cardId ~= 0 or (not queueList[self.spirit.spiritId]) then
		local btn_replace = Button:create(self.panelUI:getChildByName("formation_btn_change_captain1"))
		btn_replace:addEventListener(Events.kStart, onReplace)
	else
		self.panelUI:getChildByName("formation_btn_change_captain1"):getChildByName("normal"):setVisible(false) --置灰的情况
	end
	--end by l1ghtsaber（以下原版）
	-- local btn_replace = Button:create(self.panelUI:getChildByName("formation_btn_change_captain1"))
	-- btn_replace:addEventListener(Events.kStart, onReplace)

	-- 是否出现卸下按钮
	if self.enterAndReturnScene == "SpiritBackPackScene" then
		local btn_replace = self.panelUI:getChildByName("formation_btn_change_captain1")
	    local btn_unequip = self.panelUI:getChildByName("formation_btn_change_captain2")
	    btn_replace:setPositionXY(btn_unequip:getPositionX(), btn_unequip:getPositionY())
	    btn_unequip:setVisible(false)
	else
		local function onUnequip( evt )
			if SpiritManager.isSpiritPoolFull() then
				SpiritPackageFullPanel:show()
				return
			else
				local function unEquipSpiritSucceedResponse( e )
					--将装备从原卡牌上脱下来
					local GameData = DataManager.getGameInitData()
					local cards = DataManager.getCardsData()
					local spirits = DataManager.getSpiritsData()
					local originalCard,originalCardKey = CommonManager.getSubTableByKey(
						cards,
						{name = "cardId", value = self.spirit.cardId}
					)
					if (originalCard) then
						for aKey, aEquipId in pairs(originalCard.cardSpirits) do
							if (aEquipId.spiritId == self.spirit.spiritId) then
								table.remove(originalCard.cardSpirits, aKey)
								break
							end
						end
					end
					for k,v in pairs(spirits) do
						if v.spiritId == self.spirit.spiritId then
							self.spirit.cardId = 0 
							spirits[k] = self.spirit
						end
					end
					GameData.sharkCards.sharkCards[originalCardKey] = originalCard
					--当前阵容（下圆神）
					if (originalCard) and (GameData.sharkUser.level >= (MetaManager.game_meta.gameSettingConfig.lineupUnlockLevel or 43))	
					then
						local BattleArrayId = GameData.sharkUserExtendMore.battleArrayId
						for k,v in pairs(GameData.sharkUserBattleArray[BattleArrayId].sharkUserQueue) do
							if (originalCard.cardId == v.cardId) then v.spirits = originalCard.cardSpirits end
						end
					end
					--end by l1ghtsaber	
					DataManager.setGameInitData(GameData)
					DataManager.setSpiritsData(spirits)
					
					--显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
					DataManager.fightCapacityMaybeUpdated()

					self.container:refreshUI()
					self.container:setTableViewsEnabled(true)
					self.container.targetInfoPanel = nil
					PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
				end
			
				local function unEquipSpiritFailedResponse( e )
								
				end
				g_previousBattleCount = CommonManager:getLocalPlayerStrength()
				local params = {cardId = self.spirit.cardId , index = SpiritManager.getSpiritEquipPos( self.spirit )}
				UnequipSpiritRequest.sendRequest(params , unEquipSpiritSucceedResponse , unEquipSpiritFailedResponse)
			end
		end

		local btn_unequip = Button:create(self.panelUI:getChildByName("formation_btn_change_captain2"))
		btn_unequip:addEventListener(Events.kStart, onUnequip)
		self.panelUI:getChildByName("formation_btn_change_captain2"):getChildByName("txt"):setString(getTextByKey("spirit_spiritInfo_unequipBtn"))
	end

	local function onCompose( evt )
		local hasUnsaveSpirit = false
		  local gameInitData = DataManager.getGameInitData()
		  if gameInitData.sharkSpirits.unsaveSpiritAttributes ~= nil and #gameInitData.sharkSpirits.unsaveSpiritAttributes ~= 0 then
		    hasUnsaveSpirit = true
		  end
		  if hasUnsaveSpirit then
		  	local aPanel = MessageBoxPanel:create(self, MessageBoxType.kHaveUnsaveSpiritWarning)
  			self:addChild(aPanel)
  			aPanel:scaleIn()
		  	return
		  end
		self.container.targetInfoPanel = SpiritComposePanel:create(self.container, self.spirit , self)
        PopoutManager:sharedManager():popout(self.container.targetInfoPanel, kPopoutDir.kScale, true, false, self.container)
	end

	local btn_compose = Button:create(self.panelUI:getChildByName("formation_btn_change_captain"))
	btn_compose:addEventListener(Events.kStart, onCompose)
	self.panelUI:getChildByName("formation_btn_change_captain"):getChildByName("txt"):setString(getTextByKey("beast_enhanceBtn"))

    self.panelUI:getChildByName("normal_card_small"):setVisible(false)

    local params = {}
	  params.sourceDisplay = self.panelUI:getChildByName("normal_card_small")
	  -- params.showInCenter = true
	  local headCard = CanonGoodIcon.createGoodIcon(ResourceEnum.SPIRIT, self.spirit.metaId, 1, params)
	  -- local headCard = getHeadIconCanonCardByMetaId(101011)
	  -- headCard:setPosition(ccp(picPosX, picPosY))
	  -- headCard:setTag(TAG_PIC_REWARD)
	  self.panelUI:addChild(headCard, 1000)
	  -- headCard:dispose()

    if self.spirit.cardId ~= 0 then
    	self.panelUI:getChildByName("formation_btn_change_captain1"):getChildByName("txt"):setString(getTextByKey("cardInfo_ChangeBtn"))
	    if btn_replace then btn_replace:setVisible(isEnable) end --置灰不能有按钮 add by l1ghtsaber
	    --btn_replace:setVisible(isEnable)
	else
    	self.panelUI:getChildByName("formation_btn_change_captain1"):getChildByName("txt"):setString(getTextByKey("cardInfo_SellBtn"))
    end

	self:addChild(self.panelUI)
end

function SpiritInfoPanel:initData()

end

function SpiritInfoPanel:updata()

end

function SpiritInfoPanel:gotoSpiritComposePanel()
	self.container.targetInfoPanel = SpiritComposePanel:create(self.container, self.spirit , self)
    PopoutManager:sharedManager():popout(self.container.targetInfoPanel, kPopoutDir.kScale, true, false, self.container)
end

function SpiritInfoPanel:refresh()
	local spirit_data = DataManager.getSpiritsData()
	for k,v in pairs(spirit_data) do
		if v.spiritId == self.spirit.spiritId then
			self.spirit = v
		end
	end
	-- self.spirit = self.container._data
    self.equipMetaData = MetaManager.spirit_meta[self.spirit.metaId]    
    self.equipLevelConfig = MetaManager.equip_level[self.spirit.level]

    local allAttrValue = SpiritManager.getAllAttributesValue( self.spirit )
    
    self.panelUI:getChildByName("common_txt_propInfo_title"):getChildByName("txt_propInfo_title"):setString(getTextByKey("spirit_spiritInfo_title"))
    self.panelUI:getChildByName("txt_elesoul2"):getChildByName("txt"):setString(SpiritManager.getSpiritName( self.spirit ))
	self.panelUI:getChildByName("formation_txt_lv_num"):getChildByName("font"):setString(self.spirit.level)
    self.panelUI:getChildByName("txt_elesoul3"):getChildByName("txt"):setString(getTextByKey("popup_spiritInfo_growth"))
    self.panelUI:getChildByName("txt_elesoul3_2"):getChildByName("txt"):setString(getTextByKey("popup_spiritInfo_growth"))
    self.panelUI:getChildByName("txt_elesoul3_3"):getChildByName("txt"):setString(getTextByKey("popup_spiritInfo_growth"))

	local color = SpiritManager.getColorByRarity(self.equipMetaData.rarity)
	self.panelUI:getChildByName("txt_elesoul1"):getChildByName("txt"):setColor(color)
	self.panelUI:getChildByName("txt_elesoul7"):getChildByName("txt"):setColor(color)
	self.panelUI:getChildByName("txt_elesoul7"):getChildByName("txt"):setString(tostring(self.equipMetaData.mainAttributeGrowth))
	local spiritAttrValue = allAttrValue[1]
	self.panelUI:getChildByName("txt_elesoul1"):getChildByName("txt"):setString(SpiritManager.getTextBySpiritAttrType(self.equipMetaData.mainAttributeType).."+"..spiritAttrValue)

	if SpiritManager.isExpSpirit( self.spirit ) then
    	self.panelUI:getChildByName("txt_elesoul7"):setVisible(false)
    	self.panelUI:getChildByName("txt_elesoul3"):setVisible(false)
    else
    	self.panelUI:getChildByName("txt_elesoul7"):setVisible(true)
    	self.panelUI:getChildByName("txt_elesoul3"):setVisible(true)
    end

	for i=1,2 do
		self.panelUI:getChildByName("txt_elesoul1_"..(i + 1)):setVisible(false)
		self.panelUI:getChildByName("txt_elesoul3_"..(i + 1)):setVisible(false)
		self.panelUI:getChildByName("txt_elesoul7_"..(i)):setVisible(false)
		self.panelUI:getChildByName("icon_chp"..(i)):setVisible(false)
	end

	for i=1,#self.spirit.sharkSpiritAttributes do
		self.panelUI:getChildByName("txt_elesoul1_"..(i + 1)):setVisible(true)
		local str = SpiritManager.getTextBySpiritAttrType( self.spirit.sharkSpiritAttributes[i].attributeType ).."+"..allAttrValue[i + 1]
		-- local color = SpiritManager.getColorByRarity( rarity )
		self.panelUI:getChildByName("txt_elesoul1_"..(i + 1)):getChildByName("txt"):setString(str)

		self.panelUI:getChildByName("txt_elesoul3_"..(i + 1)):setVisible(true)
		self.panelUI:getChildByName("txt_elesoul7_"..(i)):setVisible(true)
		
		local subSpiritAttr = self.spirit.sharkSpiritAttributes[i]
		if subSpiritAttr.max then
			self.panelUI:getChildByName("icon_chp"..(i)):setVisible(true)
		end

		local color = SpiritManager.getColorByRarity(subSpiritAttr.attributeRare)
		self.panelUI:getChildByName("txt_elesoul7_"..(i)):getChildByName("txt"):setColor(color)
		self.panelUI:getChildByName("txt_elesoul1_"..(i + 1)):getChildByName("txt"):setColor(color)
		self.panelUI:getChildByName("txt_elesoul7_"..(i)):getChildByName("txt"):setString(getFloatNumber(subSpiritAttr.attributeGrowing))

	end
end