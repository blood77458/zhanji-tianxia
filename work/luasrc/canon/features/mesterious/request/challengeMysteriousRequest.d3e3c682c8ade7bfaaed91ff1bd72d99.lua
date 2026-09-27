-- <?xml version="1.0" encoding="UTF-8"?>
-- <protocol desc="挑战六星武将副本">
--     <request>
--     	<property code="id" type="int" desc="要挑战的副本id" />
--     	<property code="difficultyDegree" type="int" desc="难度" />
--     </request>
--     <response>
--         <list code="cardInitDatas" ref="BattleCardInitData" desc="敌我卡牌初始数据" />
--         <list code="eventFlow" ref="BattleEvent" desc="战斗事件流" />
--         <list code="rewards" ref="Reward" desc="挑战成功奖励" />
--         <list code="qteRewards" ref="Reward" desc="qte奖励" />
--         <list code="vipRewards" ref="Reward" desc="vip加成奖励" />
--         <property code="qte" type="boolean" desc="是否触发qte" />
--         <property code="win" type="boolean" desc="挑战是否成功" />
--         <property code="leftHpRate" type="float" desc="胜利方剩余血量比例" />
--     </response>
-- </protocol>

require "canon.request.BaseRequest"

ChallengeMysteriousRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
ChallengeMysteriousRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function ChallengeMysteriousRequest:ctor()
  self.endpoint = "challengeMysterious"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function ChallengeMysteriousRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function ChallengeMysteriousRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function ChallengeMysteriousRequest.sendRequestDefalut(id ,difficultyDegree , afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local params = {id = id , difficultyDegree = difficultyDegree}
	local function onSucceed(evt)
		ChallengeMysteriousRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	ChallengeMysteriousRequest.sendRequest(params , onSucceed, ChallengeMysteriousRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function ChallengeMysteriousRequest.sendRequest(params , succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local params = params or {}--<<<<< 2. 附加参数转换成后端提供的接口格式

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

	if not ChallengeMysteriousRequest.TEST then
		--非测试状态 正常流程
		-- if SystemManager.debug then
			print("ChallengeMysteriousRequest->params = " .. tostringRich(params, 2))--深度2 防止打印内容过多 一般够用
		-- end
		local request = ChallengeMysteriousRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(ChallengeMysteriousRequest.getDebugDatas())
	end
end

--成功的默认处理
function ChallengeMysteriousRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("ChallengeMysteriousRequest->event = " .. tostringRich(event))
	end

	CrossUnionPkData.setTeamMirrorRemind(false)
	UnionManager.eventDispatcher:dispatchEvent(Event.new(CrossUnionPkConsts.REFRESH_SHINE_SAVE_TEAM))

	local scene = Director:mgr():run()
	SuspensionLabel:showContent(scene, Localization:getInstance():getText("WGVG_Detail52"))--成功使用奋力一击
end

--失败默认处理
function ChallengeMysteriousRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end


--获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除
function ChallengeMysteriousRequest.getDebugDatas()
	local testEvt = {data = {}}

	return testEvt
end