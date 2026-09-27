--
-- UnionColosseumSummonRequest.lua
-- Author: zheng.che
-- Date: 2014-05-26 14:37:11
-- 召唤军团boss
--
require "canon.request.BaseRequest"

UnionColosseumSummonRequest = class(BaseRequest)

function UnionColosseumSummonRequest:ctor()
  self.endpoint = "summonUnionMonster"--<<<<< 1. 修改指令名称 后端提供
end

function UnionColosseumSummonRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionColosseumSummonSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionColosseumSummonRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionColosseumSummonFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

--type 召唤类型
--bossId 召唤对象的编号
function UnionColosseumSummonRequest.sendRequest(monsterMetaId, summonType, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(monsterMetaId, summonType, event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = {monsterMetaId = monsterMetaId, summonType = summonType}--<<<<< 3
	if SystemManager.debug then
		print("params = " .. tostringRich({params}))--<<<<< 3
	end
	local request = UnionColosseumSummonRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionColosseumSummonSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionColosseumSummonFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionColosseumSummonRequest.onSucceedDefault(monsterMetaId, summonType, event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. tostringRich({monsterMetaId, summonType, event}))--<<<<< 3
	end

	--召唤成功
	--提示成功召唤
	local scene = Director:mgr():run()
	SuspensionLabel:showContent(scene, Localization:getInstance():getText("union_monster_summon_finish_remind", {name = UnionManager.getBossName(monsterMetaId)}))--成功召唤怪兽{name}
 	--本周已召唤次数自增1
 	UnionManager.setColosseumWeekSommonTImes(UnionManager.getColosseumWeekSummonTimes() + 1)
 	if summonType == UnionManager.SUMMON_DOUBLE then
 		--扣金币
 		RewardManager:getReward({{itemType = ResourceEnum.GEMS, amount = -UnionManager.getRewardDoubleGemCost()}})
 	end
	--清空排行榜
	UnionManager.setColosseumRanks({})

 	--boss信息
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

--失败默认处理
function UnionColosseumSummonRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == SHARK_ERROCODE_ORIGH + 6313) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, nil)
	elseif(errorCode == SHARK_ERROCODE_ORIGH + 6378) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNOIN_MONSTER_CANNOT_SUMMON_MONSTER_THIS_TIME, nil, nil, nil)
	elseif(errorCode == SHARK_ERROCODE_ORIGH + 6426) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.HAS_NO_UNION_PRIVILIGE_SUMMON_MONSTER, nil, nil, nil)
	elseif(errorCode == SHARK_ERROCODE_ORIGH + 6384) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_MONSTER_COLOSSEUM_LEVEL_LIMIT, nil, nil, nil)
	elseif(errorCode == SHARK_ERROCODE_ORIGH + 6388) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_MONSTER_SUMMON_TIMES_LIMIT, nil, nil, nil)
	elseif(errorCode == SHARK_ERROCODE_ORIGH + 6377) then
		CanonMessageBox:Show(getTextByKey("union_monster_summon_not_satisfied1"), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, nil, nil)--同一时间只能召唤一只怪兽
	elseif(errorCode == SHARK_ERROCODE_ORIGH + 6379) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_MONSTER_HAS_REWARD_NOT_DISTRIBUTE, nil, nil, nil)
	elseif(errorCode == SHARK_ERROCODE_ORIGH + 513) then
		--金币不够 请充值
		local scene = Director:mgr():run()
		local function replaceSceneFunc()
		end
		local aPanel = AssistantMessageBoxPanel:create( scene, AsMessageBoxType.addCoin, nil, {onReplaceSceneFunc = replaceSceneFunc} )
		scene:addChild(aPanel)
		aPanel:scaleIn()
	elseif(errorCode == SHARK_ERROCODE_ORIGH + 6390) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_MONSTER_SOMEONE_SUMMONING_MONSTER, nil, nil, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
-- UNOIN_MONSTER_CANNOT_SUMMON_MONSTER_THIS_TIME(6378, "Cannot summon monster this time: {0:uid}, {1:featureName}"),
-- USER_NOT_JOIN_ANY_UNION(6313, "User has not joined any union: {0:uid}"),
-- HAS_NO_UNION_PRIVILIGE_SUMMON_MONSTER(6426, "User has no privilige to summon monster: {0:uid}, {1:serverId}, {2:unionId}, {3:title}"),
-- UNION_MONSTER_COLOSSEUM_LEVEL_LIMIT(6384, "Can not summon monster because of the level of colosseum: {0:uid}, {1:currLevel}, {2:unlockLevel}"),
-- UNION_MONSTER_SUMMON_TIMES_LIMIT(6388, "Cannot summon monster for summon times limit: {0:uid}, {1:currSummonTimes}, {2:maxSummonTimes}"),
-- UNION_MONSTER_IS_ALIVE(6377, "Union monster is alive: {0:uid}, {1:serverId}, {2:unionId}, {3:leftHp}"),
-- UNION_MONSTER_HAS_REWARD_NOT_DISTRIBUTE(6379, "You should distribute the rewards before summon monster: {0:uid}, {1:serverId}, {2:unionId}"),
-- REQUISITE_GEM_NOT_ENOUGH(513, "Gold is not enough: {0:uid}, {1:currGold}, {2:needGold}"),
--UNION_MONSTER_SOMEONE_SUMMONING_MONSTER(6390, "Someone is summoning monster: {0:uid}, {1:unionId}"),

end