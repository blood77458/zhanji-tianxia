-- CrossUnionPkGetGroupRankScoreRequest.lua
-- 2015-4-15
-- zheng.che
-- 取得跨服gvg 排位赛数据

-- <protocol desc="获得军团积分前十名及自己">
-- 	<request>
-- 	</request>
-- 	<response>
-- 		<property code="selfScore" ref="CrossGVGScoreInfo" desc="自己军团的积分信息" />
-- 		<list code="top10ScoreList" ref="CrossGVGScoreInfo" desc="积分前十名军团信息" />
-- 	</response>
-- </protocol>

-- CrossGVGScoreInfo
-- <bean desc="跨服gvg某军团积分信息">
-- 	<property code="unionId" type="int" desc="军团id" />
-- 	<property code="unionName" type="String" desc="军团名" />
-- 	<property code="score" type="int" desc="军团当前积分" />
-- 	<property code="rank" type="int" desc="当前积分排名" />
-- </bean>

require "canon.request.BaseRequest"

CrossUnionPkGetGroupRankScoreRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
CrossUnionPkGetGroupRankScoreRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function CrossUnionPkGetGroupRankScoreRequest:ctor()
  self.endpoint = "getCrossGvgGroupTop10Score"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function CrossUnionPkGetGroupRankScoreRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function CrossUnionPkGetGroupRankScoreRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function CrossUnionPkGetGroupRankScoreRequest.sendRequestDefalut(afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		CrossUnionPkGetGroupRankScoreRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	CrossUnionPkGetGroupRankScoreRequest.sendRequest(onSucceed, CrossUnionPkGetGroupRankScoreRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function CrossUnionPkGetGroupRankScoreRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
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

	if not CrossUnionPkGetGroupRankScoreRequest.TEST then
		--非测试状态 正常流程
		if SystemManager.debug then
			print("CrossUnionPkGetGroupRankScoreRequest->params = " .. tostringRich(params, 2))--深度2 防止打印内容过多 一般够用
		end
		local request = CrossUnionPkGetGroupRankScoreRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(CrossUnionPkGetGroupRankScoreRequest.getDebugDatas())
	end
end

--成功的默认处理
function CrossUnionPkGetGroupRankScoreRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("CrossUnionPkGetGroupRankScoreRequest->event = " .. tostringRich(event))
	end
end

--失败默认处理
function CrossUnionPkGetGroupRankScoreRequest.onFailedDefault(event)
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

--获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除
function CrossUnionPkGetGroupRankScoreRequest.getDebugDatas()

	local outline
	local testEvt = {data = {}}

	--自己军团的积分信息
	testEvt.data.selfScore =  {unionId = 234, unionName = "attUnion", score = 12, rank = 3}

	--积分前十名军团信息
	testEvt.data.top10ScoreList =  {}
	
	table.insert(testEvt.data.top10ScoreList, {unionId = 234, unionName = "attUnion", score = 12, rank = 1})
	table.insert(testEvt.data.top10ScoreList, {unionId = 234, unionName = "attUnion", score = 12, rank = 2})
	table.insert(testEvt.data.top10ScoreList, {unionId = 234, unionName = "attUnion", score = 12, rank = 3})
	table.insert(testEvt.data.top10ScoreList, {unionId = 234, unionName = "attUnion", score = 12, rank = 4})
	table.insert(testEvt.data.top10ScoreList, {unionId = 234, unionName = "attUnion", score = 12, rank = 5})
	table.insert(testEvt.data.top10ScoreList, {unionId = 234, unionName = "attUnion", score = 12, rank = 6})
	table.insert(testEvt.data.top10ScoreList, {unionId = 234, unionName = "attUnion", score = 12, rank = 7})
	table.insert(testEvt.data.top10ScoreList, {unionId = 234, unionName = "attUnion", score = 12, rank = 8})
	table.insert(testEvt.data.top10ScoreList, {unionId = 234, unionName = "attUnion", score = 12, rank = 9})
	table.insert(testEvt.data.top10ScoreList, {unionId = 234, unionName = "attUnion", score = 12, rank = 10})

	return testEvt
end