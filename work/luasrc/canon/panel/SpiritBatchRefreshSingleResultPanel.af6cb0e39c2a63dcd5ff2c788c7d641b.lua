require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.panel.ItemSellMessageBoxPanel"
require "canon.manager.SpiritManager"
require "canon.request.SelectSubAttributeRequest"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

SpiritBatchRefreshSingleResultPanel = class(Layer)

function SpiritBatchRefreshSingleResultPanel:ctor()
	self.container = nil
	self.selectId = 0
end

function SpiritBatchRefreshSingleResultPanel:create( container , refreshSharkSpiritAttribute)
	local s = SpiritBatchRefreshSingleResultPanel.new()
	s.container = container
	s.refreshSharkSpiritAttribute = refreshSharkSpiritAttribute
	s:initLayer()
	return s
end

function SpiritBatchRefreshSingleResultPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	SpiritBatchRefreshSingleResultPanel.super.initLayer(self)
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/elesoul.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup_refresh_result_single")
    self.panelUI:getChildByName("btn_close"):setVisible(false)
	local mainAttr = SpiritManager.getAllAttributesValue( self.container.spirit )
	local mainStr = SpiritManager.getMainAttributeName( self.container.spirit ).."+"..mainAttr[1]
	local txtTable = {
		[1] = "txt_elesoul_m",
		[2] = "txt_elesoul_r",
	}

	for i=0,1 do
		self.panelUI:getChildByName("list_ability"..i):getChildByName("txt_elesoul_l"):getChildByName("txt"):setString(mainStr)
		self.panelUI:getChildByName("list_ability"..i):getChildByName("q_other9_panel"):setVisible(false)
		self.panelUI:getChildByName("list_ability"..i):getChildByName("icon_chp1"):setVisible(false)
		self.panelUI:getChildByName("list_ability"..i):getChildByName("icon_chp2"):setVisible(false)
		local color = SpiritManager.getColorByRarity(SpiritManager.getSpiritRare( self.container.spirit ))
		self.panelUI:getChildByName("list_ability"..i):getChildByName("txt_elesoul_l"):getChildByName("txt"):setColor(color)
		for j=1,2 do
			local color = SpiritManager.getColorByRarity( self.refreshSharkSpiritAttribute[i].sharkSpiritAttribute[j].attributeRare )
			local name = SpiritManager.getTextBySpiritAttrType( self.refreshSharkSpiritAttribute[i].sharkSpiritAttribute[j].attributeType )
			local attrNum = getFloatNumber(self.refreshSharkSpiritAttribute[i].sharkSpiritAttribute[j].attributeGrowing) * self.container.spirit.level
			self.panelUI:getChildByName("list_ability"..i):getChildByName(txtTable[j]):getChildByName("txt"):setString(name.."+"..attrNum)
			self.panelUI:getChildByName("list_ability"..i):getChildByName(txtTable[j]):getChildByName("txt"):setColor(color)
			if self.refreshSharkSpiritAttribute[i].sharkSpiritAttribute[j].max then
				self.panelUI:getChildByName("list_ability"..i):getChildByName("icon_chp"..j):setVisible(true)
			end
		end
	end

	self.panelUI:getChildByName("txt_elesoul9"):getChildByName("txt"):setString(getTextByKey("spirit_refresh10_title"))
	self.panelUI:getChildByName("txt_elesoul10"):getChildByName("txt"):setString(getTextByKey("spirit_refresh11_text"))
	self.panelUI:getChildByName("txt_elesoul1"):getChildByName("txt"):setString(SpiritManager.getSpiritName( self.container.spirit ))

	local function onSelect( evt )
		self.selectId = evt.context
		for i=0,1 do
			self.panelUI:getChildByName("list_ability"..i):getChildByName("q_other9_panel"):setVisible(false)
		end
		self.panelUI:getChildByName("list_ability"..self.selectId):getChildByName("q_other9_panel"):setVisible(true)
	end

	for i=0,1 do
		local btn = Button:create(self.panelUI:getChildByName("list_ability"..i))
		btn:addEventListener(Events.kStart, onSelect , i)
	end

	-- 初始选中显示
	onSelect({context = self.selectId})

	local function onCorform( evt )
		local function onSelectSucceedResponse( e )
			self.container.spirit.lockAttributeIndex = self.container.lockId
			if self.container.lockId ~= 0 then
				local pos = (self.container.lockId == 1) and 2 or 1
				self.container.spirit.sharkSpiritAttributes[pos] = self.refreshSharkSpiritAttribute[self.selectId].sharkSpiritAttribute[pos]
				local spiritData = DataManager.getSpiritsData()
				for k,v in pairs(spiritData) do
					if v.spiritId == self.container.spirit.spiritId then
						spiritData[k] = self.container.spirit
					end
				end
				DataManager.setSpiritsData(spiritData)
				self.container:refreshAllUI(true)
			else
				for i=1,2 do
		  			self.container.spirit.sharkSpiritAttributes[i] = self.refreshSharkSpiritAttribute[self.selectId].sharkSpiritAttribute[i]
		  		end
		  		local spiritData = DataManager.getSpiritsData()
		  		for k,v in pairs(spiritData) do
		  			if v.spiritId == self.container.spirit.spiritId then
		  				spiritData[k] = self.container.spirit
		  			end
		  		end
		  		DataManager.setSpiritsData(spiritData)
		  		self.container:refreshAllUI(true)
			end
			local gameInitData = DataManager.getGameInitData()
		    if gameInitData.sharkSpirits.unsaveSpiritAttributes ~= nil and #gameInitData.sharkSpirits.unsaveSpiritAttributes ~= 0 then
		    	gameInitData.sharkSpirits.unsaveSpiritAttributes = nil
		    	DataManager.setGameInitData(gameInitData)
		    end
		    
			--显示战斗力更新 FIGHT_CAPACITY_MODIFY by zheng.che @ 2014-12-22
			DataManager.fightCapacityMaybeUpdated()
			
			self.container:setTableViewsEnabled(true)
			PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		end

		local function onSelectFailedResponse( e )
			
		end
		-- if self.selectId == 0 then
		-- 	SuspensionLabel:showContent(self.container, getTextByKey("spirit_refresh10_tips"))
		-- 	return
		-- end
		local params  = {spiritId = self.container.spirit.spiritId , refreshIndex = self.selectId - 1}
		SelectSubAttributeRequest.sendRequest(params , onSelectSucceedResponse , onSelectFailedResponse)
	end

	local comformBtn = Button:create(self.panelUI:getChildByName("formation_btn_change_captain4"))
	self.panelUI:getChildByName("formation_btn_change_captain4"):getChildByName("txt"):setString(getTextByKey("activity_fireworks_sure"))
	comformBtn:addEventListener(Events.kStart, onCorform)

	self:addChild(self.panelUI)
end