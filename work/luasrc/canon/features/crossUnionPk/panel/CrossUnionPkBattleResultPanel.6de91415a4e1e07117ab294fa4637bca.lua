-- CrossUnionPkBattleResultPanel.lua
-- 2015-5-29
-- zheng.che
-- gvg战斗结算面板 分为小组赛/淘汰赛两种相似UI

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

------------------------------------------------------------------------------------------------------

CrossUnionPkBattleResultPanel = class(Layer)

function CrossUnionPkBattleResultPanel:ctor()
end

-- battleType 战斗类型 详见 CrossUnionPkConsts
-- battleData 战斗数据
-- currentPoint 变换的积分数量
-- changePoint 当前积分
function CrossUnionPkBattleResultPanel:create(battleType, battleData, currentPoint, changePoint)
	local self = CrossUnionPkBattleResultPanel.new()
	self.battleType = battleType
	self.battleSubType = CrossUnionPkData.getBattleSubType()
	self.battleData = battleData
	self.currentPoint = currentPoint
	self.changePoint = changePoint
	self:initLayer()
	return self
end

function CrossUnionPkBattleResultPanel:initLayer()
	CrossUnionPkBattleResultPanel.super.initLayer(self)

	local builder = LayoutBuilder:createWithContentsOfFile("scene/Gvg.json")
	builder.useArtLabelTTF = true
	if self.battleType == BattleEnterEnum.kCrossGVGGroupBattle then
		--小组赛
		self.panelUI = builder:build("popup_Gvg_05")
	elseif self.battleType == BattleEnterEnum.kCrossGVGRankBattle then
		--淘汰赛
		self.panelUI = builder:build("popup_Gvg_06")
	else
		--默认
		DebugManager.addError("没有战斗类型! self.battleType = " .. tostringRich(self.battleType))
	end
	self:addChild(self.panelUI)

	local function onCloseBtnClick(evt)
		self:close()
	end

    local closeBtn = Button:create(self.panelUI:getChildByName("common_btn_close"))
    closeBtn:addEventListener( Events.kStart, onCloseBtnClick, self )

	self.panelUI:getChildByName("btn_yellow_long_Gvg"):getChildByName("txt"):setString(getTextByKey("yes"))--确定
    local yesBtn = Button:create(self.panelUI:getChildByName("btn_yellow_long_Gvg"))
    yesBtn:addEventListener( Events.kStart, onCloseBtnClick, self )

	--显示标题
	if self.battleType == BattleEnterEnum.kCrossGVGGroupBattle then
		--小组赛
		self.panelUI:getChildByName("txt_6"):getChildByName("txt"):setString(getTextByKey("WGVG_Detail57"))--小组赛
	elseif self.battleType == BattleEnterEnum.kCrossGVGRankBattle then
		--淘汰赛
		if self.battleSubType == CrossUnionPkConsts.KNOCKOUT_TYPE_16 then
			self.panelUI:getChildByName("txt_6"):getChildByName("txt"):setString(getTextByKey("WGVG_Name09"))--十六强赛
		elseif self.battleSubType == CrossUnionPkConsts.KNOCKOUT_TYPE_8 then
			self.panelUI:getChildByName("txt_6"):getChildByName("txt"):setString(getTextByKey("WGVG_Name10"))--八强赛
		elseif self.battleSubType == CrossUnionPkConsts.KNOCKOUT_TYPE_4 then
			self.panelUI:getChildByName("txt_6"):getChildByName("txt"):setString(getTextByKey("WGVG_Name11"))--四强赛
		elseif self.battleSubType == CrossUnionPkConsts.KNOCKOUT_TYPE_THIRD then
			self.panelUI:getChildByName("txt_6"):getChildByName("txt"):setString(getTextByKey("WGVG_Name08"))--季军争夺赛
		elseif self.battleSubType == CrossUnionPkConsts.KNOCKOUT_TYPE_CHAMPION then
			self.panelUI:getChildByName("txt_6"):getChildByName("txt"):setString(getTextByKey("WGVG_Name07"))--决赛
		end
	end

	--显示胜利/失败
    self.panelUI:getChildByName("lbl_attack_victory"):setVisible(self.battleData.warWin)
    self.panelUI:getChildByName("lbl_defensive_victory"):setVisible(not self.battleData.warWin)

	--显示攻方军团名和是否胜利
	self.panelUI:getChildByName("txt_1"):getChildByName("txt"):setString(self.battleData.attackUnionName)
	self.panelUI:getChildByName("signInIcon_victory_f_1"):setVisible(self.battleData.warWin)
	self.panelUI:getChildByName("signInIcon_negative_f_2"):setVisible(not self.battleData.warWin)

	--显示守方军团名和是否胜利
	self.panelUI:getChildByName("txt_2"):getChildByName("txt"):setString(self.battleData.defenseUnionName)
	self.panelUI:getChildByName("signInIcon_victory_f_2"):setVisible(not self.battleData.warWin)
	self.panelUI:getChildByName("signInIcon_negative_f_1"):setVisible(self.battleData.warWin)

	--显示先锋战胜利/失败
	self.panelUI:getChildByName("lbl_victory"):setVisible(self.battleData.win)
	self.panelUI:getChildByName("lbl_failure"):setVisible(not self.battleData.win)
	self.panelUI:getChildByName("rbl_victory"):setVisible(not self.battleData.win)
	self.panelUI:getChildByName("rbl_failure"):setVisible(self.battleData.win)

	if self.battleData.cardInitDatas then
		--显示先锋战头像昵称
		local attInfo
	    local defInfo
	    for k,v in pairs(self.battleData.cardInitDatas) do
	    	if v.posId == 1 then
	    		attInfo = v
	    	end
	    	if v.posId == 10001 then
	    		defInfo = v
	    	end
	    end

	    local newAttMeta = CommonManager:getSelfAvatarMetaByUid( attInfo.uid )
		if not newAttMeta then
			newAttMeta = attInfo.metaId
		end
		local attDisplay = self.panelUI:getChildByName("guildPK_bank_item_fdrmation1")
		local attIcon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, newAttMeta, 1, {sourceDisplay = attDisplay:getChildByName("normal_card_small") , showInCenter = true})
		attDisplay:addChildAt(attIcon,1)
		attDisplay:getChildByName("txt"):getChildByName("txt"):setString(self.battleData.singleBattleAttName)

		local newDefMeta = CommonManager:getSelfAvatarMetaByUid( defInfo.uid )
		if not newDefMeta then
			newDefMeta = defInfo.metaId
		end
		local defDisplay = self.panelUI:getChildByName("guildPK_bank_item_fdrmation2")
		local defIcon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, newDefMeta, 1, {sourceDisplay = defDisplay:getChildByName("normal_card_small") , showInCenter = true})
		defDisplay:addChildAt(defIcon,1)
		defDisplay:getChildByName("txt"):getChildByName("txt"):setString(self.battleData.singleBattleDefName)
	else
		self.panelUI:getChildByName("guildPK_bank_item_fdrmation1"):setVisible(false)
		self.panelUI:getChildByName("guildPK_bank_item_fdrmation2"):setVisible(false)

			self.panelUI:getChildByName("lbl_victory"):setVisible(true)
		self.panelUI:getChildByName("lbl_failure"):setVisible(not true)
		self.panelUI:getChildByName("rbl_victory"):setVisible(not true)
		self.panelUI:getChildByName("rbl_failure"):setVisible(true)
	end

	--显示剩余人数
	self.panelUI:getChildByName("txt_10"):getChildByName("txt"):setString(getTextByKey("UnionWar_reward_mine"))--攻方剩余人数:
	self.panelUI:getChildByName("txt_50"):getChildByName("txt"):setString(getTextByKey("UnionWar_reward_enemy"))--守方剩余人数:
	self.panelUI:getChildByName("txt_20"):getChildByName("txt"):setString(self.battleData.attUnionLeftPlayer)
	self.panelUI:getChildByName("txt_30"):getChildByName("txt"):setString(self.battleData.defUnionLeftPlayer)

	--显示当前积分
	if self.battleType == BattleEnterEnum.kCrossGVGGroupBattle then
		--小组赛
		self.panelUI:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("WGVG_Detail53"))--您当前的积分是
		self.panelUI:getChildByName("txt_5"):getChildByName("txt"):setString(self.currentPoint)

		--显示分数变化
		local name
		if self.battleData.warWin then
			name = getTextByKey("WGVG_Detail54")--提升
		else
			name = getTextByKey("WGVG_Detail55")--降低
		end
		self.panelUI:getChildByName("txt_4"):getChildByName("txt"):setString(getTextByKey("WGVG_Detail56", {name = name}))--本次{name}：
		self.panelUI:getChildByName("txt_Gvg_27"):getChildByName("txt"):setString(self.changePoint)
	elseif self.battleType == BattleEnterEnum.kCrossGVGRankBattle then
		--淘汰赛
		--不显示 资源本身就没有
	end
end


function CrossUnionPkBattleResultPanel:dispose()
	CrossUnionPkBattleResultPanel.super.dispose(self)
end

--关闭对话框
function CrossUnionPkBattleResultPanel:close()
	PopoutManager:sharedManager():pullin(self, kPopoutDir.kScale )
	if self.battleType == BattleEnterEnum.kCrossGVGRankBattle then
		--淘汰赛结算 返回淘汰赛主界面
		CrossUnionPk.gotoKnockoutScene(true)
	else
		--默认情况 返回gvg主界面
		CrossUnionPk.gotoTeamAdjustScene(true)
	end
end

-------------------------------------------------------------------------------------------------------------
