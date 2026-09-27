-- CrossPvpGetRankInfoRequest.lua
-- 2015-3-9
-- zheng.che
-- 获得跨服PVP排行榜信息

-- <protocol desc="获得跨服PVP排行榜信息">
-- 	<request>
-- 	</request>
-- 	<response>
-- 		<list code="rankInfos" ref="RankInfo" desc="排名列表" />
-- 	</response>
-- </protocol>

-- <bean desc="排行榜信息">
-- 	<property code="rank" type="int" desc="排名" />
-- 	<property code="battleScore" type="int" desc="天梯积分" />
-- 	<property code="metaId" type="int" desc="主卡牌ID" />
-- 	<property code="nickName" type="string" desc="昵称" />
-- 	<property code="level" type="int" desc="等级" />
-- 	<property code="server" type="int" desc="服务器" />
-- 	<property code="unionName" type="string" desc="军团名称" />
-- 	<property code="combat" type="int" desc="战斗力" />
-- </bean>

require "canon.request.BaseRequest"

CrossPvpGetRankInfoRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
CrossPvpGetRankInfoRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function CrossPvpGetRankInfoRequest:ctor()
  self.endpoint = "getCrossPvpRankInfo"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function CrossPvpGetRankInfoRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function CrossPvpGetRankInfoRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function CrossPvpGetRankInfoRequest.sendRequestDefalut(afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		CrossPvpGetRankInfoRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	CrossPvpGetRankInfoRequest.sendRequest(onSucceed, CrossPvpGetRankInfoRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function CrossPvpGetRankInfoRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
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

	if not CrossPvpGetRankInfoRequest.TEST then
		--非测试状态 正常流程
		local request = CrossPvpGetRankInfoRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(CrossPvpGetRankInfoRequest.getDebugDatas())
	end
end

--成功的默认处理
function CrossPvpGetRankInfoRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("CrossPvpGetRankInfoRequest->event = " .. tostringRich(event))
	end

	CrossArenaManager.setShowRanks(event.data.rankInfos)
	CrossArenaManager.setMyRank(event.data.rank)
	CrossArenaManager.setMyBattleScore(event.data.score)
end

--失败默认处理
function CrossPvpGetRankInfoRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end

--获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除
function CrossPvpGetRankInfoRequest.getDebugDatas()
	local testEvt = {data = {}}
	testEvt.data.rankInfos =  {}
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
	table.insert(testEvt.data.rankInfos, rank)

	rank = {}
	rank.rank = 2
	rank.battleScore = 1000
	rank.metaId = 101011
	rank.nickName = "nickName2"
	rank.level = 123
	rank.server = 56
	rank.unionName = "unionName2"
	rank.combat = 112233
	table.insert(testEvt.data.rankInfos, rank)

	rank = {}
	rank.rank = 3
	rank.battleScore = 1000
	rank.metaId = 101011
	rank.nickName = "nickName3"
	rank.level = 123
	rank.server = 56
	rank.unionName = "unionName3"
	rank.combat = 112233
	table.insert(testEvt.data.rankInfos, rank)

	rank = {}
	rank.rank = 4
	rank.battleScore = 1000
	rank.metaId = 101011
	rank.nickName = "nickName4"
	rank.level = 123
	rank.server = 56
	rank.unionName = "unionName4"
	rank.combat = 112233
	table.insert(testEvt.data.rankInfos, rank)

	return testEvt
end