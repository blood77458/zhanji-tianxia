-- CrossPvpGainBattleRewardRequest.lua
-- 2015-3-10
-- zheng.che
-- 领取跨服pvp奖励

-- <protocol desc="领取跨服pvp奖励">
-- 	<request>
-- 		<property code="type" type="int" desc="领取类型(0-全区礼包;1-排名礼包)" />
-- 	</request>
-- 	<response>
-- 		<list code="rewards" ref="Reward" desc="奖励详情" />
-- 	</response>
-- </protocol>

require "canon.request.BaseRequest"

CrossPvpGainBattleRewardRequest = class(BaseRequest)
--测试状态 仅限内部测试用(一般用于假数据)
CrossPvpGainBattleRewardRequest.TEST = false --提测之前请务必改回默认 false !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

function CrossPvpGainBattleRewardRequest:ctor()
  self.endpoint = "gainCrossPvpBattleReward"--<<<<< 1. 修改指令名称 后端提供
  self.succeedEventName = self.endpoint .. "Succeed"
  self.failedEventName = self.endpoint .. "Failed"
end

function CrossPvpGainBattleRewardRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(self.succeedEventName, data))
end

function CrossPvpGainBattleRewardRequest:onError( error )
  self:dispatchEvent(Event.new(self.failedEventName, {retCode = error}))
end

-------------------------------------------------------------------静态函数

--发送请求 默认处理 成功返回之后可加额外处理(参数可传nil)
function CrossPvpGainBattleRewardRequest.sendRequestDefalut(rewardType, afterSucceedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceed(evt)
		CrossPvpGainBattleRewardRequest.onSucceedDefault(evt)
		if afterSucceedCallback then
			afterSucceedCallback(evt)
		end
	end
	CrossPvpGainBattleRewardRequest.sendRequest(rewardType, onSucceed, CrossPvpGainBattleRewardRequest.onFailedDefault)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
end

--发送请求
function CrossPvpGainBattleRewardRequest.sendRequest(rewardType, succeedCallback, failedCallback)--<<<<< 2. 如果需要附加参数 从第一个函数参数开始加
	local params = {type = rewardType}--<<<<< 2. 附加参数转换成后端提供的接口格式

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

	if not CrossPvpGainBattleRewardRequest.TEST then
		--非测试状态 正常流程
		local request = CrossPvpGainBattleRewardRequest.new(params, rpc.SendingPriority.kHigh)
		request:addEventListener(request.succeedEventName, onSucceedHandle)
		request:addEventListener(request.failedEventName, onFailedHandle)
		request:start()
	else
		--测试流程 假数据
		onSucceedHandle(CrossPvpGainBattleRewardRequest.getDebugDatas())
	end
end

--成功的默认处理
function CrossPvpGainBattleRewardRequest.onSucceedDefault(event)--<<<<< 3. 成功的默认处理 do someting
	if SystemManager.debug then
		print("CrossPvpGainBattleRewardRequest->event = " .. tostringRich(event))
	end

	--标记已领取
	if event.params.type == CrossArenaConsts.REWARD_TYPE_SERVER then
		--全区礼包
		CrossArenaManager.setServerRewardStatus(CrossArenaConsts.REWARD_STATE_GAINED)
	elseif event.params.type == CrossArenaConsts.REWARD_TYPE_RANK then
		--排名礼包
		CrossArenaManager.setRankRewardStatus(CrossArenaConsts.REWARD_STATE_GAINED)
	end

	--获得奖励
	RewardManager:getReward(event.data.rewards)

    --显示获得的奖励
    local scene = Director:mgr():run()
	local aRewardPanel = RewardReviewPanel:create( scene, {rewardList = event.data.rewards, rewardTitle = Localization:getInstance():getText("activity_newyear_rewardTitle")} )
	scene:addChild(aRewardPanel)
	aRewardPanel:scaleIn()
end

--失败默认处理
function CrossPvpGainBattleRewardRequest.onFailedDefault(event)
	local errorCode = tonumber(event.data.retCode)
	local function onErrorConfirm(errorCode)
	end
	local ret = ErrorCodeManager.alert(errorCode, onErrorConfirm)
end

--获得测试用假数据--<<<<< 4. 根据需要填写测试假数据 用完删除
function CrossPvpGainBattleRewardRequest.getDebugDatas()
	local testEvt = {data = {}}
	testEvt.data.rewards =  {}
	local rank
	
	rank = {}
	rank.itemType = 5
	rank.metaId = 101011
	rank.id = 123
	rank.amount = 1
	rank.level = 1
	rank.exp = 56
	table.insert(testEvt.data.rewards, rank)

	return testEvt
end