--
-- UnionColosseumGetRankRequest.lua
-- Author: zheng.che
-- Date: 2014-05-26 15:21:08
-- 获得斗兽场排行榜
--
require "canon.request.BaseRequest"

UnionColosseumGetRankRequest = class(BaseRequest)

function UnionColosseumGetRankRequest:ctor()
  self.endpoint = "getUnionMonsterRank"--<<<<< 1. 修改指令名称 后端提供
end

function UnionColosseumGetRankRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionColosseumGetRankSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionColosseumGetRankRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionColosseumGetRankFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function UnionColosseumGetRankRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = UnionColosseumGetRankRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionColosseumGetRankSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionColosseumGetRankFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionColosseumGetRankRequest.onSucceedDefault(event)--<<<<< 3
	if SystemManager.debug then
		print("onSucceedDefault! event = " .. tostringRich({event}))--<<<<< 3
	end

	-- <response>
 --    	<list code="rankList" ref="UnionMonsterDamage" desc="伤害排行榜" />
 --    </response>

--  <bean desc="斗兽伤害值">
-- 	<property code="uid" type="long" desc="用户id" />
-- 	<property code="nickName" type="string" desc="用户昵称" />
-- 	<property code="totalDamage" type="int" desc="用户对怪兽的累积伤害" />
-- </bean>

	--存储排行榜数据
 	UnionManager.setColosseumRanks(event.data.rankList)
end

--失败默认处理
function UnionColosseumGetRankRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716313) then -- User has not joined any union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, UnionColosseumGetRankRequest.onErrorRefresh)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode, nil, UnionColosseumGetRankRequest.onErrorRefresh)
	end
-- 	USER_NOT_JOIN_ANY_UNION(6313, "User has not joined any union: {0:uid}")

end

--收到错误码导致的内容刷新
function UnionColosseumGetRankRequest.onErrorRefresh()
	--刷新军团斗兽场数据
	UnionColosseumBuildingInfoRequest.sendRequest(UnionColosseumBuildingInfoRequest.onSucceedDefault, UnionColosseumBuildingInfoRequest.onFailedDefault)
end