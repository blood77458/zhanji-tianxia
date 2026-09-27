-- UnionPkTest.lua
-- 2014-10-23
-- zheng.che
-- 提供军团战测试接口 同时也可提供测试样例

UnionPkTest = {}

--测试打开鼓舞界面
function UnionPkTest.testOpenPowerupPanel(cityData)
	print("测试打开鼓舞界面")
	UnionPkTest.testOpenPowerupPanelAsNormal(cityData)
end

--测试在成员报名阶段打开界面
function UnionPkTest.testOpenPowerupPanelAsNormal(cityData)
	print("测试在成员报名阶段打开界面")
	local getUnionFormation = {}
	--城池参与军团战军团信息
	getUnionFormation.sharkUnionCityApply = {
		{unionId=1, unionName="防守", wealth=1},
		{unionId=2, unionName="进攻1", wealth=1},
		{unionId=3, unionName="进攻2", wealth=1},
	}
	--城池军团战胜利军团信息
	getUnionFormation.winnerUnionCityApply = {}
	--城池军团战失败军团信息
	getUnionFormation.loserUnionCityApply = {}
	--军团阵型
	getUnionFormation.unionFormation = {}

	--先锋信息
	getUnionFormation.unionFormation.forwardInfo = {uid=DataManager.getGameInitData().sharkUser.uid, userName="自己", mainCardMeataId=101011, gemInspireNum=1}
	--阵首信息
	getUnionFormation.unionFormation.formationHeadInfo = {
		{uid=2, userName="玩家2", mainCardMeataId=101011, gemInspireNum=2}, 
		{uid=3, userName="玩家3", mainCardMeataId=101011, gemInspireNum=7}, 
	} 
	--阵中信息
	getUnionFormation.unionFormation.formationMiddleInfo = {}
	--阵尾信息
	getUnionFormation.unionFormation.formationTailInfo = {}
	--金币城池鼓舞次数
	getUnionFormation.unionFormation.gemInspireNum = 10

	--更改时间段
	UnionPkData.setCurrTimeLevel(UnionPkConsts.TIME_MEMBER_APPLY)
	UnionPkData.reversionEndTime = TimeUtil.getServerTimeSeconds() + 600--10分钟有效
	--设定玩家已经成功报名此城池战斗
	UnionManager.setChallengeCityId(cityData.cityId)

	local scene = Director:mgr():run()
	scene.targetInfoPanel = UnionPkCityPowerupPopPanel:create(scene, cityData, getUnionFormation)
	PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)
end

function UnionPkTest.testChangeTime(time)
	print("更改时间段")
	--更改时间段
	UnionPkData.setCurrTimeLevel(time)
	UnionPkData.reversionEndTime = TimeUtil.getServerTimeSeconds() + 600--10分钟有效
end

--临时更改时间段 短时间内有效
function UnionPkTest.testDelayTimeLevel(time)
	print("临时更改时间段 短时间内有效")
	--更改时间段
	UnionPkData.setCurrTimeLevel(time)
	UnionPkData.reversionEndTime = TimeUtil.getServerTimeSeconds() + 60--1分钟有效
end

--测试卷哦根据城池编号不同 显示不同时间段的内容
function UnionPkTest.testShowCityAtDiffrientTime(cityId)
	print("测试卷哦根据城池编号不同 显示不同时间段的内容")
	if cityId == 1 then
		time = UnionPkConsts.TIME_SELECT
	elseif cityId == 6 then
		time = UnionPkConsts.TIME_SELECTING
	elseif cityId == 7 then
		time = UnionPkConsts.TIME_MEMBER_APPLY
	elseif cityId == 8 then
		time = UnionPkConsts.TIME_ROUND1_FORM
	elseif cityId == 9 then
		time = UnionPkConsts.TIME_ROUND1_FIGHT
	end
	--更改时间段
	UnionPkData.setCurrTimeLevel(time)
	UnionPkData.reversionEndTime = TimeUtil.getServerTimeSeconds() + 600--10分钟有效
end

--测试显示城池信息窗口
function UnionPkTest.testShowCityInfoPanel(cityId)
	print("测试显示城池信息窗口")
	local function onAfterSucceed(evt)
		--此时间段用于测试显示倒计时
		UnionPkData.setCurrTimeLevel(UnionPkConsts.TIME_ROUND1_FIGHT)
		UnionPkData.reversionEndTime = TimeUtil.getServerTimeSeconds() + 60--1分钟有效

		evt.data.sharkUnionCity.report = true
		evt.data.sharkUnionCity.successfulBid = true

		local scene = Director:mgr():run()
		scene.targetInfoPanel = UnionPkCityInfoPopPanel:create(scene, evt.data)
		PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)

	end
	UnionPkGetCityInfoRequest.sendRequestDefalut(cityId, onAfterSucceed)
end

--修改当前时间
function UnionPkTest.testChangeCurrentTime(time)
	print("修改当前时间")
	--修改当前时间
	local startTime, endTime = UnionPkUtils.findTImeLevelStartAndEndTime(UnionPkConsts.TIME_MEMBER_APPLY)
	local useTime = startTime - 30
	local currentTime = TimeUtil.getServerTimeSeconds()
	--todo
end

--测试打开阵型调整界面
function UnionPkTest.testOpenModifyFormationPanel(cityData)
	print("测试打开阵型调整界面")
	local getUnionFormation = {}
	--城池参与军团战军团信息
	getUnionFormation.sharkUnionCityApply = {
		{unionId=1, unionName="防守", wealth=1},
		{unionId=2, unionName="进攻1", wealth=1},
		{unionId=3, unionName="进攻2", wealth=1},
	}
	--城池军团战胜利军团信息
	getUnionFormation.winnerUnionCityApply = {}
	--城池军团战失败军团信息
	getUnionFormation.loserUnionCityApply = {}
	--军团阵型
	getUnionFormation.unionFormation = {}

	--先锋信息
	getUnionFormation.unionFormation.forwardInfo = {uid=1, userName="玩家1", mainCardMeataId=101011, gemInspireNum=1}
	--阵首信息
	getUnionFormation.unionFormation.formationHeadInfo = {
		{uid=2, userName="玩家2", mainCardMeataId=101011, gemInspireNum=2}, 
		{uid=3, userName="玩家3", mainCardMeataId=101011, gemInspireNum=7}, 
	} 
	--阵中信息
	getUnionFormation.unionFormation.formationMiddleInfo = {}
	--阵尾信息
	getUnionFormation.unionFormation.formationTailInfo = {}
	--金币城池鼓舞次数
	getUnionFormation.unionFormation.gemInspireNum = 10

	--更改时间段
	UnionPkData.setCurrTimeLevel(1)
	UnionPkData.reversionEndTime = TimeUtil.getServerTimeSeconds() + 60--1分钟有效
	--设定玩家已经成功报名此城池战斗
	UnionManager.setChallengeCityId(cityData.cityId)

	local scene = Director:mgr():run()
	scene.targetInfoPanel = UnionPkChangeFormationPopPanel:create(scene, cityData, getUnionFormation)
	PopoutManager:sharedManager():popout(scene.targetInfoPanel, kPopoutDir.kScale, true, false , scene)
end

--测试错误码
function UnionPkTest.testShowError()
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end

--测试军团动态显示的特定信息内容
function UnionPkTest.testChangeNewsInfo(info)
	local tempWarpper
	info.unionWarNewsWrappers = {}

	tempWarpper = {}
	tempWarpper.newsType = UnionManager.NEWS_TYPE_PK
	tempWarpper.senderUid = 123
	tempWarpper.senderNickname = "我是昵称"
	tempWarpper.senderLevel = 1
	tempWarpper.mainCardId = 101042
	tempWarpper.type = UnionPkConsts.WAR_NEWS_TYPE_PREPARE
	tempWarpper.detail = "{\"ownCityIds\":[\"1\",\"6\"],\"challengeCityIds\":[\"22\",\"23\"]}"
	tempWarpper.createTime = 123
	table.insert(info.unionWarNewsWrappers, tempWarpper)

	tempWarpper = {}
	tempWarpper.newsType = UnionManager.NEWS_TYPE_PK
	tempWarpper.senderUid = 123
	tempWarpper.senderNickname = "我是昵称2"
	tempWarpper.senderLevel = 1
	tempWarpper.mainCardId = 101042
	tempWarpper.type = UnionPkConsts.WAR_NEWS_TYPE_PREPARE
	tempWarpper.detail = "{\"ownCityIds\":[\"1\",\"6\"],\"challengeCityIds\":[]}"
	tempWarpper.createTime = 123
	table.insert(info.unionWarNewsWrappers, tempWarpper)

	tempWarpper = {}
	tempWarpper.newsType = UnionManager.NEWS_TYPE_PK
	tempWarpper.senderUid = 123
	tempWarpper.senderNickname = "我是昵称2"
	tempWarpper.senderLevel = 1
	tempWarpper.mainCardId = 101042
	tempWarpper.type = UnionPkConsts.WAR_NEWS_TYPE_PREPARE
	tempWarpper.detail = "{\"ownCityIds\":[],\"challengeCityIds\":[\"22\",\"23\"]}"
	tempWarpper.createTime = 123
	table.insert(info.unionWarNewsWrappers, tempWarpper)

	tempWarpper = {}
	tempWarpper.newsType = UnionManager.NEWS_TYPE_PK
	tempWarpper.senderUid = 123
	tempWarpper.senderNickname = "我是昵称2"
	tempWarpper.senderLevel = 1
	tempWarpper.mainCardId = 101042
	tempWarpper.type = UnionPkConsts.WAR_NEWS_TYPE_DEFENSE
	tempWarpper.detail = "{\"ownCityId\":\"24\"}"
	tempWarpper.createTime = 123
	table.insert(info.unionWarNewsWrappers, tempWarpper)

	tempWarpper = {}
	tempWarpper.newsType = UnionManager.NEWS_TYPE_PK
	tempWarpper.senderUid = 123
	tempWarpper.senderNickname = "我是昵称2"
	tempWarpper.senderLevel = 1
	tempWarpper.mainCardId = 101042
	tempWarpper.type = 3
	tempWarpper.detail = "{\"bidCityId\":\"24\"}"
	tempWarpper.createTime = 123
	table.insert(info.unionWarNewsWrappers, tempWarpper)

	tempWarpper = {}
	tempWarpper.newsType = UnionManager.NEWS_TYPE_PK
	tempWarpper.senderUid = 123
	tempWarpper.senderNickname = "我是昵称2"
	tempWarpper.senderLevel = 1
	tempWarpper.mainCardId = 101042
	tempWarpper.type = 4
	tempWarpper.detail = "{\"ownCityId\":\"24\"}"
	tempWarpper.createTime = 123
	table.insert(info.unionWarNewsWrappers, tempWarpper)
end

--测试获得伪造的成员列表数据
function UnionPkTest.testGetCityMemberList()
	local event = {}
	event.data = {}
	event.data.sharkUnionMemberWrappers = {}
	local memberData = nil

	memberData = {}
	memberData.level = 55
	memberData.mainCardId = 101011
	memberData.nickName = "afeqefga"
	memberData.lastestActiveSeconds = 1420786511
	memberData.lastestConstructSeconds = 1407825616
	memberData.lastestConstructType = 1
	memberData.uid = "59690001"
	memberData.online = true
	memberData.fightCapacity = 46456
	memberData.areanaRank = 232
	memberData.title = 1
	memberData.hisContribute = "41800"
	table.insert(event.data.sharkUnionMemberWrappers, memberData)

	return event
end

--测试特定情况下 显示的奖励窗口
function UnionPkTest.testShowRewardPanel()
	--设定测试数据
	UnionPkData.setHistoryTitle(UnionManager.TITLE_MANAGER)
	local defHash = {}
	defHash[1] = 1
	UnionPkData.setDefenceCityIdsHase(defHash)
	local winList = {}
	table.insert(winList, {cityId=1,winNum=1})
	UnionPkData.setUnionWinNumList(winList)
	UnionManager.getMyUnionInfo().challengeCityId = 1

	--显示窗口
	local scene = Director:mgr():run()
	local aMyGuildPanel = UnionPKMyRewardPopPanel:create(scene)
	scene:addChild(aMyGuildPanel)
	aMyGuildPanel:scaleIn()
end