-- <?xml version="1.0" encoding="UTF-8"?>
-- <protocol desc="获得跨服军团战主界面">
-- 	<request>
-- 	</request>
-- 	<response>
-- 		<property code="version" type="int" desc="阵型版本号" />
-- 		<property code="striveInspireNum" type="int" desc="奋力一击" />
-- 		<property code="coinInspireNum" type="int" desc="金币鼓舞次数" />
-- 		<property code="gemInspireNum" type="int" desc="金币鼓舞次数" />
-- 		<list code="signs" ref="ApplicantGvgUserInfo" desc="报名玩家信息" />
-- 	</response>
-- </protocol>

require "canon.request.BaseRequest"

GetCrossGvgInfoRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
GetCrossGvgInfoRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function GetCrossGvgInfoRequest:ctor()
  self.endpoint = "getCrossGvgInfo"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function GetCrossGvgInfoRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function GetCrossGvgInfoRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function GetCrossGvgInfoRequest.sendRequestDefalut(afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		GetCrossGvgInfoRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	GetCrossGvgInfoRequest.sendRequest(onSucceed, GetCrossGvgInfoRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function GetCrossGvgInfoRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
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

	if not GetCrossGvgInfoRequest.TEST then
		--非测试状态 正常流程
		if SystemManager.debug then
			print("GetCrossGvgInfoRequest->params = " .. tostringRich(params, 2))--深度2 防止打印内容过多 一般够用
		end
		local request = GetCrossGvgInfoRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(GetCrossGvgInfoRequest.getDebugDatas())
	end
end

--成功的默认处理
function GetCrossGvgInfoRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("GetCrossGvgInfoRequest->event = " .. tostringRich(event))
	end

	--写入当前玩家银币鼓舞次数 和 奋力一击次数 add by zheng.che @ 2015-5-25
	event.data.coinInspireNum = 0
	event.data.striveInspireNum = 0
	local myUid = DataManager.getCurrUser().uid
	for i, v in ipairs(event.data.signs) do
		if v.uid == myUid then
			--有自己
			event.data.coinInspireNum = v.coinInspireNum
			event.data.striveInspireNum = v.striveInspireNum
		end
	end

	-- CrossArenaManager.setShowRanks(event.data.rankInfos)
	-- CrossArenaManager.setMyRank(event.data.rank)
	-- CrossArenaManager.setMyBattleScore(event.data.score)
	CrossUnionPkData.setCrossGvgInfo(event.data)
end

--失败默认处理
function GetCrossGvgInfoRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
		if errorCode == 716313 then
			--玩家没加入任何军团 返回主界面
			local scene = Director:mgr():run()
			scene:replaceScene(MainMenuScene)
		end
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end

-- 		<property code="version" type="int" desc="阵型版本号" />
-- 		<property code="striveInspireNum" type="int" desc="奋力一击" />
-- 		<property code="coinInspireNum" type="int" desc="金币鼓舞次数" />
-- 		<property code="gemInspireNum" type="int" desc="金币鼓舞次数" />
-- 		<property code="forward" ref="UserGvgFormationInfo" desc="单挑战玩家信息" />

-- 		<list code="signs" ref="ApplicantGvgUserInfo" desc="报名玩家信息" />

	-- <property code="uid" type="long" desc="用户id" />
	-- <property code="userName" type="String" desc="人物名称" />
	-- <property code="mainCardMeataId" type="int" desc="主卡牌metaId" />
	-- <property code="title" type="int" desc="职位" />
	-- <property code="level" type="int" desc="等级" />
	-- <property code="pkRank" type="int" desc="竞技场" />
	-- <property code="fightCapacity" type="int" desc="战斗力" />
	-- <property code="striveInspireNum" type="boolean" desc="是否奋力一击" />
	-- <property code="gemInspireNum" type="int" desc="金币鼓舞次数" />
	-- <property code="coinInspireNum" type="int" desc="银币鼓舞次数" />

--获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除
function GetCrossGvgInfoRequest.getDebugDatas()
	local testEvt = {data = {}}
	testEvt.data.version =  1
	testEvt.data.striveInspireNum =  0
	testEvt.data.coinInspireNum =  1
	testEvt.data.gemInspireNum =  1

	testEvt.data.signs =  {}
	
	local test = {
	uid = 333,
	userName = "年后",
	mainCardMeataId = 101011,
	title = 1,
	level = 100,
	pkRank = 1,
	fightCapacity = 1,
	striveInspireNum = true,
	gemInspireNum = 1,
	coinInspireNum = 1,
	position = 11,
}
	table.insert(testEvt.data.signs , test)	

	local test = {
	uid = 2,
	userName = "年后2",
	mainCardMeataId = 101012,
	title = 1,
	level = 100,
	pkRank = 1,
	fightCapacity = 1,
	striveInspireNum = true,
	gemInspireNum = 1,
	coinInspireNum = 1,
	position = 21,
}

	table.insert(testEvt.data.signs , test)	
	local test = {
	uid = 2,
	userName = "年后2",
	mainCardMeataId = 101012,
	title = 1,
	level = 100,
	pkRank = 1,
	fightCapacity = 1,
	striveInspireNum = true,
	gemInspireNum = 1,
	coinInspireNum = 1,
	position = 1,
}

	table.insert(testEvt.data.signs , test)	

	return testEvt
end