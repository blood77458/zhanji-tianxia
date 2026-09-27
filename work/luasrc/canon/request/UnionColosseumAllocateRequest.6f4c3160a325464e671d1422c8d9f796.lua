--
-- UnionColosseumAllocateRequest.lua
-- Author: zheng.che
-- Date: 2014-05-26 15:37:27
-- 军团斗兽场分配奖励
--
require "canon.request.BaseRequest"

UnionColosseumAllocateRequest = class(BaseRequest)

function UnionColosseumAllocateRequest:ctor()
  self.endpoint = "unionMonsterRewardDistributeSave"--<<<<< 1. 修改指令名称 后端提供
end

function UnionColosseumAllocateRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionColosseumSummonSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionColosseumAllocateRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionColosseumSummonFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

--allocationList 分配列表
function UnionColosseumAllocateRequest.sendRequest(allocationList, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(allocationList, event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end

	-- UnionMonsterReward
	-- <bean desc="斗兽奖励分配">
	-- 	<property code="uid" type="long" desc="用户id" />
	-- 	<property code="amount" type="int" desc="用户分得的奖励数量" />
	-- </bean>

	local params = {unionMonsterRewards = allocationList}--<<<<<
	if SystemManager.debug then
		print("params = " .. tostringRich({params}))--<<<<< 3
	end
	local request = UnionColosseumAllocateRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionColosseumSummonSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionColosseumSummonFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionColosseumAllocateRequest.onSucceedDefault(allocationList, event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. tostringRich({allocationList, event}))--<<<<< 3
	end

	--修改状态
	--设置是否已分配
	UnionManager.setColosseumMonsterRewardDistributed(true)

	--提示分配成功
	local scene = Director:mgr():run()
	SuspensionLabel:showContent(scene, Localization:getInstance():getText("union_monster_reward_distribution_finish_remind"))--战利品已分配给军团成员
end

--失败默认处理
function UnionColosseumAllocateRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716313) then -- User has not joined any union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, nil)
	elseif(errorCode == SHARK_ERROCODE_ORIGH + 6427) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.HAS_NO_UNION_PRIVILIGE_DISTRIBUTE_MONSTER_REWARD, nil, nil, nil)
	elseif(errorCode == SHARK_ERROCODE_ORIGH + 6377) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_MONSTER_IS_ALIVE, nil, nil, nil)
	elseif(errorCode == SHARK_ERROCODE_ORIGH + 6386) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_MONSTER_REWARD_ALREADY_DISTRIBUTED, nil, nil, nil)
	elseif(errorCode == SHARK_ERROCODE_ORIGH + 6339) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_IS_NOT_IN_UNION, nil, nil, nil)
	elseif(errorCode == SHARK_ERROCODE_ORIGH + 6387) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_MONSTER_REWARD_DISTRIBUTE_NUM_NOT_MATCH, nil, nil, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
-- UNION_MONSTER_REWARD_DISTRIBUTE_NUM_NOT_MATCH(6387, "Union monster reward distribute num does not equals to reward num: {0:uid}, {1:distributeNum}, {2:totalNum}"),
-- HAS_NO_UNION_PRIVILIGE_DISTRIBUTE_MONSTER_REWARD(6427, "User has no privilige to distribute monster reward: {0:uid}, {1:serverId}, {2:unionId}, {3:title}"),
-- UNION_MONSTER_IS_ALIVE(6377, "Union monster is alive: {0:uid}, {1:serverId}, {2:unionId}, {3:leftHp}"),
-- UNION_MONSTER_REWARD_ALREADY_DISTRIBUTED(6386, "Reward has already been distributed: {0:uid}, {1:serverId}, {2:unionId}"),
-- USER_IS_NOT_IN_UNION(6339, "User is not in union: {0:uid}, {1:serverId}, {2:unionId}"),

-- 军团斗兽场奖励每周可领个数超限 不提示
-- UNION_MONSTER_REWARD_WEEK_LIMIT(6391, "Can not gain union monster reward because of week limit: {0:uid}, {1:weekLimit}, {1:currGainedNum}"),

end