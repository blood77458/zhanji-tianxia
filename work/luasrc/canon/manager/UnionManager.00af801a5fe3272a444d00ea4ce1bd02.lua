--
-- UnionManager.lua
-- Author: zheng.che
-- Date: 2014-03-13 15:58:51
-- 军团管理
-- 军团怪兽奖励每周可领次数的修改 modified by zheng.che @ 2015-3-2
--

-- otherUnionName 其他功能显示军团名称 搜索关键字
-- unionUpgradeTest 测试升级效果 搜索关键字
-- unionColosseumTag 军团斗兽场改动标记 搜索关键字

require "canon.customUI.CdLabelComponent"
require "canon.scene.UnionListScene"
require "canon.scene.UnionScene"
require "canon.scene.UnionMemberListScene"
require "canon.scene.UnionShopScene"
require "canon.scene.UnionBankScene"
require "canon.scene.UnionHallScene"
require "canon.scene.UnionNewsScene"
require "canon.scene.UnionColosseumScene"

require "canon.panel.UnionManageMenuPanel"
require "canon.panel.UnionMemberListPanel"
require "canon.panel.UnionNewsListPanel"
require "canon.panel.UnionColosseumBossInfoPanel"
require "canon.panel.UnionColosseumBossListPanel"

require "canon.panel.OperationPopPanel"
require "canon.panel.UnionChangeNoticePopPanel"
require "canon.panel.UnionChangeDeclarationPopPanel"
require "canon.panel.UnionColosseumRankPopPanel"
require "canon.panel.UnionBuildingUpgradePopPanel"
require "canon.panel.UnionColosseumDistributionPopPanel"
require "canon.panel.UnionColosseumSummonSelectPopPanel"
require "canon.panel.UnionColosseumBattleResultPopPanel"

require "canon.request.UnionGetUnionInfoRequest"
require "canon.request.GetUnionBuildingShopInfoRequest"
require "canon.request.UnionAcceptRequest"
require "canon.request.UnionRejectRequest"
require "canon.request.UnionGetApplierListRequest"
require "canon.request.UnionDissolveRequest"
require "canon.request.GetUnionBuildingBankInfoRequest"
require "canon.request.GetUnionBuildingHallInfoRequest"
require "canon.request.UnionCancelDissolveRequest"
require "canon.request.UnionGetMemberListRequest"
require "canon.request.UnionRejectAllRequest"
require "canon.request.UnionTransferRequest"
require "canon.request.UnionCancelTransferRequest"
require "canon.request.UnionImpeachRequest"
require "canon.request.UnionAppointRequest"
require "canon.request.UnionKickRequest"
require "canon.request.UnionQuitRequest"
require "canon.request.UnionGetMyDataRequest"
require "canon.request.UnionBuildingUpgradeRequest"
require "canon.request.UnionChangeNoticeRequest"
require "canon.request.UnionChangeDeclarationRequest"
require "canon.request.UnionGetNewsRequest"
require "canon.request.UnionColosseumSummonRequest"
require "canon.request.UnionColosseumChallengeRequest"
require "canon.request.UnionColosseumGetRankRequest"
require "canon.request.UnionColosseumStartAllocationRequest"
require "canon.request.UnionColosseumGiveUpAllocationRequest"
require "canon.request.UnionColosseumAllocateRequest"
require "canon.request.UnionColosseumBuildingInfoRequest"

require "canon.features.unionPk.UnionPK"
require "canon.features.crossUnionPk.CrossUnionPk"
UnionManager = {}

------------------------------------------------------------------------------------------------------------------------------------枚举

--军团所处的状态
UnionManager.UNION_STATUS_NORMAL  		= 0--状态:正常
UnionManager.UNION_STATUS_DISSOLVE 		= 1--状态:已解散
UnionManager.UNION_STATUS_TRANSFERING 	= 2--状态:转让中

--玩家是否身处军团状态
UnionManager.STATUS_MEMBER 		= 0--状态:工会成员
UnionManager.STATUS_QUIT 		= 1--状态:主动退出
UnionManager.STATUS_FORECE_QUIT = 2--状态:强制退出
UnionManager.STATUS_DISSOLVE 	= 3--状态:解散工会

--职位
UnionManager.TITLE_NONE 			= 0--无职位(历史职位可能出现此值)
UnionManager.TITLE_MANAGER 			= 1--军团长
UnionManager.TITLE_VICE_MANAGER 	= 2--副军团长
UnionManager.TITLE_ELITE_MEMBER 	= 3--精英成员
UnionManager.TITLE_MEMBER 			= 4--普通成员

--建筑id
UnionManager.UNION_BUILDING_HALL 		= 1--军团大厅 
UnionManager.UNION_BUILDING_SHOP 		= 2--军团商城
UnionManager.UNION_BUILDING_BANK 		= 3--军团钱庄
UnionManager.UNION_BUILDING_COLOSSEUM 	= 4--军团斗兽场

--建设类型
UnionManager.BUILD_NONE 	= 0--无建设
UnionManager.BUILD_LEVEL1 	= 1--普通建设(银币建设)
UnionManager.BUILD_LEVEL2 	= 2--高级建设(金币建设1)
UnionManager.BUILD_LEVEL3 	= 3--至尊建设(金币建设2)

--军团动态大类型
UnionManager.NEWS_TYPE_NORMAL = 1
UnionManager.NEWS_TYPE_PK = 2

--动态类型
UnionManager.UNION_NEWS_TYPE_CREATE_UNION 		= 1--创建军团
UnionManager.UNION_NEWS_TYPE_JOIN_UNION 		= 2--玩家加入军团
UnionManager.UNION_NEWS_TYPE_DONATE 			= 3--玩家捐献
UnionManager.UNION_NEWS_TYPE_RECEIVE_WAGE 		= 4--玩家领工资
UnionManager.UNION_NEWS_TYPE_UPGRAGE_BUILDING 	= 5--军团建筑升级
UnionManager.UNION_NEWS_TYPE_TRANSFER_UNION 	= 6--转让军团长(转让生效时发送)
UnionManager.UNION_NEWS_TYPE_IMPEACH_MANAGER 	= 7--弹劾军团长成功
UnionManager.UNION_NEWS_TYPE_APPOINT 			= 8--任命职务
UnionManager.UNION_NEWS_TYPE_DISSOLVE_UNION 	= 9--解散军团(解散操作时发送)
UnionManager.UNION_NEWS_TYPE_MONSTER_SUMMON 		= 10--召唤怪兽
UnionManager.UNION_NEWS_TYPE_MONSTER_KILL 			= 11--怪兽被击杀
UnionManager.UNION_NEWS_TYPE_MONSTER_DISTRIBUTED 	= 12--奖励被分配

--召唤种类
UnionManager.SUMMON_NORMAL = 1--召唤
UnionManager.SUMMON_DOUBLE = 2--至尊召唤(花金币奖励翻倍)

------------------------------------------------------------------------------------------------------------------------------------事件

--玩家军团相关信息更新 无参数
UnionManager.EVENT_USER_UNION_DATA_UPDATE = "EVENT_USER_UNION_DATA_UPDATE"
--军团基础信息更新 无参数
UnionManager.EVENT_BASE_DATA_UPDATE = "EVENT_BASE_DATA_UPDATE"
--建筑信息更新 无参数
UnionManager.EVENT_BUILDING_DATA_UPDATE = "EVENT_BUILDING_DATA_UPDATE"
--成员列表更新 无参数
UnionManager.EVENT_MEMBERS_UPDATE = "EVENT_MEMBERS_UPDATE"
--动态列表更新 无参数
UnionManager.EVENT_NEWSES_UPDATE = "EVENT_NEWSES_UPDATE"
--当前玩家的职位更新 无参数
UnionManager.TITLE_UPDATE = "TITLE_UPDATE"
--申请者列表更新 无参数
UnionManager.APPLIERS_UPDATE = "APPLIERS_UPDATE"
--军团斗兽场信息更新 无参数
UnionManager.COLOSSEUM_DATA_UPDATE = "COLOSSEUM_DATA_UPDATE"
--军团斗兽场分配信息更新 无参数
UnionManager.COLOSSEUM_DISTRIBUTION_UPDATE = "COLOSSEUM_DISTRIBUTION_UPDATE"
--军团斗兽场boss存活状态更新 无参数
UnionManager.COLOSSEUM_BOSS_STATE_UPDATE = "COLOSSEUM_BOSS_STATE_UPDATE"

--建筑升级 参数:evt.buildingId = 建筑编号
UnionManager.EVENT_BUILDING_LEVELUP = "EVENT_BUILDING_LEVELUP"

UnionManager.eventDispatcher = EventDispatcher.new()

------------------------------------------------------------------------------------------------------------------------------------数据

--当前玩家申请列表
local myApplyList = {}

--当前工会信息
local currentUnionData = {}

--建筑信息
local buildingsData = {}
buildingsData[UnionManager.UNION_BUILDING_HALL] = {id = UnionManager.UNION_BUILDING_HALL, level = 1}
buildingsData[UnionManager.UNION_BUILDING_SHOP] = {id = UnionManager.UNION_BUILDING_SHOP, level = 1}
buildingsData[UnionManager.UNION_BUILDING_BANK] = {id = UnionManager.UNION_BUILDING_BANK, level = 1}
buildingsData[UnionManager.UNION_BUILDING_COLOSSEUM] = {id = UnionManager.UNION_BUILDING_COLOSSEUM, level = 1}

--成员列表信息
local members = {}

--动态列表
local newses = {}

--当前商城信息
local currentShopInfo = {}
--商城已购买清单
local specialBroughtList = {}

--军团解散cd时间
local unionDissolveCd = CdLabelComponent:create()

--军团最后一次建设时间戳
local lastestConstructSeconds = 0
--今日建设总次数
local todayConstructTimes = 0

--当前最新的申请者列表
local applierList = {}

local firstEnterUnionShop = true

--斗兽场信息
local colosseumData = {}
colosseumData.callerNick = 0--召唤者
colosseumData.currentHp = 0--剩余血量
colosseumData.runTime = 0--逃走时间戳
colosseumData.isDouble = false--是否翻倍
colosseumData.id = 0--怪物编号
colosseumData.rewardAmount = 0--奖励数量
colosseumData.ranks = {}--排行榜
colosseumData.weekCallNum = 0--本周已召唤次数
colosseumData.dividerUid = 0--分配者
colosseumData.rewardDistributed = true--是否已分配
--分配列表
local colosseumDistributionHash = {}
--已分配数量
local colosseumDistributionNum = 0

--军团成员本周获得斗兽场奖励总数 hash表
--hash: uid -> amount
local colosseumWeeklyGiftGetNumHash = {}

-------------------------------------------------
-- 清除军团全部数据
-------------------------------------------------
function UnionManager.clear()
	--print("UnionManager.clear!!")
	myApplyList = {}
	currentUnionData = {}

	buildingsData = {}
	buildingsData[UnionManager.UNION_BUILDING_HALL] = {id = UnionManager.UNION_BUILDING_HALL, level = 1}
	buildingsData[UnionManager.UNION_BUILDING_SHOP] = {id = UnionManager.UNION_BUILDING_SHOP, level = 1}
	buildingsData[UnionManager.UNION_BUILDING_BANK] = {id = UnionManager.UNION_BUILDING_BANK, level = 1}
	buildingsData[UnionManager.UNION_BUILDING_COLOSSEUM] = {id = UnionManager.UNION_BUILDING_COLOSSEUM, level = 1}

	members = {}
	newses = {}
	currentShopInfo = {}
	specialBroughtList = {}
	unionDissolveCd:stop()
	applierList = {}

	lastestConstructSeconds = 0
	todayConstructTimes = 0
	firstEnterUnionShop = true

	colosseumData = {}
	colosseumData.callerNick = 0--召唤者
	colosseumData.currentHp = 0--剩余血量
	colosseumData.runTime = 0--逃走时间戳
	colosseumData.isDouble = false--是否翻倍
	colosseumData.id = 0--怪物编号
	colosseumData.rewardAmount = 0--奖励数量
	colosseumData.ranks = {}--排行榜
	colosseumData.weekCallNum = 0--本周已召唤次数
	colosseumData.dividerUid = 0--分配者
	colosseumData.rewardDistributed = true--是否已分配
	colosseumDistributionHash = {}
	colosseumDistributionNum = 0
	colosseumWeeklyGiftGetNumHash = {}
end

------------------------------------------------------------------------------------------------------------------------------------控制

--启动
function UnionManager.startup()
end

--解散时间到
function onDissolveTimeComplete()
	--print("军团解散时间到! ")
	local scene = Director:mgr():run()
	SuspensionLabel:showContent(scene, Localization:getInstance():getText("union_player_button_quit_complete2"))--你已经退出军团了
end
unionDissolveCd:setCallback(nil, onDissolveTimeComplete)

------------------------------------------------------------------------------------------------------------------------------------跳转接口

-------------------------------------------------
-- 跳转到军团列表
-------------------------------------------------
function UnionManager.gotoUnionListScene()
	--print("gotoUnionListScene")
	local scene = Director:mgr():run()
	if scene and (scene.curSceneEnum == SceneEnum.UnionListScene) then
		return
	end
	local function onSucceed(startNum, amount, requestEvent)
		--默认处理
		UnionGetUnionListRequest.onSucceedDefault(startNum, amount, requestEvent)

		local argv = {params = {topList = requestEvent.data.sharkUnionWrappers or {}}}
		if Director:mgr():run().replaceScene then
			--普通场景 有进出动画
			Director:mgr():run():replaceScene(UnionListScene, argv)
		else
			--战斗之类的场景 只能直接切换
			Director:sharedDirector():replaceScene(UnionListScene:create(argv))
		end
	end

	UnionGetMyApplyListRequest.sendRequest(UnionGetMyApplyListRequest.onSucceedDefault, UnionGetMyApplyListRequest.onFailedDefault) --先获得已申请列表 默认处理
	UnionGetUnionListRequest.sendRequest(1, 20, onSucceed, UnionGetUnionListRequest.onFailedDefault)
end

-------------------------------------------------
-- 跳转到军团主页
-------------------------------------------------
function UnionManager.gotoUnionScene()
	--print("gotoUnionScene")
	local scene = Director:mgr():run()
	if (scene.curSceneEnum == SceneEnum.UnionScene) then
		return
	end

	local function onGetMyDataSucceed(getMyDataRequestEvent)
		UnionGetMyDataRequest.onSucceedDefault(getMyDataRequestEvent)

		if UnionManager.isInUnion() then
			--如果是在军团里 才去获得军团信息
			local function onSucceed(requestEvent)
				--默认处理
				UnionGetUnionInfoRequest.onSucceedDefault(requestEvent)

				local argv = {params = requestEvent.data}
				Director:mgr():run():replaceScene(UnionScene, argv)
			end
			UnionGetUnionInfoRequest.sendRequest(onSucceed, UnionGetUnionInfoRequest.onFailedDefault)
		else
			--不在军团里 干嘛要进主页 直接去军团列表!
			UnionManager.gotoUnionListScene()
		end
	end
	UnionGetMyDataRequest.sendRequest(onGetMyDataSucceed, UnionGetMyDataRequest.onFailedDefault) --先获得玩家当前的信息
end

-------------------------------------------------
-- 跳转到商城
-------------------------------------------------
function UnionManager.gotoShopScene(enterSceneName)
	local scene = Director:mgr():run()
	if (scene.curSceneEnum == SceneEnum.UnionShopScene) then
		return
	end
  local function onSucceed(requestEvent)
		--默认处理
		GetUnionBuildingShopInfoRequest.onSucceedDefault(requestEvent)
    if enterSceneName == "UnionScene" then
      local argv = {enterScene="UnionScene",returnScene="UnionScene",params={}}
      Director:mgr():run():replaceScene(UnionShopScene, argv)
    else
      assert(false, "unknown enterSceneName in UnionManager.gotoShopScene")
    end
		
	end

	GetUnionBuildingShopInfoRequest.sendRequest(onSucceed, GetUnionBuildingShopInfoRequest.onFailedDefault)
end

-------------------------------------------------
-- 跳转到军团大厅
-------------------------------------------------
function UnionManager.gotoHallScene(enterSceneName)
	local scene = Director:mgr():run()
	if (scene.curSceneEnum == SceneEnum.UnionHallScene) then
		return
	end
  local function onSucceed(requestEvent)
		GetUnionBuildingHallInfoRequest.onSucceedDefault(requestEvent)
    if enterSceneName == "UnionScene" then
      local argv = {enterScene="UnionScene",returnScene="UnionScene",params={data = requestEvent.data}}
      Director:mgr():run():replaceScene(UnionHallScene, argv)
    else
      assert(false, "unknown enterSceneName in UnionManager.gotoShopScene")
    end
		
	end

	GetUnionBuildingHallInfoRequest.sendRequest(onSucceed, GetUnionBuildingHallInfoRequest.onFailedDefault)
end

-------------------------------------------------
-- 跳转到钱庄
-------------------------------------------------
function UnionManager.gotoBankScene(enterSceneName)
	local scene = Director:mgr():run()
	if (scene.curSceneEnum == SceneEnum.UnionBankScene) then
		return
	end
  local function onSucceed(requestEvent)
		GetUnionBuildingBankInfoRequest.onSucceedDefault(requestEvent)
    if enterSceneName == "UnionScene" then
      local argv = {enterScene="UnionScene",returnScene="UnionScene",params={}}
      Director:mgr():run():replaceScene(UnionBankScene, argv)
    else
      assert(false, "unknown enterSceneName in UnionManager.gotoShopScene")
    end
		
	end

	GetUnionBuildingBankInfoRequest.sendRequest(onSucceed, GetUnionBuildingBankInfoRequest.onFailedDefault)
end

-------------------------------------------------
-- 跳转到军团成员
-------------------------------------------------
function UnionManager.gotoUnionMemberScene(pageIndex)
	local scene = Director:mgr():run()
	if (scene.curSceneEnum == SceneEnum.UnionMemberListScene) then
		return
	end

	if pageIndex == UnionMemberListTagEnum.APPLIER_LIST then
		--申请者列表
		local function onSucceed(requestEvent)
			--默认处理
			UnionGetApplierListRequest.onSucceedDefault(requestEvent)

			local params = {}
			params.pageIndex = pageIndex
			params.list = requestEvent.data.sharkUnionAppliers or {}
			local argv = {enterScene="UnionScene",returnScene="UnionScene",params=params}
			Director:mgr():run():replaceScene(UnionMemberListScene, argv)
		end

		UnionGetApplierListRequest.sendRequest(onSucceed, UnionGetApplierListRequest.onFailedDefault)
	else
		--成员列表
		local function onSucceed(requestEvent)
			--默认处理
			UnionGetMemberListRequest.onSucceedDefault(requestEvent)

			local params = {}
			params.pageIndex = pageIndex
			params.list = requestEvent.data.sharkUnionMemberWrappers or {}
			local argv = {enterScene="UnionScene",returnScene="UnionScene",params=params}
			Director:mgr():run():replaceScene(UnionMemberListScene, argv)
		end

		UnionGetMemberListRequest.sendRequest(onSucceed, UnionGetMemberListRequest.onFailedDefault)
	end
end

-------------------------------------------------
-- 跳转到军团成员 设定目标标签名 和 目标显示内容
-------------------------------------------------
function UnionManager.gotoUnionMemberSceneByTarget(targetTabName, targetMemberList)
	local scene = Director:mgr():run()
	if (scene.curSceneEnum == SceneEnum.UnionMemberListScene) then
		return
	end

	local params = {}
	params.pageIndex = UnionMemberListTagEnum.TARGET_LIST
	params.list = targetMemberList or {}
	params.targetTabName = targetTabName
	local argv = {enterScene="UnionScene",returnScene="UnionScene",params=params}
	Director:mgr():run():replaceScene(UnionMemberListScene, argv)
end

-------------------------------------------------
-- 跳转到军团消息
-------------------------------------------------
function UnionManager.gotoUnionInfomationScene()
	print("gotoUnionInfomationScene")
	local scene = Director:mgr():run()
	if (scene.curSceneEnum == SceneEnum.UnionNewsScene) then
		return
	end

	local function onSucceed(requestEvent)
		UnionGetNewsRequest.onSucceedDefault(requestEvent)

		scene:replaceScene(UnionNewsScene, argv)
	end
	UnionGetNewsRequest.sendRequest(onSucceed, UnionGetNewsRequest.onFailedDefault)
end

-------------------------------------------------
-- 跳转到军团斗兽场
-------------------------------------------------
function UnionManager.gotoUnionColosseumScene()
	--print("gotoUnionColosseumScene")
	local scene = Director:mgr():run()
	--不知为何有时跳转不了 注掉就好了
	-- if (scene.curSceneEnum == SceneEnum.UnionColosseumScene) then
	-- 	return
	-- end

	local function onSucceed(requestEvent)
		UnionColosseumBuildingInfoRequest.onSucceedDefault(requestEvent)

		scene:replaceScene(UnionColosseumScene, argv)
	end
	UnionColosseumBuildingInfoRequest.sendRequest(onSucceed, UnionColosseumBuildingInfoRequest.onFailedDefault)
end

------------------------------------------------------------------------------------------------------------------------------------校验接口

-------------------------------------------------
-- 能否创建军团
-- selectedText string 待创建军团名称
-- costType int 资源类型
-- withAlert boolean 是否提示
-------------------------------------------------
function UnionManager.canCreateUnion(selectedText, costType, withAlert)
	local needLevel = UnionManager.unionMinLevel()
	if DataManager.getGameInitData().sharkUser.level < needLevel then
		--print("不能创建军团 因为等级不够! needLevel = " .. needLevel)
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_creat_not_satisfied1", {num = needLevel}))--需要达到{num}级才能创建军团
		end
		return false
	end

	if UnionManager.isInUnion() then
		--print("不能创建军团 因为已经在军团中! ")
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_apply_not_satisfied2"))--您已加入军团
		end
		return false
	end

	if UnionManager.isInJoinCD() then
		--print("不能创建军团 因为在入团冷却中! ")
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_creat_not_satisfied4"))--您在加入军团的冷却中，冷却结束后可以执行该操作
		end
		return false
	end

	local needNum = UnionManager.getCreateCostNum(costType)
	local currentNum = CanonGoodIcon.getResourceNum(costType)
	if currentNum < needNum then
		--print("不能创建军团 因为资源不足! costType = " .. costType .. ", currentNum = " .. currentNum .. ", needNum = " .. needNum)
		if withAlert then
			local scene = Director:mgr():run()
			if costType == ResourceEnum.GEMS then
				local function replaceSceneFunc()
					--self:runAction(CCMoveBy:create(0.3, ccp(-visibleSize.width, 0)))
				end
				local aPanel = AssistantMessageBoxPanel:create( scene, AsMessageBoxType.addCoin, nil, {onReplaceSceneFunc = replaceSceneFunc} )
				scene:addChild(aPanel)
				aPanel:scaleIn()
				--PopoutManager:sharedManager():popout(aPanel, kPopoutDir.kScale, true, false , scene)
			else
				local aPanel = MessageBoxPanel:create(scene, MessageBoxType.kCoinLimit)
				scene:addChild(aPanel)
				aPanel:scaleIn()
			end
		end
		return false
	end

	if selectedText == "" then
		--print("不能创建军团 因为名字为空! ")
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_creat_not_satisfied6"))--军团名称不能为空
		end
		return false
	end

	local chinum,engnum = StringUtil.calcChineseEnglishNum(selectedText)
	local totalEngNum = chinum*2 + engnum
	if totalEngNum < 2 then
		--print("不能创建军团 因为字数过少! selectedText = " .. selectedText)
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_creat_not_satisfied7"))--军团名称过短
		end
		return false
	end
	if totalEngNum > 12 then
		--print("不能创建军团 因为字数过多! selectedText = " .. selectedText)
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_creat_not_satisfied2"))--军团名不能超过6个汉字或12位英文数字
		end
		return false
	end

	return true
end

-------------------------------------------------
-- 能否加入军团
-- unionData table 目标军团数据
-- withAlert boolean 是否提示
-------------------------------------------------
function UnionManager.canJoinUnion(unionData, withAlert)
	local needLevel = UnionManager.unionMinLevel()
	if DataManager.getGameInitData().sharkUser.level < needLevel then
		--print("不能加入军团 因为等级不够! needLevel = " .. needLevel)
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_apply_not_satisfied1", {num = needLevel}))--需要达到{num}级才能申请加入军团
		end
		return false
	end

	if UnionManager.isInUnion() then
		--print("不能加入军团 因为已经在军团中! ")
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_apply_not_satisfied2"))--您已加入军团
		end
		return false
	end

	if UnionManager.isInJoinCD() then
		--print("不能加入军团 因为在入团冷却中! ")
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_apply_not_satisfied3"))--您在加入军团的冷却中，冷却结束后可以执行该操作
		end
		return false
	end

	if UnionManager.getApplyUnionCount() >= UnionManager.getPlayMaxApplyCount() then
		--print("不能加入军团 因为申请数量满了! ")
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_apply_not_satisfied4"))--您提交的申请已经达到上限
		end
		return false
	end

	return true
end

-------------------------------------------------
-- 能否 解散 军团
-- withAlert boolean 是否提示
-------------------------------------------------
function UnionManager.canDissolveUnion(withAlert)
	if UnionManager.getMyTitle() ~= UnionManager.TITLE_MANAGER then
		--print("不能解散 因为不是军团长! ")
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_dissolve_not_satisfied1"))--只有军团长才能解散军团
		end
		return false
	end

	local currentLevel = UnionManager.getUnionLevel()
	local minLevel = UnionManager.getDissolveForbidLevel()
	if currentLevel >= minLevel then
		--print("不能解散 因为等级过高! ")
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_dissolve_not_satisfied2", {num = minLevel}))--军团等级达到{num}级后不能解散
		end
		return false
	end

	if UnionManager.getUnionMemberCount() > 1 then
		--print("不能解散 因为人数过多! ")
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_dissolve_not_satisfied3"))--军团人数为1时才能解散军团
		end
		return false
	end

	if UnionPK.isInUnionPk() then
		--在军团战期间
		if withAlert then
			local scene = Director:mgr():run()
			SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_error_txt1"))--军团战期间无法进行踢人，退出军团，解散军团等操作
		end
		return false
	end

	return true
end

-------------------------------------------------
-- 能否改公告
-- selectedText string 文字内容
-- withAlert boolean 是否提示
-------------------------------------------------
function UnionManager.canChangeNotic(selectedText, withAlert)
	if selectedText == "" then
		--print("不能改公告 因为字符串为空! ")
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_announcement_not_satisfied4"))--不能为空
		end
		return false
	end

	local chinum,engnum = StringUtil.calcChineseEnglishNum(selectedText)
	local totalEngNum = chinum*2 + engnum
	if totalEngNum > UnionManager.getUnionNoticeContentMax() then
		--print("不能改公告 因为字数过多! selectedText = " .. selectedText)
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_announcement_not_satisfied1"))--文本过长
		end
		return false
	end

	return true
end

-------------------------------------------------
-- 能否弹劾这个人
-- selectedText string 文字内容
-- withAlert boolean 是否提示
-------------------------------------------------
function UnionManager.canImpeach(memberData, withAlert)
	if tonumber(memberData.title) ~= UnionManager.TITLE_MANAGER then
		--print("不能弹劾 因为目标不是军团长! ")
		return false
	end

	if memberData.online then
		--对方在线
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_player_button_impeach_remind"))--军团长离开超过7天后才能弹劾
		end
		return false
	end

	local days = TimeUtil.getPasseddDaysToNow(memberData.lastestActiveSeconds)
	print("UnionManager.leaderLeaveMaxDays() = " .. UnionManager.leaderLeaveMaxDays())
	if days < UnionManager.leaderLeaveMaxDays() then
		--print("不能弹劾 因为时间不够! ")
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_player_button_impeach_remind"))--军团长离开超过7天后才能弹劾
		end
		return false
	end

	return true
end

-------------------------------------------------
-- 能否改宣言
-- selectedText string 文字内容
-- withAlert boolean 是否提示
-------------------------------------------------
function UnionManager.canChangeDeclaration(selectedText, withAlert)
	if selectedText == "" then
		--print("不能改宣言 因为字符串为空! ")
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_announcement_not_satisfied4"))--不能为空
		end
		return false
	end

	local chinum,engnum = StringUtil.calcChineseEnglishNum(selectedText)
	local totalEngNum = chinum*2 + engnum
	if totalEngNum > UnionManager.getUnionDeclarationContentMax() then
		--print("不能改宣言 因为字数过多! selectedText = " .. selectedText)
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_announcement_not_satisfied1"))--文本过长
		end
		return false
	end

	return true
end

-------------------------------------------------
-- 能否搜索军团
-- selectedText string 文字内容
-- withAlert boolean 是否提示
-------------------------------------------------
function UnionManager.canSearchTo(selectedText, withAlert)
	if selectedText == "" then
		--print("不能搜索军团 因为字符串为空! ")
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_search_button_click_remin1"))--请输入军团名再查询
		end
		return false
	end

	-- local chinum,engnum = StringUtil.calcChineseEnglishNum(selectedText)
	-- local totalEngNum = chinum*2 + engnum
	-- if totalEngNum > UnionManager.getUnionDeclarationContentMax() then
	-- 	--print("不能搜索军团 因为字数过多! selectedText = " .. selectedText)
	-- 	if withAlert then
	-- 		SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_announcement_not_satisfied1"))--文本过长
	-- 	end
	-- 	return false
	-- end

	return true
end

-------------------------------------------------
-- 查询当前玩家能否管理军团
-- withAlert boolean 是否提示
-------------------------------------------------
function UnionManager.canManageUnion()
	local title = UnionManager.getMyTitle()
	if title == UnionManager.TITLE_MANAGER then
		--军团长可管理军团
		return true
	end
	if title == UnionManager.TITLE_VICE_MANAGER then
		--副军团长可管理军团
		return true
	end
	--其他成员不可以
	return false
end

-------------------------------------------------
-- 能否操作申请者列表
-- withAlert boolean 是否提示
-------------------------------------------------
function UnionManager.canAccessApplier(withAlert)
	return UnionManager.canManageUnion()
end

------------------------------------------------------------------------------------------------------------------------------------配置相关资料获取

-------------------------------------------------
-- 军团相关配置
-------------------------------------------------
function UnionManager.getUnionConfig()
	local config = DataManager.GameMetaData.unionSettingConfig
	--print("config = " .. table.tostring(config))
	return config
end

-------------------------------------------------
-- 军团模块是否开放
-- withAlert boolean 是否提示
-------------------------------------------------
function UnionManager.ennabled(withAlert)
	-- if not DataManager.GameMetaData.unionSettingConfig then
	-- 	--print("无法显示军团 因为军团配置为空!")
	-- 	return false
	-- end
	local needLevel = UnionManager.unionMinLevel()
	if DataManager.getGameInitData().sharkUser.level < needLevel then
		--print("不能使用军团 因为等级不够! needLevel = " .. needLevel)
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("module_needLevel", {num = needLevel}))--主公等级达到{num}解锁，继续努力吧！
		end
		return false
	end
	return true
end

-------------------------------------------------
-- 创建军团所需资源数量
-- costType int 资源类型
-------------------------------------------------
function UnionManager.getCreateCostNum(costType)
	if costType == ResourceEnum.GEMS then
		--金币
		return UnionManager.getUnionConfig().unionCreateGold
	end
	--银币
	return UnionManager.getUnionConfig().unionCreateCoin
end

------------------------------------------------------------------------------------------------------------------------------------状态查询

-------------------------------------------------
-- 是否已申请此军团
-- unionData table 目标军团数据
-------------------------------------------------
function UnionManager.isAppliedThisUnion(unionId)
	for k, v in ipairs(myApplyList) do
		if v.unionId == unionId then
			return true
		end
	end
	return false
end

-------------------------------------------------
-- 是否已经在军团中
-------------------------------------------------
function UnionManager.isInUnion()
	if not DataManager.getGameInitData().sharkUserUnion then
		--没有军团的信息(压根没有加入过军团)
		-- print("不在军团 因为没有军团数据")
		return false
	end

	local state = UnionManager.getMyStatus()
	if (state == UnionManager.STATUS_QUIT) or (state == UnionManager.STATUS_FORECE_QUIT) then
		--当前在退出军团状态
		-- print("不在军团 因为在退出军团状态")
		return false
	end

	if state == UnionManager.STATUS_DISSOLVE then
		--解散工会状态 判断解散时间是否到达
		local dissolvedSeconds = UnionManager.getMyDissolvedSeconds()
		--print("dissolvedSeconds = " .. dissolvedSeconds)
		if dissolvedSeconds <= 0 then
			--非正常时间 强制认为passed
			-- print("不在军团 因为已经解散")
			return false
		end
		local currentTime = TimeUtil.getServerTimeSeconds()
		--print("currentTime = " .. currentTime)
		if currentTime >= dissolvedSeconds then
			--解散到期时间passed 认为当前玩家不在军团中
			-- print("不在军团 因为解散时间过了")
			return false
		end
	end

	return true
end

-------------------------------------------------
-- 军团是否正在解散中
-------------------------------------------------
function UnionManager.isDissolving()
	local state = UnionManager.getMyStatus()

	if state ~= UnionManager.STATUS_DISSOLVE then
		--状态不是解散中
		return false
	end

	local dissolvedSeconds = UnionManager.getMyDissolvedSeconds()
	if dissolvedSeconds <= 0 then
		--非正常时间 强制认为passed
		return false
	end

	local currentTime = TimeUtil.getServerTimeSeconds()
	--print("currentTime = " .. currentTime)
	if currentTime >= dissolvedSeconds then
		--解散到期时间passed 认为当前玩家不在军团中
		return false
	end

	return true
end

-------------------------------------------------
-- 军团是否正在转让中
-------------------------------------------------
function UnionManager.isTransfering()
	local state = UnionManager.getMyStatus()

	if UnionManager.getUnionStatus() ~= UnionManager.UNION_STATUS_TRANSFERING then
		--不在转让状态
		--print("不在转让中! 不在转让状态! ")
		return false
	end

	local transferedSeconds = UnionManager.getUnionTransferTime()
	--print("transferedSeconds = " .. transferedSeconds)
	if transferedSeconds <= 0 then
		--非正常时间 强制认为passed
		--print("不在转让中! 非正常时间 强制认为passed! ")
		return false
	end

	local currentTime = TimeUtil.getServerTimeSeconds()
	--print("currentTime = " .. currentTime)
	if currentTime >= transferedSeconds then
		--到期时间passed 认为已经转让成功
		--print("不在转让中! 到期时间passed 认为已经转让成功! ")
		return false
	end

	return true
end

-------------------------------------------------
-- 是否在入团冷却中
-------------------------------------------------
function UnionManager.isInJoinCD()
	local targetTime = UnionManager.getMyReactiveSeconds()
	if targetTime == 0 then
		--不存在冷却时间
		return false
	end

	local currentTime = TimeUtil.getServerTimeSeconds()
	if currentTime >= targetTime then
		--冷却时间已过
		return false
	end
	return true
end

-------------------------------------------------
-- 加入/创建军团需要等级
-------------------------------------------------
function UnionManager.unionMinLevel()
	return UnionManager.getUnionConfig().unionApplyLevel
end

-------------------------------------------------
-- 军团某等级对应的最大人数
-------------------------------------------------
function UnionManager.getMaxMemberCountByUnionLevel(unionLevel)
	local configData = MetaManager.union_building_hall[unionLevel]
	if configData then
		return configData.memberMax
	end
	return 0
end

------------------------------------------------------------------------------------------------------------------------------------分类信息获取接口

-------------------------------------------------
-- 获得职务名称
-------------------------------------------------
function UnionManager.getTitleName(title)
	if title == UnionManager.TITLE_MANAGER then
		return Localization:getInstance():getText("union_major_text_key")--军团长
	end
	if title == UnionManager.TITLE_VICE_MANAGER then
		return Localization:getInstance():getText("union_career_name1")--副军团长
	end
	if title == UnionManager.TITLE_ELITE_MEMBER then
		return Localization:getInstance():getText("union_career_name2")--精英成员
	end
	return Localization:getInstance():getText("union_career_name3")--普通成员
end

------------------------------------------------------------------------------------------------------------------------------------军团申请相关接口

-------------------------------------------------
-- 军团同一时间最多能容纳的入团申请数量
-------------------------------------------------
function UnionManager.getMaxApplyCount()
	return UnionManager.getUnionConfig().unionApplierMax
end

-------------------------------------------------
-- 玩家同时最多申请的军团数量
-------------------------------------------------
function UnionManager.getPlayMaxApplyCount()
	return UnionManager.getUnionConfig().unionPlayerApplierMax
end

-------------------------------------------------
-- 获得军团不能解散的最低等级
-------------------------------------------------
function UnionManager.getDissolveForbidLevel()
	return UnionManager.getUnionConfig().unionDissolveForbidLevel
end

-------------------------------------------------
-- 获得军团公告最大半角字符数
-------------------------------------------------
function UnionManager.getUnionNoticeContentMax()
	return UnionManager.getUnionConfig().unionNoticeContentMax
end

-------------------------------------------------
-- 获得军团宣言最大半角字符数
-------------------------------------------------
function UnionManager.getUnionDeclarationContentMax()
	return UnionManager.getUnionConfig().unionDeclarationContentMax
end

-------------------------------------------------
-- 军团长可被弹劾的离开天数
-------------------------------------------------
function UnionManager.leaderLeaveMaxDays()
	return math.floor(UnionManager.getUnionConfig().unionLeaderMaxLeaveTime / (3600*24)) --这里配置给的是秒
end

-------------------------------------------------
-- 军团建设上限数(随等级有变化)
-------------------------------------------------
function UnionManager.DonatMaxTimes()
	return UnionManager.getUnionMemberCountMax() + UnionManager.getUnionConfig().unionDonationMaxRevise
end

-------------------------------------------------
-- 清除一个申请的军团信息
-------------------------------------------------
function UnionManager.removeApplyedUnion(unionId)
	local idx = UnionManager.findApplyUnionIndex(unionId)
	if idx ~= -1 then
		table.remove(myApplyList, idx)
	end
end

-------------------------------------------------
-- 查找一个申请的军团的位置
-------------------------------------------------
function UnionManager.findApplyUnionIndex(unionId)
	for k, v in ipairs(myApplyList) do
		if v.unionId == unionId then
			return k
		end
	end
	return -1
end

-------------------------------------------------
-- 获得全部已申请军团信息
-------------------------------------------------
function UnionManager.getApplyUnions()
	return myApplyList
end

-------------------------------------------------
-- 获得已申请军团个数
-------------------------------------------------
function UnionManager.getApplyUnionCount()
	return #myApplyList
end

-------------------------------------------------
-- 增加一个申请的军团信息
-------------------------------------------------
function UnionManager.addApplyedUnion(unionData)
	local idx = UnionManager.findApplyUnionIndex(unionData.unionId)
	if idx == -1 then
		table.insert(myApplyList, unionData)
	end
	--print("addApplyedUnion! unionData = " .. table.tostring(unionData) .. ", UnionManager.getApplyUnionCount() = " .. UnionManager.getApplyUnionCount())
end

-------------------------------------------------
-- 重新设置申请列表完整信息
-------------------------------------------------
function UnionManager.setApplyedUnions(applyedUnions)
	myApplyList = applyedUnions
end

-------------------------------------------------
-- 申请列表完整信息
-------------------------------------------------
function UnionManager.clearApplyedUnions()
	myApplyList = {}
end

------------------------------------------------------------------------------------------------------------------------------------军团计算接口

------------------------------------------------------------------------------------------------------------------------------------军团弹出菜单接口

--加好友
local function addFriend(btnEvt)
	local targetMemberData = btnEvt.context
	local scene = Director:mgr():run()
	--print("addFriend")

	local function sendInvitationCallback(data)
		SuspensionLabel:showContent(scene, getTextByKey("union_player_button_add_friends_complete", {name = targetMemberData.nickName}))--已经向{name}提交好友申请
	end

	local function sendInvitationFail(error)
		local errorCode = tonumber(error.data)
		if(CommErrorCodes.FRIEND_LIST_FULL.code == errorCode) then --好友已满
			CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_LIST_FULL, nil, nil, nil)
		elseif(CommErrorCodes.FRIEND_RELATIONSHIP_EXIST.code == errorCode) then -- 已经是好友
			CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_RELATIONSHIP_EXIST, nil, nil, nil)
		elseif(CommErrorCodes.FRIEND_INVITATION_EXIST.code == errorCode) then -- 邀请已存在
			CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_INVITATION_EXIST, nil, nil, nil)--removeOpData
		elseif(CommErrorCodes.FRIEND_SENDER_INVITATION_LIST_FULL.code == errorCode) then -- 玩家发送邀请达到上限
			CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_SENDER_INVITATION_LIST_FULL, nil, nil, nil)
		elseif(CommErrorCodes.FRIEND_RECEIVER_INVITATION_LIST_FULL.code == errorCode) then -- 玩家接收邀请达到上限
			CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_RECEIVER_INVITATION_LIST_FULL, nil, nil, nil)
		elseif(CommErrorCodes.FRIEND_SELF_LIST_FULL.code == errorCode) then -- 自己好友数达上限
			CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_SELF_LIST_FULL, nil, nil, nil)
		elseif(CommErrorCodes.FRIEND_ENEMY_LIST_FULL.code == errorCode) then -- 对方好友数达上限
			CanonMessageBox:showCommErrorBox(CommErrorCodes.FRIEND_ENEMY_LIST_FULL, nil, nil, nil)
		else
			CanonMessageBox:showCommUnHandleErrorBox(errorCode)
		end
	end

	local params = {friendUid = targetMemberData.uid}
	local sendInvitationRequest = SendInvitationRequest.new(params, rpc.SendingPriority.kHigh)
	sendInvitationRequest:addEventListener(RequestNotifyEnum.SendInvitationSucceed, sendInvitationCallback)
	sendInvitationRequest:addEventListener(RequestNotifyEnum.SendInvitationFailed, sendInvitationFail)
	sendInvitationRequest:start()
end
--移交军团长
local function transferManager(btnEvt)
	local targetMemberData = btnEvt.context
	--print("transferManager")
	function onConfirm()
		UnionTransferRequest.sendRequest(targetMemberData, UnionTransferRequest.onSucceedDefault, UnionTransferRequest.onFailedDefault)
		UnionManager.refreshMembers()
	end
	CanonMessageBox:Show(getTextByKey("union_player_button_change_major_ensure", {name = targetMemberData.nickName}), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, nil, onConfirm, nil)--你确认要将军团长职位转给{name}么？
end
--撤销移交军团长
local function cancelTransferManager(btnEvt)
	local targetMemberData = btnEvt.context
	--print("cancelTransferManager")
	UnionCancelTransferRequest.sendRequest(UnionCancelTransferRequest.onSucceedDefault, UnionCancelTransferRequest.onFailedDefault)
	UnionManager.refreshMembers()
end
--任命副军团长
local function appointViceManager(btnEvt)
	local targetMemberData = btnEvt.context
	--print("appointViceManager")
	UnionAppointRequest.sendRequest(targetMemberData, UnionManager.TITLE_VICE_MANAGER, UnionAppointRequest.onSucceedDefault, UnionAppointRequest.onFailedDefault)
	UnionManager.refreshMembers()
end
--任命精英成员
local function appointEliteMember(btnEvt)
	local targetMemberData = btnEvt.context
	--print("appointEliteMember")
	UnionAppointRequest.sendRequest(targetMemberData, UnionManager.TITLE_ELITE_MEMBER, UnionAppointRequest.onSucceedDefault, UnionAppointRequest.onFailedDefault)
	UnionManager.refreshMembers()
end
--罢免职务
local function appointMember(btnEvt)
	local targetMemberData = btnEvt.context
	--print("appointMember")
	UnionAppointRequest.sendRequest(targetMemberData, UnionManager.TITLE_MEMBER, UnionAppointRequest.onSucceedDefault, UnionAppointRequest.onFailedDefault)
	UnionManager.refreshMembers()
end
--弹劾军团长
local function impeachManager(btnEvt)
	local targetMemberData = btnEvt.context
	--print("impeachManager")
	if UnionManager.canImpeach(targetMemberData, true) then
		function onConfirm()
			UnionImpeachRequest.sendRequest(UnionImpeachRequest.onSucceedDefault, UnionImpeachRequest.onFailedDefault)
			UnionManager.refreshMembers()
		end
		CanonMessageBox:Show(getTextByKey("union_player_button_impeach_ensure"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, nil, onConfirm, nil)--你确认要弹劾军团长吗？军团内个人总贡献最高的官员将成为军团长
	end
end
--踢出军团
--跨服gvg加条件判断和新提示 modified by zheng.che @ 2015-5-11
local function kick(btnEvt)
	--print("kick")
	--条件校验
	if UnionPK.isInUnionPk() then
		--在军团战期间
		local scene = Director:mgr():run()
		SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_error_txt1"))--军团战期间无法进行踢人，退出军团，解散军团等操作
		return
	end

	local targetMemberData = btnEvt.context

	--不管哪个状态 确认要踢后的操作
	function onConfirm()
		UnionKickRequest.sendRequest(targetMemberData, UnionKickRequest.onSucceedDefault, UnionKickRequest.onFailedDefault)
		UnionManager.refreshMembers()
	end

	function onAfterSucceed(requestEvent)
		--<property code="status" type="int" desc="踢人之前获得被踢玩家当前状态，0-可踢，1-已报名，2-已上阵" />
		if requestEvent.data.status == 1 then
			--已报名
			CanonMessageBox:Show(getTextByKey("WGVG_Error06"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, nil, onConfirm, nil)--该玩家已报名跨服军团战，您仍然要开除他么？
		elseif requestEvent.data.status == 2 then
			--已上阵
			CanonMessageBox:Show(getTextByKey("WGVG_Error07"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, nil, onConfirm, nil)--该玩家已被上阵跨服军团战，您仍要开除他么？
		else
			--可踢
			--但还是有个默认的提示确认
			CanonMessageBox:Show(getTextByKey("union_player_button_eviction_ensure", {name = targetMemberData.nickName}), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, nil, onConfirm, nil)--你确认要将成员{name}踢出军团吗？
		end
	end
	CrossUnionPkCheckFiredStatueRequest.sendRequestDefalut(targetMemberData.uid, onAfterSucceed)
end
--退出军团
local function quitUnion(btnEvt)
	--print("quitUnion")
	--条件校验
	if UnionPK.isInUnionPk() then
		--在军团战期间
		local scene = Director:mgr():run()
		SuspensionLabel:showContent(scene, Localization:getInstance():getText("UnionWar_error_txt1"))--军团战期间无法进行踢人，退出军团，解散军团等操作
		return
	end

	local targetMemberData = btnEvt.context

	--不管哪个状态 确认要踢后的操作
	function onConfirm()
		UnionQuitRequest.sendRequest(UnionQuitRequest.onSucceedDefault, UnionQuitRequest.onFailedDefault)
	end

	function onAfterSucceed(requestEvent)
		--<property code="status" type="int" desc="踢人之前获得被踢玩家当前状态，0-可踢，1-已报名，2-已上阵" />
		if requestEvent.data.status == 1 then
			--已报名
			CanonMessageBox:Show(getTextByKey("WGVG_Error04"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, nil, onConfirm, nil)--您已报名跨服军团战，仍然要离开军团么？
		elseif requestEvent.data.status == 2 then
			--已上阵
			CanonMessageBox:Show(getTextByKey("WGVG_Error05"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, nil, onConfirm, nil)--您在跨服军团战中上阵，仍然要离开军团么？
		else
			--可退出
			--但还是有个默认的提示确认
			CanonMessageBox:Show(getTextByKey("union_player_button_quit_ensure"), ShowMessageType.ShowText, ShowButtonType.ID_OK_CANCEL, nil, onConfirm, nil)--你确认要退出军团吗？退出后将清空所有军团贡献，职务和福利
		end
	end
	CrossUnionPkCheckFiredStatueRequest.sendRequestDefalut(targetMemberData.uid, onAfterSucceed)
end

-------------------------------------------------
-- 打开军务菜单
-------------------------------------------------
function UnionManager.popMemberOperationMenu(memberList, targetMemberData, isFriend, invitationSent)
	--print("targetMemberData.uid = " .. targetMemberData.uid)
	--print("DataManager.getGameInitData().sharkUser.uid = " .. DataManager.getGameInitData().sharkUser.uid)
	local isMe = (targetMemberData.uid == DataManager.getGameInitData().sharkUser.uid)

	local btnInfoList = {}
	local btnInfo

	if not isMe then
		--不是自己
		if isFriend then
			--已经是好友
			btnInfo = {}
			btnInfo.text = Localization:getInstance():getText("union_player_button_aready_friend")--已是好友
			btnInfo.disenabled = true
			btnInfo.context = targetMemberData
			table.insert(btnInfoList, btnInfo)
		elseif invitationSent then
			--不是好友 且已经发了邀请
			btnInfo = {}
			btnInfo.text = Localization:getInstance():getText("friend_AlreadySent")--已发申请
			btnInfo.disenabled = true
			btnInfo.context = targetMemberData
			table.insert(btnInfoList, btnInfo)
		else
			--不是好友 也没发邀请
			btnInfo = {}
			btnInfo.text = Localization:getInstance():getText("union_player_button_add_friend")--加好友
			btnInfo.callback = addFriend
			btnInfo.context = targetMemberData
			table.insert(btnInfoList, btnInfo)
		end

		if tonumber(targetMemberData.title) == UnionManager.TITLE_MANAGER then
			--对方是军团长
			btnInfo = {}
			btnInfo.text = Localization:getInstance():getText("union_player_button_impeach")--弹劾军团长
			btnInfo.callback = impeachManager
			btnInfo.context = targetMemberData
			table.insert(btnInfoList, btnInfo)
		elseif tonumber(targetMemberData.title) == UnionManager.TITLE_VICE_MANAGER then
			--对方是副军团长
			if UnionManager.getMyTitle() == UnionManager.TITLE_MANAGER then
				--自己是军团长
				btnInfo = {}
				btnInfo.text = Localization:getInstance():getText("union_player_button_recall")--罢免职务
				btnInfo.callback = appointMember
				btnInfo.context = targetMemberData
				table.insert(btnInfoList, btnInfo)

				btnInfo = {}
				btnInfo.text = Localization:getInstance():getText("union_player_button_appointment2")--任命精英成员
				btnInfo.callback = appointEliteMember
				btnInfo.context = targetMemberData
				table.insert(btnInfoList, btnInfo)
			end
		elseif tonumber(targetMemberData.title) == UnionManager.TITLE_ELITE_MEMBER then
			--对方是精英成员
			if UnionManager.getMyTitle() == UnionManager.TITLE_MANAGER then
				--自己是军团长
				btnInfo = {}
				btnInfo.text = Localization:getInstance():getText("union_player_button_appointment1")--任命副军团长
				btnInfo.callback = appointViceManager
				btnInfo.context = targetMemberData
				table.insert(btnInfoList, btnInfo)

				btnInfo = {}
				btnInfo.text = Localization:getInstance():getText("union_player_button_recall")--罢免职务
				btnInfo.callback = appointMember
				btnInfo.context = targetMemberData
				table.insert(btnInfoList, btnInfo)
			elseif UnionManager.getMyTitle() == UnionManager.TITLE_VICE_MANAGER then
				--自己是副军团长
				btnInfo = {}
				btnInfo.text = Localization:getInstance():getText("union_player_button_recall")--罢免职务
				btnInfo.callback = appointMember
				btnInfo.context = targetMemberData
				table.insert(btnInfoList, btnInfo)
			end
		else
			--对方是普通成员
			if UnionManager.getMyTitle() == UnionManager.TITLE_MANAGER then
				--自己是军团长
				btnInfo = {}
				btnInfo.text = Localization:getInstance():getText("union_player_button_appointment1")--任命副军团长
				btnInfo.callback = appointViceManager
				btnInfo.context = targetMemberData
				table.insert(btnInfoList, btnInfo)

				btnInfo = {}
				btnInfo.text = Localization:getInstance():getText("union_player_button_appointment2")--任命精英成员
				btnInfo.callback = appointEliteMember
				btnInfo.context = targetMemberData
				table.insert(btnInfoList, btnInfo)
			elseif UnionManager.getMyTitle() == UnionManager.TITLE_VICE_MANAGER then
				--自己是副军团长
				btnInfo = {}
				btnInfo.text = Localization:getInstance():getText("union_player_button_appointment2")--任命精英成员
				btnInfo.callback = appointEliteMember
				btnInfo.context = targetMemberData
				table.insert(btnInfoList, btnInfo)
			end
		end

		if UnionManager.getMyTitle() == UnionManager.TITLE_MANAGER then
			--自己是军团长
			if UnionManager.isTransfering() then
				--正在转让中
				if tonumber(targetMemberData.uid) == UnionManager.getNextManagerId() then
					--是正在被转让的成员
					btnInfo = {}
					btnInfo.text = Localization:getInstance():getText("union_player_button_cancel_change_major")--撤销转让军团长
					btnInfo.callback = cancelTransferManager
					btnInfo.context = targetMemberData
					table.insert(btnInfoList, btnInfo)
				end
			else
				--普通状态
				btnInfo = {}
				btnInfo.text = Localization:getInstance():getText("union_player_button_change_major")--转让军团长
				btnInfo.callback = transferManager
				btnInfo.context = targetMemberData
				table.insert(btnInfoList, btnInfo)
			end

			btnInfo = {}
			btnInfo.text = Localization:getInstance():getText("union_player_button_eviction")--踢出军团
			btnInfo.callback = kick
			btnInfo.context = targetMemberData
			table.insert(btnInfoList, btnInfo)
		elseif UnionManager.getMyTitle() == UnionManager.TITLE_VICE_MANAGER then
			--自己是副军团长
			if tonumber(targetMemberData.title) ~= UnionManager.TITLE_MANAGER and tonumber(targetMemberData.title) ~= UnionManager.TITLE_VICE_MANAGER then
				--对方不是军团长 也不是副军团长
				btnInfo = {}
				btnInfo.text = Localization:getInstance():getText("union_player_button_eviction")--踢出军团
				btnInfo.callback = kick
				btnInfo.context = targetMemberData
				table.insert(btnInfoList, btnInfo)
			end
		end
	else
		--是自己
		btnInfo = {}
		btnInfo.text = Localization:getInstance():getText("union_player_button_quit")--退出军团
		btnInfo.callback = quitUnion
		btnInfo.context = targetMemberData
		table.insert(btnInfoList, btnInfo)

		--测试军团长体自己 军团长罢免自己等操作
		-- btnInfo = {}
		-- btnInfo.text = Localization:getInstance():getText("union_player_button_eviction")--踢出军团
		-- btnInfo.callback = kick
		-- btnInfo.context = targetMemberData
		-- table.insert(btnInfoList, btnInfo)
		
		-- btnInfo = {}
		-- btnInfo.text = Localization:getInstance():getText("union_player_button_recall")--罢免职务
		-- btnInfo.callback = appointMember
		-- btnInfo.context = targetMemberData
		-- table.insert(btnInfoList, btnInfo)

		-- btnInfo = {}
		-- btnInfo.text = Localization:getInstance():getText("union_player_button_appointment2")--任命精英成员
		-- btnInfo.callback = appointEliteMember
		-- btnInfo.context = targetMemberData
		-- table.insert(btnInfoList, btnInfo)

		-- btnInfo = {}
		-- btnInfo.text = Localization:getInstance():getText("union_player_button_change_major")--转让军团长
		-- btnInfo.callback = transferManager
		-- btnInfo.context = targetMemberData
		-- table.insert(btnInfoList, btnInfo)
	end

	-- btnInfo = {}
	-- btnInfo.text = Localization:getInstance():getText("xxxxxxxx")
	-- btnInfo.callback = onBtn2Click
	-- btnInfo.context = targetMemberData
	-- table.insert(btnInfoList, btnInfo)

	local scene = Director:mgr():run()
	local panel = OperationPopPanel:create(scene, btnInfoList)
	scene.targetInfoPanel = panel
	PopoutManager:sharedManager():popout(panel, kPopoutDir.kScale, true, false , scene)
end

------------------------------------------------------------------------------------------------------------------------------------当前玩家军团数据get

--获得当前玩家自身军团信息
function UnionManager.getMyUnionInfo()
	return DataManager.getGameInitData().sharkUserUnion or {}
end
--获得当前玩家跨服军团战信息
function UnionManager.getCrossUnionInfo()
	return DataManager.getGameInitData() or {}
end

--获得当前玩家的军团id
function UnionManager.getMyUnionId()
	return tonumber(UnionManager.getMyUnionInfo().unionId) or 0
end

--获得当前玩家在军团的职称
function UnionManager.getMyTitle()
	return tonumber(UnionManager.getMyUnionInfo().title) or 0
end

--获得当前玩家贡献
function UnionManager.getMyContribute()
	return tonumber(UnionManager.getMyUnionInfo().contribute) or 0
end

--获得当前玩家总贡献
function UnionManager.getMyHistoryContribute()
	return tonumber(UnionManager.getMyUnionInfo().hisContribute) or 0
end

--获得当前玩家在军团的状态
function UnionManager.getMyStatus()
	return tonumber(UnionManager.getMyUnionInfo().status) or 0
end

--获得当前玩家进入军团的时刻
function UnionManager.getMyJoinSeconds()
	return tonumber(UnionManager.getMyUnionInfo().joinSeconds) or 0
end

--获得玩家能够创建/加入军团的时刻
function UnionManager.getMyReactiveSeconds()
	return tonumber(UnionManager.getMyUnionInfo().reactiveSeconds) or 0
end

--获得工会解散完成的时间 (status为3的情况会用到)
function UnionManager.getMyDissolvedSeconds()
	return tonumber(UnionManager.getMyUnionInfo().dissolvedSeconds) or 0
end

--获得自身军团名称
function UnionManager.getMyUnionName()
	return UnionManager.getMyUnionInfo().unionName or "union"
end

--获得军团战 报名战斗城池
function UnionManager.getChallengeCityId()
	UnionPkUtils.refreshVersion()
	return UnionManager.getMyUnionInfo().challengeCityId
end

--获得军团战 银币鼓舞次数
function UnionManager.getCoinInspireNum()
	UnionPkUtils.refreshVersion()
	return UnionManager.getMyUnionInfo().coinInspireNum
end

--获得军团战 奋力一击鼓舞次数
function UnionManager.getStriveInspireNum()
	UnionPkUtils.refreshVersion()
	return UnionManager.getMyUnionInfo().striveInspireNum
end

--获得军团战 金币鼓舞次数
function UnionManager.getGemInspireNum()
	UnionPkUtils.refreshVersion()
	return UnionManager.getMyUnionInfo().gemInspireNum
end

--获得军团战 版本号 *算法:军团战开始时间时间戳开始 一周时间内为1 两周内为2 以此类推
function UnionManager.getUnionWarVersion()
	return UnionManager.getMyUnionInfo().unionWarVersion
end

--获得军团战 轮次
function UnionManager.getUnionWarRound()
	--特殊 不刷新版本号
	return UnionManager.getMyUnionInfo().unionWarRound
end

--获得军团战 是否领取军团战参与奖
function UnionManager.getGainUnionWarPlayReward()
	--特殊 不刷新版本号
	return UnionManager.getMyUnionInfo().gainUnionWarPlayReward
end

--获得军团战 是否领取军团战占领奖励
function UnionManager.getGainUnionWarOccupyReward()
	--特殊 不刷新版本号
	return UnionManager.getMyUnionInfo().gainUnionWarOccupyReward
end

--获得军团战 是否领取军团战参战奖励
function UnionManager.getGainUnionWarInBattleReward()
	--特殊 不刷新版本号
	return UnionManager.getMyUnionInfo().gainUnionWarInBattleReward
end

--获得跨服军团战版本号
function UnionManager.getGainCrossUnionWarIncrossGvgVersion()
	
	return UnionManager.getCrossUnionInfo().crossGvgVersion
end

--获得个人是否报名跨服军团战
function UnionManager.getGainCrossUnionWarInselfApplyCrossGvg()
	CrossUnionPkUtils.refreshVersion()
	return UnionManager.getCrossUnionInfo().selfApplyCrossGvg
end

--获得退出跨服军团战跨服军团战
function UnionManager.getGainCrossUnionWarInselfQuitCrossGvg()
	CrossUnionPkUtils.refreshVersion()
	return UnionManager.getCrossUnionInfo().selfQuitCrossGvg
end

--获得军团是否报名跨服军团战
function UnionManager.getGainCrossUnionWarInunionApplyCrossGvg()
	CrossUnionPkUtils.refreshVersion()
	return UnionManager.getCrossUnionInfo().unionApplyCrossGvg
end

--获得是否提醒报名跨服军团战
function UnionManager.getGainCrossUnionWarInapplyCrossGvgRemind()
	CrossUnionPkUtils.refreshVersion()
	-- print("~~~~~~~~~~~~~~~~~~~~~"..tostringRich(UnionManager.getMyUnionInfo().applyCrossGvgRemind))
	return UnionManager.getCrossUnionInfo().applyCrossGvgRemind
end

--获得是否淘汰
function UnionManager.getGainCrossUnionWarInout()
	CrossUnionPkUtils.refreshVersion()
	-- print("~~~~~~~~~~~~~~~~~~~~~"..tostringRich(UnionManager.getMyUnionInfo().out))
	return UnionManager.getCrossUnionInfo().out
end

--获得是否晋级淘汰赛
function UnionManager.getGainCrossUnionWarInpromotion()
	CrossUnionPkUtils.refreshVersion()
	return UnionManager.getCrossUnionInfo().promotion
end



------------------------------------------------------------------------------------------------------------------------------------当前玩家军团数据set

--重置玩家的是否提醒报名
function UnionManager.setGainCrossUnionWarInapplyCrossGvgRemind(v)
 	local gameInitData = DataManager.getGameInitData()
 	-- print("~~~~~~~~~~~~~~~~~ gameInitData.applyCrossGvgRemind = "..tostringRich(v))
	if not gameInitData.applyCrossGvgRemind then
		gameInitData.applyCrossGvgRemind = nil
	end
	
	gameInitData.applyCrossGvgRemind = v
	DataManager.setGameInitData(gameInitData)
end 

--重置玩家的是否被淘汰
function UnionManager.setGainCrossUnionWarInout(v)
 	local gameInitData = DataManager.getGameInitData()
 	-- print("~~~~~~~~~~~~~~~~~ gameInitData.applyCrossGvgRemind = "..tostringRich(v))
	if not gameInitData.out then
		gameInitData.out = nil
	end
	
	gameInitData.out = v
	DataManager.setGameInitData(gameInitData)
end 
--重置军团是否报名
function UnionManager.setGainCrossUnionWarInunionApplyCrossGvg(v)
 	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.unionApplyCrossGvg then
		gameInitData.unionApplyCrossGvg = nil
	end
	gameInitData.unionApplyCrossGvg = v
	DataManager.setGameInitData(gameInitData)
end 

--重置军团个人是否报名
function UnionManager.setGainCrossUnionWarInselfApplyCrossGvg(v)
 	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.selfApplyCrossGvg then
		gameInitData.selfApplyCrossGvg = nil
	end
	gameInitData.selfApplyCrossGvg = v
	DataManager.setGameInitData(gameInitData)
end

--重置军团是否退出军团
function UnionManager.setGainCrossUnionWarInselfQuitCrossGvg(v)
 	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.selfQuitCrossGvg then
		gameInitData.selfQuitCrossGvg = nil
	end
	gameInitData.selfQuitCrossGvg = v
	DataManager.setGameInitData(gameInitData)
end

--重置跨服军团战版本号
function UnionManager.setGainCrossUnionWarIncrossGvgVersion(v)
 	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.crossGvgVersion then
		gameInitData.crossGvgVersion = nil
	end
	gameInitData.crossGvgVersion = v
	DataManager.setGameInitData(gameInitData)
end

--重置是否晋级淘汰赛
function UnionManager.setGainCrossUnionWarInpromotion(v)
 	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.promotion then
		gameInitData.promotion = nil
	end
	gameInitData.promotion = v
	DataManager.setGameInitData(gameInitData)
end


--重置玩家在军团的完整信息
function UnionManager.setMyUnionData(v)
	--print("v = " .. table.tostring(v))
	local gameInitData = DataManager.getGameInitData()

	gameInitData.sharkUserUnion = v
	DataManager.setGameInitData(gameInitData)

	--额外重新设置解散到期时间
	UnionManager.setMyDissolvedSeconds(v.dissolvedSeconds)

	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_USER_UNION_DATA_UPDATE))
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.TITLE_UPDATE))
end




--设置当前玩家的军团id
function UnionManager.setMyUnionId(v)
	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.sharkUserUnion then
		gameInitData.sharkUserUnion = {}
	end
	gameInitData.sharkUserUnion.unionId = v
	DataManager.setGameInitData(gameInitData)

	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_USER_UNION_DATA_UPDATE))
end

--设置当前玩家的职称
function UnionManager.setMyTitle(v)
	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.sharkUserUnion then
		gameInitData.sharkUserUnion = {}
	end
	gameInitData.sharkUserUnion.title = v
	DataManager.setGameInitData(gameInitData)

	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_USER_UNION_DATA_UPDATE))
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.TITLE_UPDATE))
end

--设置当前玩家的贡献
function UnionManager.setMyContribute(v)
	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.sharkUserUnion then
		gameInitData.sharkUserUnion = {}
	end
	gameInitData.sharkUserUnion.contribute = v
	DataManager.setGameInitData(gameInitData)

	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_USER_UNION_DATA_UPDATE))
end

--设置当前玩家的总贡献
function UnionManager.setMyHistoryContribute(v)
	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.sharkUserUnion then
		gameInitData.sharkUserUnion = {}
	end
	gameInitData.sharkUserUnion.hisContribute = v
	DataManager.setGameInitData(gameInitData)

	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_USER_UNION_DATA_UPDATE))
end

--设置当前玩家在军团状态
function UnionManager.setMyStatus(v)
	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.sharkUserUnion then
		gameInitData.sharkUserUnion = {}
	end
	gameInitData.sharkUserUnion.status = v
	DataManager.setGameInitData(gameInitData)

	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_USER_UNION_DATA_UPDATE))
end

--设置当前玩家加入军团时刻
function UnionManager.setMyJoinSeconds(v)
	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.sharkUserUnion then
		gameInitData.sharkUserUnion = {}
	end
	gameInitData.sharkUserUnion.joinSeconds = v
	DataManager.setGameInitData(gameInitData)

	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_USER_UNION_DATA_UPDATE))
end

--设置当前玩家可以创建/加入军团的时刻
function UnionManager.setMyReactiveSeconds(v)
	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.sharkUserUnion then
		gameInitData.sharkUserUnion = {}
	end
	gameInitData.sharkUserUnion.reactiveSeconds = v
	DataManager.setGameInitData(gameInitData)

	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_USER_UNION_DATA_UPDATE))
end

--设置当前玩家解散军团到期时刻
function UnionManager.setMyDissolvedSeconds(v)
	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.sharkUserUnion then
		gameInitData.sharkUserUnion = {}
	end
	gameInitData.sharkUserUnion.dissolvedSeconds = v
	DataManager.setGameInitData(gameInitData)

	if TimeUtil.getServerTimeSeconds() < v then
		unionDissolveCd:setTargetTime(v)
		unionDissolveCd:start()
	else
		unionDissolveCd:stop()
	end

	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_USER_UNION_DATA_UPDATE))
end

--设置军团战 报名战斗城池 如果没有报名则为0
function UnionManager.setChallengeCityId(v)
	UnionPkUtils.refreshVersion()
	
	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.sharkUserUnion then
		gameInitData.sharkUserUnion = {}
	end
	gameInitData.sharkUserUnion.challengeCityId = v
	DataManager.setGameInitData(gameInitData)

	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionPkConsts.UNIONPK_USERDATA_UPDATE))
end

--设置军团战 银币鼓舞次数
function UnionManager.setCoinInspireNum(v)
	UnionPkUtils.refreshVersion()
	
	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.sharkUserUnion then
		gameInitData.sharkUserUnion = {}
	end
	gameInitData.sharkUserUnion.coinInspireNum = v
	DataManager.setGameInitData(gameInitData)

	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionPkConsts.UNIONPK_USERDATA_UPDATE))
end

--设置军团战 奋力一击鼓舞次数
function UnionManager.setStriveInspireNum(v)
	UnionPkUtils.refreshVersion()
	
	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.sharkUserUnion then
		gameInitData.sharkUserUnion = {}
	end
	gameInitData.sharkUserUnion.striveInspireNum = v
	DataManager.setGameInitData(gameInitData)

	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionPkConsts.UNIONPK_USERDATA_UPDATE))
end

--设置军团战 金币鼓舞次数
function UnionManager.setGemInspireNum(v)
	UnionPkUtils.refreshVersion()
	
	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.sharkUserUnion then
		gameInitData.sharkUserUnion = {}
	end
	gameInitData.sharkUserUnion.gemInspireNum = v
	DataManager.setGameInitData(gameInitData)

	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionPkConsts.UNIONPK_USERDATA_UPDATE))
end

--设置军团战 版本号 *算法:军团战开始时间时间戳开始 一周时间内为1 两周内为2 以此类推
function UnionManager.setUnionWarVersion(v)
	--此方法特殊 不刷新版本号
	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.sharkUserUnion then
		gameInitData.sharkUserUnion = {}
	end
	gameInitData.sharkUserUnion.unionWarVersion = v
	DataManager.setGameInitData(gameInitData)

	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionPkConsts.UNIONPK_USERDATA_UPDATE))
end


--设置跨服军团战 版本号 *算法:军团战开始时间时间戳开始 一周时间内为1 两周内为2 以此类推
function UnionManager.setCrossUnionWarVersion(v)
	--此方法特殊 不刷新版本号
	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.sharkUserUnion then
		gameInitData.sharkUserUnion = {}
	end
	gameInitData.sharkUserUnion.crossGvgVersion = v
	DataManager.setGameInitData(gameInitData)

	UnionManager.eventDispatcher:dispatchEvent(Event.new(CrossUnionPkConsts.CROSSUNIONPK_USERDATA_UPDATE))  --通知更新
end


--设置军团战 轮次
function UnionManager.setUnionWarRound(v)
	--此方法特殊 不刷新版本号
	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.sharkUserUnion then
		gameInitData.sharkUserUnion = {}
	end
	gameInitData.sharkUserUnion.unionWarRound = v
	DataManager.setGameInitData(gameInitData)

	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionPkConsts.UNIONPK_USERDATA_UPDATE))
end

--设置军团战 是否领取军团战参与奖
function UnionManager.setGainUnionWarPlayReward(v)
	UnionPkUtils.refreshVersion()
	
	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.sharkUserUnion then
		gameInitData.sharkUserUnion = {}
	end
	gameInitData.sharkUserUnion.gainUnionWarPlayReward = v
	DataManager.setGameInitData(gameInitData)

	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionPkConsts.UNIONPK_USERDATA_UPDATE))
end

--设置军团战 是否领取军团战占领奖励
function UnionManager.setGainUnionWarOccupyReward(v)
	UnionPkUtils.refreshVersion()
	
	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.sharkUserUnion then
		gameInitData.sharkUserUnion = {}
	end
	gameInitData.sharkUserUnion.gainUnionWarOccupyReward = v
	DataManager.setGameInitData(gameInitData)

	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionPkConsts.UNIONPK_USERDATA_UPDATE))
end

--设置军团战 是否领取军团战参战奖励
function UnionManager.setGainUnionWarInBattleReward(v)
	UnionPkUtils.refreshVersion()
	
	local gameInitData = DataManager.getGameInitData()
	if not gameInitData.sharkUserUnion then
		gameInitData.sharkUserUnion = {}
	end
	gameInitData.sharkUserUnion.gainUnionWarInBattleReward = v
	DataManager.setGameInitData(gameInitData)

	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionPkConsts.UNIONPK_USERDATA_UPDATE))
end
------------------------------------------------------------------------------------------------------------------------------------当前军团数据get

--获得军团id
function UnionManager.getUnionId()
	--return tonumber(currentUnionData.unionId) or 0--改为从用户接口获取
	return UnionManager.getMyUnionId()
end

--获得军团名称
function UnionManager.getUnionName()
	--return currentUnionData.name or ""--改为从用户接口获取
	return UnionManager.getMyUnionName()
end

--获得军团宣言
function UnionManager.getUnionDeclaration()
	return currentUnionData.declaration or ""
end

--获得军团公告
function UnionManager.getUnionNotice()
	return currentUnionData.notice or ""
end

--获得军团等级
function UnionManager.getUnionLevel()
	--改用军团大厅等级
	return tonumber(UnionManager.getBuildingLevel(UnionManager.UNION_BUILDING_HALL)) or 1
end

--获得商城等级
function UnionManager.getShopLevel()
	return tonumber(UnionManager.getBuildingLevel(UnionManager.UNION_BUILDING_SHOP)) or 1
end

--获得钱庄等级
function UnionManager.getBankLevel()
	return tonumber(UnionManager.getBuildingLevel(UnionManager.UNION_BUILDING_BANK)) or 1
end

--获得军团财富
function UnionManager.getUnionWealth()
	return tonumber(currentUnionData.wealth) or 0
end

--获得军团解散时间
function UnionManager.getUnionUnbandTime()
	return tonumber(currentUnionData.unbandTime) or 0
end

--获得军团长id
function UnionManager.getUnionManagerId()
	return tonumber(currentUnionData.managerId) or 0
end

--获得军团长转让到期时间
function UnionManager.getUnionTransferTime()
	return tonumber(currentUnionData.transferTime) or 0
end

--获得军团状态
function UnionManager.getUnionStatus()
	return tonumber(currentUnionData.status) or 0
end

--获得军团成员数量
function UnionManager.getUnionMemberCount()
	return tonumber(currentUnionData.memberNum) or 0
end

--获得军团成员数量上限
function UnionManager.getUnionMemberCountMax()
	return UnionManager.getMaxMemberCountByUnionLevel(UnionManager.getUnionLevel())
end

--获得被转让军团长id
function UnionManager.getNextManagerId()
	return tonumber(currentUnionData.nextManagerId) or 0
end

------------------------------------------------------------------------------------------------------------------------------------当前军团数据set

--设置军团信息
function UnionManager.setUnionData(v)
	currentUnionData = v

	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_BASE_DATA_UPDATE))
end

--设置军团建筑信息
function UnionManager.setUnionBuildingData(v)
	UnionManager.setBuildingLevel(UnionManager.UNION_BUILDING_HALL, v.buildingHallLevel)
	UnionManager.setBuildingLevel(UnionManager.UNION_BUILDING_SHOP, v.buildingShopLevel)
	UnionManager.setBuildingLevel(UnionManager.UNION_BUILDING_BANK, v.buildingBankLevel)
	--print("v.buildingColosseumLevel = " .. tostringRich(v.buildingColosseumLevel))
	UnionManager.setBuildingLevel(UnionManager.UNION_BUILDING_COLOSSEUM, v.buildingColosseumLevel)

	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_BASE_DATA_UPDATE))
end

--设置军团宣言
function UnionManager.setUnionDeclaration(v)
	currentUnionData.declaration = v
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_BASE_DATA_UPDATE))
end

--设置军团公告
function UnionManager.setUnionNotice(v)
	--print("setUnionNotice! v = " .. table.tostring(v))
	currentUnionData.notice = v
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_BASE_DATA_UPDATE))
end

--设置军团等级
function UnionManager.setUnionLevel(v)
	currentUnionData.level = v
	UnionManager.setBuildingLevel(UnionManager.UNION_BUILDING_HALL, v)
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_BASE_DATA_UPDATE))
end

--设置商城等级
function UnionManager.setShopLevel(v)
	currentUnionData.buildingShopLevel = v
	UnionManager.setBuildingLevel(UnionManager.UNION_BUILDING_SHOP, v)
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_BASE_DATA_UPDATE))
end

--设置钱庄等级
function UnionManager.setBankLevel(v)
	currentUnionData.buildingBankLevel = v
	UnionManager.setBuildingLevel(UnionManager.UNION_BUILDING_BANK, v)
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_BASE_DATA_UPDATE))
end

--设置军团财富
function UnionManager.setUnionWealth(v)
	currentUnionData.wealth = v
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_BASE_DATA_UPDATE))
end

--设置军团长转让到期时间
function UnionManager.setUnionTransferTime(v)
	currentUnionData.transferTime = v
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_BASE_DATA_UPDATE))
end

--设置军团解散时间
function UnionManager.getUnionUnbandTime(v)
	currentUnionData.unbandTime = v
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_BASE_DATA_UPDATE))
end

--设置军团长id
function UnionManager.getUnionManagerId(v)
	currentUnionData.managerId = v
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_BASE_DATA_UPDATE))
end

--设置军团状态
function UnionManager.setUnionStatus(v)
	currentUnionData.status = v
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_BASE_DATA_UPDATE))
end

--设置军团成员数量
function UnionManager.setUnionMemberCount(v)
	currentUnionData.memberNum = v
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_BASE_DATA_UPDATE))
end

--设置被转让军团长id
function UnionManager.setNextManagerId(v)
	currentUnionData.nextManagerId = v
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_BASE_DATA_UPDATE))
end

------------------------------------------------------------------------------------------------------------------------------------建筑信息get

--获得建筑等级
function UnionManager.getBuildingLevel(buildingId)
	return buildingsData[buildingId].level
end

--获得建筑名称
function UnionManager.getBuildingName(buildingId)
	if tonumber(buildingId) == UnionManager.UNION_BUILDING_HALL then
		return Localization:getInstance():getText("union_building_name1")--军团大厅
	elseif tonumber(buildingId) == UnionManager.UNION_BUILDING_SHOP then
		return Localization:getInstance():getText("union_building_name2")--军团商城
	elseif tonumber(buildingId) == UnionManager.UNION_BUILDING_BANK then
		return Localization:getInstance():getText("union_building_name3")--军团钱庄
	elseif tonumber(buildingId) == UnionManager.UNION_BUILDING_COLOSSEUM then
		return Localization:getInstance():getText("union_monster_building_name")--军团斗兽场
	end
	return buildingId
end

--获得建筑配置文件
function UnionManager.getbuildingConfig(buildingId)
	if buildingId == UnionManager.UNION_BUILDING_HALL then
		return MetaManager.union_building_hall
	elseif buildingId == UnionManager.UNION_BUILDING_SHOP then
		return MetaManager.union_building_shop
	elseif buildingId == UnionManager.UNION_BUILDING_BANK then
		return MetaManager.union_building_bank
	elseif buildingId == UnionManager.UNION_BUILDING_COLOSSEUM then
		return MetaManager.union_building_colosseum
	end
	return MetaManager.union_building_hall
end

--获得建筑最大等级
function UnionManager.getbuildingMaxLevel(buildingId)
	local config = UnionManager.getbuildingConfig(buildingId)
	return #config
end

--获得建筑升级消耗的财富数量 (这里不考虑等级上限)
function UnionManager.getBuildingUpgradeCost(buildingId)
	local level = buildingsData[buildingId].level
	return UnionManager.getbuildingConfig(buildingId)[level].wealth
end

--查询建筑是否满级
function UnionManager.isBuildingMaxLevel(buildingId)
	local currentLevel = UnionManager.getBuildingLevel(buildingId)
	local maxLevel = UnionManager.getbuildingMaxLevel(buildingId)
	if currentLevel >= maxLevel then
		--等级达到上限
		return true
	end

	return false
end

--查询能否升级建筑
function UnionManager.canUpgradeBuilding(buildingId)
	if (UnionManager.getMyTitle() ~= UnionManager.TITLE_MANAGER) and (UnionManager.getMyTitle() ~= UnionManager.TITLE_VICE_MANAGER) then
		--不是军团长和副军团长
		return false
	end

	local currentLevel = UnionManager.getBuildingLevel(buildingId)
	local maxLevel = UnionManager.getbuildingMaxLevel(buildingId)
	if currentLevel >= maxLevel then
		--等级达到上限
		return false
	end

	if buildingId ~= UnionManager.UNION_BUILDING_HALL then
		local hallLevel = UnionManager.getBuildingLevel(UnionManager.UNION_BUILDING_HALL)
		if currentLevel >= hallLevel then
			--等级达到大厅等级
			return false
		end
	end

	local currentNum = UnionManager.getUnionWealth()
	local needCost = UnionManager.getBuildingUpgradeCost(buildingId)
	if currentNum < needCost then
		--财富不足
		return false
	end

	if UnionManager.isDissolving() then
		--解散中
		return false
	end

	return true
end

--查询能否修改公告
function UnionManager.canChangeNotice()
	if (UnionManager.getMyTitle() ~= UnionManager.TITLE_MANAGER) and (UnionManager.getMyTitle() ~= UnionManager.TITLE_VICE_MANAGER) then
		--不是军团长和副军团长
		return false
	end

	return true
end

------------------------------------------------------------------------------------------------------------------------------------建筑信息set

--设置建筑等级
function UnionManager.setBuildingLevel(buildingId, v)
	buildingsData[buildingId].level = v
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_BUILDING_DATA_UPDATE))
end

------------------------------------------------------------------------------------------------------------------------------------建设相关

-------------------------------------------------
-- 查询是否银币建设
-- buildType 建设类型
-------------------------------------------------
function UnionManager.isSilverBuild(buildType)
	buildType = tonumber(buildType)
	if buildType == UnionManager.BUILD_LEVEL1 then
		return true
	end
	return false
end

-------------------------------------------------
-- 查询是否金币建设
-- buildType 建设类型
-------------------------------------------------
function UnionManager.isGemBuild(buildType)
	buildType = tonumber(buildType)
	if buildType == UnionManager.BUILD_LEVEL2 then
		return true
	end
	if buildType == UnionManager.BUILD_LEVEL3 then
		return true
	end
	return false
end

-------------------------------------------------
-- 查询建设消耗资源种类的文字
-- buildType 建设类型
-------------------------------------------------
function UnionManager.getBuildCostTypeStr(buildType)
	buildType = tonumber(buildType)
	if UnionManager.isSilverBuild(buildType) then
		return Localization:getInstance():getText("resource_silverCoin")--银币
	end
	if UnionManager.isGemBuild(buildType) then
		return Localization:getInstance():getText("resource_goldCoin")--金币
	end
	return ""
end

-------------------------------------------------
-- 查询建设消耗数值
-- buildType 建设类型
-------------------------------------------------
function UnionManager.getBuildCostNum(buildType)
	buildType = tonumber(buildType)
	if buildType == UnionManager.BUILD_LEVEL1 then
		return UnionManager.getUnionConfig().unionDonation1Cost
	end
	if buildType == UnionManager.BUILD_LEVEL2 then
		return UnionManager.getUnionConfig().unionDonation2Cost
	end
	if buildType == UnionManager.BUILD_LEVEL3 then
		return UnionManager.getUnionConfig().unionDonation3Cost
	end
	return 0
end

-------------------------------------------------
-- 查询建设贡献度数值
-- buildType 建设类型
-------------------------------------------------
function UnionManager.getBuildContributeNum(buildType)
	buildType = tonumber(buildType)
	if buildType == UnionManager.BUILD_LEVEL1 then
		return UnionManager.getUnionConfig().unionDonation1Contribute
	end
	if buildType == UnionManager.BUILD_LEVEL2 then
		return UnionManager.getUnionConfig().unionDonation2Contribute
	end
	if buildType == UnionManager.BUILD_LEVEL3 then
		return UnionManager.getUnionConfig().unionDonation3Contribute
	end
	return 0
end

-------------------------------------------------
-- 查询建设财富数值
-- buildType 建设类型
-------------------------------------------------
function UnionManager.getBuildWealthNum(buildType)
	buildType = tonumber(buildType)
	if buildType == UnionManager.BUILD_LEVEL1 then
		return UnionManager.getUnionConfig().unionDonation1Wealth
	end
	if buildType == UnionManager.BUILD_LEVEL2 then
		return UnionManager.getUnionConfig().unionDonation2Wealth
	end
	if buildType == UnionManager.BUILD_LEVEL3 then
		return UnionManager.getUnionConfig().unionDonation3Wealth
	end
	return 0
end

-------------------------------------------------
-- 设置建设时间和总次数
-------------------------------------------------
function UnionManager.setTodayBuildTotalTimes(aLastestConstructSeconds, aTodayConstructTimes)
	lastestConstructSeconds = aLastestConstructSeconds
	todayConstructTimes = aTodayConstructTimes
end

-------------------------------------------------
-- 今日建设总次数+1
-------------------------------------------------
function UnionManager.addTodayBuildTotalTimes()
	local passedDays = TimeUtil.getPasseddDaysToNow(lastestConstructSeconds)
	if passedDays > 0 then
		--不是今天
		lastestConstructSeconds = TimeUtil.getServerTimeSeconds()
		todayConstructTimes = 0
	end

	todayConstructTimes = todayConstructTimes + 1
end

-------------------------------------------------
-- 设置建设总次数
-------------------------------------------------
function UnionManager.getTodayBuildTotalTimes()
	local passedDays = TimeUtil.getPasseddDaysToNow(lastestConstructSeconds)
	if passedDays > 0 then
		--不是今天
		return 0
	end
	return todayConstructTimes
end

------------------------------------------------------------------------------------------------------------------------------------成员列表相关

--获得成员列表
function UnionManager.getMembers()
	return members
end

--设置成员列表
function UnionManager.setMembers(v)
	members = v
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_MEMBERS_UPDATE))
end

--刷新成员列表
function UnionManager.refreshMembers()
	UnionGetMemberListRequest.sendRequest(UnionGetMemberListRequest.onSucceedDefault, UnionGetMemberListRequest.onFailedDefault)
end

------------------------------------------------------------------------------------------------------------------------------------动态列表相关

--获得动态列表
function UnionManager.getNewses()
	return newses
end

--设置成员列表
function UnionManager.setNewses(v)
	newses = v
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.EVENT_NEWSES_UPDATE))
end

--刷新成员列表
function UnionManager.refreshNewses()
	UnionGetNewsRequest.sendRequest(UnionGetNewsRequest.onSucceedDefault, UnionGetNewsRequest.onFailedDefault)
end

------------------------------------------------------------------------------------------------------------------------------------商城信息

--查询是否可以购买
function UnionManager.canBuy(itemInfo)
	if itemInfo.leftNum <= 0 then
		--不能买 因为没有了
		return false
	end
	if UnionManager.isBrought(itemInfo.id) then
		--不能买 因为买过了
		return false
	end
	return true
end

--查询是否购买过该道具
function UnionManager.isBrought(id)
	local index = table.indexOf(specialBroughtList, id)
	if not index then
		return false
	end
	return true
end

--设置已购买清单
function UnionManager.setSpecialBroughtList(v)
	specialBroughtList = v
end

--添加到已购买清单
function UnionManager.addToSpecialBroughtList(id)
	table.insert(specialBroughtList, id)
end

function UnionManager.getShopUpgradePrice()
  local aShopLevelConfig = MetaManager.union_building_shop[UnionManager.getShopLevel()]
  return aShopLevelConfig and aShopLevelConfig.wealth or nil
end

function UnionManager.getShopSpecialInfoList()
  return currentShopInfo.specialInfoList or {}
end

function UnionManager.setShopSpecialInfoList(aInfoList)
  currentShopInfo.specialInfoList = aInfoList
end

function UnionManager.getShopNormalInfoList()
  local result = {}
  local unionNormalProps = DailyDataManager.getDailyDataUnionNormalProps()
  for _, v in pairs(MetaManager.union_shop_normal) do
    local temp = {}
    temp.dailyPurchaseLimit = v.dailyPurchaseLimit
    temp.id = v.id
    temp.contributeCost = v.contributeCost
    temp.requireShopLevel = v.requireShopLevel
    temp.itemType = v.itemType
    temp.metaId = v.metaId
    temp.amount = v.amount
    temp.order = v.order
    if temp.dailyPurchaseLimit > 0 then
      temp.leftNum = temp.dailyPurchaseLimit
      for _, v2 in ipairs(unionNormalProps) do
        if v2.goodMetaId == v.id then
          temp.leftNum = temp.leftNum - v2.dailyPurchaseTimes
          break
        end
      end
    end
    
    table.insert(result, temp)
  end
  table.sort(result, function(a, b)
      return a.order < b.order
    end
  )
  
  return result
end

function UnionManager.getShopSpecialConfigWithId(aId)
  return MetaManager.union_shop_special[aId]
end

function UnionManager.getOwnNumWithTypeAndMetaId(aType, aMetaId)
  local result = 0
  if aType == ResourceEnum.CARD then
    local cardsData = DataManager.getCardsData()
    for _, aCard in pairs(cardsData) do
      if aCard.metaId == aMetaId then
        result = result + 1
      end
    end
  elseif aType == ResourceEnum.EQUIP then
    local equipsData = DataManager.getEquipsData()
    for _, aEquip in pairs(equipsData) do
      if aEquip.metaId == aMetaId then
        result = result + 1
      end
    end
  elseif aType == ResourceEnum.PROP then
    local propsData = DataManager.getPropsData()
    for _, aProp in pairs(propsData) do
      if aProp.metaId == aMetaId then
        result = aProp.amount
      end
    end
  elseif aType == ResourceEnum.CARD_FRAGMENT then
    local cardFragmentsData = DataManager.getCardFragmentsData()
    for _, aCardFragment in pairs(cardFragmentsData) do
      if aCardFragment.metaId == aMetaId then
        result = aCardFragment.amount
      end
    end
  elseif aType == ResourceEnum.EQUIP_FRAGMENT then
    local equipFragmentsData = DataManager.getEquipFragmentsData()
    for _, aEquipFragment in pairs(equipFragmentsData) do
      if aEquipFragment.metaId == aMetaId then
        result = aEquipFragment.amount
      end
    end
  end
  return result
end

------------------------------------------------------------------------------------------------------------------------------------钱庄信息
function UnionManager.getBankUpgradePrice()
  local aBankLevelConfig = MetaManager.union_building_bank[UnionManager.getBankLevel()]
  return aBankLevelConfig and aBankLevelConfig.wealth or nil
end

--获得领工资对应的礼包id
function UnionManager.getWageRewardPackageId(level)
  local aBankLevelConfig = MetaManager.union_building_bank[level]
  return aBankLevelConfig and aBankLevelConfig.rewardId or nil
end

------------------------------------------------------------------------------------------------------------------------------------军团动态相关

-------------------------------------------------
-- 获得军团动态文字内容
-- newsType 动态类型
-- detailData 后端返回的详细信息json
-------------------------------------------------
function UnionManager.getNewsStr(newsType, detailData)
	local _json = require("cjson")
	detailData = _json.decode(detailData)

	if newsType == UnionManager.UNION_NEWS_TYPE_CREATE_UNION then
		--{creatorNickname：xxx, unionName:xxx}
		return Localization:getInstance():getText("union_dynamic_content1", {name = detailData.creatorNickname, name2 = detailData.unionName})--【{name}】创建了军团【{name2}】，准备一展宏图
	elseif newsType == UnionManager.UNION_NEWS_TYPE_JOIN_UNION then
		--{nickname:xxx}
		return Localization:getInstance():getText("union_dynamic_content2", {name = detailData.nickname})--【{name}】加入了军团
	elseif newsType == UnionManager.UNION_NEWS_TYPE_DONATE then
		--{nickname:xxx, constructType:xxx}
		local costNum = UnionManager.getBuildCostNum(detailData.constructType)
		local costTypeName = UnionManager.getBuildCostTypeStr(detailData.constructType)
		local rewardWealthNum = UnionManager.getBuildWealthNum(detailData.constructType)
		local rewardContribute = UnionManager.getBuildContributeNum(detailData.constructType)
		return Localization:getInstance():getText("union_dynamic_content3", {name = detailData.nickname, num1 = costNum, typeName = costTypeName, num2 = rewardWealthNum, num3 = rewardContribute})--【{name}】消耗{num1}{typeName}为军团增加{num2}财富，获得了{num3}个人贡献
	elseif newsType == UnionManager.UNION_NEWS_TYPE_RECEIVE_WAGE then
		--{nickname:xxx, wageLevel:xxx}
		local rewardPackageId = UnionManager.getWageRewardPackageId(tonumber(detailData.wageLevel))
		--print("rewardPackageId = " .. rewardPackageId)
		local params = {}
		params.mutiMark = Localization:getInstance():getText("union_dynamic_content_Symbol2")--*
		local names = CanonGoodIcon.getGoodNamesByPackageReward(rewardPackageId, params)
		return Localization:getInstance():getText("union_dynamic_content4", {name = detailData.nickname, name1 = names})--【{name}】领取工资，获得了{name1}
	elseif newsType == UnionManager.UNION_NEWS_TYPE_UPGRAGE_BUILDING then
		--{nickname:xxx, buildingType:xxx, currBuildingLevel:xxx}
		local buildingName = UnionManager.getBuildingName(detailData.buildingType)
		return Localization:getInstance():getText("union_dynamic_content5", {name = detailData.nickname, buildName = buildingName, num1 = detailData.currBuildingLevel})--【{name}】将{buildName}升级到{num1}级
	elseif newsType == UnionManager.UNION_NEWS_TYPE_TRANSFER_UNION then
		--{nickname:xxx, transferedNickname:xxx}
		return Localization:getInstance():getText("union_dynamic_content6", {name1 = detailData.nickname, name2 = detailData.transferedNickname})--【{name1}】将军团长转让给【{name2}】
	elseif newsType == UnionManager.UNION_NEWS_TYPE_IMPEACH_MANAGER then
		--{oldManagerNickname:xxx, currManagerNickname:xxx}
		return Localization:getInstance():getText("union_dynamic_content7", {name1 = detailData.oldManagerNickname, name2 = detailData.currManagerNickname})--【{name1}】被弹劾，【{name2}】成为新的军团长
	elseif newsType == UnionManager.UNION_NEWS_TYPE_APPOINT then
		--{nickname:xxx, title:xxx, appointedNickname:xxx, appointedTitle:xxx}
		local appointedTitleName = UnionManager.getTitleName(tonumber(detailData.appointedTitle))
		local titleName = UnionManager.getTitleName(tonumber(detailData.title))
		return Localization:getInstance():getText("union_dynamic_content8", {name1 = detailData.appointedNickname, careerName1 = titleName, name2 = detailData.nickname, careerName2 = appointedTitleName})--【{name1}】被{careerName1}【{name2}】任命为{careerName2}
	elseif newsType == UnionManager.UNION_NEWS_TYPE_DISSOLVE_UNION then
		--{nickname:xxx, dissolveTime:xxx}
		local remainedSec = detailData.dissolveTime - TimeUtil.getServerTimeSeconds()
		local formatedTimeStr = TimeUtil.formatTime(remainedSec)
		return Localization:getInstance():getText("union_dynamic_content9", {name = detailData.nickname, num = formatedTimeStr})--【{name}】解散了军团，军团将在{num}后解散
	elseif newsType == UnionManager.UNION_NEWS_TYPE_MONSTER_SUMMON then
		--{nickname:xxx,title:xxx,bossId:xxx}
		local titleName = UnionManager.getTitleName(tonumber(detailData.title))
		local bossName = UnionManager.getBossName(tonumber(detailData.bossId))
		return Localization:getInstance():getText("union_dynamic_content10", {name = detailData.nickname, careet = titleName, bossName = bossName})--【{careet}】{name}召唤了怪兽【{bossName}】，团员们速速攻打
	elseif newsType == UnionManager.UNION_NEWS_TYPE_MONSTER_KILL then
		--{nickname:xxx,bossId:xxx}
		local bossName = UnionManager.getBossName(tonumber(detailData.bossId))
		return Localization:getInstance():getText("union_dynamic_content11", {name = detailData.nickname, bossName = bossName})--【{bossName}】被{name}击杀了
	elseif newsType == UnionManager.UNION_NEWS_TYPE_MONSTER_DISTRIBUTED then
		--{nickname:xxx,title:xxx,bossId:xxx}
		local titleName = UnionManager.getTitleName(tonumber(detailData.title))
		local bossName = UnionManager.getBossName(tonumber(detailData.bossId))
		return Localization:getInstance():getText("union_dynamic_content12", {name = detailData.nickname, careet = titleName, bossName = bossName})--【{careet}】{name}分配了【{bossName}】的战利品
	end
	return ""
end

------------------------------------------------------------------------------------------------------------------------------------申请者列表相关

--设置最新申请者列表
function UnionManager.setApplierList(v)
	applierList = v or {}
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.APPLIERS_UPDATE))
end

--从申请者列表中删除某申请者
function UnionManager.delApplier(applierUid)
	for k, v in ipairs(applierList) do
		if v.uid == applierUid then
			table.remove(applierList, k)
		end
	end
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.APPLIERS_UPDATE))
end

--从申请者列表中删除全部申请者
function UnionManager.delAllApplier()
	applierList = {}
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.APPLIERS_UPDATE))
end

--获得当前最新的申请者列表
function UnionManager.getApplierList()
	return applierList
end

--获得申请者数量
function UnionManager.getApplierNum()
	return #applierList
end

function UnionManager.getFirstEnterUnionShop()
  return firstEnterUnionShop
end

function UnionManager.setFirstEnterUnionShop(aValue)
  firstEnterUnionShop = aValue
end

------------------------------------------------------------------------------------------------------------------------------------斗兽场相关

--------------------------------------------setter

--设置军团斗兽场团员本周领取奖励数量情况hash表
function UnionManager.setColosseumWeeklyGiftGetNumHash(value)
	colosseumWeeklyGiftGetNumHash = value
end

--------------------------------------------配置信息

--一周可召唤最大次数
function UnionManager.getColosseumWeekSummonMaxTimes()
	local buildingConfig = UnionManager.getbuildingConfig(UnionManager.UNION_BUILDING_COLOSSEUM)
	local currentLevel = UnionManager.getBuildingLevel(UnionManager.UNION_BUILDING_COLOSSEUM)
	local levelData = buildingConfig[currentLevel]
	if levelData then
		return levelData.summonTimes
	end

	DebugManager.addError("无效的斗兽场等级! currentLevel = " .. tostringRich(currentLevel))
	return 0
end

--获得军团斗技场boss配置列表
function UnionManager.getColosseumBossConfigList()
	return MetaManager.union_boss_meta
end

--获得军团斗技场单个boss配置信息
function UnionManager.getColosseumBossConfigData(bossMetaId)
	local bossConfigData = MetaManager.union_boss_meta[bossMetaId]
	if not bossConfigData then
		DebugManager.addError("无效的军团斗兽场boss编号! bossMetaId = " .. tostringRich(bossMetaId))
	end
	return bossConfigData
end

--获得某个boss的奖励内容
function UnionManager.getBossRewardData(bossMetaId)
	local bossConfigData = UnionManager.getColosseumBossConfigData(bossMetaId)
	return CanonGoodIcon.getRewardInfo(bossConfigData.rewardId)
end

--获得某个boss的最大血量
function UnionManager.getBossMaxHp(bossMetaId)
	local bossConfigData = UnionManager.getColosseumBossConfigData(bossMetaId)
	return bossConfigData.hp
end

--获得某个boss的名称
function UnionManager.getBossName(bossMetaId)
	local bossConfigData = UnionManager.getColosseumBossConfigData(bossMetaId)
	local bossName = CanonGoodIcon.getGoodName(ResourceEnum.CARD, bossConfigData.cardId, 1, {withoutAmount = true})
	return bossName
end



--奖励翻倍消耗金币
function UnionManager.getRewardDoubleGemCost()
	return UnionManager.getUnionConfig().rewardDoubleGemCost or 0
end

--玩家每天攻击怪兽的次数有总上限
function UnionManager.getUnionMonsterPlayerAttMax()
	return UnionManager.getUnionConfig().unionMonsterPlayerAttMax or 0
end

--召唤怪兽的每周周几，如1为周一，2为周二
function UnionManager.getUnionMonsterRefreshDay()
	return UnionManager.getUnionConfig().unionMonsterRefreshDay or 0
end

--召唤怪兽的当天的具体小时，如0为0点，1为1点，24为24点
function UnionManager.getUnionMonsterRefreshHour()
	return UnionManager.getUnionConfig().unionMonsterRefreshHour or 0
end

--打怪兽需要消耗的道具ID
function UnionManager.getUnionMonsterFightItem()
	return UnionManager.getUnionConfig().unionMonsterFightItem or 0
end

--召唤军团怪兽开关名称
function UnionManager.getUnionMonsterSummonFeatureName()
	return UnionManager.getUnionConfig().unionMonsterSummonFeatureName
end

--军团怪兽奖励领取个数 每周上限
function UnionManager.getUnionMonsteWeeklyrGiftTotalNum()
	return UnionManager.getUnionConfig().unionMonsterSummonRewardWeekLimit
end

--------------------------------------------getter

--获得怪物召唤者
function UnionManager.getColosseumMonsterCallerNick()
	return colosseumData.callerNick or ""
end

--获得怪物当前血量
function UnionManager.getColosseumMonsterCurrentHp()
	return colosseumData.currentHp or 0
end

--获得怪物逃跑时间戳
function UnionManager.getColosseumMonsterRunTime()
	return colosseumData.runTime or 0
end

--获得是否双倍奖励
function UnionManager.getColosseumMonsterIsDouble()
	return colosseumData.isDouble or false
end

--获得怪物编号
function UnionManager.getColosseumMonsterMetaId()
	return colosseumData.id or 1
end

--获得怪物结算奖励的数量
function UnionManager.getColosseumMonsterRewardAmount()
	return tonumber(colosseumData.rewardAmount) or 0
end

--获得排行榜列表 table
function UnionManager.getColosseumRanks()
	return colosseumData.ranks or {}
end

--获得本周已召唤次数
function UnionManager.getColosseumWeekSummonTimes()
	return colosseumData.weekCallNum or 0
end

--获得分配者
function UnionManager.getColosseumDividerUid()
	return colosseumData.dividerUid or 0
end

--是否已分配
function UnionManager.getColosseumMonsterRewardDistributed()
	return colosseumData.rewardDistributed or false
end

------通过计算获取接口

--获得刷新时间
function UnionManager.getColosseumNextRefreshTimestamp()
	--配置的是星期数和小时数
	local weekday = math.mod(UnionManager.getUnionMonsterRefreshDay(), 7)
	local daysec = UnionManager.getUnionMonsterRefreshHour() * 3600

	local todayWeekday = TimeUtil.getTodayWeekday()

	--下个目标日和今天相差天数(不能小于今天)
	local gapDay = weekday - todayWeekday
	if gapDay < 0 then
		gapDay = (weekday+7) - todayWeekday
	end

	local result = TimeUtil.getTodayTimestampBy(0, 0, 0) + gapDay * TimeUtil.DAY + daysec
	
	if SystemManager.debug then
		print("UnionManager.getUnionConfig = " .. tostringRich(UnionManager.getUnionConfig()))
	end

	return result
end

--获得本周可召唤剩余次数
function UnionManager.getColosseumWeekLeftSummonTimes()
	return colosseumData.dividerUid
end

--是否在攻击boss状态
function UnionManager.isInBossAttackState()
	if UnionManager.getColosseumMonsterCurrentHp() <= 0 then
		--已被击杀
		return false
	end

	local currentTime = TimeUtil.getServerTimeSeconds()
	if currentTime >= UnionManager.getColosseumMonsterRunTime() then
		--已逃跑
		return false
	end

	--boss存在! 
	return true
end

--寻找当前玩家的排名 -1表示未上榜
function UnionManager.findMyRank()
	local tempList = UnionManager.getColosseumRanks()
	for k, v in ipairs(tempList) do
		if v.uid == DataManager.getGameInitData().sharkUser.uid then
			return k
		end
	end
	return -1
end

--寻找某玩家的排名 -1表示未上榜
function UnionManager.findRankByUid(uid)
	local tempList = UnionManager.getColosseumRanks()
	for k, v in ipairs(tempList) do
		if v.uid == uid then
			return k
		end
	end
	return -1
end

--本周还可召唤次数
function UnionManager.summonLeftTimes()
	local currentTimes = UnionManager.getColosseumWeekSummonTimes()
	local maxTimes = UnionManager.getColosseumWeekSummonMaxTimes()
	local resut = maxTimes - currentTimes
	if resut < 0 then
		resut = 0
	end
	return resut
end

--军团成员本周可领取奖励最大个数 (配置总数 - 已领个数)
function UnionManager.memberGiftMaxNum(uid)
	local totalNum = UnionManager.getUnionMonsteWeeklyrGiftTotalNum()
	local currentNum = colosseumWeeklyGiftGetNumHash[uid] or 0
	local result = totalNum - currentNum
	if result < 0 then result = 0 end
	return result
end

--------------------------------------------setter

--设置怪物召唤者
function UnionManager.setColosseumMonsterCallerNick(v)
	colosseumData.callerNick = v
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.COLOSSEUM_DATA_UPDATE))
end

--设置怪物当前血量
function UnionManager.setColosseumMonsterCurrentHp(v)
	colosseumData.currentHp = v
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.COLOSSEUM_DATA_UPDATE))
end

--设置怪物逃跑时间戳
function UnionManager.setColosseumMonsterRunTime(v)
	colosseumData.runTime = v + 3--加3秒 因为可能会导致刷新时前后端显示不一致
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.COLOSSEUM_DATA_UPDATE))
end

--设置是否双倍奖励
function UnionManager.setColosseumMonsterIsDouble(v)
	colosseumData.isDouble = v
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.COLOSSEUM_DATA_UPDATE))
end

--设置怪物编号
function UnionManager.setColosseumMonsterMetaId(v)
	colosseumData.id = v
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.COLOSSEUM_DATA_UPDATE))
end

--设置怪物结算奖励的数量
function UnionManager.setColosseumMonsterRewardAmount(v)
	colosseumData.rewardAmount = v
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.COLOSSEUM_DATA_UPDATE))
end

--设置排行榜列表 table
function UnionManager.setColosseumRanks(v)
	colosseumData.ranks = v
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.COLOSSEUM_DATA_UPDATE))
end

--设置本周已召唤次数
function UnionManager.setColosseumWeekSommonTImes(v)
	colosseumData.weekCallNum = v
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.COLOSSEUM_DATA_UPDATE))
end

--设置分配者
function UnionManager.setColosseumDividerUid(v)
	colosseumData.dividerUid = v
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.COLOSSEUM_DATA_UPDATE))
end

--设置是否已分配
function UnionManager.setColosseumMonsterRewardDistributed(v)
	colosseumData.rewardDistributed = v
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.COLOSSEUM_DATA_UPDATE))
end

--------------------------------------------分配信息

--设置是否已分配
function UnionManager.colosseumDistributionClear()
	colosseumDistributionHash = {}
	colosseumDistributionNum = 0
	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.COLOSSEUM_DISTRIBUTION_UPDATE))
end

--更改某人分配点数
function UnionManager.colosseumDistributionAdd(uid, num)
	if num == 0 then
		return
	end

	local itemData = colosseumDistributionHash[uid]
	if not itemData then
		itemData = {uid = uid, amount = 0}
		colosseumDistributionHash[uid] = itemData
	end

	--增加的数不能超过奖励剩余数目
	local totalNum = UnionManager.getColosseumMonsterRewardAmount()
	local remainNum = totalNum - colosseumDistributionNum
	if num > 0 and num > remainNum then
		num = remainNum
	end

	--增加的数不能超过这个玩家还能领的个数
	local currentNum = UnionManager.getColosseumDistributionNumByUid(uid)--这个玩家当前分配的个数
	local maxNum = UnionManager.memberGiftMaxNum(uid)--这个玩家本周最多能获得的个数
	local userCanAddMaxNum = maxNum - currentNum--这个玩家本周还能获得个数
	if num > 0 and num > userCanAddMaxNum then
		num = userCanAddMaxNum
	end

	--减去的数不能超过已有数目
	if num < 0 and num < -itemData.amount then
		num = -itemData.amount
	end

	itemData.amount = itemData.amount + num
	colosseumDistributionNum = colosseumDistributionNum + num
	-- print("uid, num = " .. tostringRich({uid, num}))
	-- print("itemData = " .. tostringRich(itemData))
	-- print("colosseumDistributionNum = " .. tostringRich(colosseumDistributionNum))
	-- print("")

	UnionManager.eventDispatcher:dispatchEvent(Event.new(UnionManager.COLOSSEUM_DISTRIBUTION_UPDATE))
end

--获得某人当前的分配点数
function UnionManager.getColosseumDistributionNumByUid(uid)
	local itemData = colosseumDistributionHash[uid]
	if itemData then
		return itemData.amount
	end
	return 0
end

--获得当前剩余分配数量
function UnionManager.getColosseumDistributionRemainNum()
	local totalNum = UnionManager.getColosseumMonsterRewardAmount()
	local remainNum = totalNum - colosseumDistributionNum
	return remainNum
end

--获得当前已分配的人数
function UnionManager.getColosseumDistributionUserNum()
	local result = 0
	for k, itemData in pairs(colosseumDistributionHash) do
		if itemData.amount > 0 then
			result = result + 1
		end
	end
	return result
end

--查询此人能否增加点数
function UnionManager.checkColosseumDistributionIncreaceByUid(uid, num)
	if num == 0 then
		return true
	end

	if num > 0 then
		--增加
		--判断是否超过最大数值
		local currentNum = UnionManager.getColosseumDistributionNumByUid(uid)--当前分配点数
		local maxNum = UnionManager.memberGiftMaxNum(uid)--最大分配点数
		if currentNum >= maxNum then
			return false
		end

		--判断奖励是否还有剩
		local totalNum = UnionManager.getColosseumMonsterRewardAmount()
		local remainNum = totalNum - colosseumDistributionNum 
		if remainNum <= 0 then
			--没有剩余了 不能增加
			return false
		end
	else
		--减少
		local userCurrentNum = 0
		local itemData = colosseumDistributionHash[uid]
		if itemData then
			userCurrentNum = itemData.amount
		end
		if userCurrentNum <= 0 then
			--减到底了 不能减少
			return false
		end
	end

	return true
end

--查询是否分配完毕
function UnionManager.checkColosseumDistributionIsEmpty()
	local totalNum = UnionManager.getColosseumMonsterRewardAmount()
	local remainNum = totalNum - colosseumDistributionNum
	if remainNum <= 0 then
		--没有剩余了
		return true
	end

	return false
end

--获得分配表
function UnionManager.getColosseumDistributionHash()
	return colosseumDistributionHash
end

--------------------------------------------校验接口

--能否看到召唤按钮
function UnionManager.colosseumCanSeeSummonBtn()
	local title = UnionManager.getMyTitle()
	if (title == UnionManager.TITLE_ELITE_MEMBER) or (title == UnionManager.TITLE_MEMBER) then
		--职务不满足
		return false
	end

	return true
end

--能否看到分配按钮
function UnionManager.colosseumCanSeeAllocateBtn()
	return UnionManager.colosseumCanSeeSummonBtn()
end


--校验能否召唤
function UnionManager.colosseumCanSummon(withAlert)
	if not UnionManager.colosseumCanSeeSummonBtn() then
		return false
	end

	if UnionManager.isInBossAttackState() then
		--boss存在
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_monster_summon_not_satisfied1"))--同一时间只能召唤一只怪兽
		end
		return false
	end
	
	local isEnable, isOpenTime = MaintenanceManager.isActivityOpen(UnionManager.getUnionMonsterSummonFeatureName())
	if not isOpenTime then
		--召唤时间不满足
		if withAlert then
			local timeTable = MaintenanceManager:getStartAndEndHourMinOfOneDay(UnionManager.getUnionMonsterSummonFeatureName())
			local startTime = TimeUtil.formatTimeWithHM(timeTable.beginHour * 3600 + timeTable.beginMin * 60)
			local endTime = TimeUtil.formatTimeWithHM(timeTable.endHour * 3600 + timeTable.endMin * 60)
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_monster_summon_not_satisfied2", {num1 = startTime, num2 = endTime}))--怪兽只能每天{num1}至{num2}之间召唤
		end
		return false
	end

	if not UnionManager.getColosseumMonsterRewardDistributed() then
		--未分配
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_monster_summon_not_satisfied3"))--必须分配完战利品之后才能召唤
		end
		return false
	end

	if UnionManager.summonLeftTimes() <= 0 then
		--召唤次数用尽
		if withAlert then
			SuspensionLabel:showContent(Director:mgr():run(), getTextByKey("union_monster_summon_not_satisfied4"))--
		end
		return false
	end

	return true
end

--能否点击挑战按钮
function UnionManager.colosseumCanClickChallengeBtn()
	local currentTimes = DailyDataManager.getChallengeUnionMonsterTimes()
	local maxTimes = UnionManager.getUnionMonsterPlayerAttMax()
	local leftTimes = maxTimes - currentTimes
	if leftTimes <= 0 then
		--今日挑战次数不足
		return false
	end

	local costItemMetaId = UnionManager.getUnionMonsterFightItem()
	local currentNum = BagCalcManager.getNumById(costItemMetaId)
	if currentNum <= 0 then
		--道具数量不足
		return false
	end

	return true
end