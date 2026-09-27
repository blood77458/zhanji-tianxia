GetEleSoulPanel = class(Layer)

function GetEleSoulPanel:ctor()
    self.container = nil
	self.soulInfo = {}
end

function GetEleSoulPanel:create( container ,soulInfo,callBackFunc)
    self.container = container
    self.callBackFunc = callBackFunc

    local s = GetEleSoulPanel.new()
    s.soulInfo = soulInfo
    s:initLayer()
    return s
end



function GetEleSoulPanel:initLayer()
	self.container:setTableViewsEnabled(false)
	
    GetEleSoulPanel.super.initLayer(self)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/destiny_fight.json")
	self.panelUI = builder:build("popup_getelesoul_1")
	
	if #self.soulInfo == 1 then
	--	self.panelUI = builder:build("popup_getelesoul_1")
	elseif #self.soulInfo == 2 then
		self.panelUI = builder:build("popup_getelesoul_2")
	end
    
	--if self.panelUI == nil then
	--	return
	--end
    
	local spiritPurplePopMaybe = false
	local spiritOrangePopMaybe = false
    local function onClosePanel(evt)
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
        self.container:setTableViewsEnabled(true)
        self.container.targetInfoPanel = nil
		--facebook share first get purple/orange spirt info
		if spiritOrangePopMaybe and FacebookShareManager.facebookShareSpirit(FacebookSpiritShareID.ORANGE,self.callBackFunc) then
			--pop share orange spirit
		elseif spiritPurplePopMaybe and FacebookShareManager.facebookShareSpirit(FacebookSpiritShareID.PURPLE,self.callBackFunc) then
			--pop share  purple spirit
		else
			if self.callBackFunc and type(self.callBackFunc) == "function" then
				self:callBackFunc()
			end 
		end 
        --if self.callBackFunc and type(self.callBackFunc) == "function" then
        --    self:callBackFunc()
        --end 
    end 
	
	self.closeBtn = Button:create(self.panelUI:getChildByName("btn_close"))
	self.closeBtn:addEventListener( Events.kStart, onClosePanel, self ) 
	
	self.sureBtn = Button:create(self.panelUI:getChildByName("btn_cha"))
	self.sureBtn:addEventListener( Events.kStart, onClosePanel, self ) 
    --init UI
	self.panelUI:getChildByName("txt_selectmain_info"):getChildByName("txt"):setString(getTextByKey("spiritConcentrate_successText"))
	self.panelUI:getChildByName("btn_cha"):getChildByName("txt"):setString(getTextByKey("yes"))
	
	for i = 1,#self.soulInfo do
		local soulItem = self.panelUI:getChildByName("list_getelesoul_"..i)
		soulItem:getChildByName("formation_txt_lv_num"):getChildByName("font"):setString(self.soulInfo[i].level)
		soulItem:getChildByName("txt_elesoul2"):getChildByName("txt"):setString(SpiritManager.getSpiritName( self.soulInfo[i] ))
		local spiritType = SpiritManager.getMainAttributeName( self.soulInfo[i] )
		local spiritVale = SpiritManager.getSingleAttributeValue( self.soulInfo[i] )
		soulItem:getChildByName("txt_elesoul1"):getChildByName("txt"):setString(spiritType .. " +".. spiritVale)
		local icon = CanonGoodIcon.createGoodIcon(ResourceEnum.SPIRIT, self.soulInfo[i].metaId, 0, nil)
		icon:setScale(0.9)
		icon:setPosition(ccp(soulItem:getChildByName("normal_card_small"):getPositionX() ,
							 soulItem:getChildByName("normal_card_small"):getPositionY() ))
		soulItem:addChild(icon)
		soulItem:getChildByName("normal_card_small"):setVisible(false)
		
		if MetaManager.spirit_meta[self.soulInfo[i].metaId].rarity == 4 then
			spiritPurplePopMaybe = true
		end
		if MetaManager.spirit_meta[self.soulInfo[i].metaId].rarity == 5 then
			spiritOrangePopMaybe = true
		end
	end
	
	self:addChild(self.panelUI)
end