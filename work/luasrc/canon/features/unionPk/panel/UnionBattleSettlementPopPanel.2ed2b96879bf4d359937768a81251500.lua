-- UnionBattleSettlementPopPanel.lua
-- zhehua.ou
-- 2014-9-5
-- 军团战 战斗结算

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

------------------------------------------------------------------------------------------------------

UnionBattleSettlementPopPanel = class(Layer)

function UnionBattleSettlementPopPanel:ctor()
	self.container = nil
	self.content = nil
end

function UnionBattleSettlementPopPanel:create(container , data , detailData)
	local s = UnionBattleSettlementPopPanel.new()
	s.container = container
	s.data = data
	s.detailData = detailData
	s:initLayer()
	return s
end

function UnionBattleSettlementPopPanel:initLayer()
	UnionBattleSettlementPopPanel.super.initLayer(self)

	self.pre_container_targetInfoPanel = self.container.targetInfoPanel
	self.container.targetInfoPanel = self
    
    self.colorLayer = LayerColor:create()
    self.colorLayer:setOpacity(kDarkOpacity)
    self.colorLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.colorLayer)

    self.tempLayer = Layer:create()
    self.tempLayer:setContentSize(CCSizeMake(visibleSize.width, visibleSize.height))
    self:addChild(self.tempLayer)
    self.tempLayer:setAnchorPoint(ccp(0.5, 0.5))
    
    local builder = LayoutBuilder:createWithContentsOfFile("scene/guild_pk.json")
    builder.useArtLabelTTF = true
    self.panelUI = builder:build("popup_settlement_1")
    self.tempLayer:addChild(self.panelUI)

    local function closeBtnAction(evt)
    	local cityId = self.data.cityId

      	self:dismissSelf()
      	UnionPK.battleBackToUnionPkScene(cityId)
    end
    local closeBtnDisplay = self.panelUI:getChildByName("login_btn_close")
    local closeBtn = Button:create(closeBtnDisplay)
    closeBtn:addEventListener( Events.kStart, closeBtnAction, self )
    
    self.panelUI:getChildByName("txt_4"):getChildByName("txt"):setString(UnionPkUtils.getCityNameById(self.data.cityId))

    self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(self.data.left_name)
    self.panelUI:getChildByName("signInIcon_victory_f_1"):setVisible(self.data.left_winOrlose)
    self.panelUI:getChildByName("signInIcon_negative_f_2"):setVisible(not self.data.left_winOrlose)

	self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(self.data.right_name)
	self.panelUI:getChildByName("signInIcon_victory_f_2"):setVisible(self.data.right_winOrlose)
	self.panelUI:getChildByName("signInIcon_negative_f_1"):setVisible(not self.data.right_winOrlose)

	self.panelUI:getChildByName("btn"):getChildByName("txt_guild_66"):getChildByName("txt"):setString(getTextByKey("yes"))

	local yesBtn = Button:create(self.panelUI:getChildByName("btn"))
	yesBtn:addEventListener(Events.kStart, closeBtnAction, self)
	
    local attInfo = self.panelUI:getChildByName("guildPK_bank_item_fdrmation1")
    
    local attUID 
    local defUID
    for k,v in pairs(self.detailData.cardInitDatas) do
    	if v.pos == 1 then
    		attUID = v.uid
    	end
    	if v.pos == 10000 then
    		defUID = v.uid
    	end
    end

    local newAttMeta = CommonManager:getSelfAvatarMetaByUid( attUID )
	if not newAttMeta then
		newAttMeta = self.detailData.attack_general_cardId
	end
	local attIcon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, newAttMeta, 1, {sourceDisplay = attInfo:getChildByName("normal_card_small") , showInCenter = true})
	attInfo:addChildAt(attIcon,1)
    attInfo:getChildByName("txt"):getChildByName("txt"):setString(self.detailData.attack_general_name)

	local defInfo = self.panelUI:getChildByName("guildPK_bank_item_fdrmation2")
	local newDefMeta = CommonManager:getSelfAvatarMetaByUid( defUID )
	if not newDefMeta then
		newDefMeta = self.detailData.defend_general_cardId
	end
	local defIcon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, newDefMeta, 1, {sourceDisplay = defInfo:getChildByName("normal_card_small") , showInCenter = true})
	defInfo:addChildAt(defIcon,1)
    defInfo:getChildByName("txt"):getChildByName("txt"):setString(self.detailData.defend_general_name)

	self.panelUI:getChildByName("lbl_victory"):setVisible(self.detailData.isAttWin)
	self.panelUI:getChildByName("lbl_failure"):setVisible(not self.detailData.isAttWin)
	self.panelUI:getChildByName("rbl_victory"):setVisible(not self.detailData.isAttWin)
	self.panelUI:getChildByName("rbl_failure"):setVisible(self.detailData.isAttWin)

    self.panelUI:getChildByName("lbl_attack_victory"):setVisible(self.detailData.isAttWin)
    self.panelUI:getChildByName("lbl_defensive_victory"):setVisible(not self.detailData.isAttWin)

    self.panelUI:getChildByName("txt_10"):getChildByName("txt"):setString(getTextByKey("UnionWar_reward_mine"))
	self.panelUI:getChildByName("txt_50"):getChildByName("txt"):setString(getTextByKey("UnionWar_reward_enemy"))

	self.panelUI:getChildByName("txt_20"):getChildByName("txt"):setString(self.detailData.attLeftNum)
	self.panelUI:getChildByName("txt_30"):getChildByName("txt"):setString(self.detailData.defLeftNum)

	self.tempLayer:setScale(0.1)

end

function UnionBattleSettlementPopPanel:dispose()
	UnionBattleSettlementPopPanel.super.dispose(self)
end

function UnionBattleSettlementPopPanel:scaleIn()
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

	UiStackManager.push(self)
end

function UnionBattleSettlementPopPanel:dismissSelf()
	UiStackManager.remove(self)

	self.container.targetInfoPanel = self.pre_container_targetInfoPanel
	self:removeFromParentAndCleanup(true)
end







function UnionBattleSettlementPopPanel.FormatData(fatherData)
	-- 主面板
	local data = {}
	fatherData = fatherData.sharkUnionBattlefieldReport
	
	data.cityId = UnionPkData.getBattleCityId()

	local attackUnionName = nil
	if fatherData.attackUnionName == nil or fatherData.attackUnionName == "" then
		attackUnionName = UnionPkUtils.getCityNpcNameById(data.cityId)
	else
		attackUnionName = fatherData.attackUnionName
	end
	data.left_name = attackUnionName

	local defenseUnionName = nil
	if fatherData.defenseUnionName == nil or fatherData.defenseUnionName == "" then
		defenseUnionName = UnionPkUtils.getCityNpcNameById(data.cityId)
	else
		defenseUnionName = fatherData.defenseUnionName
	end
	data.right_name = defenseUnionName

	data.left_winOrlose = fatherData.warWin
	data.right_winOrlose = not fatherData.warWin


	-- 子面板
	local detailData = {}
	-- 没打
	if fatherData.cardInitDatas then
		detailData.available = true

		local attackData = nil
		local defendData = nil

		for k, v in pairs(fatherData.cardInitDatas) do
			if v.posId == 1 then
				attackData = v
				attackData.userName = fatherData.singleBattleAttName
				attackData.unionId = fatherData.attUnionId
			end

			if v.posId == 10001 then
				defendData = v
				defendData.userName = fatherData.singleBattleDefName
				defendData.unionId = fatherData.defUnionId
			end
		end
	
		detailData.attack_general_name = attackData.userName or UnionPkUtils.getCityCardNpcNameById(data.cityId)
		detailData.attack_general_cardId = attackData.metaId

		detailData.defend_general_name = defendData.userName or UnionPkUtils.getCityCardNpcNameById(data.cityId)
		detailData.defend_general_cardId = defendData.metaId

		detailData.isAttWin = fatherData.warWin
		detailData.attLeftNum = fatherData.attUnionLeftPlayer
		detailData.defLeftNum = fatherData.defUnionLeftPlayer
		detailData.cardInitDatas = fatherData.cardInitDatas
	else
		detailData.available = false
	end

	return data , detailData
end