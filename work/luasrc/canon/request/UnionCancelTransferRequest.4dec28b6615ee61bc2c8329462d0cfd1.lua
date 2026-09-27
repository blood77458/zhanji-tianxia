--
-- UnionCancelTransferRequest.lua
-- Author: zheng.che
-- Date: 2014-03-26 10:24:34
-- 撤销转让军团长
--
require "canon.request.BaseRequest"

UnionCancelTransferRequest = class(BaseRequest)

function UnionCancelTransferRequest:ctor()
  self.endpoint = "cancelTransferUnion"--<<<<< 1. 修改指令名称 后端提供
end

function UnionCancelTransferRequest:onSuccess( data )  
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionCancelTransferSucceed, data))--<<<<< 2. 修改枚举名称 定义在BaseRequest里 不能重复
end

function UnionCancelTransferRequest:onError( error )
  self:dispatchEvent(Event.new(RequestNotifyEnum.UnionCancelTransferFailed, {retCode = error}))--<<<<< 2
end

-------------------------------------------------------------------静态函数

function UnionCancelTransferRequest.sendRequest(succeedCallback, failedCallback)--<<<<< 3. 如果需要附加参数 从第一个函数参数开始加
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
	local request = UnionCancelTransferRequest.new(params, rpc.SendingPriority.kHigh)
	request:addEventListener(RequestNotifyEnum.UnionCancelTransferSucceed, onSucceedHandle)--<<<<< 2
	request:addEventListener(RequestNotifyEnum.UnionCancelTransferFailed, onFailedHandle)--<<<<< 2
	request:start()
end

--成功的默认处理
function UnionCancelTransferRequest.onSucceedDefault(event)--<<<<< 3
	--print("onSucceedDefault! event = " .. table.tostring(event))

	UnionManager.setUnionTransferTime(0)
	UnionManager.getUnionStatus(UnionManager.UNION_STATUS_NORMAL)
end

--失败默认处理
function UnionCancelTransferRequest.onFailedDefault(event)--<<<<< 4. 修改错误码对应逻辑处理
	--print("onFailedDefault!")
	local errorCode = tonumber(event.data.retCode)
	if(errorCode == 716313) then -- User has not joined any union: {0:uid}
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_NOT_JOIN_ANY_UNION, nil, nil, nil)
	elseif(errorCode == 716327) then -- 
		CanonMessageBox:showCommErrorBox(CommErrorCodes.USER_IS_NOT_UNION_MANAGER, nil, nil, nil)
	elseif(errorCode == 716328) then -- 
		CanonMessageBox:showCommErrorBox(CommErrorCodes.UNION_NOT_IN_TRANSFER_STATUS, nil, nil, nil)
	else
		CanonMessageBox:showCommUnHandleErrorBox(errorCode)
	end
-- 	USER_NOT_JOIN_ANY_UNION(6313, "User has not joined any union: {0:uid}")
-- USER_IS_NOT_UNION_MANAGER(6327, "User is not manager of union: {0:uid}, {1:unionId}")
-- UNION_NOT_IN_TRANSFER_STATUS(6328, "Union is not in transfer status: {0:uid}, {1:unionId}")

end