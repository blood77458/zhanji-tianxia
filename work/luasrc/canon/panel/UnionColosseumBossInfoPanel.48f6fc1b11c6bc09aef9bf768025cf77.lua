--
-- UnionColosseumBossInfoPanel.lua
-- Author: zheng.che
-- Date: 2014-05-27 16:28:47
-- 军团斗兽场boss信息面板
--
local visibleSize = CCDirector:sharedDirector():getVisibleSize()

--显示排名
local function onRankBtnClick(evt)
	local self = evt.context
	--print("onRankBtnClick!")
	local function onSucceed(requestEvent)
		--默认处理
		UnionColosseumGetRankRequest.onSucceedDefault(requestEvent)

		--弹出窗口
		local scene = Director:mgr():run()
		scene.targetInfoPanel = UnionColosseumRankPopPanel:create(scene)
		PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)
	end
	UnionColosseumGetRankRequest.sendRequest(onSucceed, UnionColosseumGetRankRequest.onFailedDefault)
end

--挑战
local function onChallengeBtnClick(evt)
	--print("onChallengeBtnClick!")
	local self = evt.context
	UnionColosseumChallengeRequest.sendRequest(UnionColosseumChallengeRequest.onSucceedDefault, UnionColosseumChallengeRequest.onFailedDefault)
end

---------------------------------------------------------------------------------------------

UnionColosseumBossInfoPanel = class(Layer)

function UnionColosseumBossInfoPanel:ctor()
	self.container = nil
	self.sourceDisplay = nil
end

function UnionColosseumBossInfoPanel:create( container, sourceDisplay )
	local s = UnionColosseumBossInfoPanel.new()
	s:initLayer(container, sourceDisplay)
	return s
end

function UnionColosseumBossInfoPanel:initLayer(container, sourceDisplay)
	local function refreshSelf()
	end
	self.refreshSelf = refreshSelf

	local function onTimeTick(remainedSec)
		local formatedTimeStr = TimeUtil.formatTime(remainedSec)
		self.sourceDisplay:getChildByName("txt_guild_44"):getChildByName("txt"):setString(formatedTimeStr)--[逃跑倒计时]
	end
	self.onTimeTick = onTimeTick

	local function onTimeComplete()
		--时间已过 怪物已逃跑
		--刷新数据内容(奖励信息后端给)
		local function onSucceed(requestEvent)
			UnionColosseumBuildingInfoRequest.onSucceedDefault(requestEvent)
			--父容器刷新
			self.container.refreshSelf()
		end
		UnionColosseumBuildingInfoRequest.sendRequest(onSucceed, UnionColosseumBuildingInfoRequest.onFailedDefault)
	end
	self.onTimeComplete = onTimeComplete
	
	--加测试粒子效果
	local function addParticle(effectPath)
		local particle = CCParticleSystemQuad:create(effectPath)
		particle:setPosition(ccp(0, 0))
		particle:setScale(2.5)
		self.sourceDisplay:getChildByName("space"):addChild(CocosObject.new(particle))
	end

	UnionColosseumBossInfoPanel.super.initLayer(self)

	self.container = container
	self.sourceDisplay = sourceDisplay
	self.dataList = {}

	self.sourceDisplay:setVisible(true)

	--无变化文字
	self.sourceDisplay:getChildByName("txt_guild_48"):getChildByName("txt"):setString(getTextByKey("union_monster_summon_player_name_txt"))--召唤者：
	self.sourceDisplay:getChildByName("txt_guild_45"):getChildByName("txt"):setString(getTextByKey("union_monster_escape_last_time"))--后逃走
	self.sourceDisplay:getChildByName("txt_guild_47"):getChildByName("txt"):setString(getTextByKey("union_monster_reward_double_use"))--奖励翻倍已开启
	self.sourceDisplay:getChildByName("txt-guild_49"):getChildByName("txt"):setString(getTextByKey("union_monster_hurt_turns_mine_txt"))--我的排名
	self.sourceDisplay:getChildByName("union_monster_fi_times-max_emind"):getChildByName("txt"):setString(getTextByKey("union_monster_fight_times_max_remind"))--今日挑战次数已达上限

	--排名按钮
	self.rankBtnDisplay = self.sourceDisplay:getChildByName("btn_yanking_view")
	self.rankBtnDisplay:getChildByName("txt"):setString(getTextByKey("union_monster_hurt_turns_button"))--排名
	self.rankBtn = CanonButton:create(self.rankBtnDisplay)
	self.rankBtn:addEventListener(Events.kStart, onRankBtnClick, self)

	--挑战按钮
	self.challengeBtnDisplay = self.sourceDisplay:getChildByName("btn_guild_colosseum_challenge")
	self.challengeBtnDisplay:getChildByName("txt"):setString(getTextByKey("union_monster_fight_button"))--挑战怪兽
	self.challengeBtn = CanonButton:create(self.challengeBtnDisplay, true)
	self.challengeBtn:addEventListener(Events.kStart, onChallengeBtnClick, self)

	--显示boss形象和名称
	local bossDataList = UnionManager.getColosseumBossConfigList()
	local currentBossMetaId = UnionManager.getColosseumMonsterMetaId()
	for k, bossConfigData in ipairs(bossDataList) do
		local showThisBoss = (bossConfigData.id == currentBossMetaId)

		local bossDisplay = self.sourceDisplay:getChildByName("icon_monster_" .. bossConfigData.cardPic)
		if bossDisplay then
			bossDisplay:setVisible(showThisBoss)
		else
			print("军团斗兽场美术资源缺少boss图片的层名! target = " .. "icon_monster_" .. bossConfigData.cardPic)
		end

		local bossNameDisplay = self.sourceDisplay:getChildByName("lbl_monster_" .. bossConfigData.cardPic)
		if bossNameDisplay then
			bossNameDisplay:setVisible(showThisBoss)
		else
			print("军团斗兽场美术资源缺少boss名称的层名! target = " .. "lbl_monster_" .. bossConfigData.cardPic)
		end

		--显示对应特效
		if showThisBoss then
			addParticle("effect/fx_union_colosseum_boss_" .. bossConfigData.cardPic .. ".plist")
		end
	end

	--显示排名预览
	local rankList = UnionManager.getColosseumRanks()
	local rank1 = rankList[1]
	local rank2 = rankList[2]
	local rank3 = rankList[3]
	if rank1 then
		self.sourceDisplay:getChildByName("txt_guild_member_name_l_2"):setVisible(true)

		self.sourceDisplay:getChildByName("txt_guild_member_name_l_2"):getChildByName("txt"):setString(rank1.nickName)--[用户昵称]
	else
		self.sourceDisplay:getChildByName("txt_guild_member_name_l_2"):setVisible(false)
	end
	if rank2 then
		self.sourceDisplay:getChildByName("txt_guild_member_name_l_3"):setVisible(true)

		self.sourceDisplay:getChildByName("txt_guild_member_name_l_3"):getChildByName("txt"):setString(rank2.nickName)--[用户昵称]
	else
		self.sourceDisplay:getChildByName("txt_guild_member_name_l_3"):setVisible(false)
	end
	if rank3 then
		self.sourceDisplay:getChildByName("txt_guild_member_name_l_4"):setVisible(true)

		self.sourceDisplay:getChildByName("txt_guild_member_name_l_4"):getChildByName("txt"):setString(rank3.nickName)--[用户昵称]
	else
		self.sourceDisplay:getChildByName("txt_guild_member_name_l_4"):setVisible(false)
	end

	--我的排名
	local myRank = UnionManager.findMyRank()
	if myRank ~= -1 then
		self.sourceDisplay:getChildByName("txt_guild_14"):getChildByName("txt"):setString(myRank)--[我的排名]
	else
		self.sourceDisplay:getChildByName("txt_guild_14"):getChildByName("txt"):setString(getTextByKey("union_monster_hurt_turns_no"))--未参与
	end

	--召唤者
	self.sourceDisplay:getChildByName("txt_guild_member_name_l_1"):getChildByName("txt"):setString(UnionManager.getColosseumMonsterCallerNick())

	--消耗道具名称和数量
	local costItemMetaId = UnionManager.getUnionMonsterFightItem()
	local currentNum = BagCalcManager.getNumById(costItemMetaId)
	self.sourceDisplay:getChildByName("txt_guild_46"):getChildByName("txt"):setString("x1 " .. getTextByKey("union_monster_brackets", {num = currentNum}))

	--显示血条
	local currentHp = UnionManager.getColosseumMonsterCurrentHp()
	local maxHp = UnionManager.getBossMaxHp(UnionManager.getColosseumMonsterMetaId())
	local hpBarBg = Sprite:create("battle/pic/xuecao.png")
	hpBarBg:setPosition(ccp(visibleSize.width/2, 894 - 103))
	hpBarBg:setScaleX(0.6)
	self.sourceDisplay:addChild(hpBarBg)
	local aPercentage = currentHp / maxHp * 100.0
	self.enemyHpPB = CCProgressTimer:create(CCSprite:create("battle/pic/xue.png"))
	self.enemyHpPB:setPosition(ccp(visibleSize.width/2, 894 - 103))
	self.enemyHpPB:setType(kCCProgressTimerTypeBar);
	self.enemyHpPB:setMidpoint(ccp(0,1))
	self.enemyHpPB:setBarChangeRate(ccp(1, 0))
	self.enemyHpPB:setPercentage(aPercentage)
	self.enemyHpPB:setScaleX(0.6)
	self.sourceDisplay:addChild(CocosObject.new(self.enemyHpPB))
	local aBloodLabel = ArtLabelTTF:create(string.format("%d/%d", currentHp, maxHp), true)
	--aBloodLabel:setCenterColor(ccc3(255,236,60))
	--aBloodLabel:setAroundColor(ccc3(96,37,8))
	aBloodLabel:setSize(35 * 0.8)
	aBloodLabel:construct()
	aBloodLabel:setPosition(ccp(visibleSize.width/2, 891 - 100))
	self.sourceDisplay:addChild(CocosObject.new(aBloodLabel))

	--倒计时组件
	self.cdLabelComponent = CdLabelComponent:create()
	self.cdLabelComponent:setCallback(self.onTimeTick, self.onTimeComplete)
	self.cdLabelComponent:setTargetTime(UnionManager.getColosseumMonsterRunTime())
	self.cdLabelComponent:start()

	--挑战按钮状态
	if UnionManager.colosseumCanClickChallengeBtn() then
		--可以点击
		self.challengeBtn:setEnable(true)
	else
		--不可点击
		self.challengeBtn:setEnable(false)
	end

	--挑战按钮下面的文字状态
	local currentTimes = DailyDataManager.getChallengeUnionMonsterTimes()
	local maxTimes = UnionManager.getUnionMonsterPlayerAttMax()
	local leftTimes = maxTimes - currentTimes
	if leftTimes <= 0 then
		--今日挑战次数不足
		self.sourceDisplay:getChildByName("union_monster_fi_times-max_emind"):setVisible(true)
		
		self.sourceDisplay:getChildByName("icon_fight_can"):setVisible(false)
		self.sourceDisplay:getChildByName("txt_guild_46"):setVisible(false)
	else
		self.sourceDisplay:getChildByName("union_monster_fi_times-max_emind"):setVisible(false)
		
		self.sourceDisplay:getChildByName("icon_fight_can"):setVisible(true)
		self.sourceDisplay:getChildByName("txt_guild_46"):setVisible(true)
	end

	--是否翻倍状态
	if UnionManager.getColosseumMonsterIsDouble() then
		--翻倍
		self.sourceDisplay:getChildByName("txt_guild_47"):setVisible(true)
		self.sourceDisplay:getChildByName("bg_guild_fight_prompt"):setVisible(true)
	else
		--没翻倍
		self.sourceDisplay:getChildByName("txt_guild_47"):setVisible(false)
		self.sourceDisplay:getChildByName("bg_guild_fight_prompt"):setVisible(false)
	end

	self.refreshSelf()
end

function UnionColosseumBossInfoPanel:dispose()
	if self.cdLabelComponent then
		self.cdLabelComponent:dispose()
		self.cdLabelComponent = nil
	end

	UnionColosseumBossInfoPanel.super.dispose(self)
end

function UnionColosseumBossInfoPanel:panelEnter(callback)
	--print("UnionColosseumBossInfoPanel:panelEnter")
	if callback then
		callback()
	end
end

function UnionColosseumBossInfoPanel:panelExit(callback)
	--print("UnionColosseumBossInfoPanel:panelExit")
	self.sourceDisplay:setVisible(false)
	if callback then
		callback()
	end
end

--设置触摸是否开启
function UnionColosseumBossInfoPanel:setTableViewTouched(enabled)
end