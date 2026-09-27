-- EliteSweepRequest.lua
-- 2015-3-27
-- zheng.che
-- 精英关卡扫荡

-- <protocol desc="扫荡精英关卡">
--     <request>
--     	<property code="eliteId" type="int" desc="精英关卡id" />
--     </request>
--     <response>
--     	<list code="rewards" ref="ClearMissionReward" desc="扫荡结果" />
--     </response>
-- </protocol>

require "canon.request.BaseRequest"

EliteSweepRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
EliteSweepRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function EliteSweepRequest:ctor()
  self.endpoint = "clearElite"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function EliteSweepRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function EliteSweepRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function EliteSweepRequest.sendRequestDefalut(eliteId, rounds, eilteMissionInfo, afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		EliteSweepRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	EliteSweepRequest.sendRequest(eliteId, rounds, eilteMissionInfo, onSucceed, EliteSweepRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function EliteSweepRequest.sendRequest(eliteId, rounds, eilteMissionInfo, succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local params = {eliteId = eliteId}--<<<<< 2. 附加参数转换成后端提供的接口格式

	local function onSucceedHandle(event)
		event.params = params
		event.rounds = rounds
		event.eilteMissionInfo = eilteMissionInfo
		if succeedCallback then
			succeedCallback(event)
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end

	if not EliteSweepRequest.TEST then
		--非测试状态 正常流程
		local request = EliteSweepRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(EliteSweepRequest.getDebugDatas())
	end
end

--成功的默认处理
function EliteSweepRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("EliteSweepRequest->event = " .. tostringRich(event))
	end

	--更新体力
	RewardManager.setEnergy(event.data.lastEnergy)

	--添加奖励
	RewardManager:getReward(event.data.mergeRewards)

	--合并显示奖励内容
	local mergedMissionRewards = {}
	for _, aClearMissionReward in ipairs(event.data.rewards) do
		local aMergedMissionReward = {}
		aMergedMissionReward.round = aClearMissionReward.round
		aMergedMissionReward.rewards = {}
		local aRewardType
		local aRewardMetaId
		local aReward
		for _, aTempReward in ipairs(aClearMissionReward.rewards) do
			if (aRewardType == aTempReward.itemType) and (aRewardMetaId == aTempReward.metaId) then
				aReward.amount = aReward.amount + 1
			else
				aRewardType = aTempReward.itemType
				aRewardMetaId = aTempReward.metaId
				aReward = aTempReward
				table.insert(aMergedMissionReward.rewards, aReward)
			end
		end
		table.insert(mergedMissionRewards, aMergedMissionReward)
	end

	--显示奖励
	local scene = Director:mgr():run()
	local aPanel = SweepResultPanel:create(scene, mergedMissionRewards)
	scene:addChild(aPanel)
	aPanel:scaleIn()

	--更新已挑战计数
	event.eilteMissionInfo.challengeNum = event.data.challengeNum
end

--失败默认处理
function EliteSweepRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end

--获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除
function EliteSweepRequest.getDebugDatas()
	local testEvt = {data = {}}

	return testEvt
end