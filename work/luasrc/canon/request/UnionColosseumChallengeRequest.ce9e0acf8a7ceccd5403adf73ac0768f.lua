--
-- UnionColosseumChallengeRequest.lua
-- Author: zheng.che
-- Date: 2014-05-26 15:17:04
-- 军团挑战怪物
--
require "canon.request.BaseRequest"

UnionColosseumChallengeRequest = class(BaseRequest)

function UnionColosseumChallengeRequest:ctor()
  self.endpoint = "challengeUnionMonster"--<<<<< 1. 修改指令名称 后端提供
end

function UnionColosseumChallengeRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionColosseumChallengeSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionColosseumChallengeRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionColosseumChallengeFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function UnionColosseumChallengeRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = UnionColosseumChallengeRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionColosseumChallengeSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionColosseumChallengeFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionColosseumChallengeRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		--print("onSucceedDefault! event = " .. tostringRich({event}))--<<<<< 3
	end

	-- <response>
 --    	<property code="win" type="boolean" desc="战斗是否胜利" />
	-- 	<property code="damage" type="int" desc="战斗造成的伤害值" />
	-- 	<list code="cardInitDatas" ref="BattleCardInitData" desc="释放完套装技和合体技之后的卡牌初始数据" />
	-- 	<list code="eventFlow" ref="BattleEvent" desc="战斗事件流" />
	-- 	<property code="generalExp" type="int" desc="奖励的武将经验" />
 --    </response>


 	--加经验
 	RewardManager:getReward({{itemType = ResourceEnum.GENERALEXP, amount = event.data.generalExp}})
 	--扣道具
    local delItems = {}
    table.insert(delItems, {itemType = ResourceEnum.PROP, metaId = UnionManager.getUnionMonsterFightItem(), amount = -1})
    RewardManager:getReward(delItems)
    --今日挑战次数+1
    DailyDataManager.setChallengeUnionMonsterTimes(DailyDataManager.getChallengeUnionMonsterTimes() + 1)

    --先设定最大血量为配置的最大血量 否则进入战斗后会以当前血量作为最大值
	event.data.bossHpMax = UnionManager.getBossMaxHp(UnionManager.getColosseumMonsterMetaId())
	--进入战斗
 	Director:sharedDirector():replaceScene(BattleScene:create(event.data, BattleBackType.kUnionColosseum, BattleEnterEnum.kUnionColosseum))
end

--失败默认处理
function UnionColosseumChallengeRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716313) then -- User has not joined any union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, nil)
	elseif(errorCode == SHARK_ERROCODE_ORIGH + 6382) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_MONSTER_ESCAPE, nil, nil, nil)
	elseif(errorCode == SHARK_ERROCODE_ORIGH + 6383) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_MONSTER_IS_DEAD, nil, nil, nil)
	elseif(errorCode == SHARK_ERROCODE_ORIGH + 2301) then
		--道具不足
		local function closeCanonMessageBox()
		end
		local scene = Director:mgr():run()
		local propname = Localization:getInstance():getText(MetaManager.prop_meta[UnionManager.getUnionMonsterFightItem()].name)
		scene.targetInfoPanel = CanonMessageBox:Show(getTextByKey("popup_noProp", {propname = propname}), ShowMessageType.ShowText, ShowButtonType.ID_OK, nil, closeCanonMessageBox, nil)
	elseif(errorCode == SHARK_ERROCODE_ORIGH + 6385) then
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_MONSTER_DAILY_ATT_TIMES_LIMIT, nil, nil, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
-- UNION_MONSTER_ESCAPE(6382, "Union monster escape: {0:uid}, {1:serverId}, {2:unionId}"),
-- UNION_MONSTER_IS_DEAD(6383, "Union monster is dead: {0:uid}, {1:serverId}, {2:unionId}"),
-- PROP_NOT_ENOUGH(2301, "Prop is not enough: {0:uid}, {1:propId}, {2:ownNum}, {3:needNum}"),
-- UNION_MONSTER_DAILY_ATT_TIMES_LIMIT(6385, "Can not challenge today for daily att times limit: {0:uid}, {1:currAttTimes}, {2:maxAttTimes}"),
end