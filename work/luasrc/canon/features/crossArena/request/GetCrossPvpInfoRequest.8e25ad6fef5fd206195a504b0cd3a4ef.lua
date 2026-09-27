-- <protocol desc="获得跨服PVP信息">
-- 	<request>
-- 	</request>
-- 	<response>
-- 		<property code="crossVersion" type="int" desc="届数" />
-- 		<property code="phaseIndex" type="int" desc="阶段指针(0-战斗;1-领奖)" />
-- 		<property code="battleInfo" ref="BattlePhase" desc="战斗阶段信息" />
-- 		<property code="rewardInfo" ref="RewawrdPhase" desc="领奖阶段信息" />
-- 	</response>
-- </protocol>

require "canon.request.BaseRequest"
require "canon.features.crossArena.manager.CrossArenaManager"

--获取pvp信息
GetCrossPvpInfoRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
GetCrossPvpInfoRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function GetCrossPvpInfoRequest:ctor()
  self.endpoint = "getCrossPvpInfo"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function GetCrossPvpInfoRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function GetCrossPvpInfoRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function GetCrossPvpInfoRequest.sendRequestDefalut(afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		GetCrossPvpInfoRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	GetCrossPvpInfoRequest.sendRequest(onSucceed, GetCrossPvpInfoRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function GetCrossPvpInfoRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local params = {}--<<<<< 2. 附加参数转换成后端提供的接口格式

	local function onSucceedHandle(event)
		event.params = params
		if succeedCallback then
			succeedCallback(event)
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end

	if not GetCrossPvpInfoRequest.TEST then
		--非测试状态 正常流程
		local request = GetCrossPvpInfoRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		local testEvt = {data = {}}
		onSucceedHandle(GetCrossPvpInfoRequest.getDebugDatas())
	end
end

--成功的默认处理
function GetCrossPvpInfoRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("GetCrossPvpInfoRequest->event = " .. tostringRich(event))
	end

	if event.data.phaseIndex == 0 then--战斗阶段
		CrossArenaManager.setMyBattleScore(event.data.battleInfo.battleScore)
		CrossArenaManager.setMyRank(event.data.battleInfo.rank)
		--修改到用dailyDataManager管理activeScore
		local pvpDailyInfo = DailyDataManager.getCrossPvpDailyData()
        pvpDailyInfo.activeScore = event.data.battleInfo.activeScore
        DailyDataManager.setCrossPvpDailyData(pvpDailyInfo)

		CrossArenaManager.setMatchList(event.data.battleInfo.matchList)
		CrossArenaManager.setFreeRefreshTimestamp(event.data.battleInfo.freeRefreshTimestamp)
	else
		CrossArenaManager.setTop3Ranks( event.data.rewardInfo.ranks )
		CrossArenaManager.setRankRewardStatus(event.data.rewardInfo.rankRewardStatus)
		CrossArenaManager.setServerRewardStatus(event.data.rewardInfo.serverRewardStatus)
	end

end

--失败默认处理
function GetCrossPvpInfoRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end

--获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除
function GetCrossPvpInfoRequest.getDebugDatas()
	local testEvt = {data = {}}

	testEvt.data.crossVersion = 1
	testEvt.data.phaseIndex = 1
	testEvt.data.battleInfo = {}
	testEvt.data.rewardInfo = {}

	testEvt.data.rewardInfo.rewardStatus = 1
	testEvt.data.rewardInfo.ranks = {}

	local rank

	rank = {}
	rank.rank = 1
	rank.battleScore = 1000
	rank.metaId = 101011
	rank.nickName = "nickName1"
	rank.level = 123
	rank.server = 56
	rank.unionName = "unionName1"
	rank.combat = 112233
	table.insert(testEvt.data.rewardInfo.ranks, rank)

	rank = {}
	rank.rank = 2
	rank.battleScore = 1000
	rank.metaId = 101011
	rank.nickName = "nickName2"
	rank.level = 123
	rank.server = 56
	rank.unionName = "unionName2"
	rank.combat = 112233
	table.insert(testEvt.data.rewardInfo.ranks, rank)

	rank = {}
	rank.rank = 3
	rank.battleScore = 1000
	rank.metaId = 101011
	rank.nickName = "nickName3"
	rank.level = 123
	rank.server = 56
	rank.unionName = "unionName3"
	rank.combat = 112233
	table.insert(testEvt.data.rewardInfo.ranks, rank)

	return testEvt
end