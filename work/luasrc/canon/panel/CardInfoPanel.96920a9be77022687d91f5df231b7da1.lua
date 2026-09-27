--------------------------------------------------------------------------------
-- CardInfoPanel.lua - 卡牌信息面板
-- author: shaomin.shi & fanzhou.long
-- created: 2013-08-29
-- location: scene/skillEnhance/cardInfo
-- modified by zheng.che @ 2014-8-15 16:42:45 增加万能转生卡处理
--------------------------------------------------------------------------------

require "hecore.display.Director"
require "hecore.ui.LayoutBuilder"
require "hecore.ui.Button"
require "hecore.display.Layer"
require "canon.data.MetaManager"
require "canon.models.CommonManager"
require "canon.customUI.CanonItem"

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

CardInfoPanel = class(Layer)

function CardInfoPanel:ctor()
    self.container = nil
    self.metaId = nil
end

function CardInfoPanel:create( container , forceShowSell , index)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/formation_new.json")
	self.forceShowSell = forceShowSell
    self.container = container
	self.cardId = self.container._data.cardId
    self.metaId = self.container._data.metaId
    self.level = self.container._data.level
    self.exp = self.container._data.exp
    self.newIndex = index
	if (container.title == getTextByKey("formation_title")) then
		self.enterScene = "CardQueueScene"
		self.returnScene = "CardQueueScene"
	elseif (container.title == getTextByKey("matrix_enter")) then
		self.enterScene = "MatrixScene"
		self.returnScene = "MatrixScene"
	else
		self.enterScene = "BackpackScene"
		self.returnScene = "BackpackScene"
	end
    local s = CardInfoPanel.new()
    s:initLayer()
    return s
end

function CardInfoPanel:initLayer()
	CardInfoPanel.super.initLayer(self)
	self.container:setTableViewsEnabled(false)
	
	
	if (not self.container.playerTeamData) then
		self.cardStatus = CommonManager:getCardPropertiesWithSharkCard(self.container._data)
	else
		self.cardStatus = CommonManager:getCardPropertiesWithSharkCard(
			self.container._data,
			CommonManager.getQueueData(self.container.playerTeamData.mainCardId , self.container.playerTeamData.additionalCardIds),
			nil,
			self.container.playerTeamData.sharkCards,
			self.container.playerTeamData.sharkEquips,
			CommonManager:getMatrixCardData({self.container.playerTeamData.sharkMatrices.sharkMatrices}),
			self.container.playerTeamData.sharkMatrices.sharkMatrices,
			self.container.playerTeamData.sharkBeasts,
			self.container.playerTeamData.sharkSpirits
		)
	end
	
	local cardMeta = MetaManager.card_meta[self.metaId]
    CardInfoPanel.super.initLayer(self)
	local builder = LayoutBuilder:createWithContentsOfFile("scene/skillEnhance_new.json")
	builder.useArtLabelTTF = true
	
    self.panelUI = builder:build("skillEnhance_cardInfo")
	
    self.panelUI:getChildByName("txt_cardInfo_Title"):getChildByName("txt_cardInfo_Title"):setString(Localization:getInstance():getText("cardInfo_Title"))
    -- self.panelUI:getChildByName("frameS_upper"):getChildByName("txt_item_name"):getChildByName("txt_equip_Name"):setString(Localization:getInstance():getText("cardInfo_Skill"))
    -- self.panelUI:getChildByName("frameS_bottom"):getChildByName("txt_item_name"):getChildByName("txt_equip_Name"):setString(Localization:getInstance():getText("cardInfo_MainSkill"))
    self.panelUI:getChildByName("txt_cardInfo_lv_num"):getChildByName("font"):setString(self.container._data.level) --LV
    self.panelUI:getChildByName("txt_cardInfo_EvolveLevel"):getChildByName("txt_cardInfo_EvolveLevel"):setString(getTextByKey("cardInfo_EvolveLevel"))
    self.panelUI:getChildByName("txt_cardInfo_Leadership"):getChildByName("txt_cardInfo_Leadership"):setString(getTextByKey("cardInfo_Leadership"))
    
    self.panelUI:getChildByName("txt_cardInfo_EvolveLevel_num"):getChildByName("txt_cardInfo_EvolveLevel_num"):setString(cardMeta.evolutionLevel  .. "/" .. cardMeta.maxEvolvedLevel) --进化等级
    self.panelUI:getChildByName("txt_cardInfo_Leadership_num"):getChildByName("txt_cardInfo_Leadership_num"):setString(cardMeta.leadPoint) --统御力
    
    self.panelUI:getChildByName("txt_card_atk_num"):getChildByName("font"):setString(math.floor(self.cardStatus.att)) --攻击
    self.panelUI:getChildByName("txt_card_def_num"):getChildByName("font"):setString(math.floor(self.cardStatus.def)) --防御
    self.panelUI:getChildByName("txt_card_hp_num"):getChildByName("font"):setString(math.floor(self.cardStatus.hp)) --血
    --self.panelUI:getChildByName("txt_cardInfo_Desc"):getChildByName("txt_cardInfo_Desc"):setString(Localization:getInstance():getText("cardInfo_Desc")) --简介
    
	local aDescArea = self.panelUI:getChildByName("txt_cardInfo_cardDesc"):getChildByName("txt_cardInfo_cardDesc")
	local aPanel = CardDescPanel:create(
		self.metaId,
		{height=425, width=580},
		ccc3(0,0,0),
		self.container._data.cardId
	)
	aPanel:setViewPosition(aDescArea:getPosition().x,aDescArea:getPosition().y+5)
	self.panelUI:getChildByName("txt_cardInfo_cardDesc"):addChild(aPanel)
	aDescArea:setVisible(false)
	self.panelUI:getChildByName("pattern_cardInfor_line"):setVisible(false)
	
    self.panelUI:getChildByName("btn_cardInfo_TrainBtn"):getChildByName("txt_cardInfo_TrainBtn"):setString(Localization:getInstance():getText("cardInfo_TrainBtn")) --培养
    self.panelUI:getChildByName("btn_cardInfo_EnhanceBtn"):getChildByName("txt_cardInfo_EnhanceBtn"):setString(Localization:getInstance():getText("cardInfo_EnhanceBtn")) --合成
    self.panelUI:getChildByName("btn_cardInfo_EnhanceBtn2"):getChildByName("txt_cardInfo_EnhanceBtn"):setString(Localization:getInstance():getText("cardInfo_EnhanceBtn")) --合成
	self.panelUI:getChildByName("btn_cardInfo_ChangeBtn"):getChildByName("txt_cardInfo_ChangeBtn"):setString(Localization:getInstance():getText("cardInfo_SellBtn")) --卖出
	self.panelUI:getChildByName("btn_cardInfo_ChangeBtn_inactive"):getChildByName("txt_cardInfo_ChangeBtn"):setString(Localization:getInstance():getText("cardInfo_SellBtn")) --卖出
    self.panelUI:getChildByName("btn_cardInfo_EvolveBtn"):getChildByName("txt_cardInfo_EvolveBtn"):setString(Localization:getInstance():getText("cardInfo_EvolveBtn")) --进化
   
	local argv = {
			enterScene=self.enterScene,
			returnScene=self.returnScene,
			params={card=self.container._data}
	}
    local function onClickCardTraining( e )
		if (DataManager.getCurrUser().level<19) then
			SuspensionLabel:showContent(self.container, Localization:getInstance():getText("cardInfo_TrainLocked"))
			return
		end

		--print("self.container._data = " .. tostringRich(self.container._data))
		local cardMetaId = self.container._data.metaId
		if not ItemManager.checkCardTypeCanTrain(cardMetaId) then
			SuspensionLabel:showContent(self.container, Localization:getInstance():getText("cardTrainLimited"))--此武将不能进行培养
			return
		end

		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		self.container:replaceScene(CardTrainingScene,argv)
    end
    local function onClickCardEvolution( e )
		--print("self.container._data = " .. tostringRich(self.container._data))
		local cardMetaId = self.container._data.metaId
		if not ItemManager.checkCardTypeCanEvolve(cardMetaId) then
			SuspensionLabel:showContent(self.container, Localization:getInstance():getText("cardEvolveLimited"))--此武将不能进行转生
			return
		end

        PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		self.container._data.cardType = "master"
        self.container:replaceScene(CardEvolutionScene,{
		enterScene="CardInfoPanel",
		returnScene=self.returnScene,
		params=self.container._data
		})
    end
    local function onClickCardCompose(e)
		--print("self.container._data = " .. tostringRich(self.container._data))
		local cardMetaId = self.container._data.metaId
		if not ItemManager.checkCardTypeCanUpgrade(cardMetaId) then
			SuspensionLabel:showContent(self.container, Localization:getInstance():getText("cardEnhanceLimited"))--此武将不能进行强化
			return
		end
		
        PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
        self.container:replaceScene(CardComposeScene,{
		enterScene="CardInfoPanel",
		returnScene=self.returnScene,
		params={cardId=self.container._data.cardId,metaId = self.container._data.metaId, cardType = "mainCard"}
		})
    end     
    local function onClosePanel(evt)
        PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
        self.container:setTableViewsEnabled(true)
		self.container.targetInfoPanel = nil
    end 
	local function onClickChange( e )
		PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
		if self.enterScene == "MatrixScene" then
			if type(self.container.changeMatrixCard) == "function" then
				self.container:changeMatrixCard(self.cardId)
			end
		else
			CardQueueScene.changeCard( self.cardId , self.container)
		end
	end
	local function onClickSell( e )
		local aPanel = ItemSellMessageBoxPanel:create( self.container , {cardData={self.container._data.cardId}}, self , self.newIndex)
		self.container:addChild(aPanel)
		aPanel:scaleIn()
	end
	
    --培养
    local btn_cardInfo_TrainBtn = Button:create(self.panelUI:getChildByName("btn_cardInfo_TrainBtn"))
    btn_cardInfo_TrainBtn:addEventListener(Events.kStart , onClickCardTraining)    
    --更换
	local btn_cardInfo_ChangeBtn = Button:create(self.panelUI:getChildByName("btn_cardInfo_ChangeBtn"))
	local cardQueue = CommonManager:getEffectCardQueue()
	local cardIds = {}
	for aKey, aCardId  in pairs(cardQueue) do
		cardIds[aCardId] = aKey
	end
	self.panelUI:getChildByName("btn_cardInfo_ChangeBtn_inactive"):setVisible(false)
	if (cardIds[self.cardId]) then
		if self.forceShowSell then
			self.panelUI:getChildByName("btn_cardInfo_ChangeBtn"):setVisible(false)
			self.panelUI:getChildByName("btn_cardInfo_ChangeBtn_inactive"):setVisible(true)
		else
			--更换
			self.panelUI:getChildByName("btn_cardInfo_ChangeBtn"):getChildByName("txt_cardInfo_ChangeBtn"):setString("更换") --更换
			btn_cardInfo_ChangeBtn:addEventListener(Events.kStart ,onClickChange , self.container._data) 
		end
	else
		--卖出
		btn_cardInfo_ChangeBtn:addEventListener(Events.kStart ,onClickSell , self.container._data) 
	end
	local cardEvolveMeta = MetaManager.card_evolve[cardMeta.evolutionLevel]
	
    --进化
	if (self.level>=cardEvolveMeta.evolveNeedLevel and cardMeta.evolutionLevel<cardMeta.maxEvolvedLevel) or (ItemManager.getCardTypeByMetaId(self.container._data.metaId) == ItemManager.CARD_TYPE_BRON) then
		--未达到满级 或者是万能转生卡
		local btCardEvolution = Button:create(self.panelUI:getChildByName("btn_cardInfo_EvolveBtn"))
		btCardEvolution:addEventListener(Events.kStart ,onClickCardEvolution , self.container._data)
		self.panelUI:getChildByName("btn_cardInfo_EvolveBtn"):setVisible(true)
		self.panelUI:getChildByName("btn_cardInfo_EvolveBtn2"):setVisible(false)
	else
		if (cardMeta.evolutionLevel == cardMeta.maxEvolvedLevel) then
			self.panelUI:getChildByName("btn_cardInfo_EvolveBtn2"):getChildByName("txt_cardInfo_EvolveBtn"):setString(
				Localization:getInstance():getText(
					"cardEvolveMax"
				)
			)
		else
			self.panelUI:getChildByName("btn_cardInfo_EvolveBtn2"):getChildByName("txt_cardInfo_EvolveBtn"):setString(
				Localization:getInstance():getText(
					"cardEvolveNeedLevel",
					{num = cardEvolveMeta.evolveNeedLevel}
				)
			)
		end
		self.panelUI:getChildByName("btn_cardInfo_EvolveBtn"):setVisible(false)
		self.panelUI:getChildByName("btn_cardInfo_EvolveBtn2"):setVisible(true)
	end
	
	--合成
	if (self.level<cardEvolveMeta.maxCardLevel) then
		local btn_cardInfo_EnhanceBtn = Button:create(self.panelUI:getChildByName("btn_cardInfo_EnhanceBtn"))
		btn_cardInfo_EnhanceBtn:addEventListener(Events.kStart ,onClickCardCompose , self.container._data)        
		self.panelUI:getChildByName("btn_cardInfo_EnhanceBtn"):setVisible(true)
		self.panelUI:getChildByName("btn_cardInfo_EnhanceBtn2"):setVisible(false)
	else
		self.panelUI:getChildByName("btn_cardInfo_EnhanceBtn"):setVisible(false)
		self.panelUI:getChildByName("btn_cardInfo_EnhanceBtn2"):setVisible(true)
	end
	--关闭
    local bt_panel_close = Button:create(self.panelUI:getChildByName("btn_close"))
    bt_panel_close:addEventListener(Events.kStart, onClosePanel)   
    self.panelUI:getChildByName("frameB"):setZOrder(99)
    self:addChild(self.panelUI)
    
    self.metaId = self.container._data.metaId
    local cardFigure = getBigCanonCardWithInfoByMetaId(self.metaId)
    cardFigure:setAtk(math.floor(self.cardStatus.att))
    cardFigure:setDef(math.floor(self.cardStatus.def))
    cardFigure:setHp(math.floor(self.cardStatus.hp))
    cardFigure:setLevel(self.level)
    local cardLevelMeta = MetaManager.card_level[self.level]
    --cardFigure:setExp(self.exp, cardLevelMeta.exp)
    
    cardFigure:setScale(0.8)
    self.panelUI:getChildByName("frameB"):setVisible(false)
	local card_position = self.panelUI:getChildByName("frameB"):getPosition()
    cardFigure:setPosition(ccp(card_position.x,card_position.y))
    self:addChild(cardFigure)
	
	local scalePercent = self.panelUI:getChildByName("frameS_mid"):getContentSize().height / 144
	local aCardMeta = MetaManager.card_meta[self.metaId]
	self.panelUI:getChildByName("frameS_mid"):setVisible(false)
	if (aCardMeta["mainSkill"] ~= 0) then
		local mainSkillFigure = CanonItem:create()
		mainSkillFigure:loadByMetaId(aCardMeta["mainSkill"])
		local position = self.panelUI:getChildByName("frameS_mid"):getPosition()
		mainSkillFigure:setPosition(ccp(position.x,position.y))
		mainSkillFigure:setScale(scalePercent)
		self.panelUI:addChild(mainSkillFigure)
		self.panelUI:getChildByName("item_name2"):setZOrder(2001)
		self.panelUI:getChildByName("item_name2"):getChildByName("txt"):getChildByName("txt_item_name"):setString(getTextByKey(MetaManager.skill_meta[aCardMeta["mainSkill"]]["name"]))
	else
		local aFigure = Sprite:create("Item/Picture/Skill_empty.png")
		local position = self.panelUI:getChildByName("frameS_mid"):getPosition()
		aFigure:setPosition(ccp(position.x,position.y))
		aFigure:setScale(108/130)
		self.panelUI:addChild(aFigure)
	end
	
	self.panelUI:getChildByName("frameS_upper"):setVisible(false)
	if (aCardMeta["skill"] ~= 0) then
		local leaderSkillFigure = CanonItem:create()
		leaderSkillFigure:loadByMetaId(aCardMeta["skill"])
		local position = self.panelUI:getChildByName("frameS_upper"):getPosition()
		leaderSkillFigure:setPosition(ccp(position.x,position.y))
		leaderSkillFigure:setScale(scalePercent)
		self.panelUI:addChild(leaderSkillFigure)
		self.panelUI:getChildByName("frameS_upper"):setVisible(false)
		self.panelUI:getChildByName("item_name1"):setZOrder(2001)
		self.panelUI:getChildByName("item_name1"):getChildByName("txt"):getChildByName("txt_item_name"):setString(getTextByKey(MetaManager.skill_meta[aCardMeta["skill"]]["name"]))
	else
		local aFigure = Sprite:create("Item/Picture/Skill_empty.png")
		local position = self.panelUI:getChildByName("frameS_upper"):getPosition()
		aFigure:setPosition(ccp(position.x,position.y))
		aFigure:setScale(108/130)
		self.panelUI:addChild(aFigure)
	end
	
	local icon_lock = Sprite:create(UI_RES_PATH.."/formation_new/formation_icon_lock_sb.png")
	local originalIcon = self.panelUI:getChildByName("frameS_bottom")
	icon_lock:setPosition(ccp(originalIcon:getPositionX(),originalIcon:getPositionY()))
	icon_lock:setScale(108/135)
	originalIcon:removeFromParentAndCleanup(true)
	self.panelUI:addChild(icon_lock)
	
	local scopeIcon = self.panelUI:getChildByName("icon_cardScope")
	local aScopeDisplay = Sprite:create(UI_RES_PATH.."/skillEnhance_new/skillEnhance_icon_cardScope_sb.png")
	aScopeDisplay:setZOrder(1001)
	aScopeDisplay:setPosition(ccp(scopeIcon:getPosition().x, scopeIcon:getPosition().y))
	aScopeDisplay:setAnchorPoint(scopeIcon:getAnchorPoint())
	self:addChild(aScopeDisplay)
	local function onClickScope( e )
		self.container._data.id = self.container._data.metaId
		local aPanel = CardIllustratedShowPanel:create( self.container ,false)
		self.container.targetInfoPanel = aPanel
		PopoutManager:sharedManager():popout(aPanel, kPopoutDir.kScale, true, false ,self.container)
	end
	local aScopeButton = Button:create(aScopeDisplay)
	aScopeButton:addEventListener(Events.kStart, onClickScope, self.container._data)
	
	local aCardIconButton = Button:create(cardFigure)
	aCardIconButton:addEventListener(Events.kStart, onClickScope, self.container._data)
	
	local sprite = Sprite:create(UI_RES_PATH.."/skillEnhance_new/skillEnhance_expbar.png")
	local exp_pic = self.panelUI:getChildByName("expbar")
	sprite:setPosition(ccp(exp_pic:getPosition().x, exp_pic:getPosition().y))
	sprite:setAnchorPoint(exp_pic:getAnchorPoint())
	exp_pic:setVisible(false)--隐藏原进度条
	self.progress = ProgressBar:create(sprite) 
	self.progress:setPercentage(self.exp * 100 / cardLevelMeta.exp)
	self.panelUI:addChild(sprite)
end