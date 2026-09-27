--
-- UnionColosseumBuildingInfoRequest.lua
-- Author: zheng.che
-- Date: 2014-05-26 15:49:14
-- 军团斗兽场建筑信息
--
require "canon.request.BaseRequest"

UnionColosseumBuildingInfoRequest = class(BaseRequest)

function UnionColosseumBuildingInfoRequest:ctor()
  self.endpoint = "getUnionBuildingColosseumInfo"--<<<<< 1. 修改指令名称 后端提供
end

function UnionColosseumBuildingInfoRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionColosseumBuildingInfoSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionColosseumBuildingInfoRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionColosseumBuildingInfoFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function UnionColosseumBuildingInfoRequest.sendRequest(succeedCallback, failedCallback, withoutLoading)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = UnionColosseumBuildingInfoRequest.new(params, rpc.SendingPriority.kHigh)
	if withoutLoading then
		request.showLoading = false
	end
	request:addEventListener(RequestNotifyEnum.UnionColosseumBuildingInfoSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionColosseumBuildingInfoFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionColosseumBuildingInfoRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. tostringRich({event}))--<<<<< 3
	end

	--写入军团斗兽场数据
	-- <response>
 --    	<property code="level" type="int" desc="军团斗兽场等级" />
 --    	<property code="summonTimes" type="int" desc="本周召唤次数" />
 --    	<property code="sharkUnionMonster" ref="SharkUnionMonster" desc="军团怪兽信息" />
 --    </response>

 	--设置斗兽场等级
 	UnionManager.setBuildingLevel(UnionManager.UNION_BUILDING_COLOSSEUM, event.data.level)
 	--本周已召唤次数
 	UnionManager.setColosseumWeekSommonTImes(event.data.summonTimes)
	--设置排行榜列表 table
	UnionManager.setColosseumRanks(event.data.rankList)
	--设置军团财富信息
	UnionManager.setUnionWealth(event.data.unionWealth)
 	--boss信息
 	if event.data.sharkUnionMonster then
 		--存在boss
		--设置怪物召唤者
		UnionManager.setColosseumMonsterCallerNick(event.data.sharkUnionMonster.summonUserNickname)
		--设置怪物当前血量
		UnionManager.setColosseumMonsterCurrentHp(event.data.sharkUnionMonster.monsterLeftHp)
		--设置怪物逃跑时间戳
		UnionManager.setColosseumMonsterRunTime(event.data.sharkUnionMonster.escapeSeconds)
		--设置是否双倍奖励
		UnionManager.setColosseumMonsterIsDouble(event.data.sharkUnionMonster.rewardDouble)
		--设置怪物编号
		UnionManager.setColosseumMonsterMetaId(event.data.sharkUnionMonster.monsterId)
		--设置怪物结算奖励的数量
		UnionManager.setColosseumMonsterRewardAmount(event.data.sharkUnionMonster.reward.amount)
		--设置分配者
		UnionManager.setColosseumDividerUid(event.data.sharkUnionMonster.distributingUid)
		--设置是否已分配
		UnionManager.setColosseumMonsterRewardDistributed(event.data.sharkUnionMonster.rewardDistributed)
	end
end

--失败默认处理
function UnionColosseumBuildingInfoRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716313) then -- User has not joined any union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, UnionColosseumBuildingInfoRequest.onErrorRefresh)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode, nil, UnionColosseumBuildingInfoRequest.onErrorRefresh)
	end
-- 	USER_NOT_JOIN_ANY_UNION(6313, "User has not joined any union: {0:uid}")

end

--收到错误码导致的内容刷新
function UnionColosseumBuildingInfoRequest.onErrorRefresh()
	--刷新军团斗兽场数据
	UnionColosseumBuildingInfoRequest.sendRequest(UnionColosseumBuildingInfoRequest.onSucceedDefault, UnionColosseumBuildingInfoRequest.onFailedDefault)
end