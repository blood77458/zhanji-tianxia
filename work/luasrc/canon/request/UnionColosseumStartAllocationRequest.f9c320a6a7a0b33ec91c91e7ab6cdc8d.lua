--
-- UnionColosseumStartAllocationRequest.lua
-- Author: zheng.che
-- Date: 2014-05-26 15:29:59
-- 军团斗兽场开始分配
--
require "canon.request.BaseRequest"

UnionColosseumStartAllocationRequest = class(BaseRequest)

function UnionColosseumStartAllocationRequest:ctor()
  self.endpoint = "unionMonsterRewardDistributeBegin"--<<<<< 1. 修改指令名称 后端提供
end

function UnionColosseumStartAllocationRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionColosseumStartAllocationSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionColosseumStartAllocationRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionColosseumStartAllocationFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function UnionColosseumStartAllocationRequest.sendRequest(succeedCallback, failedCallback, withoutLoading)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = {}--<<<<< 3
	local request = UnionColosseumStartAllocationRequest.new(params, rpc.SendingPriority.kHigh)
	if withoutLoading then
		request.showLoading = false
	end
	request:addEventListener(RequestNotifyEnum.UnionColosseumStartAllocationSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionColosseumStartAllocationFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionColosseumStartAllocationRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. tostringRich({event}))--<<<<< 3
	end

	--修改分配状态 分配者为当前玩家
	UnionManager.setColosseumDividerUid(DataManager.getGameInitData().sharkUser.uid)

	--重置成员本周领取数量
	local tempHash = {}
	-- <bean desc="斗兽奖励分配">
	-- <property code="uid" type="long" desc="用户id" />
	-- <property code="amount" type="int" desc="用户分得的奖励数量" />
	-- </bean>
	for i, v in ipairs(event.data.currMonsterRewards) do
		tempHash[tostring(v.uid)] = v.amount
	end
	UnionManager.setColosseumWeeklyGiftGetNumHash(tempHash)
end

--失败默认处理
function UnionColosseumStartAllocationRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716313) then -- User has not joined any union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, UnionColosseumStartAllocationRequest.onErrorRefresh)
	elseif(errorCode == SHARK_ERROCODE_ORIGH + 6427) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.HAS_NO_UNION_PRIVILIGE_DISTRIBUTE_MONSTER_REWARD, nil, nil, UnionColosseumStartAllocationRequest.onErrorRefresh)
	elseif(errorCode == SHARK_ERROCODE_ORIGH + 6377) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_MONSTER_IS_ALIVE, nil, nil, UnionColosseumStartAllocationRequest.onErrorRefresh)
	elseif(errorCode == SHARK_ERROCODE_ORIGH + 6386) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_MONSTER_REWARD_ALREADY_DISTRIBUTED, nil, nil, UnionColosseumStartAllocationRequest.onErrorRefresh)
	elseif(errorCode == SHARK_ERROCODE_ORIGH + 6389) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_MONSTER_SOMEONE_DISTRIBUTING_REWARD, nil, nil, UnionColosseumStartAllocationRequest.onErrorRefresh)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode, nil, UnionColosseumStartAllocationRequest.onErrorRefresh)
	end
-- HAS_NO_UNION_PRIVILIGE_DISTRIBUTE_MONSTER_REWARD(6427, "User has no privilige to distribute monster reward: {0:uid}, {1:serverId}, {2:unionId}, {3:title}"),
-- UNION_MONSTER_IS_ALIVE(6377, "Union monster is alive: {0:uid}, {1:serverId}, {2:unionId}, {3:leftHp}"),
-- UNION_MONSTER_REWARD_ALREADY_DISTRIBUTED(6386, "Reward has already been distributed: {0:uid}, {1:serverId}, {2:unionId}"),
--UNION_MONSTER_SOMEONE_DISTRIBUTING_REWARD(6389, "Someone is distributing reward: {0:uid}, {1:unionId}, {2:distributingUid}"),

end

--收到错误码导致的内容刷新
function UnionColosseumStartAllocationRequest.onErrorRefresh()
	--刷新军团斗兽场数据
	UnionColosseumBuildingInfoRequest.sendRequest(UnionColosseumBuildingInfoRequest.onSucceedDefault, UnionColosseumBuildingInfoRequest.onFailedDefault)
end