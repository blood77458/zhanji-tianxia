--
-- UnionCancelDissolveRequest.lua
-- Author: zheng.che
-- Date: 2014-03-24 18:09:13
-- 取消解散军团
--
require "canon.request.BaseRequest"

UnionCancelDissolveRequest = class(BaseRequest)

function UnionCancelDissolveRequest:ctor()
  self.endpoint = "cancelDissolveUnion"--<<<<< 1. 修改指令名称 后端提供
end

function UnionCancelDissolveRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionCancelDissolveSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionCancelDissolveRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionCancelDissolveFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function UnionCancelDissolveRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = UnionCancelDissolveRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionCancelDissolveSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionCancelDissolveFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionCancelDissolveRequest.onSucceedDefault(event)--<<<<< 3
	--print("onSucceedDefault! event = " .. table.tostring(event))

	UnionManager.setMyStatus(UnionManager.STATUS_MEMBER)--回归成员
	UnionManager.setMyDissolvedSeconds(0)--到期时间清零
end

--失败默认处理
function UnionCancelDissolveRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716313) then -- User has not joined any union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, nil)
	elseif(errorCode == 716317) then -- User is not manager of union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_UNION_MANAGER, nil, nil, nil)
	elseif(errorCode == 716329) then -- Union is not in dissolve status: {0:uid}, {1:unionId}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_NOT_IN_DISSOLVE_STATUS, nil, nil, nil)
	elseif(errorCode == 716330) then -- 
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_ALREADY_DISSOLVED, nil, nil, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end

-- 	USER_NOT_JOIN_ANY_UNION(6313, "User has not joined any union: {0:uid}"),
-- USER_NOT_UNION_MANAGER(6317, "User is not manager of union: {0:uid}"),
-- UNION_NOT_IN_DISSOLVE_STATUS(6329, "Union is not in dissolve status: {0:uid}, {1:unionId}"),

-- UNION_ALREADY_DISSOLVED(6330, "Union has already been dissolved: {0:uid}, {1:unionId}"),
end