--
-- UnionRejectRequest.lua
-- Author: zheng.che
-- Date: 2014-03-21 16:13:15
-- 军团拒绝申请
--
require "canon.request.BaseRequest"

UnionRejectRequest = class(BaseRequest)

function UnionRejectRequest:ctor()
  self.endpoint = "rejectUnionApply"--<<<<< 1. 修改指令名称 后端提供
end

function UnionRejectRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionRejectSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionRejectRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionRejectFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

-- applierUid 目标玩家id
function UnionRejectRequest.sendRequest(applierUid, succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	--print("params = " .. table.tostring(params))
	local request = UnionRejectRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionRejectSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionRejectFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionRejectRequest.onSucceedDefault(applierUid, event)--<<<<< 3
	--print("onSucceedDefault! event = " .. table.tostring(event))
	
	--删除申请者
	UnionManager.delApplier(applierUid)
end

--失败默认处理
function UnionRejectRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716313) then -- User has not joined any union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, nil)
	elseif(errorCode == 716421) then -- User has no privilige to applly examine: {0:uid}, {1:serverId}, {2:unionId}, {3:title}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.HAS_NO_UNION_PRIVILIGE_APPLY_EXAMINE, nil, nil, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
-- 	USER_NOT_JOIN_ANY_UNION(6313, "User has not joined any union: {0:uid}")
-- HAS_NO_UNION_PRIVILIGE_APPLY_EXAMINE(6421, "User has no privilige to applly examine: {0:uid}, {1:serverId}, {2:unionId}, {3:title}")

end