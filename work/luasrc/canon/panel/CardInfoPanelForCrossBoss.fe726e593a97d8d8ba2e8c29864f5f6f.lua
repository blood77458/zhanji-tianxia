require "canon.canonUtils"
require "canon.data.DataManager"
require "canon.data.MetaManager"
require "hecore.display.CocosObject"
require "hecore.display.Director"
require "hecore.ui.PopoutManager"

local visibleSize = CCDirector:sharedDirector():getVisibleSize();

CardInfoPanelForCrossBoss = class(Layer)

function CardInfoPanelForCrossBoss:create(container, cardData, onClose)
	local panel = CardInfoPanelForCrossBoss.new()
	panel.container = container
	panel.cardData = cardData
	panel.onClose = onClose
	if (container.title == getTextByKey("formation_title")) then
		panel.enterScene = "CardQueueScene"
		panel.returnScene = "CardQueueScene"
	else
		panel.enterScene = "BackpackScene"
		panel.returnScene = "BackpackScene"
	end

	panel:initLayer()
	return panel
end

function CardInfoPanelForCrossBoss:initLayer()
	CardInfoPanelForCrossBoss.super.initLayer(self)

	local cardStatus = CommonManager:getCardPropertiesWithSharkCard(self.cardData)

	local cardMeta = MetaManager.card_meta[self.cardData.metaId]
	local builder = LayoutBuilder:createWithContentsOfFile("scene/GachaResult_new.json")
	builder.useArtLabelTTF = true

	self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))

    self.panelUI = builder:build("cardInfo")
    self.panelUI:getChildByName("txt_cardInfo_Title"):getChildByName("txt_cardInfo_Title"):setString(Localization:getInstance():getText("cardInfo_Title"))
    -- self.panelUI:getChildByName("frameS_upper"):getChildByName("txt_item_name"):getChildByName("txt_equip_Name"):setString(Localization:getInstance():getText("cardInfo_Skill"))
    -- self.panelUI:getChildByName("frameS_bottom"):getChildByName("txt_item_name"):getChildByName("txt_equip_Name"):setString(Localization:getInstance():getText("cardInfo_MainSkill"))
    self.panelUI:getChildByName("txt_cardInfo_lv_num"):getChildByName("font"):setString(self.cardData.level) --LV
    self.panelUI:getChildByName("txt_cardInfo_EvolveLevel"):getChildByName("txt_cardInfo_EvolveLevel"):setString(getTextByKey("cardInfo_EvolveLevel"))
    self.panelUI:getChildByName("txt_cardInfo_Leadership"):getChildByName("txt_cardInfo_Leadership"):setString(getTextByKey("cardInfo_Leadership"))

    self.panelUI:getChildByName("txt_cardInfo_EvolveLevel_num"):getChildByName("txt_cardInfo_EvolveLevel_num"):setString(cardMeta.evolutionLevel  .. "/" .. cardMeta.maxEvolvedLevel) --进化等级
    self.panelUI:getChildByName("txt_cardInfo_Leadership_num"):getChildByName("txt_cardInfo_Leadership_num"):setString(cardMeta.leadPoint) --统御力

    self.panelUI:getChildByName("txt_card_atk_num"):getChildByName("font"):setString(math.floor(cardStatus.att)) --攻击
    self.panelUI:getChildByName("txt_card_def_num"):getChildByName("font"):setString(math.floor(cardStatus.def)) --防御
    self.panelUI:getChildByName("txt_card_hp_num"):getChildByName("font"):setString(math.floor(cardStatus.hp)) --血
    --self.panelUI:getChildByName("txt_cardInfo_Desc"):getChildByName("txt_cardInfo_Desc"):setString(Localization:getInstance():getText("cardInfo_Desc")) --简介

	local aDescArea = self.panelUI:getChildByName("txt_cardInfo_cardDesc"):getChildByName("txt_cardInfo_cardDesc")
	local aPanel = CardDescPanel:create(
		self.cardData.metaId,
		{height=386, width=580},
		ccc3(0,0,0),
		self.cardData.cardId
	)
	aPanel:setViewPosition(aDescArea:getPosition().x,aDescArea:getPosition().y+5)
	self.panelUI:getChildByName("txt_cardInfo_cardDesc"):addChild(aPanel)
	aDescArea:setVisible(false)
	self.panelUI:getChildByName("pattern_cardInfor_line"):setVisible(false)

	--关闭
    local function onClosePanel(e)
		self:dismiss()
		if self.onClose then
			self.onClose()
		end
	end
	local bt_panel_close = Button:create(self.panelUI:getChildByName("common_btn_close"))
	bt_panel_close:addEventListener(Events.kStart, onClosePanel)
	self.panelUI:getChildByName("frameB"):setZOrder(99)
	self.tempLayer:addChild(self.panelUI)

    local cardFigure = getBigCanonCardWithInfoByMetaId(self.cardData.metaId)
    cardFigure:setAtk(math.floor(cardStatus.att))
    cardFigure:setDef(math.floor(cardStatus.def))
    cardFigure:setHp(math.floor(cardStatus.hp))
    cardFigure:setLevel(self.cardData.level)
    local cardLevelMeta = MetaManager.card_level[self.cardData.level]
    --cardFigure:setExp(self.cardData.exp, cardLevelMeta.exp)
    cardFigure:setScale(0.8)
    self.panelUI:getChildByName("frameB"):setVisible(false)
	local position = self.panelUI:getChildByName("frameB"):getPosition()
    cardFigure:setPosition(ccp(position.x, position.y))
    self.panelUI:addChild(cardFigure)

	local scalePercent = self.panelUI:getChildByName("frameS_mid"):getContentSize().height / 144
	self.panelUI:getChildByName("frameS_mid"):setVisible(false)
	if cardMeta.mainSkill ~= 0 then
		local mainSkillFigure = CanonItem:create()
		mainSkillFigure:loadByMetaId(cardMeta.mainSkill)
		local position = self.panelUI:getChildByName("frameS_mid"):getPosition()
		mainSkillFigure:setPosition(ccp(position.x,position.y))
		mainSkillFigure:setScale(scalePercent)
		self.panelUI:addChild(mainSkillFigure)
		self.panelUI:getChildByName("item_name2"):setZOrder(2001)
		self.panelUI:getChildByName("item_name2"):getChildByName("txt"):getChildByName("txt_item_name"):setString(getTextByKey(MetaManager.skill_meta[cardMeta.mainSkill].name))
	else
		local aFigure = Sprite:create("Item/Picture/Skill_empty.png")
		local position = self.panelUI:getChildByName("frameS_mid"):getPosition()
		aFigure:setPosition(ccp(position.x,position.y))
		aFigure:setScale(108/130)
		self.panelUI:addChild(aFigure)
	end
	self.panelUI:getChildByName("frameS_upper"):setVisible(false)
	if cardMeta.skill ~= 0 then
		local leaderSkillFigure = CanonItem:create()
		leaderSkillFigure:loadByMetaId(cardMeta.skill)
		local position = self.panelUI:getChildByName("frameS_upper"):getPosition()
		leaderSkillFigure:setPosition(ccp(position.x,position.y))
		leaderSkillFigure:setScale(scalePercent)
		self.panelUI:addChild(leaderSkillFigure)
		self.panelUI:getChildByName("item_name1"):setZOrder(2001)
		self.panelUI:getChildByName("item_name1"):getChildByName("txt"):getChildByName("txt_item_name"):setString(getTextByKey(MetaManager.skill_meta[cardMeta.skill].name))
	else
		local aFigure = Sprite:create("Item/Picture/Skill_empty.png")
		local position = self.panelUI:getChildByName("frameS_upper"):getPosition()
		aFigure:setPosition(ccp(position.x,position.y))
		aFigure:setScale(108/130)
		self.panelUI:addChild(aFigure)
	end

	local tbuilder = LayoutBuilder:createWithContentsOfFile("scene/formation_new.json")
	local icon_lock = Sprite:create(UI_RES_PATH.."/formation_new/formation_icon_lock_sb.png")
	local originalIcon = self.panelUI:getChildByName("frameS_bottom")
	icon_lock:setPosition(ccp(originalIcon:getPositionX(),originalIcon:getPositionY()))
	icon_lock:setScale(108/135)
	originalIcon:removeFromParentAndCleanup(true)
	self.panelUI:addChild(icon_lock)
	
	local scopeIcon = self.panelUI:getChildByName("icon_cardScope")
	local scopeDisplay = Sprite:create(UI_RES_PATH.."/GachaResult_new/GachaResult_icon_cardScope_sb.png")
	scopeDisplay:setZOrder(1001)
	scopeDisplay:setPosition(ccp(scopeIcon:getPosition().x, scopeIcon:getPosition().y))
	scopeDisplay:setAnchorPoint(scopeIcon:getAnchorPoint())
	self.panelUI:addChild(scopeDisplay, 1)
	local function onClickScope( e )
		print(self.cardData.metaId.."*****")
		local aPanel = CardIllustratedShowPanel:create(self.container, false, self.cardData.metaId)
		self.container.targetInfoPanel = aPanel
		PopoutManager:sharedManager():popout(aPanel, kPopoutDir.kScale, false, false ,self.container)
	end
	local scopeButton = Button:create(scopeDisplay)
	scopeButton:addEventListener(Events.kStart, onClickScope)

	local sprite = Sprite:create(UI_RES_PATH.."/GachaResult_new/GachaResult_expbar.png")
	local exp_pic = self.panelUI:getChildByName("expbar")
	sprite:setPosition(ccp(exp_pic:getPosition().x, exp_pic:getPosition().y))
	sprite:setAnchorPoint(exp_pic:getAnchorPoint())
	exp_pic:setVisible(false)--隐藏原进度条
	self.progress = ProgressBar:create(sprite)
	self.progress:setPercentage(self.cardData.exp * 100 / cardLevelMeta.exp)
	self.panelUI:addChild(sprite)

	self.tempLayer:setScale(0.1)
end

function CardInfoPanelForCrossBoss:scaleIn()
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

function CardInfoPanelForCrossBoss:dismiss()
    self.container.targetInfoPanel = nil
    self:removeFromParentAndCleanup(true)
    -- self.container:setTableViewsEnabled(true)
end