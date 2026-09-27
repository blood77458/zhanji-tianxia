require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

BackPackSortPanel = class(Layer)

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

local queueData = {}--出战&上阵卡牌

local function isCardInBattle(card)
	if card.isInBattle == nil or card.isLeaderCard == nil or card.isInMatrix then
		local isLeaderCard = false;
		card.isInBattle = false;
		card.isLeaderCard = false
		card.isInMatrix = false
		if queueData[card.cardId] then
			if queueData[card.cardId] == 1 then
				card.isLeaderCard = true;
				card.isInBattle = true;
			elseif queueData[card.cardId] > 100 then--isInMatrix
				card.isInMatrix = true
			else
				card.isInBattle = true;
			end
		end
	end
	return card.isInBattle,card.isLeaderCard, card.isInMatrix
end

function BackPackSortPanel:ctor()
	self.container = nil
end

function BackPackSortPanel:create( container  , argvs)
	local s = BackPackSortPanel.new()
	s.argvs = argvs
	s.container = container
	s:initLayer()
	queueData = argvs.queueData
	return s
end

function BackPackSortPanel:initLayer()
	if type(self.container.setTableViewsEnabled) == "function" then
		self.container:setTableViewsEnabled(false)
	end
	BackPackSortPanel.super.initLayer(self)

	self.showInBattleCards = HeMemDataHolder:getString("notShowInBattleCards")
	self.notShowCountryCards = HeMemDataHolder:getInteger("notShowCountryCards")
	
	local builder = LayoutBuilder:createWithContentsOfFile("scene/package_new.json")
	builder.useArtLabelTTF = true
	self.panelUI = builder:build("popup/popup_package_sort_card")
    
    
	if self.showInBattleCards == "" or self.showInBattleCards == "false" then
		self.panelUI:getChildByName("btn_checkbox"):getChildByName("package_icon_checkbox_sb"):setVisible(false)
		self.panelUI:getChildByName("btn_checkbox"):getChildByName("package_bg_checkbox_sb"):setVisible(true)
	else
		self.panelUI:getChildByName("btn_checkbox"):getChildByName("package_icon_checkbox_sb"):setVisible(true)
		self.panelUI:getChildByName("btn_checkbox"):getChildByName("package_bg_checkbox_sb"):setVisible(false)
	end

	--显示x国卡牌
	self.panelUI:getChildByName("txt_packagesort_1"):getChildByName("txt"):setString(getTextByKey("cardInfo_showcountry1"))
	self.panelUI:getChildByName("txt_packagesort_3"):getChildByName("txt"):setString(getTextByKey("cardInfo_showcountry2"))
	self.panelUI:getChildByName("txt_packagesort_4"):getChildByName("txt"):setString(getTextByKey("cardInfo_showcountry3"))
	self.panelUI:getChildByName("txt_packagesort_5"):getChildByName("txt"):setString(getTextByKey("cardInfo_showcountry4"))
	local function checkShowCountryCards(state)
		local tempState = state
		for i = 1,4 do 
			local num = BitOperManager:_shl(1,i-1,4)
			if BitOperManager:_and(state,num,4) ~= 0 then 
				self.panelUI:getChildByName("btn_checkbox"..i):getChildByName("package_icon_checkbox_sb"):setVisible(false)
				self.panelUI:getChildByName("btn_checkbox"..i):getChildByName("package_bg_checkbox_sb"):setVisible(true)
			else
				self.panelUI:getChildByName("btn_checkbox"..i):getChildByName("package_icon_checkbox_sb"):setVisible(true)
				self.panelUI:getChildByName("btn_checkbox"..i):getChildByName("package_bg_checkbox_sb"):setVisible(false)
			end
		end
	end
	checkShowCountryCards(self.notShowCountryCards)

	local function onSelectSortWithCheckBtn()
		if self.showInBattleCards ~= HeMemDataHolder:getString("notShowInBattleCards") then
			if HeMemDataHolder:getString("notShowInBattleCards") == "true" then
				local tempTable = {}
				for k,v in pairs(self.container.card_data) do
					local isAInBattle, isALeaderCard, isAInMatirx = isCardInBattle(v)
					if isAInBattle == false and isAInMatirx == false then
						table.insert(tempTable , v)
					end
				end
				for i = #self.container.card_data, 1, -1 do
					table.remove(self.container.card_data, i)
				end
				for k,v in pairs(tempTable) do
					table.insert(self.container.card_data , v)
				end
				-- self.container:refreshTable(false)
			else
				-- self.container.card_data = {}
				for i = #self.container.card_data, 1, -1 do
					table.remove(self.container.card_data, i)
				end
				if self.container.argv.params.filter ~=nil and self.container.argv.params.filter==BACKPACK_FILTER.CARD then 
		            local id_list = self.container.argv.params.filterFunc(DataManager.getCardsData())
		            for k,v in pairs(id_list) do
						table.insert(self.container.card_data , v)
					end
				else
					for k,v in pairs(DataManager.getCardsData()) do
						table.insert(self.container.card_data , v)
					end
		        end

				-- sort({context = SORT_TYPE.RARE_ASC})
				-- self.container:refreshTable(false)
				for i,card in pairs(self.container.card_data) do 
			        --计算卡牌攻，防，血
			        --稀有度
			        self.container.card_data[i].rare = MetaManager.card_meta[card.metaId].rare
					isCardInBattle(self.container.card_data[i])
			    end 
			    self.container.noCardText:setVisible(#self.container.card_data == 0)
			end
		end

		--显示x国卡牌的状态改变时
		if self.notShowCountryCards ~= HeMemDataHolder:getInteger("notShowCountryCards") then
			self.notShowCountryCards = HeMemDataHolder:getInteger("notShowCountryCards")
			for i = #self.container.card_data, 1, -1 do
				local isAInBattle, isALeaderCard, isAInMatirx = isCardInBattle(self.container.card_data[i])
				if isAInBattle == false and isAInMatirx == false then
					table.remove(self.container.card_data, v)
				end
			end
			for k,v in pairs(DataManager.getCardsData()) do
				local num = BitOperManager:_shl(1,MetaManager.card_meta[v.metaId].country-1,4)
				local isAInBattle, isALeaderCard, isAInMatirx = isCardInBattle(v)
				if isAInBattle == false and isAInMatirx == false then
					if  BitOperManager:_and(num,self.notShowCountryCards) == 0 then
						table.insert(self.container.card_data,v)
					end
				end
			end
			for i,card in pairs(self.container.card_data) do 
		        --计算卡牌攻，防，血
		        --稀有度
		        self.container.card_data[i].rare = MetaManager.card_meta[card.metaId].rare
				isCardInBattle(self.container.card_data[i])
		    end 
		    self.container.noCardText:setVisible(#self.container.card_data == 0)
		end
	end

	local function onTouchLayerWithCheckBtn( )
		if self.showInBattleCards ~= HeMemDataHolder:getString("notShowInBattleCards") then
			if HeMemDataHolder:getString("notShowInBattleCards") == "true" then
				local tempTable = {}
				for k,v in pairs(self.container.card_data) do
					local isAInBattle, isALeaderCard, isAInMatirx = isCardInBattle(v)
					if isAInBattle == false and isAInMatirx == false then
						table.insert(tempTable , v)
					end
				end
				for i = #self.container.card_data, 1, -1 do
					table.remove(self.container.card_data, i)
				end
				for k,v in pairs(tempTable) do
					table.insert(self.container.card_data , v)
				end
				self.container:refreshTable(false)
			else
				-- self.container.card_data = {}
				for i = #self.container.card_data, 1, -1 do
					table.remove(self.container.card_data, i)
				end
				if self.container.argv.params.filter ~=nil and self.container.argv.params.filter==BACKPACK_FILTER.CARD then 
		            local id_list = self.container.argv.params.filterFunc(DataManager.getCardsData())
		            for k,v in pairs(id_list) do
						table.insert(self.container.card_data , v)
					end
				else
					for k,v in pairs(DataManager.getCardsData()) do
						table.insert(self.container.card_data , v)
					end
		        end
			    for i,card in pairs(self.container.card_data) do 
			        --计算卡牌攻，防，血
			        --稀有度
			        self.container.card_data[i].rare = MetaManager.card_meta[card.metaId].rare
					isCardInBattle(self.container.card_data[i])
			    end 
			    if HeMemDataHolder:getString("savedSortOrder_card") == "" then
					self.argvs.sortFunc({context = SORT_TYPE.RARE_ASC})
				else
					self.argvs.sortFunc({context = tonumber(HeMemDataHolder:getString("savedSortOrder_card"))})
				end
				
				self.container:refreshTable(false)
				self.container.noCardText:setVisible(#self.container.card_data == 0)
			end
		end

		--显示x国卡牌的状态改变时
		if self.notShowCountryCards ~= HeMemDataHolder:getInteger("notShowCountryCards") then
			print(self.notShowCountryCards,HeMemDataHolder:getInteger("notShowCountryCards"))
			self.notShowCountryCards = HeMemDataHolder:getInteger("notShowCountryCards")
			for i = #self.container.card_data, 1, -1 do
				local isAInBattle, isALeaderCard, isAInMatirx = isCardInBattle(self.container.card_data[i])
				if isAInBattle == false and isAInMatirx == false then
					table.remove(self.container.card_data, v)
				end
			end
			for k,v in pairs(DataManager.getCardsData()) do
				--if k == 1 then print(tostringRich(MetaManager.card_meta[v.metaId])) end
				local num = BitOperManager:_shl(1,MetaManager.card_meta[v.metaId].country-1,4)
				local isAInBattle, isALeaderCard, isAInMatirx = isCardInBattle(v)
				if isAInBattle == false and isAInMatirx == false then
					if  BitOperManager:_and(num,self.notShowCountryCards) == 0 then
						table.insert(self.container.card_data,v)
					end
				end
			end
			for i,card in pairs(self.container.card_data) do 
		        --计算卡牌攻，防，血
		        --稀有度
		        self.container.card_data[i].rare = MetaManager.card_meta[card.metaId].rare
				isCardInBattle(self.container.card_data[i])
		    end 
		    if HeMemDataHolder:getString("savedSortOrder_card") == "" then
				self.argvs.sortFunc({context = SORT_TYPE.RARE_ASC})
			else
				self.argvs.sortFunc({context = tonumber(HeMemDataHolder:getString("savedSortOrder_card"))})
			end

		    self.container:refreshTable(false)
		    self.container.noCardText:setVisible(#self.container.card_data == 0)
		end

	end

		-- 关闭Panel事件
	local function onClosePanel(evt)
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
	"cardInfo_Attack1",
	"cardInfo_Attack1",
	"cardInfo_Defense1",
	"cardInfo_Defense1",
	"cardInfo_HP1",
	"cardInfo_HP1",
}

	for i=1,10 do
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

	--显示x国武将btn
	local function onCheckCountryBtn(evt)
		local countryId = evt.context
		local num = BitOperManager:_shl(1,countryId-1,4)
		local notShowCountryCards = HeMemDataHolder:getInteger("notShowCountryCards")
		if BitOperManager:_and(notShowCountryCards,num,4) ~= 0 then
			HeMemDataHolder:setInteger("notShowCountryCards" , notShowCountryCards - num)
			self.panelUI:getChildByName("btn_checkbox"..countryId):getChildByName("package_icon_checkbox_sb"):setVisible(true)
			self.panelUI:getChildByName("btn_checkbox"..countryId):getChildByName("package_bg_checkbox_sb"):setVisible(false)
		else
			HeMemDataHolder:setInteger("notShowCountryCards" , notShowCountryCards + num)
			self.panelUI:getChildByName("btn_checkbox"..countryId):getChildByName("package_icon_checkbox_sb"):setVisible(false)
			self.panelUI:getChildByName("btn_checkbox"..countryId):getChildByName("package_bg_checkbox_sb"):setVisible(true)
		end
	end

	for i = 1,4 do 
		local btn = Button:create(self.panelUI:getChildByName("btn_checkbox"..i))
		btn:addEventListener(Events.kStart, onCheckCountryBtn ,i)
	end

	local function onCheckBoxBtn( evt )
		local showInBattleCards = HeMemDataHolder:getString("notShowInBattleCards")
		if showInBattleCards == "" or showInBattleCards == "false" then
			HeMemDataHolder:setString("notShowInBattleCards" , "true")
			self.panelUI:getChildByName("btn_checkbox"):getChildByName("package_icon_checkbox_sb"):setVisible(true)
			self.panelUI:getChildByName("btn_checkbox"):getChildByName("package_bg_checkbox_sb"):setVisible(false)
		else
			HeMemDataHolder:setString("notShowInBattleCards" , "false")
			self.panelUI:getChildByName("btn_checkbox"):getChildByName("package_icon_checkbox_sb"):setVisible(false)
			self.panelUI:getChildByName("btn_checkbox"):getChildByName("package_bg_checkbox_sb"):setVisible(true)
		end
	end

	local checkBoxBtn = Button:create(self.panelUI:getChildByName("btn_checkbox"))
	checkBoxBtn:addEventListener(Events.kStart, onCheckBoxBtn )

	self.panelUI:getChildByName("txt_packagesort_2"):getChildByName("txt"):setString(getTextByKey("bagSort_EquipmentCard"))

	local function onTouchLayer( evt )
		onTouchLayerWithCheckBtn()
		onClosePanel()
	end

    local closeLayerBtn = Button:create(self.panelUI:getChildByName("space"))
    closeLayerBtn:addEventListener(Events.kStart, onTouchLayer )
	
	self:addChild(self.panelUI)
end
