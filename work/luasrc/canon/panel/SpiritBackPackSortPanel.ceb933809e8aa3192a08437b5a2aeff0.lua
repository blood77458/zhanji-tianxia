require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

SpiritBackPackSortPanel = class(Layer)

local SORT_TYPE = table.const{
	RARE_ASC = 1,
	RARE_DESC = 2,
	LV_ASC = 3,
	LV_DESC = 4,
	ATK_ASC = 5,
	ATK_DESC = 6,
	DEF_ASC = 7,
	DEF_DESC = 8,
	HP_ASC = 9,
	HP_DESC = 10,
}


function SpiritBackPackSortPanel:ctor()
	self.container = nil
end

function SpiritBackPackSortPanel:create( container  , argvs)
	local s = SpiritBackPackSortPanel.new()
	s.argvs = argvs
	s.container = container
	s:initLayer()
	return s
end

function SpiritBackPackSortPanel:initLayer()
	if type(self.container.setTableViewsEnabled) == "function" then
		self.container:setTableViewsEnabled(false)
	end
	SpiritBackPackSortPanel.super.initLayer(self)

	self.notShowEquipedItems = nil
	if self.argvs.enterType == "BackPackScene" then
		self.notShowEquipedItems = HeMemDataHolder:getString("notShowEquipedItems")
	elseif self.argvs.enterType == "SpiritBackPackScene" then
		self.notShowEquipedItems = HeMemDataHolder:getString("notShowEquipedSpirits")
	elseif self.argvs.enterType == "TreasureBackPackScene" then
		self.notShowEquipedItems = HeMemDataHolder:getString("notShowEquipedTreasure")
	end
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/package_new.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup/popup_package_sort_equipment")

	if self.notShowEquipedItems == "" or self.notShowEquipedItems == "false" then
		self.panelUI:getChildByName("btn_checkbox"):getChildByName("package_icon_checkbox_sb"):setVisible(false)
		self.panelUI:getChildByName("btn_checkbox"):getChildByName("package_bg_checkbox_sb"):setVisible(true)
	else
		self.panelUI:getChildByName("btn_checkbox"):getChildByName("package_icon_checkbox_sb"):setVisible(true)
		self.panelUI:getChildByName("btn_checkbox"):getChildByName("package_bg_checkbox_sb"):setVisible(false)
	end

	local function onSelectSortWithCheckBtn( )
		local notShowEquipedItems
		if self.argvs.enterType == "BackPackScene" then
			notShowEquipedItems = HeMemDataHolder:getString("notShowEquipedItems")
		elseif self.argvs.enterType == "SpiritBackPackScene" then
			notShowEquipedItems = HeMemDataHolder:getString("notShowEquipedSpirits")
		elseif self.argvs.enterType == "TreasureBackPackScene" then
			notShowEquipedItems = HeMemDataHolder:getString("notShowEquipedTreasure")
		end
		if self.notShowEquipedItems ~= notShowEquipedItems then
			if self.argvs.enterType == "BackPackScene" then
				if notShowEquipedItems == "true" then
					local tempTable = {}
					for k,v in pairs(self.container.equip_data) do
						if v.cardId == 0 then
							table.insert(tempTable , v)
						end
					end
					for i = #self.container.equip_data, 1, -1 do
						table.remove(self.container.equip_data, i)
					end
					for k,v in pairs(tempTable) do
						table.insert(self.container.equip_data , v)
					end
				else
					-- self.container.equip_data = DataManager.getEquipsData()
					for i = #self.container.equip_data, 1, -1 do
						table.remove(self.container.equip_data, i)
					end
					if self.container.argv.params.filter ~=nil and self.container.argv.params.filter==BACKPACK_FILTER.EQUIP then 
			            local id_list = self.container.argv.params.filterFunc(DataManager.getEquipsData())
			            for k,v in pairs(id_list) do
							table.insert(self.container.equip_data , v)
						end
					else
						for k,v in pairs(DataManager.getEquipsData()) do
							table.insert(self.container.equip_data , v)
						end
			        end
					for i,equip in pairs(self.container.equip_data) do
				        self.container.equip_data[i].quality  = MetaManager.equip_meta[equip.metaId].quality
						self.container.equip_data[i].price = MetaManager.equip_meta[self.container.equip_data[i].metaId].sellPriceCoe * MetaManager.equip_level[self.container.equip_data[i].level].sellPriceBase
				    end
				    self.container.noEquipText:setVisible(#self.container.equip_data == 0)
				end
			elseif self.argvs.enterType == "SpiritBackPackScene" then
				if notShowEquipedItems == "true" then
					local tempTable = {}
					for k,v in pairs(self.container.spirit_data) do
						if v.cardId == 0 then
							table.insert(tempTable , v)
						end
					end
					for i = #self.container.spirit_data, 1, -1 do
						table.remove(self.container.spirit_data, i)
					end
					for k,v in pairs(tempTable) do
						table.insert(self.container.spirit_data , v)
					end
					-- self.container:refreshTable(false)
				else
					-- self.container.card_data = {}
					for i = #self.container.spirit_data, 1, -1 do
						table.remove(self.container.spirit_data, i)
					end
					if self.container.argv.params.filterFunc ~=nil then 
			            local id_list = self.container.argv.params.filterFunc(DataManager.getSpiritsData())
			            for k,v in pairs(id_list) do
							table.insert(self.container.spirit_data , v)
						end
					else
						for k,v in pairs(DataManager.getSpiritsData()) do
							table.insert(self.container.spirit_data , v)
						end
			        end
					-- for k,v in pairs(DataManager.getSpiritsData()) do
					-- 	table.insert(self.container.spirit_data , v)
					-- end
					for i,spirit in pairs(self.container.spirit_data) do
				        self.container.spirit_data[i].quality  = MetaManager.spirit_meta[spirit.metaId].rarity
						-- SELF.spirit_data[i].price = MetaManager.spirit_meta[SELF.equip_data[i].metaId].sellPriceCoe * MetaManager.equip_level[SELF.equip_data[i].level].sellPriceBase
				    end
				end
			elseif self.argvs.enterType == "TreasureBackPackScene" then
				if notShowEquipedItems == "true" then
					local tempTable = {}
					for k,v in pairs(self.container.treasure_data) do
						if v.cardId == 0 then
							table.insert(tempTable , v)
						end
					end
					for i = #self.container.treasure_data, 1, -1 do
						table.remove(self.container.treasure_data , i)
					end
					for k,v in pairs(tempTable) do
						table.insert(self.container.treasure_data , v)
					end
				else
					for i = #self.container.treasure_data, 1, -1 do
						table.remove(self.container.treasure_data, i)
					end
					if self.container.argv.params.filterFunc ~=nil then 
			            local id_list = self.container.argv.params.filterFunc(DataManager.getTreasuresData())
			            for k,v in pairs(id_list) do
							table.insert(self.container.treasure_data , v)
						end
					else
						for k,v in pairs(DataManager.getTreasuresData()) do
							table.insert(self.container.treasure_data , v)
						end
			        end
					for i,treasure in pairs(self.container.treasure_data) do
				        self.container.treasure_data[i].quality  = MetaManager.treasure_meta[treasure.metaId].rare
				    end
				end
			end
		end
	end

	local function onTouchLayerWithCheckBtn( )
		local notShowEquipedItems
		if self.argvs.enterType == "BackPackScene" then
			notShowEquipedItems = HeMemDataHolder:getString("notShowEquipedItems")
		elseif self.argvs.enterType == "SpiritBackPackScene" then
			notShowEquipedItems = HeMemDataHolder:getString("notShowEquipedSpirits")
		elseif self.argvs.enterType == "TreasureBackPackScene" then
			notShowEquipedItems = HeMemDataHolder:getString("notShowEquipedTreasure")
		end
		print(self.notShowEquipedItems,notShowEquipedItems,"notShowEquipedTreasure")
		if self.notShowEquipedItems ~= notShowEquipedItems then
			print("jjjj")
			if self.argvs.enterType == "BackPackScene" then
				if notShowEquipedItems == "true" then
					local tempTable = {}
					for k,v in pairs(self.container.equip_data) do
						if v.cardId == 0 then
							table.insert(tempTable , v)
						end
					end
					for i = #self.container.equip_data, 1, -1 do
						table.remove(self.container.equip_data, i)
					end
					for k,v in pairs(tempTable) do
						table.insert(self.container.equip_data , v)
					end
					self.container:refreshTable(false)
				else
					-- self.container.card_data = {}
					for i = #self.container.equip_data, 1, -1 do
						table.remove(self.container.equip_data, i)
					end
					if self.container.argv.params.filter ~=nil and self.container.argv.params.filter==BACKPACK_FILTER.EQUIP then 
			            local id_list = self.container.argv.params.filterFunc(DataManager.getEquipsData())
			            for k,v in pairs(id_list) do
							table.insert(self.container.equip_data , v)
						end
					else
						for k,v in pairs(DataManager.getEquipsData()) do
							table.insert(self.container.equip_data , v)
						end
			        end
					-- for k,v in pairs(DataManager.getEquipsData()) do
					-- 	table.insert(self.container.equip_data , v)
					-- end
				    for i,equip in pairs(self.container.equip_data) do
				        self.container.equip_data[i].quality  = MetaManager.equip_meta[equip.metaId].quality
						self.container.equip_data[i].price = MetaManager.equip_meta[self.container.equip_data[i].metaId].sellPriceCoe * MetaManager.equip_level[self.container.equip_data[i].level].sellPriceBase
				    end
				    if HeMemDataHolder:getString("savedSortOrder_equip") == "" then
						self.argvs.sortFunc({context = SORT_TYPE.RARE_ASC})
					else
						self.argvs.sortFunc({context = tonumber(HeMemDataHolder:getString("savedSortOrder_equip"))})
					end
					
					self.container:refreshTable(false)
					self.container.noEquipText:setVisible(#self.container.equip_data == 0)
				end
			elseif self.argvs.enterType == "SpiritBackPackScene" then
				if notShowEquipedItems == "true" then
					local tempTable = {}
					for k,v in pairs(self.container.spirit_data) do
						if v.cardId == 0 then
							table.insert(tempTable , v)
						end
					end
					for i = #self.container.spirit_data, 1, -1 do
						table.remove(self.container.spirit_data, i)
					end
					for k,v in pairs(tempTable) do
						table.insert(self.container.spirit_data , v)
					end

					self.container:refreshTable(false)
				else
					-- self.container.card_data = {}
					for i = #self.container.spirit_data, 1, -1 do
						table.remove(self.container.spirit_data, i)
					end
					if self.container.argv.params.filterFunc ~=nil then 
			            local id_list = self.container.argv.params.filterFunc(DataManager.getSpiritsData())
			            print(table.tostring(id_list))
			            for k,v in pairs(id_list) do
							table.insert(self.container.spirit_data , v)
						end
					else
						for k,v in pairs(DataManager.getSpiritsData()) do
							table.insert(self.container.spirit_data , v)
						end
			        end
				    for i,spirit in pairs(self.container.spirit_data) do
				        self.container.spirit_data[i].quality  = MetaManager.spirit_meta[spirit.metaId].rarity
						-- SELF.spirit_data[i].price = MetaManager.spirit_meta[SELF.equip_data[i].metaId].sellPriceCoe * MetaManager.equip_level[SELF.equip_data[i].level].sellPriceBase
				    end
				    if HeMemDataHolder:getString("savedSortOrder_spirit") == "" then
						self.argvs.sortFunc({context = SORT_TYPE.RARE_ASC})
					else
						self.argvs.sortFunc({context = tonumber(HeMemDataHolder:getString("savedSortOrder_spirit"))})
					end
					
					self.container:refreshTable(false)
				end
			elseif self.argvs.enterType == "TreasureBackPackScene" then
				if notShowEquipedItems == "true" then
					local tempTable = {}
					for k,v in pairs(self.container.treasure_data) do
						if v.cardId == 0 then
							table.insert(tempTable , v)
						end
					end
					for i = #self.container.treasure_data, 1, -1 do
						table.remove(self.container.treasure_data , i)
					end
					for k,v in pairs(tempTable) do
						table.insert(self.container.treasure_data , v)
					end
				else
					for i = #self.container.treasure_data, 1, -1 do
						table.remove(self.container.treasure_data, i)
					end
					if self.container.argv.params.filterFunc ~=nil then 
			            local id_list = self.container.argv.params.filterFunc(DataManager.getTreasuresData())
			            for k,v in pairs(id_list) do
							table.insert(self.container.treasure_data , v)
						end
					else
						for k,v in pairs(DataManager.getTreasuresData()) do
							table.insert(self.container.treasure_data , v)
						end
			        end
					for i,treasure in pairs(self.container.treasure_data) do
				        self.container.treasure_data[i].quality  = MetaManager.treasure_meta[treasure.metaId].rare
				    end
				end
				if HeMemDataHolder:getString("savedSortOrder_treasure") == "" then
					self.argvs.sortFunc({context = SORT_TYPE.RARE_ASC})
				else
					self.argvs.sortFunc({context = tonumber(HeMemDataHolder:getString("savedSortOrder_treasure"))})
				end
				self.container:refreshTable(false)
			end
		end
	end

		-- 关闭Panel事件
	local function onClosePanel(evt)

		--没有可显示的元神时提示去凝神 by l1ghtsaber 2015/5/27
		if self.argvs.enterType == "SpiritBackPackScene" then
			if #self.container.spirit_data == 0 then
				self.container.noSpiritText:setVisible(true) 
				self.container.getSpiritDisplay:setVisible(true) 
			else
				self.container.noSpiritText:setVisible(false) 
				self.container.getSpiritDisplay:setVisible(false) 
			end
		end

		if self.argvs.enterType == "TreasureBackPackScene" then
			if #self.container.treasure_data == 0 then
				self.container.noSpiritText:setVisible(true) 
				self.container.getSpiritDisplay:setVisible(true) 
			else
				self.container.noSpiritText:setVisible(false) 
				self.container.getSpiritDisplay:setVisible(false) 
			end
		end

		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale)
		-- self:dismissSelf()
		if type(self.container.setTableViewsEnabled) == "function" then
			self.container:setTableViewsEnabled(true)
		end
	end
    
	local function onSelect( evt )
		self.selectId = evt.context
		onSelectSortWithCheckBtn()
		self.argvs.sortFunc(evt)
		self.container:refreshTable(false)
		onClosePanel()
	end

	--关闭按钮不显示 和旧UI保持逻辑一致 by dangchao --新UI 美术需要关闭按钮的显示 - xiemeilan
    -- self.panelUI:getChildByName("other_solid_gray9_panel"):getChildByName("btn_close"):setVisible(false)
    local checkBoxBtn = Button:create(self.panelUI:getChildByName("other_solid_gray9_panel"):getChildByName("btn_close"))
	checkBoxBtn:addEventListener(Events.kStart, onSelect )

	local strTable = {
	"cardInfo_Rare1",
	"cardInfo_Rare1",
	"cardInfo_Level1",
	"cardInfo_Level1",
}

	for i=1,4 do
		local btn = Button:create(self.panelUI:getChildByName("btn_"..i))
		btn:addEventListener(Events.kStart, onSelect , i)
		if (i % 2) == 1 then
			self.panelUI:getChildByName("btn_"..i):getChildByName("icon_lift2"):setVisible(false)
			self.panelUI:getChildByName("btn_"..i):getChildByName("icon_lift1"):setVisible(true)
		else
			self.panelUI:getChildByName("btn_"..i):getChildByName("icon_lift2"):setVisible(true)
			self.panelUI:getChildByName("btn_"..i):getChildByName("icon_lift1"):setVisible(false)
		end
		self.panelUI:getChildByName("btn_"..i):getChildByName("txt"):getChildByName("txt"):setString(getTextByKey(strTable[i]))
	end

	local function onCheckBoxBtn( evt )
		local notShowEquipedItems
		if self.argvs.enterType == "BackPackScene" then
			notShowEquipedItems = HeMemDataHolder:getString("notShowEquipedItems")
		elseif self.argvs.enterType == "SpiritBackPackScene" then
			notShowEquipedItems = HeMemDataHolder:getString("notShowEquipedSpirits")
		elseif self.argvs.enterType == "TreasureBackPackScene" then
			notShowEquipedItems = HeMemDataHolder:getString("notShowEquipedTreasure")
		end

		if notShowEquipedItems == "" or notShowEquipedItems == "false" then
			if self.argvs.enterType == "BackPackScene" then
				HeMemDataHolder:setString("notShowEquipedItems" , "true")
			elseif self.argvs.enterType == "SpiritBackPackScene" then
				HeMemDataHolder:setString("notShowEquipedSpirits" , "true")
			elseif self.argvs.enterType == "TreasureBackPackScene" then
				HeMemDataHolder:setString("notShowEquipedTreasure" , "true")
			end
			-- HeMemDataHolder:setString("notShowEquipedItems" , "true")
			self.panelUI:getChildByName("btn_checkbox"):getChildByName("package_icon_checkbox_sb"):setVisible(true)
			self.panelUI:getChildByName("btn_checkbox"):getChildByName("package_bg_checkbox_sb"):setVisible(false)
		else
			if self.argvs.enterType == "BackPackScene" then
				HeMemDataHolder:setString("notShowEquipedItems" , "false")
			elseif self.argvs.enterType == "SpiritBackPackScene" then
				HeMemDataHolder:setString("notShowEquipedSpirits" , "false")
			elseif self.argvs.enterType == "TreasureBackPackScene" then
				HeMemDataHolder:setString("notShowEquipedTreasure" , "false")
			end
			-- HeMemDataHolder:setString("notShowEquipedItems" , "false")
			self.panelUI:getChildByName("btn_checkbox"):getChildByName("package_icon_checkbox_sb"):setVisible(false)
			self.panelUI:getChildByName("btn_checkbox"):getChildByName("package_bg_checkbox_sb"):setVisible(true)
		end
	end

	local checkBoxBtn = Button:create(self.panelUI:getChildByName("btn_checkbox"))
	checkBoxBtn:addEventListener(Events.kStart, onCheckBoxBtn )

	if self.argvs.enterType == "BackPackScene" then
		self.panelUI:getChildByName("txt_packagesort_2"):getChildByName("txt"):setString(getTextByKey("bagSort_EquipmentItem"))
	elseif self.argvs.enterType == "SpiritBackPackScene" then
		self.panelUI:getChildByName("txt_packagesort_2"):getChildByName("txt"):setString(getTextByKey("bagSort_EquipmentSpiri"))
	elseif self.argvs.enterType == "TreasureBackPackScene" then
		self.panelUI:getChildByName("txt_packagesort_2"):getChildByName("txt"):setString(getTextByKey("Treasure_text_34"))
	end
	
	local function onTouchLayer( evt )
		onTouchLayerWithCheckBtn()
		onClosePanel()
	end

    local closeLayerBtn = Button:create(self.panelUI:getChildByName("space"))
    closeLayerBtn:addEventListener(Events.kStart, onTouchLayer )
	
	self:addChild(self.panelUI)
end
