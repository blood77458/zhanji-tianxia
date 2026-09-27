GetTenEleSoulPanel = class(Layer)

function GetTenEleSoulPanel:ctor()
    self.container = nil
	self.soulInfo = {}
end

function GetTenEleSoulPanel:create( container ,soulInfo, onceAgainBtnData ,onceAgainFunc)
    local s = GetTenEleSoulPanel.new()
    s.container = container
    s.onceAgainBtnData = onceAgainBtnData
    s.callBackFunc = onceAgainFunc
    s.soulInfo = soulInfo
    s:initLayer()
    return s
end

function GetTenEleSoulPanel:initLayer()
	self.container:setTableViewsEnabled(false)
    GetTenEleSoulPanel.super.initLayer(self)

	local builder = LayoutBuilder:createWithContentsOfFile("scene/destiny_fight.json")
	self.panelUI = builder:build("popup_getelesoul_3")
    
	local spiritPurplePopMaybe = false
	local spiritOrangePopMaybe = false
    local function onClosePanel(evt)
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
        self.container:setTableViewsEnabled(true)
        self.container.targetInfoPanel = nil
		--facebook share first get purple/orange spirt info
		if spiritOrangePopMaybe and FacebookShareManager.facebookShareSpirit(FacebookSpiritShareID.ORANGE) then
			--pop share orange spirit
		elseif spiritPurplePopMaybe and FacebookShareManager.facebookShareSpirit(FacebookSpiritShareID.PURPLE) then
			--pop share  purple spirit
		end 
    end

    local function onOnceAgain(evt)
		onClosePanel()
        if self.callBackFunc and type(self.callBackFunc) == "function" then
            self:callBackFunc()
        end 
    end
	
	self.closeBtn = Button:create(self.panelUI:getChildByName("btn_close"))
	self.closeBtn:addEventListener( Events.kStart, onClosePanel, self ) 
	
	self.sureBtn = Button:create(self.panelUI:getChildByName("btn_cha"))
	self.sureBtn:addEventListener( Events.kStart, onClosePanel, self )

	self.onceAgainBtn = Button:create(self.panelUI:getChildByName("btn_goup1"))
	self.onceAgainBtn:addEventListener( Events.kStart, onOnceAgain, self )

	self.panelUI:getChildByName("txt_selectmain_info"):getChildByName("txt"):setString(getTextByKey("spiritConcentrate_successText"))
	self.panelUI:getChildByName("btn_cha"):getChildByName("txt"):setString(getTextByKey("yes"))
	self.panelUI:getChildByName("btn_goup1"):getChildByName("txt"):setString(self.onceAgainBtnData.text)

	if self.onceAgainBtnData.unable then
		self.onceAgainBtn:setEnable(false)
		self.onceAgainBtn.display:getChildByName("btn"):setVisible(false)
	end
	
	for i=1,10 do
		local soulItem = self.panelUI:getChildByName("item_"..i)

		local params = {}
		params.sourceDisplay = soulItem:getChildByName("common_normal_card_small_sb")
		params.showInCenter = true
		params.sourceSizes = {108,108}

		local icon = CanonGoodIcon.createGoodIcon(ResourceEnum.SPIRIT, self.soulInfo[i].metaId, 0, params)
		soulItem:addChildAt(icon,1)

		soulItem:getChildByName("common_txt_item_name"):getChildByName("txt_item_name"):setString(SpiritManager.getSpiritName(self.soulInfo[i]))
		
		-- local spiritType = SpiritManager.getMainAttributeName(self.soulInfo[i])
		-- local spiritVale = SpiritManager.getSingleAttributeValue(self.soulInfo[i])
		-- soulItem:getChildByName("common_txt_item_quantity"):getChildByName("txt_item_quantity"):setString(spiritType .. " +".. spiritVale)
		
		if MetaManager.spirit_meta[self.soulInfo[i].metaId].rarity == 4 then
			spiritPurplePopMaybe = true
		end
		if MetaManager.spirit_meta[self.soulInfo[i].metaId].rarity == 5 then
			spiritOrangePopMaybe = true
		end
	end
	
	self:addChild(self.panelUI)
end