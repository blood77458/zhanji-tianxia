-- CrossUnionPKTeamAdjustScene.lua
-- zheng.che
-- 2014-7-24
-- 军团战场景

local visibleSize = CCDirector:sharedDirector():getVisibleSize()

local enter_animation_duration = 0.3
local selectedText = ""

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == nil)
end

-------------------------------------------------------------------------------
-- 按钮点击
-------------------------------------------------------------------------------
--点击返回
local function onBackBtnClick(evt)
	local self = evt.context
	self:back()
end

local function onPassDay( evt )
	local stage = CrossUnionPkUtils.findCurrentTimeLevel()
	if stage ~= CrossUnionPkConsts.TIME_ARMY1_FIGHTING then
		return
	end
	--更新战斗次数
	CrossUnionPkData.setChallengeNum(0)
	local self = evt.context
	self:refreshFightBtn()
end

--点击问号
local function onQaBtnClick(evt)
	local self = evt.context
  -- self:setTableViewsEnabled(false)
  --ReNameCoolingPanel
  local aInfoPanel = ActivityInfoPanel:create(self, getTextByKey("WGVG_Detail44"))
  self:addChild(aInfoPanel)
  aInfoPanel:scaleIn()
end

--点击排名
local function onRankBtnClick(evt)
	CrossUnionPk.popGroupRankPanel()
end

-------------------------------------------------------------------------------
-- 事件侦听
-------------------------------------------------------------------------------

--焦点变化事件
local function onFocusChanged(evt)
	evt.context:setTableViewsEnabled(evt.data == nil)
end

--时间段更新事件
local function onTimelevelUpdate(evt)
	local self = evt.context
	local function onAfterSucceed(evt)
		self:refreshSelf()
	end
	local stage = CrossUnionPkUtils.findCurrentTimeLevel()
	if stage == CrossUnionPkConsts.TIME_GROUP_REWARD then
		CrossUnionPk.gotoCrossLoginUnionPkScene()
	elseif stage == CrossUnionPkConsts.TIME_ARMY2_FIGHTING_16 then
		CrossUnionPk.gotoCrossLoginUnionPkScene()
	else
		GetCrossGvgInfoRequest.sendRequestDefalut(onAfterSucceed)
	end
	
end

--刷新自己
local function onRefreshSelf( evt )
	local self = evt.context
	local function onAfterSucceed(evt)
		self:refreshSelf()
	end
	GetCrossGvgInfoRequest.sendRequestDefalut(onAfterSucceed)
end

local function onRefreshShineSaveTeam( evt )
	local self = evt.context
	if not CrossUnionPkData.getTeamMirrorRemind() and not CrossUnionPkData.getTeamAdjustLightOn() then
		self:refreshShineSaveTeamBtn(false)
	else
		self:refreshShineSaveTeamBtn(true)
	end
end

local function onRefershBattleUI( evt )
	local self = evt.context

	self:refreshBattleUI()
end

local function onRefreshShineDailyReports( evt )
	local self = evt.context
	self:refreshShineDailyReportsBtn(false)
end
--------------------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- 初始化处理
-------------------------------------------------------------------------------

CrossUnionPKTeamAdjustScene = class(BaseUIScene)

function CrossUnionPKTeamAdjustScene:ctor()
end

function CrossUnionPKTeamAdjustScene:create(argv)
	local s = CrossUnionPKTeamAdjustScene.new()
	if argv then 
		s.argv = argv 
	else
		s.argv = {enterScene=nil,returnScene=nil,params={}}
	end
	s.curSceneEnum = SceneEnum.CrossUnionPKTeamAdjustScene

	--当前显示中的列表内容(注意: 子panel可能读取)
	s.selectedDataList = {}
	s:initScene()
	return s
end

function CrossUnionPKTeamAdjustScene:onInit()
	BaseUIScene.initBackGround(self)

	local builder = LayoutBuilder:createWithContentsOfFile("scene/Gvg.json")
	builder.useArtLabelTTF = true


	-- local topUI = builder:build("endbattle/GvG_endbattle")
	-- self:addChild(topUI)
	-- self.titleUI = topUI

	local ui = builder:build("GvG_ongoing")
	self:addChild(ui)
	self.mainUI = ui

	local titleUI = builder:build("Gvg_colosseuml_title")
	self:addChild(titleUI)
	self.titleUI = titleUI
	self.titleUI:setPositionY(visibleSize.height-35)

	--静态文本
	self.mainUI:getChildByName("txt_Gvg_12"):getChildByName("txt"):setString(getTextByKey("WGVG_Detail18"))
	self.mainUI:getChildByName("txt_Gvg_12_2"):getChildByName("txt"):setString(getTextByKey("WGVG_Detail19"))
	self.mainUI:getChildByName("txt_3_2"):getChildByName("txt"):setString(getTextByKey("UnionWar_battle_firstArray"))
	self.mainUI:getChildByName("txt_5_2"):getChildByName("txt"):setString(getTextByKey("UnionWar_battle_array"))
	self.mainUI:getChildByName("txt_6"):getChildByName("txt"):setString(getTextByKey("UnionWar_battle_lastArray"))

	self.mainUI:getChildByName("txt_3"):getChildByName("txt"):setString(getTextByKey("UnionWar_battle_mine"))
	self.mainUI:getChildByName("txt_4"):getChildByName("txt"):setString(getTextByKey("UnionWar_battle_union"))
	self.mainUI:getChildByName("txt_5"):getChildByName("txt"):setString(getTextByKey("UnionWar_battle_win"))

	--按钮
	local backButton = Button:create(titleUI:getChildByName("r_click"))
	backButton:addEventListener(Events.kStart, onBackBtnClick, self)

	local qaButton = Button:create(titleUI:getChildByName("sky_btn_qa"))
	qaButton:addEventListener(Events.kStart, onQaBtnClick, self)

	local rankButton = Button:create(titleUI:getChildByName("icon_Gvg_ranking"))
	rankButton:addEventListener(Events.kStart, onRankBtnClick, self)
	self.rankButton = rankButton

	local function onClickPioneer( evt )
		local title = UnionManager.getMyTitle()
    	if title == UnionManager.TITLE_ELITE_MEMBER or title == UnionManager.TITLE_MEMBER then
    		--如果是精英或者普通成员
    		return
    	end
		CrossUnionPkData.setCurrentSelectedPos(1)
		CrossUnionPk.gotoMemberSelectScene()
	end

	local function onClickInspire( id )
		self.inspireType = id
		local function afterSucceedCallback( evt )
			self:refreshGemAndCoin()
			self:refreshButtonsUI()
		end
		local params = {type = id}
		InspireCrossGvgRequest.sendRequestDefalut(params , afterSucceedCallback)
	end

	local btn = Button:create(self.mainUI:getChildByName("normal_card_small_Gvg"))
	btn:addEventListener(Events.kStart, onClickPioneer, self)

	local function onCoinInspire( evt )
		print("onCoinInspire")
		onClickInspire(2)
	end

	self.coinInspireBtn = Button:create(self.mainUI:getChildByName("btn_1"))
	self.coinInspireBtn:addEventListener(Events.kStart, onCoinInspire, self)

	local function onGemInspire( evt )
		print("onGemInspire")
		onClickInspire(1)
	end

	self.gemInspireBtn = Button:create(self.mainUI:getChildByName("btn_2"))
	self.gemInspireBtn:addEventListener(Events.kStart, onGemInspire, self)

	local function onForceFight( evt )
		print("onForceFight")
		onClickInspire(3)
	end

	self.forceFightBtn = Button:create(self.mainUI:getChildByName("btn_3"))
	self.forceFightBtn:addEventListener(Events.kStart, onForceFight, self)
-- UnionManager.TITLE_NONE 			= 0--无职位(历史职位可能出现此值)
-- UnionManager.TITLE_MANAGER 			= 1--军团长
-- UnionManager.TITLE_VICE_MANAGER 	= 2--副军团长
-- UnionManager.TITLE_ELITE_MEMBER 	= 3--精英成员
-- UnionManager.TITLE_MEMBER 			= 4--普通成员

	local function onClickSave( evt )
		print("onClickSaveTeam")
		local title = UnionManager.getMyTitle()
		if title == UnionManager.TITLE_MANAGER or title == UnionManager.TITLE_VICE_MANAGER then
			--弹框
			self.targetInfoPanel = CrossUnionPkUpdatePanel:create()
		    PopoutManager:sharedManager():popout(self.targetInfoPanel, kPopoutDir.kScale, true, false , self)
		else
			CanonMessageBox.showText(
		        ShowButtonType.ID_OK_CANCEL,
		        getTextByKey("WGVG_Detail09"),
		        {
		            text = getTextByKey("yes"),
		            callbackFunc = function()
		                UploadCrossGvgTeamMirrorRequest.sendRequestDefalut()
		            end
		        }
		    )
		end
	end

	self.saveTeamBtn = Button:create(self.mainUI:getChildByName("btn_guildppk_reguistred"))
	self.saveTeamBtn:addEventListener(Events.kStart, onClickSave, self)
	self.mainUI:getChildByName("btn_guildppk_reguistred"):getChildByName("txt"):setString(getTextByKey("WGVG_Detail07-4"))

--今日战报
	local function onClickReview( evt )
		print("onClickReview")
		local stage = CrossUnionPkUtils.findCurrentTimeLevel()
		if stage == CrossUnionPkConsts.TIME_ARMY1_FIGHTING then--军团战战斗阶段
			--弹出每日战报
			CrossUnionPk.popGroupReport()
		elseif stage == CrossUnionPkConsts.TIME_ARMY2_PREPARE then--军团战淘汰才准备阶段
			--弹出服务器分组
			CrossUnionPk.popServerInfoPanel()
		end
	end

	self.reviewBtn = Button:create(self.mainUI:getChildByName("btn_guildppk_reguistred2"))
	self.reviewBtn:addEventListener(Events.kStart, onClickReview, self)

	local function onClickFight( evt )
		print("onClickFight")
		CrossUnionPkGroupBattleRequest.sendRequestDefalut()
	end

	self.fightBtn = Button:create(self.mainUI:getChildByName("btn_GvG_fighting"))
	self.fightBtn:addEventListener(Events.kStart, onClickFight, self)

	self.mainUI:getChildByName("btn_guildppk_reguistred"):getChildByName("btn_light_upyellow"):setVisible(false)
	self.mainUI:getChildByName("btn_guildppk_reguistred2"):getChildByName("btn_light_upyellow"):setVisible(false)

	if CrossUnionPkData.getTeamMirrorRemind() or CrossUnionPkData.getTeamAdjustLightOn() then
		self:refreshShineSaveTeamBtn(true)
	end

	local stage = CrossUnionPkUtils.findCurrentTimeLevel()
	if CrossUnionPkData.getGroupChallengedRemind() and stage == CrossUnionPkConsts.TIME_ARMY1_FIGHTING then
		self:refreshShineDailyReportsBtn(true)
	end

	BaseUIScene.onInit(self, SceneMenuTypeEnum.UNION)

	self.mainUI:getChildByName("table_GvG_list1"):setVisible(false)

	self:refreshBattleUI()

	self:refreshGemAndCoin()

	self:refreshButtonsUI()

	self:refreshFightBtn()

	self:refreshTitle()
	--其他初始化操作

	UiStackManager_EventDispatcher:addEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged, self)

	UnionManager.eventDispatcher:addEventListener(CrossUnionPkConsts.NEED_REFRESH_TEAM_ADJUST_SCENE, onRefreshSelf, self)
	UnionManager.eventDispatcher:addEventListener(CrossUnionPkConsts.REFRESH_SHINE_SAVE_TEAM, onRefreshShineSaveTeam, self)
	UnionManager.eventDispatcher:addEventListener(CrossUnionPkConsts.REFRESH_SHINE_DAILY_REPORTS, onRefreshShineDailyReports, self)

	UnionManager.eventDispatcher:addEventListener(CrossUnionPkConsts.REFRESH_BATTLE_UI, onRefershBattleUI, self)


	NotificationManager:addEventListener(PassDayManager.PASS_DAY, onPassDay, self)

	UnionManager.eventDispatcher:addEventListener(CrossUnionPkConsts.UNIONPK_TIMELEVEL_PASSED, onTimelevelUpdate, self)
end

-----------------------------------------------内部接口------------------------------------------------------------

function CrossUnionPKTeamAdjustScene:refreshShineSaveTeamBtn(isShine)
	local shineObj = self.mainUI:getChildByName("btn_guildppk_reguistred"):getChildByName("btn_light_upyellow")
	self.saveTeamBtn:setShined(isShine , shineObj)
end

function CrossUnionPKTeamAdjustScene:refreshShineDailyReportsBtn( isShine )
	local shineObj = self.mainUI:getChildByName("btn_guildppk_reguistred2"):getChildByName("btn_light_upyellow")
	self.reviewBtn:setShined(isShine , shineObj)
end

function CrossUnionPKTeamAdjustScene:refreshTitle()
	local function getCurrentTeamName()
		local text = {
		[1] = "WGVG_Name01",
		[2] = "WGVG_Name02",
		[3] = "WGVG_Name03",
		[4] = "WGVG_Name04",
	}
		local score = CrossUnionPkData.getCrossGvgScore()

		local tempTxt = getTextByKey("arena_pointsTableTxt") .. ":" .. score

		local config = CrossUnionPkConfig.getSettingConfig().groupIntervals

		local index = 1
		for k,v in pairs(config) do
			if score >= v.regionMin and score < v.regionMax then
				index = k
			end
		end

		return getTextByKey(text[index]) .. getTextByKey("WGVG_Detail62") .. tempTxt
	end

	local stage = CrossUnionPkUtils.findCurrentTimeLevel()
	if stage == CrossUnionPkConsts.TIME_ARMY1_PREPARE then
		self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_08"):getChildByName("txt"):setString(getTextByKey("WGVG_title01"))
	elseif stage == CrossUnionPkConsts.TIME_ARMY1_FIGHTING then
		local teamName = getCurrentTeamName()
		self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_08"):setVisible(false)
		self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_09"):getChildByName("txt"):setString(getTextByKey("WGVG_title01"))
		self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_10"):getChildByName("txt"):setString(teamName)
	elseif stage == CrossUnionPkConsts.TIME_ARMY2_PREPARE then
		self.titleUI:getChildByName("bg_Gvg_title"):getChildByName("txt_Gvg_08"):getChildByName("txt"):setString(getTextByKey("WGVG_title07"))
	end
end

function CrossUnionPKTeamAdjustScene:refreshFightBtn()
	local stage = CrossUnionPkUtils.findCurrentTimeLevel()
	self.fightBtn:setEnable(true)
	self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("normal"):setVisible(true)
	self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt"):setString(getTextByKey("WGVG_Detail08"))
	local lastFightNum = CrossUnionPkConfig.getSettingConfig().wGVGTime - CrossUnionPkData.getChallengeNum()
	self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt_1"):setString("("..lastFightNum..")")
	self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt_2"):setString(getTextByKey("WGVG_Detail49"))
	self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt_3"):setString(getTextByKey("WGVG_Detail50"))

	--全部隐掉, 再打开
	self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt"):setVisible(false)
	for i=1,4 do
		self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt_"..i):setVisible(false)
	end
	local title = UnionManager.getMyTitle()
	if (title == UnionManager.TITLE_MANAGER or title == UnionManager.TITLE_VICE_MANAGER) then
		if stage == CrossUnionPkConsts.TIME_ARMY1_PREPARE then
			self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("normal"):setVisible(false)
			self.fightBtn:setEnable(false)
			self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt"):setVisible(true)
			-- self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt_1"):setVisible(true)
		elseif stage == CrossUnionPkConsts.TIME_ARMY1_FIGHTING and lastFightNum > 0 then
			self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt"):setVisible(true)
			self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt_1"):setVisible(true)
		elseif stage == CrossUnionPkConsts.TIME_ARMY1_FIGHTING and lastFightNum <= 0 then
			self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("normal"):setVisible(false)
			self.fightBtn:setEnable(false)
			self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt"):setVisible(true)
			self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt_1"):setVisible(true)
		elseif stage == CrossUnionPkConsts.TIME_ARMY2_PREPARE then
			if self.fightBtnCdLabelComponent then
				self.fightBtnCdLabelComponent:dispose()
				self.fightBtnCdLabelComponent = nil
			end
			local function onTimeTick(remainedSec)
				local formatedTimeStr = TimeUtil.formatTime(remainedSec)
				self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt_4"):setString(formatedTimeStr)
			end
			self.fightBtnCdLabelComponent = CdLabelComponent:create()
			self.fightBtnCdLabelComponent:setCallback(onTimeTick, nil)
			local startTime, endTime = CrossUnionPkUtils.findTImeLevelStartAndEndTime(CrossUnionPkConsts.TIME_ARMY2_PREPARE) --这个接口不支持跨界
			self.fightBtnCdLabelComponent:setTargetTime(endTime)
			self.fightBtnCdLabelComponent:start()
			self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt_2"):setVisible(true)
			self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt_3"):setVisible(true)
			self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt_4"):setVisible(true)
			self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("normal"):setVisible(false)
			self.fightBtn:setEnable(false)
		end
	else
		if stage == CrossUnionPkConsts.TIME_ARMY2_PREPARE then
			if self.fightBtnCdLabelComponent then
				self.fightBtnCdLabelComponent:dispose()
				self.fightBtnCdLabelComponent = nil
			end
			local function onTimeTick(remainedSec)
				local formatedTimeStr = TimeUtil.formatTime(remainedSec)
				self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt_4"):setString(formatedTimeStr)
			end
			self.fightBtnCdLabelComponent = CdLabelComponent:create()
			self.fightBtnCdLabelComponent:setCallback(onTimeTick, nil)
			local startTime, endTime = CrossUnionPkUtils.findTImeLevelStartAndEndTime(CrossUnionPkConsts.TIME_ARMY2_PREPARE) --这个接口不支持跨界
			self.fightBtnCdLabelComponent:setTargetTime(endTime)
			self.fightBtnCdLabelComponent:start()
			self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt_2"):setVisible(true)
			self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt_3"):setVisible(true)
			self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt_4"):setVisible(true)
			self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("normal"):setVisible(false)
			self.fightBtn:setEnable(false)
		else
			self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("normal"):setVisible(false)
			self.fightBtn:setEnable(false)
			self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt"):setVisible(true)
			self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("txt_1"):setVisible(true)
		end
	end
	
end

function CrossUnionPKTeamAdjustScene:refreshSelf()
	self:refreshBattleUI()
	self:refreshButtonsUI()
	self:refreshGemAndCoin()
	self:refreshFightBtn()
	self:refreshTitle()
end
--刷新阵型啥的相关的UI
function CrossUnionPKTeamAdjustScene:refreshBattleUI()
	local tableOffset = nil
	if self.tableView then
		tableOffset = self.tableView:getContentOffset()
		self.tableView:removeFromParentAndCleanup(true)
	end
	local data = self:sortInBattleMembers()
	self.tableView = self:createTableView(self.mainUI:getChildByName("table_GvG_list1") , data)
	self.mainUI:addChild(self.tableView)

	if tableOffset ~= nil then
		self.tableView:setContentOffset(tableOffset)
	end

	self:showPioneerMember()

	local inBattleNum = self:getInBattleMemberNum()
	local tatolNum = self:getTotalMemberNum()
	local maxNum = CrossUnionPkConfig.getSettingConfig().teamMax *3 + 1
	self.mainUI:getChildByName("txt_Gvg_13"):getChildByName("txt"):setString(inBattleNum .. "/" .. maxNum)
	self.mainUI:getChildByName("txt_Gvg_13_2"):getChildByName("txt"):setString(tatolNum)
end

--刷新下面这些蛋疼按钮的UI
function CrossUnionPKTeamAdjustScene:refreshButtonsUI()
	local coinInspireValue = CrossUnionPkData.getCoinInspireValue()
	local gemInspireValue = CrossUnionPkData.getGemInspireValue()
	local striveInpireValue = CrossUnionPkData.getStriveInspireNum()
	self.mainUI:getChildByName("txt_7"):getChildByName("txt"):setString("+"..coinInspireValue * UnionPkConfig.silverBuff().."%")--银币
	self.mainUI:getChildByName("txt_8"):getChildByName("txt"):setString("+"..gemInspireValue * UnionPkConfig.goldBuff().."%")--金币
	if striveInpireValue >= UnionPkConfig.striveNum() then
		self.forceFightBtn:setEnable(false)
		self.mainUI:getChildByName("btn_3"):getChildByName("normal"):setVisible(false)
	else
		self.forceFightBtn:setEnable(true)
		self.mainUI:getChildByName("btn_3"):getChildByName("normal"):setVisible(true)
	end

	--银币鼓舞达到上限
	if coinInspireValue >= UnionPkConfig.silverBuffNum() then
		self.coinInspireBtn:setEnable(false)
		self.mainUI:getChildByName("btn_1"):getChildByName("normal"):setVisible(false)
	else
		self.coinInspireBtn:setEnable(true)
		self.mainUI:getChildByName("btn_1"):getChildByName("normal"):setVisible(true)
	end

	--金币上限 
	if gemInspireValue >= UnionPkConfig.goldBuffNum() then
		self.gemInspireBtn:setEnable(false)
		self.mainUI:getChildByName("btn_2"):getChildByName("normal"):setVisible(false)
	else
		self.gemInspireBtn:setEnable(true)
		self.mainUI:getChildByName("btn_2"):getChildByName("normal"):setVisible(true)
	end

	local stage = CrossUnionPkUtils.findCurrentTimeLevel()
	if stage == CrossUnionPkConsts.TIME_ARMY1_PREPARE then--军团战准备阶段
		-- self.fightBtn:setEnable(false)
		self.reviewBtn:setEnable(false)
		-- self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("normal"):setVisible(false)
		self.mainUI:getChildByName("btn_guildppk_reguistred2"):getChildByName("normal"):setVisible(false)
		self.mainUI:getChildByName("btn_guildppk_reguistred2"):getChildByName("txt"):setString(getTextByKey("WGVG_Detail07-5"))
	elseif stage == CrossUnionPkConsts.TIME_ARMY1_FIGHTING then--军团战战斗阶段
		self.reviewBtn:setEnable(true)
		-- self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("normal"):setVisible(true)
		self.mainUI:getChildByName("btn_guildppk_reguistred2"):getChildByName("normal"):setVisible(true)
		self.mainUI:getChildByName("btn_guildppk_reguistred2"):getChildByName("txt"):setString(getTextByKey("WGVG_Detail07-5"))
	elseif stage == CrossUnionPkConsts.TIME_ARMY2_PREPARE then--军团战淘汰才准备阶段
		-- self.fightBtn:setEnable(false)
		self.reviewBtn:setEnable(true)
		-- self.mainUI:getChildByName("btn_GvG_fighting"):getChildByName("normal"):setVisible(false)
		self.mainUI:getChildByName("btn_guildppk_reguistred2"):getChildByName("normal"):setVisible(true)
		self.mainUI:getChildByName("btn_guildppk_reguistred2"):getChildByName("txt"):setString(getTextByKey("WGVG_Detail21"))

		self.titleUI:getChildByName("icon_Gvg_ranking"):setVisible(false)--淘汰赛准备阶段不显示查看排名按钮
		self.rankButton:setEnable(false)
	end
end

--刷新上面的金币数据
function CrossUnionPKTeamAdjustScene:refreshGemAndCoin()
	local gem = CalculationManager.calcComplex_getGemsNow()
	self.titleUI:getChildByName("txt_Gvg_10_2"):getChildByName("txt"):setString(gem)
	local coin = DataManager.getGameInitData().sharkUser.coins
	self.titleUI:getChildByName("txt_Gvg_10"):getChildByName("txt"):setString(coin)
end
--整理阵上成员
function CrossUnionPKTeamAdjustScene:sortInBattleMembers()
	local signedMenbers = CrossUnionPkData.getAllSignedMenbers()
	local retTable = {}
	local oneNumInRow = CrossUnionPkConfig.getSettingConfig().teamMax
	for i=1,oneNumInRow do
		local temp = {nil , nil ,nil}
		table.insert(retTable , temp)
	end
	for k,v in pairs(signedMenbers) do
		if v.position >= 10 then
			local row = math.modf((v.position + 1) / 10)
			retTable[v.position + 1 - row*10][row] = v
		end
	end

	return retTable
end
--获取先锋战的数据
function CrossUnionPKTeamAdjustScene:getPioneerMember()
	local ret = nil
	local signedMenbers = CrossUnionPkData.getAllSignedMenbers()
	for k,v in pairs(signedMenbers) do
		if v.position == 1 then
			ret = v
		end
	end

	return ret
end

--获取总人数
function CrossUnionPKTeamAdjustScene:getTotalMemberNum()
	local signedMenbers = CrossUnionPkData.getAllSignedMenbers()
	return #signedMenbers
end

--获取上阵人数
function CrossUnionPKTeamAdjustScene:getInBattleMemberNum()
	local signedMenbers = CrossUnionPkData.getAllSignedMenbers()
	local total = 0
	for k,v in pairs(signedMenbers) do
		if v.position ~= 0 then
			total = total + 1
		end
	end
	return total
end

--显示先锋战的人
function CrossUnionPKTeamAdjustScene:showPioneerMember()
	if self.oldPioneerIcon then
		self.oldPioneerIcon:removeFromParentAndCleanup(true)
	end
	local pioneer = self:getPioneerMember()

	local builder = LayoutBuilder:createWithContentsOfFile("scene/Gvg.json")
	builder.useArtLabelTTF = true
	local ui = builder:build("GvG_ongoing")
	local sourceDisplay = ui:getChildByName("normal_card_small_Gvg"):getChildByName("normal_card_small")
	sourceDisplay:setVisible(false)
	local params = {}
	params.sourceDisplay = sourceDisplay
	params.showInCenter = true
	self.oldPioneerIcon = nil
	if pioneer ~= nil then
		self.oldPioneerIcon = CanonGoodIcon.createGoodIcon(ResourceEnum.CARD, pioneer.mainCardMetaId, 0, params)
		self.mainUI:getChildByName("txt_1"):getChildByName("txt"):setString(pioneer.userName)
		self.mainUI:getChildByName("txt_Gvg_14"):getChildByName("txt"):setString(pioneer.level)
		self.mainUI:getChildByName("icon_lv"):setVisible(true)
	else
		self.oldPioneerIcon = CanonGoodIcon.createGoodIcon(CanonGoodIcon.CARD_ADD, nil, 0, params)
		self.mainUI:getChildByName("txt_1"):getChildByName("txt"):setString("")
		self.mainUI:getChildByName("txt_Gvg_14"):getChildByName("txt"):setString("")
		self.mainUI:getChildByName("icon_lv"):setVisible(false)
	end
	
	self.mainUI:getChildByName("normal_card_small_Gvg"):addChildAt(self.oldPioneerIcon,sourceDisplay:getZOrder() - 10)

end

function CrossUnionPKTeamAdjustScene:createTableView(display , dataList)
    local cellTag = 1024

    local CrossUnionPKTeamAdjustRenderer = class(TableViewRenderer)

    function CrossUnionPKTeamAdjustRenderer:ctor(width , height )
        self.width = width
        self.height = height
        self.list = dataList or {}
    end

    function CrossUnionPKTeamAdjustRenderer:buildCell(container)
        local builder = LayoutBuilder:createWithContentsOfFile("scene/Gvg.json")
        local aCell = builder:build("list/GvG_list")
        container:addChild(aCell)
        aCell:setTag(cellTag)

        --扫描cell并自动添加tag
        self:addTags(aCell)
    end

    function CrossUnionPKTeamAdjustRenderer:setData(rawCocosObj, index)
        local aCell = self:getChildByTag(rawCocosObj, cellTag)
        local aData = self.list[index + 1]

        local function addItem( i )
			local aCardDisplay = self:getChildByNames(aCell, "item_employees"..i.."/normal_card_small")
	        local oldIcon = aCell:getChildByTag(-100 - i)
	        if oldIcon then
	          oldIcon:removeFromParentAndCleanup(true)
	        end
	        local params = {}
	        params.sourceDisplay = aCardDisplay
	        params.showInCenter = true

	        local iconType
	        if aData[i] == nil then
        		iconType = CanonGoodIcon.CARD_ADD
		    else
				iconType = ResourceEnum.CARD
	        end

	        local meta = nil
	        if aData[i] then
	        	meta = CommonManager:getSelfAvatarMetaByUid( aData[i].uid )
		        if not meta then
		        	meta = aData[i].mainCardMetaId
		        end
	        end
	        
	        local icon = CanonGoodIcon.createGoodIcon(iconType, meta, 0, params)
	        local iconContainer1 = self:getChildByNames(aCell, "item_employees"..i)
	        iconContainer1:addChild(icon.refCocosObj, aCardDisplay:getZOrder())
	        if icon then
	          icon:setTag(-100 - i)
	          icon:dispose()
	        end
	        aCardDisplay:setVisible(false)

	        self:getChildByNames(aCell, "item_employees"..i.."/icon_gold_inspire_number"):setVisible(false)
	        self:getChildByNames(aCell, "item_employees"..i.."/txt_2"):setVisible(false)
	        self:getChildByNames(aCell, "item_employees"..i.."/txt"):setVisible(false)
	        if iconType == ResourceEnum.CARD then
				self:getChildByNames(aCell, "item_employees"..i.."/icon_gold_inspire_number"):setVisible(true)
		        self:getChildByNames(aCell, "item_employees"..i.."/txt_2"):setVisible(true)
		        self:getChildByNames(aCell, "item_employees"..i.."/txt"):setVisible(true)

		        self:setTxtByNames(aCell, "item_employees"..i.."/txt_2/txt", getTextByKey("crossBoss_inspire")..":"..aData[i].gemInspireNum)
		        self:setTxtByNames(aCell, "item_employees"..i.."/txt/txt", aData[i].userName)
	        end
        end

        for i=1,3 do
        	addItem(i)
        end

        self:setTxtByNames(aCell, "txt/txt", tostring(index + 1))--行

        -- --不显示按钮
        -- self:getChildByNames(aCell, "btn"):setVisible(false)
    end

    local function onListItemTouch( evt )
    	local title = UnionManager.getMyTitle()
    	if title == UnionManager.TITLE_ELITE_MEMBER or title == UnionManager.TITLE_MEMBER then
    		--如果是精英或者普通成员
    		return
    	end

		local aIndex = evt.data + 1
		local newCell = self.tableView:cellAtIndex(aIndex - 1)
		local aCell = newCell:getChildByTag(cellTag)
		local posInCell = newCell:convertToNodeSpace(evt.globalPosition)

		-- local btnBgDisplay = self.renderer:getChildByNames(aCell, "btn/normal")
      	for i = 1, 3 do

			local memberDisplay = self.renderer:getChildByNames(aCell, "item_employees"..i):getChildByTag(-100 - i)
			-- local memberData = aData[i]
			local posInCell = memberDisplay:convertToNodeSpace(evt.globalPosition)

			-- local cardDisplay = memberDisplay:getChildByTag(-10)
			-- exchangeDisplay = cardDisplay
			exchangeSize = HeDisplayUtil:getNodeGroupBounds(memberDisplay, nil, kHitAreaObjectTag).size
			-- print("posInCell.x = " .. posInCell.x)
			-- print("posInCell.y = " .. posInCell.y)
			-- print("cardDisplay:getPositionX() = " .. cardDisplay:getPositionX())
			-- print("cardDisplay:getPositionY() = " .. cardDisplay:getPositionY())
			-- print("exchangeSize.width = " .. exchangeSize.width)
			-- print("exchangeSize.height = " .. exchangeSize.height)
			if posInCell.x > (memberDisplay:getPositionX() - exchangeSize.width / 2) and
			posInCell.x < (memberDisplay:getPositionX() + exchangeSize.width / 2) and
			posInCell.y > (memberDisplay:getPositionY() - exchangeSize.height / 2) and
			posInCell.y < (memberDisplay:getPositionY() + exchangeSize.height / 2) then
				--点击物品图标
				local pos = i * 10 + aIndex - 1
				CrossUnionPkData.setCurrentSelectedPos(pos)
				CrossUnionPk.gotoMemberSelectScene()
				return
			end
		end
    end

    local builder = LayoutBuilder:createWithContentsOfFile("scene/Gvg.json")
    local aCell = builder:build("list/GvG_list")

    local tableViewSizes = getTableViewSizes(display)
    tableViewSizes.table_height = tableViewSizes.table_height + 15--高度修正(因为上下边缘有文本框)
	tableViewSizes.table_width = tableViewSizes.table_width + 20--宽度修正(用于显示滚动条)
    display:setVisible(false)

    self.renderer = CrossUnionPKTeamAdjustRenderer.new(tableViewSizes.item_width, 183.45)
    self.renderer:scanTags(aCell)
    local aTableView = TableView:create(self.renderer, tableViewSizes.table_width, tableViewSizes.table_height, cellTag, {}, CCScale9Sprite:create("pic/scroll.png"), CCScale9Sprite:create("pic/scroll.png"))
    aTableView:setPosition(ccp(tableViewSizes.table_posX, tableViewSizes.table_posY))
    aTableView:addEventListener(DisplayEvents.kTouchItem, onListItemTouch , self)
    -- self.mainUI:addChild(aTableView)
    return aTableView
end

-----------------------------------------------外部接口------------------------------------------------------------

function CrossUnionPKTeamAdjustScene:setTableViewsEnabled(enabled)
	if self.tableView then
		self.tableView:setTouchEnabled(enabled)
	end
end

-----------------------------------------------进出场景动画------------------------------------------------------------
function CrossUnionPKTeamAdjustScene:doEnterAnimation()
	self:preEnterAnimation()
	self:startEnterAnimation()
end 

function CrossUnionPKTeamAdjustScene:preEnterAnimation()
	BaseUIScene.preEnterAnimation(self)
	--
	CanonPlayBackgroundMusic("music/m_unionPk.mp3", true)
end

function CrossUnionPKTeamAdjustScene:startEnterAnimation()
	BaseUIScene.startEnterAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()
	end

	self.mainUI:setPositionX(self.mainUI:getPositionX() - visibleSize.width)
	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(0.3, ccp(visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.mainUI:runAction(CCSequence:create(arr))

	local aHeight = self.titleUI:getGroupBounds().size.height

	self.titleUI:setPositionY(self.titleUI:getPositionY() + aHeight)
	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(0, -aHeight)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.titleUI:runAction(CCSequence:create(arr))

end

function CrossUnionPKTeamAdjustScene:sufEnterAnimation()
	BaseUIScene.sufEnterAnimation(self)
end

function CrossUnionPKTeamAdjustScene:doExitAnimation()
	self:preExitAnimation()
	self:startExitAnimation()
end

function CrossUnionPKTeamAdjustScene:preExitAnimation()
	BaseUIScene.preExitAnimation(self)
end

function CrossUnionPKTeamAdjustScene:startExitAnimation()
	BaseUIScene.startExitAnimation(self)
	local function enterActionFinished()
		self:nodeAnimationFinished()
	end

	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(-visibleSize.width, 0)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.mainUI:runAction(CCSequence:create(arr))

	local aHeight = self.titleUI:getGroupBounds().size.height
	local arr = CCArray:create()
	arr:addObject(CCMoveBy:create(enter_animation_duration, ccp(0, aHeight)))
	arr:addObject(CCCallFunc:create(enterActionFinished))
	self.titleUI:runAction(CCSequence:create(arr))
end

function CrossUnionPKTeamAdjustScene:sufExitAnimation()
	BaseUIScene.sufExitAnimation(self)
end
-----------------------------------------------进出场景动画------------------------------------------------------------

-- 退出到外层
function CrossUnionPKTeamAdjustScene:back()
	CrossUnionPkData.setTeamAdjustLightOn(false)
	CrossUnionPk.gotoCrossLoginUnionPkScene()
end

function CrossUnionPKTeamAdjustScene:dispose()

	UiStackManager_EventDispatcher:removeEventListener(UiStackManager_EVENT_UPDATE, onFocusChanged)
	UnionManager.eventDispatcher:removeEventListener(CrossUnionPkConsts.NEED_REFRESH_TEAM_ADJUST_SCENE, onRefreshSelf)
	UnionManager.eventDispatcher:removeEventListener(CrossUnionPkConsts.REFRESH_SHINE_SAVE_TEAM, onRefreshShineSaveTeam)
	UnionManager.eventDispatcher:removeEventListener(CrossUnionPkConsts.REFRESH_SHINE_DAILY_REPORTS, onRefreshShineDailyReports)
	UnionManager.eventDispatcher:removeEventListener(CrossUnionPkConsts.REFRESH_BATTLE_UI, onRefershBattleUI)

	NotificationManager:removeEventListener(PassDayManager.PASS_DAY, onPassDay, self)
	UnionManager.eventDispatcher:removeEventListener(CrossUnionPkConsts.UNIONPK_TIMELEVEL_PASSED, onTimelevelUpdate)

	CrossUnionPKTeamAdjustScene.super.dispose(self)

	if self.fightBtnCdLabelComponent then
		self.fightBtnCdLabelComponent:dispose()
		self.fightBtnCdLabelComponent = nil
	end
end

