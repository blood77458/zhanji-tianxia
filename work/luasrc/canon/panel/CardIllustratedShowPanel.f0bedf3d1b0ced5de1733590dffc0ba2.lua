--------------------------------------------------------------------------------
-- CardIllustratedShowPanel.lua - card illustrated show panel卡牌图鉴显示面板
-- author: dang chao
-- updated: 2013-09-18
--------------------------------------------------------------------------------

require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.data.MetaManager"
require "canon.models.CommonManager"
require "canon.customUI.CanonItem"

CardIllustratedShowPanel = class(Layer)

function CardIllustratedShowPanel:ctor()
    self.container = nil
    self.metaId = nil
	self.showSkillInfo = false
end

function CardIllustratedShowPanel:create( container ,isShowInfoBtn, metaId , argv)
    self.container = container
    self.metaId = metaId or self.container._data.id
    self.argv = argv
	if isShowInfoBtn ~= nil then
		self.isShowInfoBtn = isShowInfoBtn
	else
		self.isShowInfoBtn = true
	end 
    local s = CardIllustratedShowPanel.new()
    s:initLayer()
    return s
end

function CardIllustratedShowPanel:initLayer()
	local cardMeta = MetaManager.card_meta[self.metaId]
    CardIllustratedShowPanel.super.initLayer(self)
		
	local builder = LayoutBuilder:createWithContentsOfFile("scene/illustrated_new.json")
    self.panelUI = builder:build("illustrated_bg_illustrated_cardinfo")
    local cardInfoBoxScaleY = 5.5
    self.panelUI:getChildByName("cardinfo_box"):setScaleY(cardInfoBoxScaleY)
    local isCardInfoBtnClick = false
    local function showCardSkillInfo(isShow)
	    self.showSkillInfo = isShow
    	self.panelUI:getChildByName("cardinfo_box"):setVisible(isShow)
		self.panelUI:getChildByName("btn_add_reduce"):getChildByName("btn_plus"):setVisible(not isShow)
		self.panelUI:getChildByName("btn_add_reduce"):getChildByName("btn_reduce"):setVisible(isShow)
		--for i = 1,8 do 
		--    self.panelUI:getChildByName("txt_skillinfo"..i):getChildByName("txt_skillinfo"):setVisible(isShow)
	    --end 
        --self.panelUI:getChildByName("txt_cardinfo"):getChildByName("txt_cardinfo"):setVisible(isShow)
    end 
    local function onClickCardInfo(e)
        isCardInfoBtnClick = true
        if self.showSkillInfo then
			showCardSkillInfo(false)
		else
			showCardSkillInfo(true)
		end
    end    
    local function onClosePanel(evt)
        if not isCardInfoBtnClick then
            self.panelUI:removeAllEventListeners()
            PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
        end 
        isCardInfoBtnClick = false
    end 
    --init UI
	for i = 1,8 do 
		self.panelUI:getChildByName("txt_skillinfo"..i):getChildByName("txt_skillinfo"):setVisible(false)
	end 
    self.panelUI:getChildByName("txt_cardinfo"):getChildByName("txt_cardinfo"):setVisible(false)
	--self.panelUI:getChildByName("txt_cardinfo"):getChildByName("txt_cardinfo"):setString(Localization:getInstance():getText(cardMeta.desc))
    self.panelUI:getChildByName("cardinfo_box"):setVisible(false)
	self.panelUI:getChildByName("pattern_line_center"):setVisible(false)

	--card skill
	local aDescArea = self.panelUI:getChildByName("cardinfo_box")
	local skillPanel = CardDescPanel:create(
		self.metaId,
		{height=250, width=515},
		ccc3(255,255,255)
	)
	skillPanel:setViewPosition(25,300)
	skillPanel:setScaleX(0.9)
	skillPanel:setScaleY(1/cardInfoBoxScaleY)
	skillPanel:setScrollViewTouchEnable(true)
	self.panelUI:getChildByName("cardinfo_box"):addChild(skillPanel)
		
      
    --close
    local closeTouchLayer = Layer:create()
    local winSize = CCDirector:sharedDirector():getWinSize()
    closeTouchLayer:setContentSize(CCSizeMake(winSize.width, winSize.height))
    self:addChild(closeTouchLayer)
    local btn_close_Btn = Button:create(closeTouchLayer)
    btn_close_Btn:addEventListener(Events.kStart ,onClosePanel) 
    --show card skill info
	if self.isShowInfoBtn then
		local btn_cardInfo_Btn = Button:create(self.panelUI:getChildByName("btn_add_reduce"))
		btn_cardInfo_Btn:addEventListener(Events.kStart ,onClickCardInfo) 
		self.panelUI:getChildByName("btn_add_reduce"):getChildByName("btn_plus"):setVisible(true)
		self.panelUI:getChildByName("btn_add_reduce"):getChildByName("btn_reduce"):setVisible(false)
	else
		self.panelUI:getChildByName("btn_add_reduce"):setVisible(false)
	end
	self:addChild(self.panelUI)
	--local btn_close_Btn1 = Button:create(self.panelUI,nil,true)
    --btn_close_Btn1:addEventListener(Events.kStart ,onClosePanel) 
    --
    
    local movingSpace = 0
    local maxMovingSpace = 7
    local function onPanelUIBegin( evt )
        movingSpace = 0
	    local button = evt.context
	    if button.selected then
		    do return end
	    end
	    button.selected = true
	end
		
    local function onPanelUIEnd( evt )
	    local button = evt.context
	    
        if not button.selected then
	        do return end
        end
        button.selected = false;
    end
    
    local function onPanelUITap( evt )
	    local button = evt.context
	    
	    if button and button:hasEventListenerByName(Events.kStart) then
	        if movingSpace > maxMovingSpace then
	            return
	        end
		    button:dispatchEvent(Event.new(Events.kStart, nil, button))
	    end
    end

    local function onPanelUIMove( evt )
	    movingSpace = movingSpace + 1
    end
    self.panelUI:addEventListener(Events.kStart ,onClosePanel)
    self.panelUI:addEventListener(DisplayEvents.kTouchBegin, onPanelUIBegin, self.panelUI)
	self.panelUI:addEventListener(DisplayEvents.kTouchEnd, onPanelUIEnd, self.panelUI)
	self.panelUI:addEventListener(DisplayEvents.kTouchTap, onPanelUITap, self.panelUI)
	self.panelUI:addEventListener(DisplayEvents.kTouchMove, onPanelUIMove, self.panelUI)

    self.panelUI:getChildByName("normal_card_big_sb"):setVisible(false)
	RequestLoadingBox:createLoadingBox()
	RequestLoadingBox:showLoadingBox()
	local cardPictures
	if DataManager.GameMetaData.cardPictureConfig then
		cardPictures = table.deserialize(HeMemDataHolder:getString("cardPictures"))
	end
	if cardMeta and DataManager.GameMetaData.cardPictureConfig and cardPictures then
		local url = nil
		for i,v in ipairs(cardPictures) do
			if v.id == tostring(self.metaId) then
				--print("card info is "..table.tostring(v))
				if isInAppleReview() then
					url = v.urlHarmonious
				else
					url = v.url
				end
				break;
			end
		end
		local function LoadCardCallback(event, data)
			RequestLoadingBox:removeLoadingBox()
			local cardFigure = CocosObject:create()
			-- 背景图片
			local bg = Sprite:create("card/background/" .. cardMeta.backgroundName)
			if bg.refCocosObj == nil then
				bg = Sprite:create("card/background/wei12_1234.png")
			end
			bg:setScaleX(640 / bg:getContentSize().width)
			bg:setScaleY(900 / bg:getContentSize().height)
			cardFigure:addChild(bg)
			-- 卡牌
			if event == ResCallbackEvent.onSuccess and data and data.realPath then
				local cardSprite = Sprite:create(data.realPath)
				cardFigure:addChild(cardSprite)
			else
				SuspensionLabel:showContent(self, getTextByKey("gallery_downloadFailure"))
				local cardSprite = Sprite:createWithSpriteFrame(getCardSpriteFrame(self.metaId))
				cardSprite:setScale(900 / cardSprite:getContentSize().height)
				cardFigure:addChild(cardSprite)
			end
			-- 边框
			local builder = LayoutBuilder:createWithContentsOfFile("scene/big_cardBorder.json")
			local border = builder:build("cardBorder_" .. cardMeta.rare)
			local borderSize = border:getGroupBounds().size
			border:setPosition(ccp(-0.5*borderSize.width, 0.5*borderSize.height))
			cardFigure:addChild(border)
			-- 国家
			local country = Sprite:createWithSpriteFrameName("countryCircle_" .. cardMeta.country .. ".png")
			country:setAnchorPoint(ccp(0, 1))
			country:setPosition(ccp(-302, 442))
			country:setScale(2)
			cardFigure:addChild(country)
			-- 星 
			local evovlePosX = -176
			local evovlePosY = 388
			local evovleInc = 36
			local xin_bg = Sprite:createWithSpriteFrameName("xin_bg.png")
			xin_bg:setPosition(ccp(evovlePosX, evovlePosY-1))
			xin_bg:setAnchorPoint(ccp(0,1))
			xin_bg:setScaleX(2*cardMeta.rare)
			xin_bg:setScaleY(2)
			cardFigure:addChild(xin_bg)
			local xin_bg_ex = Sprite:createWithSpriteFrameName("xin_bg_ex.png")
			xin_bg_ex:setPosition(ccp(evovlePosX + cardMeta.rare*evovleInc, evovlePosY))
			xin_bg_ex:setAnchorPoint(ccp(0,1))
			xin_bg_ex:setScale(2)
			cardFigure:addChild(xin_bg_ex)
			for i = 1, cardMeta.rare do
				local star = Sprite:createWithSpriteFrameName("card_xing.png")
				star:setPosition(ccp(evovlePosX + (i-1)*evovleInc, evovlePosY-1))
				star:setAnchorPoint(ccp(0,1))
				star:setScale(1.6)
				cardFigure:addChild(star)
			end
			-- 名字
			local showName 
			if self.argv and self.argv.oldName then
				showName = self.argv.oldName
			else
				showName = getTextByKey(cardMeta.name)
			end
			local name = TextField:create(showName, nil, 48, CCSizeMake(0,0), kCCTextAlignmentCenter, kCCTextAlignmentCenter)
			name:setPosition(ccp(0, 420))
			cardFigure:addChild(name)

			cardFigure.touchEnabled = false
			cardFigure.touchChildren = false
			local card_position = self.panelUI:getChildByName("normal_card_big_sb"):getPosition()
			cardFigure:setPosition(ccp(card_position.x,card_position.y))
			self:addChildAt(cardFigure, 1)
		end
		if url then
			ResourceLoader.loadThirdPartyRes({url}, LoadCardCallback)
		else
			LoadCardCallback()
		end
	end
end