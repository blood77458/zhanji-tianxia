--
-- UnionGetUnionInfoRequest.lua
-- Author: zheng.che
-- Date: 2014-03-20 14:25:21
-- 请求获得军团信息
--
require "canon.request.BaseRequest"

UnionGetUnionInfoRequest = class(BaseRequest)

function UnionGetUnionInfoRequest:ctor()
  self.endpoint = "getUnionInfo"--<<<<< 1. 修改指令名称 后端提供
end

function UnionGetUnionInfoRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionGetUnionInfoSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionGetUnionInfoRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionGetUnionInfoFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function UnionGetUnionInfoRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = UnionGetUnionInfoRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionGetUnionInfoSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionGetUnionInfoFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionGetUnionInfoRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. tostringRich({event}))--<<<<< 3
	end

	--存储军团信息
	UnionManager.setUnionData(event.data.sharkUnion)
	--存储军团建筑信息
	UnionManager.setUnionBuildingData(event.data.sharkUnionBuildingWrapper)

	--设置军团兽剩余hp
	UnionManager.setColosseumMonsterCurrentHp(tonumber(event.data.unionMonsterHp))
	--设置军团兽逃跑时间
	UnionManager.setColosseumMonsterRunTime(event.data.unionMonsterEscapeSeconds)
	--设置军团兽奖励是否已分配
	UnionManager.setColosseumMonsterRewardDistributed(event.data.canDistributeMonsterReward)

	UnionPkData.setUnionWarLightOn(event.data.unionWarLightOn)
	--更新总战斗力
	UnionPkData.setUnionTotalFightCapacity(tonumber(event.data.unionTotalFightCapacity))
	--清空申请列表
	UnionManager.clearApplyedUnions()
end

--失败默认处理
function UnionGetUnionInfoRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716313) then -- User has not joined any union: {0:uid}
		local function onClose()
			--回到军团列表
			print("onClose")
			--UnionManager.gotoUnionListScene()
		end
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, onClose)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
	--USER_NOT_JOIN_ANY_UNION(6313, "User has not joined any union: {0:uid}")

end