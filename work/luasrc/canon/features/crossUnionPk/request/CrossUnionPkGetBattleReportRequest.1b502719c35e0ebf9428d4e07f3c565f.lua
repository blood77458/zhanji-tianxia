-- CrossUnionPkGetBattleReportRequest.lua
-- 2015-4-21
-- zheng.che
-- 获取gvg战斗信息

-- <protocol desc="获取gvg战斗信息">
-- 	<request>
-- 		<property code="reportId" type="int" desc="战报id" />
-- 		<property code="knockout" type="boolean" desc="是否是淘汰赛" />
-- 	</request>
-- 	<response>
-- 		<property code="battleReport" ref="SharkUnionBattlefieldReport" desc="战报" />
-- 	</response>
-- </protocol>

require "canon.request.BaseRequest"

CrossUnionPkGetBattleReportRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
CrossUnionPkGetBattleReportRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function CrossUnionPkGetBattleReportRequest:ctor()
  self.endpoint = "getGvgBattleResultDetail"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function CrossUnionPkGetBattleReportRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function CrossUnionPkGetBattleReportRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
--reportId 战报id
--isKnockout 是否是淘汰赛
--battleSubType 战斗子类型
function CrossUnionPkGetBattleReportRequest.sendRequestDefalut(reportId, isKnockout, battleSubType, afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		CrossUnionPkGetBattleReportRequest.onSucceedDefault(evt , isKnockout)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	CrossUnionPkGetBattleReportRequest.sendRequest(reportId, isKnockout, battleSubType, onSucceed, CrossUnionPkGetBattleReportRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function CrossUnionPkGetBattleReportRequest.sendRequest(reportId, isKnockout, battleSubType, succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local params = {reportId = reportId, knockout = isKnockout}--<<<<< 2. 附加参数转换成后端提供的接口格式

	local function onSucceedHandle(event)
		event.params = params
		event.battleSubType = battleSubType
		if succeedCallback then
			succeedCallback(event)
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end

	if not CrossUnionPkGetBattleReportRequest.TEST then
		--非测试状态 正常流程
		if SystemManager.debug then
			print("CrossUnionPkGetBattleReportRequest->params = " .. tostringRich(params, 3))--深度3 防止打印内容过多 一般够用
		end
		local request = CrossUnionPkGetBattleReportRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(CrossUnionPkGetBattleReportRequest.getDebugDatas())
	end
end

--成功的默认处理
function CrossUnionPkGetBattleReportRequest.onSucceedDefault(event , isKnockout)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("CrossUnionPkGetBattleReportRequest->event = " .. tostringRich(event, 3))--太大
	end

	--进入战场
	local params = {}
	if isKnockout then
		params.BattleEnterEnum = BattleEnterEnum.kCrossGVGRankBattle
		params.BattleBackType = BattleBackType.kCrossGVGRankBattle
	else
		params.BattleEnterEnum = BattleEnterEnum.kCrossGVGGroupBattle
		params.BattleBackType = BattleBackType.kCrossGVGGroupBattle
	end
	CrossUnionPk.gotoBattleField(event.data, event.battleSubType , params)
end

--失败默认处理
function CrossUnionPkGetBattleReportRequest.onFailedDefault(event)
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
function CrossUnionPkGetBattleReportRequest.getDebugDatas()
	local outline
	local testEvt = {data = {}}

	return testEvt
end