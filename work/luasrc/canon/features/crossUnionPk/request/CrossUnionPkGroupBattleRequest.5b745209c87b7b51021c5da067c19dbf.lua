-- CrossUnionPkGroupBattleRequest.lua
-- 2015-6-1
-- zheng.che
-- 获得跨服军团战小组赛战斗信息

-- <protocol desc="获得跨服军团战小组赛战斗信息">
-- 	<request>
-- 	</request>
-- 	<response>
-- 		<property code="battleReport" ref="SharkUnionBattlefieldReport" desc="城池的战报" />
-- 		<property code="changePoints" type="int" desc="变化的积分数" />
-- 		<property code="currPoints" type="int" desc="当前积分" />
-- 	</response>
-- </protocol>

require "canon.request.BaseRequest"

CrossUnionPkGroupBattleRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
CrossUnionPkGroupBattleRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function CrossUnionPkGroupBattleRequest:ctor()
  self.endpoint = "crossGVGGroupBattle"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function CrossUnionPkGroupBattleRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function CrossUnionPkGroupBattleRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function CrossUnionPkGroupBattleRequest.sendRequestDefalut(afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		CrossUnionPkGroupBattleRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	CrossUnionPkGroupBattleRequest.sendRequest(onSucceed, CrossUnionPkGroupBattleRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function CrossUnionPkGroupBattleRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
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

	if not CrossUnionPkGroupBattleRequest.TEST then
		--非测试状态 正常流程
		if SystemManager.debug then
			print("CrossUnionPkGroupBattleRequest->params = " .. tostringRich(params, 2))--深度2 防止打印内容过多 一般够用
		end
		local request = CrossUnionPkGroupBattleRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(CrossUnionPkGroupBattleRequest.getDebugDatas())
	end
end

--成功的默认处理
function CrossUnionPkGroupBattleRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("CrossUnionPkGroupBattleRequest->event = " .. tostringRich(event, 3))--太大
	end

	--进入战场
	local params = {}

	params.BattleEnterEnum = BattleEnterEnum.kCrossGVGGroupBattle
	params.BattleBackType = BattleBackType.kCrossGVGGroupBattle

	CrossUnionPk.gotoBattleField(event.data, nil , params)
end

--失败默认处理
function CrossUnionPkGroupBattleRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
		if errorCode == 716313 then
			--玩家没加入任何军团 返回主界面
			local scene = Director:mgr():run()
			scene:replaceScene(MainMenuScene)
		elseif errorCode == 717030 then
			--每日挑战次数已达上限 刷新挑战次数
			UnionManager.eventDispatcher:dispatchEvent(Event.new(CrossUnionPkConsts.NEED_REFRESH_TEAM_ADJUST_SCENE))
		end
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end

--获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除
function CrossUnionPkGroupBattleRequest.getDebugDatas()
	local outline
	local testEvt = {data = {}}

	return testEvt
end