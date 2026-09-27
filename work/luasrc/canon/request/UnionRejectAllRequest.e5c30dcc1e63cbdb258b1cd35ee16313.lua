--
-- UnionRejectAllRequest.lua
-- Author: zheng.che
-- Date: 2014-03-25 10:52:41
-- 请求全部拒绝
--
require "canon.request.BaseRequest"

UnionRejectAllRequest = class(BaseRequest)

function UnionRejectAllRequest:ctor()
  self.endpoint = "rejectUnionAllApplies"--<<<<< 1. 修改指令名称 后端提供
end

function UnionRejectAllRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionRejectAllSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionRejectAllRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionRejectAllFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

-- applierUid 目标玩家id
function UnionRejectAllRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	print("params = " .. table.tostring(params))
	local request = UnionRejectAllRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionRejectAllSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionRejectAllFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionRejectAllRequest.onSucceedDefault(event)--<<<<< 3
	--print("onSucceedDefault! event = " .. table.tostring(event))

	--删除全部申请者
	UnionManager.delAllApplier()
end

--失败默认处理
function UnionRejectAllRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
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