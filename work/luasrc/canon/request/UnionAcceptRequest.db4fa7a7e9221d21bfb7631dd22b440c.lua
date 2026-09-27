--
-- UnionAcceptRequest.lua
-- Author: zheng.che
-- Date: 2014-03-21 15:56:31
-- 军团同意申请
--
require "canon.request.BaseRequest"

UnionAcceptRequest = class(BaseRequest)

function UnionAcceptRequest:ctor()
  self.endpoint = "acceptUnionApply"--<<<<< 1. 修改指令名称 后端提供
end

function UnionAcceptRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionAcceptSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionAcceptRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionAcceptFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

-- applierUid 目标玩家id
function UnionAcceptRequest.sendRequest(applierUid, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
	local function onSucceedHandle(event)
		if succeedCallback then
			succeedCallback(applierUid, event)--<<<<< 3
		end
	end 
	local function onFailedHandle(event)
		if failedCallback then
			failedCallback(event)
		end
	end
	local params = {applierUid = applierUid}--<<<<< 3
	local request = UnionAcceptRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionAcceptSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionAcceptFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionAcceptRequest.onSucceedDefault(applierUid, event)--<<<<< 3
	--print("onSucceedDefault! event = " .. table.tostring(event))
	
	--删除申请者
	UnionManager.delApplier(applierUid)
  
  ChatManager.sendChat({method = MethodDict.JOINUNION, uid = applierUid, unionId = UnionManager.getUnionId()})
end

--失败默认处理
function UnionAcceptRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716313) then --User has not joined any union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, nil)
	elseif(errorCode == 716421) then -- User has no privilige to applly examine: {0:uid}, {1:serverId}, {2:unionId}, {3:title}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.HAS_NO_UNION_PRIVILIGE_APPLY_EXAMINE, nil, nil, nil)
	elseif(errorCode == 716320) then -- Union members reach upper: {0:serverId}, {1:unionId}, {2:unionLevel}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_MEMBERS_REACH_UPPER, nil, nil, nil)
	elseif(errorCode == 716314) then -- Union apply is not exist: {0:unionId}, {1:applierId}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_APPLY_NOT_EXIST, nil, nil, nil)
	elseif(errorCode == 716331) then -- Union is in dissolve status: {0:uid}, {1:unionId}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_IN_DISSOLVE_STATUS, nil, nil, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end

-- 	USER_NOT_JOIN_ANY_UNION(6313, "User has not joined any union: {0:uid}"),
-- SHARK_UNION_NOT_EXIST(6315, "SharkUserUnion is not exist: {0:serverId}, {1:unionId}"),
-- HAS_NO_UNION_PRIVILIGE_APPLY_EXAMINE(6421, "User has no privilige to applly examine: {0:uid}, {1:serverId}, {2:unionId}, {3:title}"),
-- UNION_BUILDING_HALL_META_NOT_CONFIGED(6354, "Union building hall meta not configed in union-building-hall.xml: {0:buildingLevel}"),
-- UNION_MEMBERS_REACH_UPPER(6320, "Union members reach upper: {0:serverId}, {1:unionId}, {2:unionLevel}"),
-- UNION_APPLY_NOT_EXIST(6314, "Union apply is not exist: {0:unionId}, {1:applierId}"),

--UNION_IN_DISSOLVE_STATUS(6331, "Union is in dissolve status: {0:uid}, {1:unionId}"),
end